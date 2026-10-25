if not lib then return end

-- Right click > Rename: the new name is saved in the item metadata (`label`).

local settings = shared.rename

if not settings.Enabled then return end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local maxLength = math.tointeger(settings.MaxLength) or 32
local cooldown = math.tointeger(settings.Cooldown) or 1000
local lastRename = {}

---@return string?
local function cleanName(text)
    if type(text) ~= 'string' or #text > maxLength * 4 then return end

    -- no control characters, no line breaks, single spaces
    text = text:gsub('%c', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')

    local length = utf8.len(text)
    if not length or length < 1 or length > maxLength then return end

    return text
end

RegisterNetEvent('pure_inventory:renameItem', function(slot, text)
    local source = source
    local now = GetGameTimer()

    if now - (lastRename[source] or 0) < cooldown then return end
    lastRename[source] = now

    slot = math.tointeger(slot)
    local name = cleanName(text)
    local inv = Inventory(source)

    if not slot or not name or not inv or server.isPlayerRestrained(source) then return end

    local data = inv.items[slot]
    if not data then return end

    local item = Items(data.name)
    if not item then return end

    local metadata = table.clone(data.metadata or {})

    -- back to the normal name = no custom name
    metadata.label = name ~= item.label and name or nil

    if metadata.label == data.metadata?.label then return end

    Inventory.SetMetadata(inv, slot, metadata)
end)

AddEventHandler('playerDropped', function()
    lastRename[source] = nil
end)
