-- Standalone mode: no framework. Players are identified by a FiveM identifier (Config.Standalone.Identifier),
-- their inventory is saved in the `pure_inventory_players` table, money is the `money` item.

local Inventory = require 'modules.inventory.server'
local settings = shared.standalone

local function getIdentifier(source)
    local wanted = settings.Identifier or 'license'
    return GetPlayerIdentifierByType(source, wanted) or GetPlayerIdentifierByType(source, 'license')
end

-- Groups come from ACE permissions: `pure_inventory.group.<name>` gives the group <name> at grade 0.
local function getGroups(source)
    local groups = {}

    for _, name in ipairs(settings.Groups or {}) do
        if IsPlayerAceAllowed(source, ('pure_inventory.group.%s'):format(name)) then
            groups[name] = 0
        end
    end

    return groups
end

local function loadPlayer(source)
    source = tonumber(source)
    if not source or source < 1 or Inventory(source) then return end

    local identifier = getIdentifier(source)

    if not identifier then
        return warn(('player %s has no %s identifier, inventory not loaded'):format(source, settings.Identifier or 'license'))
    end

    server.setPlayerInventory({
        source = source,
        identifier = identifier,
        name = GetPlayerName(source),
        groups = getGroups(source),
    })
end

-- Sent by the client once its scripts are loaded (also after a restart of this resource).
-- Loading twice is ignored, so the event cannot be abused.
RegisterNetEvent('pure_inventory:standalone:ready', function()
    loadPlayer(source)
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    return {
        source = player.source,
        name = player.name,
        groups = player.groups or {},
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss()
    return false
end

exports('LoadStandalonePlayer', loadPlayer)
