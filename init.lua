local function addDeferral(err)
    err = err:gsub("%^%d", "")

    AddEventHandler('playerConnecting', function(_, _, deferrals)
        deferrals.defer()
        deferrals.done(err)
    end)
end

-- Settings come from config.lua (shared_script loaded before this file).
-- An `inventory:<name>` convar still overrides a setting when it is set, for ox_inventory users.

local Config = Config or {}

local function convar(name, default)
    local value = GetConvar('inventory:' .. name, '')
    if value == '' then return default end
    if type(default) == 'boolean' then return value == '1' or value == 'true' end
    if type(default) == 'number' then return tonumber(value) or default end
    if type(default) == 'table' then return json.decode(value) or default end
    return value
end

local function setting(value, name, default)
    if value == nil then value = default end
    return convar(name, value)
end

local function detectFramework()
    local wanted = setting(Config.Framework, 'framework', 'auto')
    if wanted ~= 'auto' then return wanted == 'none' and 'standalone' or wanted end

    local frameworks = {
        { 'qbx_core', 'qbx' },
        { 'qb-core', 'qb' },
        { 'es_extended', 'esx' },
        { 'ox_core', 'ox' },
        { 'ND_Core', 'nd' },
    }

    for i = 1, #frameworks do
        local state = GetResourceState(frameworks[i][1])
        if state ~= 'missing' and state ~= 'unknown' then return frameworks[i][2] end
    end

    return 'standalone'
end

shared = {
    resource = GetCurrentResourceName(),
    framework = detectFramework(),
    playerslots = setting(Config.PlayerSlots, 'slots', 50),
    playerweight = setting(Config.PlayerWeight, 'weight', 30000),
    target = setting(Config.Target, 'target', false),
    police = setting(Config.PoliceJobs, 'police', { 'police', 'sheriff' }),
    networkdumpsters = convar('networkdumpsters', false),
    keepopen = Config.KeepOpenOnUse ~= false,
    rename = Config.Rename or {},
    clothing = Config.Clothing or {},
    preview = Config.PedPreview or {},
    theme = Config.Theme or {},
    standalone = Config.Standalone or {},
}

shared.dropslots = setting(Config.DropSlots, 'dropslots', shared.playerslots)
shared.dropweight = setting(Config.DropWeight, 'dropweight', shared.playerweight)

