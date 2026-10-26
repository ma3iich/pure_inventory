if not lib then return end

-- The radial menus of QBCore / Qbox have a "Clothing" part (take off / put back the top, the pants...) that
-- undresses the character without the clothing slots: the piece disappears without becoming an item, and the
-- inventory no longer matches the character. Config.Clothing.DisableRadialClothing removes that part.
--
-- qbx_radialmenu (Qbox) builds its menu with the radial menu of ox_lib, shared by every resource: its "Clothing"
-- entry (id 'clothesMenu' in the submenu 'generalMenu', default config) is removed by id with lib.removeRadialItem.
-- qb-radialmenu has no export to hide one of its built-in entries: see modules/clothing/server.lua.

local settings = shared.clothing

if not settings.Enabled or settings.DisableRadialClothing == false then return end

local RADIAL = 'qbx_radialmenu'
local ENTRY, PARENT = 'clothesMenu', 'generalMenu'

local function removeEntry()
    if GetResourceState(RADIAL) ~= 'started' then return end

    -- ox_lib raises an error when the submenu does not exist yet (player not loaded, ids changed in its config)
    pcall(lib.removeRadialItem, ENTRY, PARENT)
    pcall(lib.removeRadialItem, ENTRY)
end

-- qbx_radialmenu builds its menu again on each of these events: remove the entry once it is done.
local function removeSoon()
    SetTimeout(1000, removeEntry)
end

removeSoon()

AddEventHandler('onClientResourceStart', function(resource)
    if resource == RADIAL then removeSoon() end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', removeSoon)
RegisterNetEvent('QBCore:Client:OnJobUpdate', removeSoon)
RegisterNetEvent('QBCore:Client:OnGangUpdate', removeSoon)
RegisterNetEvent('radialmenu:client:deadradial', removeSoon)
