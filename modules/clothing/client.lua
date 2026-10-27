if not lib then return end

-- Clothing slots around the 3D character (see modules/clothing/server.lua).
-- Click a worn piece (or drag it into the inventory) = take it off; drag the item on the character,
-- on its slot, or use it = put it on.

local settings = shared.clothing
local Preview = require 'modules.preview.client'

local Clothing = {}

if not settings.Enabled then
    Clothing.getSlots = function() return {} end
    return Clothing
end

local Items = require 'modules.items.client'

local MALE, FEMALE = `mp_m_freemode_01`, `mp_f_freemode_01`
local slots = {}

for _, slot in ipairs(settings.Slots or {}) do
    slots[slot.key] = slot
end

-- Default animations (dict, clip, duration ms); a slot of the config can have its own `anim`.
local ANIMS = {
    hat = { 'mp_masks@standard_car@ds@', 'put_on_mask', 600 },
    glasses = { 'clothingspecs', 'take_off', 1000 },
    mask = { 'mp_masks@standard_car@ds@', 'put_on_mask', 800 },
    ears = { 'mp_cp_stolen_tut', 'b_think', 900 },
    neck = { 'clothingtie', 'try_tie_positive_a', 1200 },
    watch = { 'nmt_3_rcm-10', 'cs_nigel_dual-10', 1200 },
    bracelet = { 'nmt_3_rcm-10', 'cs_nigel_dual-10', 1200 },
    jacket = { 'clothingtie', 'try_tie_negative_a', 1200 },
    shirt = { 'clothingtie', 'try_tie_negative_a', 1200 },
    vest = { 'clothingtie', 'try_tie_negative_a', 1200 },
    decals = { 'clothingtie', 'try_tie_negative_a', 1200 },
    bag = { 'anim@heists@ornate_bank@grab_cash', 'intro', 1600 },
    gloves = { 'nmt_3_rcm-10', 'cs_nigel_dual-10', 1200 },
    pants = { 're@construction', 'out_of_breath', 1300 },
    shoes = { 'random@domestic', 'pickup_low', 1200 },
}

local busy = false

local function supported()
    local model = GetEntityModel(cache.ped)
    return model == MALE or model == FEMALE
end

local function nakedTable(ped)
    return (settings.Naked or {})[GetEntityModel(ped or cache.ped) == MALE and 'male' or 'female'] or {}
end

local function nakedValue(slot, ped)
    return nakedTable(ped)[slot.component] or 0
end

local collectionsOk = GetPedCollectionNameFromDrawable ~= nil and GetPedCollectionLocalIndexFromDrawable ~= nil
    and GetPedCollectionNameFromProp ~= nil and GetPedCollectionLocalIndexFromProp ~= nil

-- Key of the picture of a piece, as pure_clothing names them: <m|f>/<c11|p0>/<collection or _base>/<index>
local function pictureKey(ped, slot, d)
    if not collectionsOk or d < 0 then return end
    local isProp = slot.prop ~= nil
    local id = slot.prop or slot.component
    local nameOf = isProp and GetPedCollectionNameFromProp or GetPedCollectionNameFromDrawable
    local localOf = isProp and GetPedCollectionLocalIndexFromProp or GetPedCollectionLocalIndexFromDrawable
    local collection = string.lower(nameOf(ped, id, d) or '')
    return ('%s/%s%d/%s/%d'):format(GetEntityModel(ped) == MALE and 'm' or 'f', isProp and 'p' or 'c', id,
        collection == '' and '_base' or collection, localOf(ped, id, d))
end

local function read(slot, ped)
    ped = ped or cache.ped

    if slot.prop then
        local d = GetPedPropIndex(ped, slot.prop)
        return { d = d, t = math.max(GetPedPropTextureIndex(ped, slot.prop), 0), c = pictureKey(ped, slot, d) }
    end

    local d = GetPedDrawableVariation(ped, slot.component)
    local piece = { d = d, t = GetPedTextureVariation(ped, slot.component), c = pictureKey(ped, slot, d) }

    if slot.component == 11 then
        piece.arms = { d = GetPedDrawableVariation(ped, 3), t = GetPedTextureVariation(ped, 3) }
    end

    return piece