do
    if type(shared.police) == 'string' then
        shared.police = { shared.police }
    end

    local police = table.create(0, shared.police and #shared.police or 0)

    for i = 1, #shared.police do
        police[shared.police[i]] = 0
    end

    shared.police = police
end

-- Scripts written for ox_inventory call exports.ox_inventory:... : every export of this resource is
-- also registered under the name ox_inventory (`provide 'ox_inventory'` in fxmanifest.lua already makes
-- GetResourceState('ox_inventory') and the dependencies work). Do not run a real ox_inventory next to it.
if shared.resource ~= 'ox_inventory' then
    local meta = getmetatable(exports)
    local register = meta and meta.__call

    if register then
        meta.__call = function(self, name, func)
            register(self, name, func)
            AddEventHandler(('__cfx_export_ox_inventory_%s'):format(name), function(setCB)
                setCB(func)
            end)
        end
    end
end

if Config.Locale and lib and lib.locale then
    lib.locale(Config.Locale)
end

if IsDuplicityVersion() then
    server = {
        bulkstashsave = setting(Config.BulkStashSave, 'bulkstashsave', true),
        loglevel = setting(Config.LogLevel, 'loglevel', 1),
        randomprices = setting(Config.RandomPrices, 'randomprices', false),
        randomloot = setting(Config.RandomLoot, 'randomloot', true),
        evidencegrade = setting(Config.EvidenceGrade, 'evidencegrade', 2),
        trimplate = setting(Config.TrimPlate, 'trimplate', true),
        versioncheck = setting(Config.VersionCheck, 'versioncheck', true),
        clearstashes = setting(Config.ClearStashes, 'clearstashes', '6 MONTH'),
        vehicleloot = json.decode(GetConvar('inventory:vehicleloot', [[
			[
				["sprunk", 1, 1],
				["water", 1, 1],
				["garbage", 1, 2, 50],
				["panties", 1, 1, 5],
				["money", 1, 50],
				["money", 200, 400, 5],
				["bandage", 1, 1]
			]
		]])),
        dumpsterloot = json.decode(GetConvar('inventory:dumpsterloot', [[
			[
				["mustard", 1, 1],
				["garbage", 1, 3],
				["money", 1, 10],
				["burger", 1, 1]
			]
		]])),
        validhosts = json.decode(GetConvar('inventory:validhosts', [[
			{
                "r2.fivemanage.com": true,
                "i.fmfile.com": true
            }
		]])),
    }

    local accounts = setting(Config.Accounts, 'accounts', { 'money' })
    server.accounts = table.create(0, #accounts)

    for i = 1, #accounts do
        server.accounts[accounts[i]] = 0
    end
else
    PlayerData = {}

    local enablekeys = { 249 }

    if Config.WalkWhileOpen ~= false then
        enablekeys[#enablekeys + 1] = 30
        enablekeys[#enablekeys + 1] = 31
    end

    client = {
        autoreload = convar('autoreload', false),
        screenblur = setting(Config.ScreenBlur, 'screenblur', false),
        keys = setting(Config.Keys, 'keys', { 'F2', 'K', 'TAB' }),
        enablekeys = convar('enablekeys', enablekeys),
        aimedfiring = setting(Config.AimedFiring, 'aimedfiring', false),
        giveplayerlist = setting(Config.GivePlayerList, 'giveplayerlist', false),
        weaponanims = setting(Config.WeaponAnims, 'weaponanims', true),
        itemnotify = setting(Config.ItemNotify, 'itemnotify', true),
        weaponnotify = setting(Config.WeaponNotify, 'weaponnotify', true),
        imagepath = setting(Config.ImagePath, 'imagepath', ('nui://%s/web/images'):format(shared.resource)),
        dropprops = setting(Config.DropProps, 'dropprops', false),
        dropmodel = joaat(setting(Config.DropModel, 'dropmodel', 'prop_med_bag_01b')),
        weaponmismatch = setting(Config.WeaponMismatch, 'weaponmismatch', true),
        ignoreweapons = setting(Config.IgnoreWeapons, 'ignoreweapons', {}),
        suppresspickups = setting(Config.SuppressPickups, 'suppresspickups', true),
        disableweapons = setting(Config.DisableWeapons, 'disableweapons', false),
        disablesetupnotification = setting(Config.DisableSetupNotification, 'disablesetupnotification', true),
        enablestealcommand = setting(Config.EnableStealCommand, 'enablestealcommand', true),
    }

    local closeOnUse = {}

    for _, name in ipairs(Config.CloseOnUse or {}) do
        closeOnUse[name] = true
    end

    client.closeonuse = closeOnUse
    client.closeonusepatterns = Config.CloseOnUsePatterns or {}

    local ignoreweapons = table.create(0, (client.ignoreweapons and #client.ignoreweapons or 0) + 3)

    for i = 1, #client.ignoreweapons do
        local weapon = client.ignoreweapons[i]
        ignoreweapons[tonumber(weapon) or joaat(weapon)] = true
    end

    ignoreweapons[`WEAPON_UNARMED`] = true
    ignoreweapons[`WEAPON_HANDCUFFS`] = true
    ignoreweapons[`WEAPON_GARBAGEBAG`] = true
    ignoreweapons[`OBJECT`] = true
    ignoreweapons[`WEAPON_HOSE`] = true

    client.ignoreweapons = ignoreweapons

    local fallbackmarker = {
        type = 0,
        colour = {150, 150, 150},
        scale = {0.5, 0.5, 0.5}
    }

    client.shopmarker = json.decode(GetConvar('inventory:shopmarker', [[
        {
            "type": 29,
            "colour": [30, 150, 30],
            "scale": [0.5, 0.5, 0.5]
        }
    ]])) or fallbackmarker

    client.evidencemarker = json.decode(GetConvar('inventory:evidencemarker', [[
        {
            "type": 2,
            "colour": [30, 30, 150],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker

    client.craftingmarker = json.decode(GetConvar('inventory:craftingmarker', [[
        {
            "type": 2,
            "colour": [150, 150, 30],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker

    client.dropmarker = json.decode(GetConvar('inventory:dropmarker', [[
        {
            "type": 2,
            "colour": [150, 30, 30],
            "scale": [0.3, 0.2, 0.15]
        }
    ]])) or fallbackmarker
end

function shared.print(...) print(string.strjoin(' ', ...)) end

function shared.info(...) lib.print.info(string.strjoin(' ', ...)) end

---Throws a formatted type error.
---```lua
---error("expected %s to have type '%s' (received %s)")
---```
---@param variable string
---@param expected string
---@param received string
function TypeError(variable, expected, received)
    error(("expected %s to have type '%s' (received %s)"):format(variable, expected, received))
end

-- People like ignoring errors for some reason
local function spamError(err)
    shared.ready = false

    CreateThread(function()
        while true do
            Wait(10000)
            CreateThread(function()
                error(err, 0)
            end)
        end
    end)

    addDeferral(err)
    error(err, 0)
end

---@param name string
---@return table
---@deprecated
function data(name)
    if shared.server and shared.ready == nil then return {} end
    local file = ('data/%s.lua'):format(name)
    local datafile = LoadResourceFile(shared.resource, file)
    local path = ('@@%s/%s'):format(shared.resource, file)

    if not datafile then
        warn(('no datafile found at path %s'):format(path:gsub('@@', '')))
        return {}
    end

    local func, err = load(datafile, path)

    if not func or err then
        shared.ready = false
        ---@diagnostic disable-next-line: return-type-mismatch
        return spamError(err)
    end

    return func()
end

if not lib then
    return spamError(('%s requires the ox_lib resource, refer to the documentation.'):format(GetCurrentResourceName()))
end

local success, msg = lib.checkDependency('oxmysql', '2.7.3')

if success then
    success, msg = lib.checkDependency('ox_lib', '3.27.0')
end

if not success then
    return spamError(msg)
end

if not LoadResourceFile(shared.resource, 'web/build/index.html') then
    return spamError(
        'UI has not been built, refer to the documentation or download a release build.\n	^3https://coxdocs.dev/ox_inventory^0')
end

-- No we're not going to support qtarget any longer.
if shared.target and GetResourceState('ox_target') ~= 'started' then
    shared.target = false
    warn(('ox_target is not loaded - it should start before %s'):format(shared.resource))
end

if lib.context == 'server' then
    shared.ready = false
    return require 'server'
end

require 'client'
