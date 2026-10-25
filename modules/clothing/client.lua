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

local function nakedTable()
    return (settings.Naked or {})[GetEntityModel(cache.ped) == MALE and 'male' or 'female'] or {}
end

local function nakedValue(slot)
    return nakedTable()[slot.component] or 0
end

local function read(slot)
    local ped = cache.ped

    if slot.prop then
        return { d = GetPedPropIndex(ped, slot.prop), t = math.max(GetPedPropTextureIndex(ped, slot.prop), 0) }
    end

    local piece = { d = GetPedDrawableVariation(ped, slot.component), t = GetPedTextureVariation(ped, slot.component) }

    if slot.component == 11 then
        piece.arms = { d = GetPedDrawableVariation(ped, 3), t = GetPedTextureVariation(ped, 3) }
    end

    return piece
end

local function isNaked(slot, piece)
    if slot.prop then return piece.d < 0 end
    return piece.d == nakedValue(slot)
end

---@param piece table | 'off'
local function apply(slot, piece)
    local ped = cache.ped

    if piece == 'off' then
        if slot.prop then
            ClearPedProp(ped, slot.prop)
        else
            SetPedComponentVariation(ped, slot.component, nakedValue(slot), 0, 0)

            -- bare torso = bare arms
            if slot.component == 11 then
                SetPedComponentVariation(ped, 3, nakedTable()[3] or 15, 0, 0)
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
function Clothing.getState()
    local state = { supported = supported(), worn = {} }

    if state.supported then
        for key, slot in pairs(slots) do
            state.worn[key] = not isNaked(slot, read(slot))
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
function Clothing.takeOff(key, toSlot)
    local slot = slots[key]
    if not slot then return end

    run(function()
        local current = read(slot)
        if isNaked(slot, current) then return end

        playAnim(slot)

        local success, err = lib.callback.await('pure_inventory:clothing:takeOff', false, key, toSlot, current)

        if success then
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

        local success, piece = lib.callback.await('pure_inventory:clothing:putOn', false, invSlot, read(slot))

        if success then
            apply(slot, piece)
        else
            notify(piece)
        end
    end)
end

---Puts back what the player changed, after the appearance script dressed the character
---(connection, respawn, new model). A slot changed somewhere else (clothing shop) is forgotten.
function Clothing.reconcile()
    if not PlayerData.loaded or not supported() then return end

    local state = lib.callback.await('pure_inventory:clothing:getState', false)
    local forget = {}

    for key, entry in pairs(state or {}) do
        local slot = slots[key]

        if slot then
            local now = read(slot)

            local function matches(target)
                if target == 'off' then return isNaked(slot, now) end
                return type(target) == 'table' and now.d == target.d and now.t == target.t
            end

            if not matches(entry.cur) then
                if matches(entry.base) then
                    apply(slot, entry.cur)
                else
                    forget[#forget + 1] = key
                end
            end
        end
    end

    if #forget > 0 then
        TriggerServerEvent('pure_inventory:clothing:forget', forget)
    end

    Preview.refresh()
end

local readyAt

CreateThread(function()
    while true do
        while not PlayerData.loaded do Wait(1000) end

        Wait(settings.ApplyDelay or 3000)
        readyAt = GetGameTimer()
        Clothing.reconcile()

        while PlayerData.loaded do Wait(1000) end

        readyAt = nil
    end
end)

lib.onCache('ped', function()
    if not readyAt then return end

    SetTimeout(settings.ApplyDelay or 3000, Clothing.reconcile)
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
    Preview.start()

    -- the appearance script may have dressed the character since the last check
    if readyAt then CreateThread(Clothing.reconcile) end

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