end

local function isNaked(slot, piece, ped)
    if slot.prop then return piece.d < 0 end
    return piece.d == nakedValue(slot, ped)
end

---@param piece table | 'off'
local function apply(slot, piece, ped)
    ped = ped or cache.ped

    if piece == 'off' then
        if slot.prop then
            ClearPedProp(ped, slot.prop)
        else
            SetPedComponentVariation(ped, slot.component, nakedValue(slot, ped), 0, 0)

            -- bare torso = bare arms
            if slot.component == 11 then
                SetPedComponentVariation(ped, 3, nakedTable(ped)[3] or 15, 0, 0)
            end
        end
    elseif type(piece) == 'table' then
        if slot.prop then
            SetPedPropIndex(ped, slot.prop, piece.d, piece.t, true)
        else
            SetPedComponentVariation(ped, slot.component, piece.d, piece.t, 0)

            if slot.component == 11 and type(piece.arms) == 'table' then
                SetPedComponentVariation(ped, 3, piece.arms.d, piece.arms.t, 0)
            end
        end
    end
end

local function playAnim(slot)
    if not settings.Animations then return end

    local anim = slot.anim or ANIMS[slot.key] or ANIMS.jacket
    local dict, clip, duration = anim[1] or anim.dict, anim[2] or anim.clip, anim[3] or anim.duration or 1000

    if not pcall(lib.requestAnimDict, dict, 1000) then return end

    TaskPlayAnim(cache.ped, dict, clip, 3.0, 3.0, duration, 51, 0.0, false, false, false)
    Wait(duration)
    StopAnimTask(cache.ped, dict, clip, 1.0)
    RemoveAnimDict(dict)
end

local function notify(key)
    if key then lib.notify({ type = 'error', description = locale(key) }) end
end

---State of the slots for the interface: { supported, worn = { [key] = boolean } }
-- With pure_clothing, a worn piece shows its picture in its slot (the same as in its shops).
local function picturesOn()
    return settings.Pictures ~= false and GetResourceState('pure_clothing') == 'started'
end

function Clothing.getState()
    local state = { supported = supported(), worn = {}, pictures = {} }

    if state.supported then
        local pictures = picturesOn()
        for key, slot in pairs(slots) do
            local piece = read(slot)
            state.worn[key] = not isNaked(slot, piece)
            if pictures and state.worn[key] and piece.c then
                state.pictures[key] = ('nui://pure_clothing/web/miniatures/%s.webp'):format(piece.c)
            end
        end
    end

    return state
end

local function sendState()
    SendNUIMessage({ action = 'clothingState', data = Clothing.getState() })
end

local function run(action)
    if busy then return end
    if not supported() then return notify('clothing_wrong_model') end

    -- same rule as the items: nothing during a progress bar, handcuffed, dead...
    if LocalPlayer.state.invBusy or IsPedFatallyInjured(cache.ped) or IsPedCuffed(cache.ped) then
        return notify('cannot_perform')
    end

    busy = true

    local ok, err = pcall(action)

    if not ok then lib.print.error(err) end

    busy = false
    Preview.refresh()
    sendState()
end

---Takes off the piece of the slot `key`; it goes in the inventory slot `toSlot` (or the first free one).
local known = {} -- state of the character (what he changed), as the server knows it

function Clothing.takeOff(key, toSlot)
    local slot = slots[key]
    if not slot then return end

    run(function()
        local current = read(slot)
        if isNaked(slot, current) then return end

        playAnim(slot)

        local success, err = lib.callback.await('pure_inventory:clothing:takeOff', false, key, toSlot, current)

        if success then
            known[key] = { base = known[key] and known[key].base or { d = current.d, t = current.t }, cur = 'off' }
            apply(slot, 'off')
        else
            notify(err)
        end
    end)
end

