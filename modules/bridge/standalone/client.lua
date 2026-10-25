-- Standalone mode: tells the server when this client is ready to receive its inventory.

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end

    TriggerServerEvent('pure_inventory:standalone:ready')
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    -- No status system without a framework: other resources can listen to this event (hunger, thirst...).
    TriggerEvent('pure_inventory:setPlayerStatus', values)
end
