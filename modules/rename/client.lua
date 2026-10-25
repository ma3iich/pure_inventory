if not lib then return end

-- Right click > Rename: the name is typed directly in the slot of the inventory.

local settings = shared.rename

if not settings.Enabled then return end

-- While the player types, the keys must not reach the game (1-5 = use a slot, W = walk...).
RegisterNUICallback('renameStart', function(_, cb)
    cb(1)
    if LocalPlayer.state.invOpen then SetNuiFocusKeepInput(false) end
end)

RegisterNUICallback('renameEnd', function(data, cb)
    cb(1)

    if LocalPlayer.state.invOpen then SetNuiFocusKeepInput(true) end

    if type(data) == 'table' and data.slot and type(data.label) == 'string' then
        TriggerServerEvent('pure_inventory:renameItem', data.slot, data.label)
    end
end)