---Puts on the clothing item of the inventory slot `invSlot`. `expectedKey`: the slot it was dropped on.
function Clothing.putOn(invSlot, expectedKey)
    local item = PlayerData.inventory[invSlot]
    local data = item and item.name == (settings.Item or 'clothing') and item.metadata?.clothing

    if not data then
        if expectedKey then notify('clothing_wrong_slot') end
        return
    end

    local slot = slots[data.key]
    if not slot then return end
    if expectedKey and expectedKey ~= data.key then return notify('clothing_wrong_slot') end
    if data.model ~= GetEntityModel(cache.ped) then return notify('clothing_wrong_model') end

    run(function()
        playAnim(slot)

        local worn = read(slot)
        local success, piece = lib.callback.await('pure_inventory:clothing:putOn', false, invSlot, worn)

        if success then
            known[slot.key] = { base = known[slot.key] and known[slot.key].base or { d = worn.d, t = worn.t }, cur = piece }
            apply(slot, piece)
        else
            notify(piece)
        end
    end)
end

---Puts back what the player changed, after the appearance script dressed the character
---(connection, respawn, new model). A slot changed somewhere else (clothing shop) is forgotten.
local function matchesPiece(slot, now, target, ped)
    if target == 'off' then return isNaked(slot, now, ped) end
    return type(target) == 'table' and now.d == target.d and now.t == target.t
end

-- Waits (up to ApplyTimeout) until the appearance script dressed the character with the base outfit,
-- so that the pieces he changed are put back at once, without the old outfit showing for seconds.
local function waitForBaseOutfit(state)
    local deadline = GetGameTimer() + (settings.ApplyTimeout or 10000)
    repeat
        local ready = true
        for key, entry in pairs(state or {}) do
            local slot = slots[key]
            if slot and type(entry) == 'table' then
                local now = read(slot)
                if not matchesPiece(slot, now, entry.cur) and not matchesPiece(slot, now, entry.base) then ready = false end
            end
        end
        if ready then return end
        Wait(250)
    until GetGameTimer() > deadline
end

