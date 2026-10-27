if not lib then return end

-- Hanger slot (Config.Clothing.Hanger): every worn piece of clothing in ONE `outfit` item, put on / taken off at once.
--
-- The outfit on the hanger is remembered with the clothes, in the same row of `pure_inventory_clothing`:
--   _hanger = { uid, label, model }   (label = nil: outfit without a name)
-- While an outfit is on the hanger, every worn piece is part of it: the item is made when the outfit is taken off,
-- from what the character wears then (a piece taken off alone leaves the outfit, a piece put on joins it).
-- An empty hanger (`hanger` item) dropped on the slot starts an outfit with the clothes worn; an outfit emptied and
-- taken off becomes a hanger again (with its name). No outfit can be made without a hanger: no free hanger.

local settings = shared.clothing.Hanger

return function(clothing)
    if type(settings) ~= 'table' or not settings.Enabled then return end

    local Inventory = require 'modules.inventory.server'
    local Items = require 'modules.items.server'

    local slots = clothing.slots
    local outfitItem = settings.OutfitItem or 'outfit'
    local hangerItem = settings.HangerItem or 'hanger'
    local duration = math.max(tonumber(settings.Duration) or 8000, 0)
    local exclude = type(settings.Exclude) == 'table' and settings.Exclude or {}
    local MALE = `mp_m_freemode_01`

    -- slots that go in an outfit, in the order of the config (the gloves after the top: they share the arms)
    local order = {}

    for _, slot in ipairs(shared.clothing.Slots or {}) do
        if slots[slot.key] == slot and not exclude[slot.key] then order[#order + 1] = slot.key end
    end

    local pending = {} -- [source] = outfit being put on: { slot, uid, start, pieces }
    local count = 0

    local function newUid()
        count = count + 1
        return ('%x%x%x'):format(os.time(), count, math.random(0, 0xFFFFFF))
    end

    local function nameOf(metadata)
        local label = type(metadata) == 'table' and metadata.label
        return type(label) == 'string' and label ~= '' and label or nil
    end

    local function nakedPiece(slot, model)
        if slot.prop then return { d = -1, t = 0 } end
        local naked = (shared.clothing.Naked or {})[model == MALE and 'male' or 'female'] or {}
        return { d = naked[slot.component] or 0, t = 0 }
    end

    -- What the character wears in each slot of an outfit. A piece put on from an item is known by the server; for
    -- the others the game says what the appearance script dressed him with (same rule as a slot clicked alone).
    local function wornPieces(state, model, reported)
        local list = {}
        reported = type(reported) == 'table' and reported or {}

        for _, key in ipairs(order) do
            local slot, entry = slots[key], state[key]
            local piece

            if entry and type(entry.cur) == 'table' then
                piece = clothing.readPiece(slot, entry.cur)
                local now = clothing.readPiece(slot, reported[key])
                -- its picture comes from what the character wears (same piece)
                if piece and not piece.c and now and now.d == piece.d then piece.c = now.c end
            elseif not entry then
                piece = clothing.readPiece(slot, reported[key])
            end

            if piece and not clothing.isNaked(slot, model, piece) then
                list[#list + 1] = { key = key, piece = piece }
            end
        end

        return list
    end

    -- Pieces held by an outfit item, checked again (one per slot, slots of the config only, never an excluded one).
    local function readOutfit(data, model)
        local list = {}
        if type(data.pieces) ~= 'table' then return list end

        for _, key in ipairs(order) do
            local piece = clothing.readPiece(slots[key], data.pieces[key])

            if piece and not clothing.isNaked(slots[key], model, piece) then
                list[#list + 1] = { key = key, piece = piece }
            end
        end

        return list
    end

    -- What the appearance script dresses the character with in this slot (kept when the slot changes).
    local function baseOf(state, key, model, reported)
        local entry = state[key]
        if entry and entry.base then return entry.base end

        local piece = clothing.readPiece(slots[key], type(reported) == 'table' and reported[key])
        if piece then return { d = piece.d, t = piece.t } end

        return nakedPiece(slots[key], model)
    end

    local function outfitMetadata(hanger, model, worn)
        local pieces, lines, weight = {}, {}, 0

        for _, w in ipairs(worn) do
            pieces[w.key] = w.piece
            lines[#lines + 1] = '- ' .. locale(('clothing_%s'):format(w.key))
            weight = weight + (slots[w.key].weight or 0)
        end

        return {
            label = hanger.label,
            description = ('%s  \n%s'):format(locale('outfit_pieces', #worn), table.concat(lines, '  \n')),
            weight = weight,
            outfit = { uid = hanger.uid, model = model, pieces = pieces },
        }
    end

    -- An emptied outfit becomes a hanger again; it keeps its name (a hanger without a name stacks with the others).
    local function emptyHanger(hanger)
        return hanger.label and { label = hanger.label } or nil
    end

    -- What the character wears goes back to the inventory: in the outfit on the hanger if there is one (the hanger
    -- itself when nothing is worn any more), otherwise piece by piece.
    local function giveBackList(state, model, worn)
        local hanger = state._hanger

        if hanger then
            if #worn == 0 then return { { hangerItem, emptyHanger(hanger) } } end
            return { { outfitItem, outfitMetadata(hanger, model, worn) } }
        end

        local list = {}

        for _, w in ipairs(worn) do
            list[#list + 1] = { clothing.itemName, clothing.makeMetadata(slots[w.key], model, w.piece) }
        end

        return list
    end

    -- Room for `items` ({ name, metadata }) once `freedWeight` grams and `freedSlots` slots are given back.
    -- One free slot per item: never more than the real need.
    local function fits(inv, items, freedWeight, freedSlots)
        if #items == 0 then return true end

        local weight = (inv.weight or 0) - (freedWeight or 0)

        for _, it in ipairs(items) do
            local item = Items(it[1])
            weight = weight + (item and item.weight or 0) + (it[2] and tonumber(it[2].weight) or 0)
        end

        if weight > (inv.maxWeight or 0) then return false end

        local free = freedSlots or 0

        for i = 1, inv.slots do
            if not inv.items[i] then free = free + 1 end
        end

        return free >= #items
    end

    local function add(source, name, metadata, toSlot)
        Inventory.MuteNotifications(source, true)
        local ok, success = pcall(Inventory.AddItem, source, name, 1, metadata, toSlot)
        Inventory.MuteNotifications(source, false)

        return ok and success
    end

    -- Gives an item back; when the inventory is full after all, it is put on the ground at the player's feet.
    local function giveBack(source, name, metadata)
        if add(source, name, metadata) then return end

        TriggerEvent('ox_inventory:customDrop', 'Drop', { { name, 1, metadata } }, GetEntityCoords(GetPlayerPed(source)))
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('outfit_dropped') })
    end

    local function take(source, name, slot)
        Inventory.MuteNotifications(source, true)
        local ok, success = pcall(Inventory.RemoveItem, source, name, 1, nil, slot)
        Inventory.MuteNotifications(source, false)

        return ok and success
    end

    -- The worn pieces are taken off (they went back to the inventory). Returns the slots changed, for the client.
    local function undress(state, model, worn, reported)
        local changed = {}

        for _, w in ipairs(worn) do
            state[w.key] = { base = baseOf(state, w.key, model, reported), cur = 'off' }
            changed[w.key] = state[w.key]
        end

        return changed
    end

    -- An empty hanger (or an outfit without any piece) dropped on the slot: no progress bar.
    local function putHanger(source, inv, invSlot, state, model, item, reported)
        local worn = state._hanger and wornPieces(state, model, reported) or {}
        local back = state._hanger and giveBackList(state, model, worn) or {}
        local each = (item.weight or 0) / (item.count or 1)

        if not fits(inv, back, each, (item.count or 1) <= 1 and 1 or 0) then return false, 'outfit_no_room' end
        if not take(source, item.name, invSlot) then return false end

        -- the outfit already on the hanger goes back to the inventory, with all it held
        local changed = undress(state, model, worn, reported)
        for _, it in ipairs(back) do giveBack(source, it[1], it[2]) end

        state._hanger = { uid = newUid(), label = nameOf(item.metadata), model = model }
        clothing.saveState(inv.owner)

        return true, { done = true, changed = changed, hanger = state._hanger }
    end

    ---Starts putting on the outfit (or the empty hanger) of the inventory slot `invSlot`.
    ---`reported`: what the character wears, slot by slot, read by the game.
    lib.callback.register('pure_inventory:outfit:start', function(source, invSlot, reported)
        local inv = Inventory(source)
        invSlot = math.tointeger(invSlot)

        if not inv or not inv.owner or not invSlot or pending[source] or clothing.tooFast(source) then return false end
        if server.isPlayerRestrained(source) then return false, 'cannot_perform' end

        local item = inv.items[invSlot]
        if not item or (item.name ~= outfitItem and item.name ~= hangerItem) then return false, 'outfit_wrong_item' end

        local model = clothing.getModel(source)
        if not model then return false, 'clothing_wrong_model' end

        local state = clothing.getState(inv.owner)
        local data = item.name == outfitItem and type(item.metadata) == 'table' and type(item.metadata.outfit) == 'table'
            and item.metadata.outfit

        if data and data.model ~= model then return false, 'clothing_wrong_model' end

        local pieces = data and readOutfit(data, model) or {}

        if #pieces == 0 then return putHanger(source, inv, invSlot, state, model, item, reported) end
        if type(data.uid) ~= 'string' then return false, 'outfit_damaged' end

        local worn = wornPieces(state, model, reported)

        if not fits(inv, giveBackList(state, model, worn), item.weight or 0, 1) then return false, 'outfit_no_room' end

        pending[source] = { slot = invSlot, uid = data.uid, start = GetGameTimer(), pieces = pieces }

        return true, { pieces = pieces, duration = duration }
    end)

    ---End of the progress bar. The item is only taken now, if it is still in the same slot (same uid): an outfit
    ---given or dropped during the bar cannot be put on as well.
    lib.callback.register('pure_inventory:outfit:finish', function(source, success, reported)
        local p = pending[source]
        pending[source] = nil

        if not p or success ~= true then return false end

        local inv = Inventory(source)
        if not inv or not inv.owner then return false end
        if GetGameTimer() - p.start < duration - 1500 then return false end
        if server.isPlayerRestrained(source) then return false, 'cannot_perform' end

        local item = inv.items[p.slot]
        local data = item and item.name == outfitItem and type(item.metadata) == 'table'
            and type(item.metadata.outfit) == 'table' and item.metadata.outfit

        if not data or data.uid ~= p.uid then return false, 'outfit_moved' end

        local model = clothing.getModel(source)
        if not model or data.model ~= model then return false, 'clothing_wrong_model' end

        local state = clothing.getState(inv.owner)
        local worn = wornPieces(state, model, reported)
        local back = giveBackList(state, model, worn)

        if not fits(inv, back, item.weight or 0, 1) then return false, 'outfit_no_room' end
        if not take(source, outfitItem, p.slot) then return false end

        -- everything worn is taken off first (back to the inventory), then the outfit is put on
        local changed = undress(state, model, worn, reported)
        for _, it in ipairs(back) do giveBack(source, it[1], it[2]) end

        for _, w in ipairs(p.pieces) do
            state[w.key] = { base = baseOf(state, w.key, model, reported), cur = w.piece }
            changed[w.key] = state[w.key]
        end

        state._hanger = { uid = data.uid, label = nameOf(item.metadata), model = model }
        clothing.saveState(inv.owner)

        return true, { changed = changed, hanger = state._hanger }
    end)

    ---Takes the outfit off the hanger: every worn piece goes in one outfit item (in `toSlot` when it is free).
    lib.callback.register('pure_inventory:outfit:takeOff', function(source, toSlot, reported)
        local inv = Inventory(source)

        if not inv or not inv.owner or pending[source] or clothing.tooFast(source) then return false end
        if server.isPlayerRestrained(source) then return false, 'cannot_perform' end

        local state = clothing.getState(inv.owner)
        local hanger = state._hanger
        if not hanger then return false end

        local model = clothing.getModel(source)
        if not model then return false, 'clothing_wrong_model' end

        local worn = wornPieces(state, model, reported)
        local name, metadata = outfitItem, nil

        if #worn == 0 then
            name, metadata = hangerItem, emptyHanger(hanger)
        else
            metadata = outfitMetadata(hanger, model, worn)
        end

        toSlot = math.tointeger(toSlot)

        if toSlot and (toSlot < 1 or toSlot > inv.slots or inv.items[toSlot]) then
            toSlot = nil
        end

        if not fits(inv, { { name, metadata } }) or not add(source, name, metadata, toSlot) then
            return false, 'cannot_carry'
        end

        local changed = undress(state, model, worn, reported)
        state._hanger = nil
        clothing.saveState(inv.owner)

        return true, { changed = changed, hanger = false }
    end)

    AddEventHandler('playerDropped', function()
        pending[source] = nil
    end)
end
