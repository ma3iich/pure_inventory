--This file has been modified from the current version to return older functionality that allows for the use of qb-core.

local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = require 'modules.inventory.client'
local Weapon = require 'modules.weapon.client'

RegisterNetEvent('QBCore:Client:OnPlayerUnload', client.onLogout)

-- Dead / handcuffed state from the QBCore metadata.
local function applyState(metadata)
    if type(metadata) ~= 'table' then return end

    local dead = metadata.isdead or metadata.inlaststand or false

    if dead ~= (PlayerData.dead or false) then
        PlayerData.dead = dead
        OnPlayerData('dead', PlayerData.dead)
    end

    if metadata.ishandcuffed then
        LocalPlayer.state:set('invBusy', true, false)

        if not PlayerData.cuffed then
            PlayerData.cuffed = true
            TriggerEvent('ox_inventory:disarm', true)
        end
    elseif PlayerData.cuffed then
        PlayerData.cuffed = false
        LocalPlayer.state:set('invBusy', false, false)
    end
end

local function setGroup(field, value)
    if not value or not value.name or not value.grade then return end

    local groups = PlayerData.groups

    if groups[value.name] == value.grade.level and PlayerData[field] == value.name then return end

    if PlayerData[field] then
        groups[PlayerData[field]] = nil
    end

    PlayerData[field] = value.name
    groups[value.name] = value.grade.level
    PlayerData.groups = groups
    OnPlayerData('groups', PlayerData.groups)
end

-- qb-core 1.3+ only sends SetPlayerData when the character loads; later changes come with OnPlayerUpdated.
RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, value)
    if not PlayerData.loaded then return end

    if key == 'job' then
        setGroup('job', value)
    elseif key == 'gang' then
        setGroup('gang', value)
    elseif key == 'metadata' then
        applyState(value)
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if source == '' or not PlayerData.loaded then return end

    local groups = PlayerData.groups

    if not groups[data.job.name] or not groups[data.gang.name] or groups[data.job.name] ~= data.job.grade.level or groups[data.gang.name] ~= data.gang.grade.level then
        PlayerData.groups = {
            [data.job.name] = data.job.grade.level,
            [data.gang.name] = data.gang.grade.level,
        }
        PlayerData.job = data.job.name
        PlayerData.gang = data.gang.name

        OnPlayerData('groups', PlayerData.groups)
    end

    applyState(data.metadata)
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    for name, value in pairs(values) do
        -- compatibility for ESX style values
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        if name == "hunger" then
            TriggerServerEvent('consumables:server:addHunger', QBCore.Functions.GetPlayerData().metadata.hunger + value)
        elseif name == "thirst" then
            TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + value)
        elseif name == "stress" then
            if value > 0 then
                TriggerServerEvent('hud:server:GainStress', value)
            else
                value = math.abs(value)
                TriggerServerEvent('hud:server:RelieveStress', value)
            end
        end
    end
end

AddStateBagChangeHandler('inv_busy', ('player:%s'):format(cache.serverId), function(_, _, value)
    LocalPlayer.state:set('invBusy', value, false)
end)

local function export(exportName, func)
    AddEventHandler(('__cfx_export_%s_%s'):format(string.strsplit('.', exportName, 2)), function(setCB)
        setCB(func or function()
            error(("export '%s' is not supported when using ox_inventory"):format(exportName))
        end)
    end)
end

export('qb-inventory.HasItem', function(items, amount)
    amount = amount or 1

    if type(items) == 'table' then
        for _, v in pairs(items) do
            if Inventory.GetItemCount(v) < amount then
                return false
            end
        end

        return true
    else
        return Inventory.GetItemCount(items) >= amount
    end
end)