---@param fetch boolean? read the state from the server (connection, respawn); otherwise the local copy is used
function Clothing.reconcile(fetch)
    if not PlayerData.loaded or not supported() or busy then return end

    if fetch then
        local state = lib.callback.await('pure_inventory:clothing:getState', false)
        known = type(state) == 'table' and state or {}
        waitForBaseOutfit(known)
    end

    local forget, changed = {}, fetch == true

    for key, entry in pairs(known) do
        local slot = slots[key]

        if slot and type(entry) == 'table' then
            local now = read(slot)

            local function matches(target)
                if target == 'off' then return isNaked(slot, now) end
                return type(target) == 'table' and now.d == target.d and now.t == target.t
            end

            if not matches(entry.cur) then
                if matches(entry.base) or isNaked(slot, now) then
                    -- another script applied the saved outfit (or undressed): what the character changed is put back
                    apply(slot, entry.cur)
                    changed = true
                elseif type(entry.cur) == 'table' then
                    -- a piece put on from an item, replaced by another script (outfit changer...): it goes back
                    -- into the inventory, and that script decides for the slot from now on
                    local success = lib.callback.await('pure_inventory:clothing:takeOff', false, key, nil, entry.cur)
                    if success then apply(slot, now) end
                    forget[#forget + 1] = key
                    changed = true
                else
                    forget[#forget + 1] = key
                end
            end
        end
    end

    if #forget > 0 then
        for _, key in ipairs(forget) do known[key] = nil end
        TriggerServerEvent('pure_inventory:clothing:forget', forget)
    end

    if changed then Preview.refresh() end
end

local readyAt

CreateThread(function()
    while true do
        while not PlayerData.loaded do Wait(1000) end

        Wait(settings.ApplyDelay or 3000)
        readyAt = GetGameTimer()
        Clothing.reconcile(true)

        -- every few seconds: another script (outfit changer, radial menu...) may have dressed the character
        while PlayerData.loaded do
            Wait(settings.WatchInterval or 2000)
            if readyAt and next(known) then Clothing.reconcile(false) end
        end

        readyAt = nil
    end
end)

lib.onCache('ped', function()
    if not readyAt then return end

    SetTimeout(settings.ApplyDelay or 3000, function() Clothing.reconcile(true) end)
end)

exports('ReapplyClothing', Clothing.reconcile)

-- Using a clothing item (right click > Use, ALT + click, dropped on the character) puts it on.
do
    local item = Items[settings.Item or 'clothing']

    if item then
        local previous = item.effect -- clothing items of the original ox_inventory format

        item.effect = function(self, slotData)
            if type(slotData.metadata?.clothing) == 'table' then
                Clothing.putOn(slotData.slot)
            elseif previous then
                previous(self, slotData)
            end
        end
    end
end

-- ---- character selection screen (qb-multicharacter) --------------------------------------------
-- The preview ped is dressed by qb-clothing with the saved outfit: the pieces the character changed are
-- applied on it too, so he looks like he really does (the server sends the state when the screen asks
-- for the skin of a character).

local previews = {} -- [citizenid] = { state, at }

RegisterNetEvent('pure_inventory:clothing:previewState', function(citizenid, state)
    if type(citizenid) == 'string' and type(state) == 'table' then
        previews[citizenid] = { state = state, at = GetGameTimer() }
    end
end)

local function pedShows(ped, state)
    for key, entry in pairs(state) do
        local slot = slots[key]
        if slot and type(entry) == 'table' then
            local now = read(slot, ped)
            if not matchesPiece(slot, now, entry.base, ped) and not matchesPiece(slot, now, entry.cur, ped) then return false end
        end
    end
    return true
end

AddEventHandler('qb-clothing:client:loadPlayerClothing', function(_, ped)
    if type(ped) ~= 'number' or ped == 0 or ped == PlayerPedId() or not DoesEntityExist(ped) then return end
    CreateThread(function()
        Wait(300)
        if not DoesEntityExist(ped) then return end
        local model = GetEntityModel(ped)
        if model ~= MALE and model ~= FEMALE then return end

        -- the state received for this selection, else the character whose outfit matches the ped
        local chosen, newestAt = nil, 0
        for _, p in pairs(previews) do
            if next(p.state) and p.at > newestAt and GetGameTimer() - p.at < 3000 then chosen, newestAt = p.state, p.at end
        end
        if not chosen then
            for _, p in pairs(previews) do
                if next(p.state) and pedShows(ped, p.state) then chosen = p.state break end
            end
        end
        if not chosen then return end

        local deadline = GetGameTimer() + 3000
        while DoesEntityExist(ped) and not pedShows(ped, chosen) and GetGameTimer() < deadline do Wait(100) end
        if not DoesEntityExist(ped) then return end
        for key, entry in pairs(chosen) do
            local slot = slots[key]
            if slot and type(entry) == 'table' then apply(slot, entry.cur, ped) end
        end
    end)
end)

-- Slots shown by the interface (sent with the `init` message).
function Clothing.getSlots()
    local list = {}

    for i, slot in ipairs(settings.Slots or {}) do
        list[i] = {
            key = slot.key,
            side = slot.side == 'right' and 'right' or 'left',
            icon = slot.icon or slot.key,
            label = locale(('clothing_%s'):format(slot.key)),
        }
    end

    return list
end

RegisterNUICallback('previewStart', function(_, cb)
    -- the appearance script may have dressed the character since the last check: fixed before the 3D copy
    if readyAt then Clothing.reconcile(false) end

    Preview.start()

    cb(Clothing.getState())
end)

RegisterNUICallback('previewStop', function(_, cb)
    Preview.stop()
    cb(1)
end)

RegisterNUICallback('clothingTakeOff', function(data, cb)
    cb(1)

    if type(data) ~= 'table' or type(data.key) ~= 'string' then return end

    CreateThread(function()
        Clothing.takeOff(data.key, math.tointeger(tonumber(data.toSlot)))
    end)
end)

RegisterNUICallback('clothingPutOn', function(data, cb)
    cb(1)

    local slot = type(data) == 'table' and math.tointeger(tonumber(data.slot))
    if not slot then return end

    CreateThread(function()
        Clothing.putOn(slot, type(data.key) == 'string' and data.key or nil)
    end)
end)

return Clothing
