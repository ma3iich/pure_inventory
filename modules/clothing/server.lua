if not lib then return end

-- Clothing slots: a piece taken off the character becomes an item (Config.Clothing.Item), the item put back
-- on the character dresses him again.
--
-- What each player has changed is remembered per character in `pure_inventory_clothing`:
--   [slot] = { base = what the appearance script dresses the character with, cur = 'off' or the worn piece }
-- After a reconnection the appearance script dresses the character with `base` again: the client puts `cur`
-- back on, so a piece already turned into an item cannot be taken off a second time (no duplication).

local settings = shared.clothing

if not settings.Enabled then return end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local itemName = settings.Item or 'clothing'
local slots = {}

for _, slot in ipairs(settings.Slots or {}) do
    slots[slot.key] = slot
end

local MALE, FEMALE = `mp_m_freemode_01`, `mp_f_freemode_01`

local states = {}
local lastAction = {}

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `pure_inventory_clothing` (
		`owner` varchar(64) NOT NULL,
		`data` longtext DEFAULT NULL,
		`lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
		PRIMARY KEY (`owner`)
	)]])
end)

local function getState(owner)
    local state = states[owner]
    if state then return state end

    local row = MySQL.scalar.await('SELECT data FROM pure_inventory_clothing WHERE owner = ?', { owner })
    state = row and json.decode(row) or {}
    states[owner] = state

    return state
end

local function saveState(owner)
    local state = states[owner]

    if not state or not next(state) then
        return MySQL.prepare('DELETE FROM pure_inventory_clothing WHERE owner = ?', { owner })
    end

    MySQL.prepare('INSERT INTO pure_inventory_clothing (owner, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { owner, json.encode(state) })
end

local function getModel(source)
    local ped = GetPlayerPed(source)
    if ped == 0 then return end

    local model = GetEntityModel(ped)
    if model ~= MALE and model ~= FEMALE then return end

    return model
end

-- A piece sent by the client: whole numbers in the ranges of GTA.
local function readPiece(slot, piece)
    if type(piece) ~= 'table' then return end

    local d, t = math.tointeger(piece.d), math.tointeger(piece.t)
    if not d or not t or t < 0 or t > 255 or d > 4095 then return end
    if slot.prop and d < -1 or not slot.prop and d < 0 then return end

    local result = { d = d, t = t }

    -- picture of the piece (pure_clothing), only used for the item
    if type(piece.c) == 'string' and piece.c:match('^[mf]/[cp]%d+/[%w_]+/%d+$') then result.c = piece.c end

    -- the arms go with the torso (their shape depends on it)
    if slot.component == 11 and type(piece.arms) == 'table' then
        local ad, at = math.tointeger(piece.arms.d), math.tointeger(piece.arms.t)

        if ad and at and ad >= 0 and ad <= 4095 and at >= 0 and at <= 255 then
            result.arms = { d = ad, t = at }
        end
    end

    return result
end

local function isNaked(slot, model, piece)
    if slot.prop then return piece.d < 0 end

    local naked = (settings.Naked or {})[model == MALE and 'male' or 'female'] or {}
    return piece.d == (naked[slot.component] or 0)
end

local function samePiece(a, b)
    return type(a) == 'table' and type(b) == 'table' and a.d == b.d and a.t == b.t
end

local function tooFast(source)
    local now = GetGameTimer()
    if now - (lastAction[source] or 0) < 400 then return true end
    lastAction[source] = now
end

-- With pure_clothing, the item shows the picture of the piece (the same as in its shops).
local function pictureUrl(piece)
    if not piece.c or GetResourceState('pure_clothing') ~= 'started' then return end
    local ok, url = pcall(function() return exports.pure_clothing:PictureUrl(piece.c) end)
    return ok and url or nil
end

local function makeMetadata(slot, model, piece)
    return {
        label = locale(('clothing_%s'):format(slot.key)),
        image = ('clothing_%s'):format(slot.key),
        imageurl = pictureUrl(piece),
        weight = slot.weight or 0,
        clothing = { key = slot.key, model = model, d = piece.d, t = piece.t, arms = piece.arms },
    }
end

-- Adds an item without the "Added 1x" notification: the piece only changes place.
local function addQuietly(source, metadata, toSlot)
    Inventory.MuteNotifications(source, true)
    local ok, success = pcall(Inventory.AddItem, source, itemName, 1, metadata, toSlot)
    Inventory.MuteNotifications(source, false)

    return ok and success
end

local function removeQuietly(source, slot)
    Inventory.MuteNotifications(source, true)
    local ok, success = pcall(Inventory.RemoveItem, source, itemName, 1, nil, slot)
    Inventory.MuteNotifications(source, false)

    return ok and success
end

---Takes a piece off: it goes into the inventory (in `toSlot` when it is free).
lib.callback.register('pure_inventory:clothing:takeOff', function(source, key, toSlot, current)
    local slot = slots[key]
    local inv = Inventory(source)

    if not slot or not inv or not inv.owner or tooFast(source) then return false end
    if server.isPlayerRestrained(source) then return false, 'cannot_perform' end

    local model = getModel(source)
    if not model then return false, 'clothing_wrong_model' end

    local reported = readPiece(slot, current)
    if not reported then return false end

    local state = getState(inv.owner)
    local entry = state[key]

    -- already taken off (the appearance script dressed the character again): no second item
    if entry and entry.cur == 'off' then return false, 'clothing_already_removed' end

    -- a piece put on from an item is known by the server: the client cannot change it
    local piece = entry and readPiece(slot, entry.cur) or reported
    if isNaked(slot, model, piece) then return false end
    -- its picture comes from what the character wears (same piece), the server does not know collections
    if not piece.c and reported.d == piece.d then piece.c = reported.c end

    toSlot = math.tointeger(toSlot)

    if toSlot and (toSlot < 1 or toSlot > inv.slots or inv.items[toSlot]) then
        toSlot = nil
    end

    if not addQuietly(source, makeMetadata(slot, model, piece), toSlot) then
        return false, 'cannot_carry'
    end

    state[key] = { base = entry and entry.base or reported, cur = 'off' }
    saveState(inv.owner)

    return true
end)

---Puts on the piece of clothing held in the inventory slot `invSlot`.
---The piece worn in the same place (if any) takes the place of the item in the inventory.
lib.callback.register('pure_inventory:clothing:putOn', function(source, invSlot, current)
    local inv = Inventory(source)
    invSlot = math.tointeger(invSlot)

    if not inv or not inv.owner or not invSlot or tooFast(source) then return false end
    if server.isPlayerRestrained(source) then return false, 'cannot_perform' end

    local item = inv.items[invSlot]
    local data = item and item.name == itemName and type(item.metadata.clothing) == 'table' and item.metadata.clothing
    local slot = data and slots[data.key]

    if not slot then return false end

    local model = getModel(source)
    if not model or data.model ~= model then return false, 'clothing_wrong_model' end

    local newPiece = readPiece(slot, data)
    if not newPiece then return false end
    -- keep the picture of the item for the day the piece is taken off again
    local url = type(item.metadata.imageurl) == 'string' and item.metadata.imageurl:match('^nui://pure_clothing/web/miniatures/(.+)%.webp$')
    if url and url:match('^[mf]/[cp]%d+/[%w_]+/%d+$') then newPiece.c = url end

    -- what the character wears in this place now, as dressed by the appearance script (can be "nothing")
    local reported = readPiece(slot, current)
    if not reported then return false end

    local state = getState(inv.owner)
    local entry = state[slot.key]
    local worn

    if not entry then
        worn = reported
    elseif entry.cur ~= 'off' then
        worn = entry.cur -- put on from an item: known by the server
    end

    if worn and isNaked(slot, model, worn) then worn = nil end
    if worn and not worn.c and reported.d == worn.d then worn.c = reported.c end

    if not removeQuietly(source, invSlot) then return false end

    -- the piece that was worn goes where the new one was
    if worn and not addQuietly(source, makeMetadata(slot, model, worn), invSlot) then
        addQuietly(source, item.metadata, invSlot)
        return false, 'cannot_carry'
    end

    state[slot.key] = { base = entry and entry.base or reported, cur = newPiece }
    saveState(inv.owner)

    return true, newPiece
end)

---What this character changed: the client puts it back on after the appearance script dressed him.
lib.callback.register('pure_inventory:clothing:getState', function(source)
    local inv = Inventory(source)
    if not inv or not inv.owner then return {} end

    return getState(inv.owner)
end)

---Slots the player changed somewhere else (clothing shop, outfit...): forgotten, the appearance script decides.
RegisterNetEvent('pure_inventory:clothing:forget', function(keys)
    local inv = Inventory(source)
    if not inv or not inv.owner or type(keys) ~= 'table' then return end

    local state = getState(inv.owner)
    local changed = false

    for i = 1, math.min(#keys, 32) do
        local key = keys[i]

        if type(key) == 'string' and state[key] then
            state[key] = nil
            changed = true
        end
    end

    if changed then saveState(inv.owner) end
end)

AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)

-- Character selection screen (qb-multicharacter): when it asks for the skin of one of the player's
-- characters, the pieces that character changed are sent too, for the preview ped.
RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, citizenid)
    if name ~= 'qb-multicharacter:server:getSkin' or type(citizenid) ~= 'string' then return end
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    local owner = MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', { citizenid })
    if not license or owner ~= license then return end
    TriggerClientEvent('pure_inventory:clothing:previewState', src, citizenid, getState(citizenid))
end)

-- Characters that left are removed from memory (read again from the database next time).
SetInterval(function()
    local online = {}

    for _, playerId in ipairs(GetPlayers()) do
        local inv = Inventory(tonumber(playerId))
        if inv and inv.owner then online[inv.owner] = true end
    end

    for owner in pairs(states) do
        if not online[owner] then states[owner] = nil end
    end
end, 30 * 60000)

exports('GetClothingItem', function() return Items(itemName) end)

-- qb-radialmenu has a "Clothing" part that undresses the character without the slots (the piece never becomes
-- an item). Its exports cannot hide one of its built-in entries (RemoveOption only removes entries added with
-- AddOption), so the server owner has to remove it in its config: warn him (Config.Clothing.DisableRadialClothing).
-- qbx_radialmenu is handled on the client (modules/clothing/radial.lua).
local function checkRadialMenu()
    if settings.DisableRadialClothing == false then return end

    local state = GetResourceState('qb-radialmenu')
    if state ~= 'started' and state ~= 'starting' then return end

    lib.print.warn("qb-radialmenu is running: its 'Clothing' menu takes clothes off without the clothing slots (the piece never becomes an item). qb-radialmenu has no export to hide that entry: delete the 'clothesmenu' entry of Config.MenuItems in qb-radialmenu/config.lua. Config.Clothing.DisableRadialClothing = false hides this warning.")
end

SetTimeout(2000, checkRadialMenu)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'qb-radialmenu' then checkRadialMenu() end
end)
