--[[
    Pure Inventory - configuration
    Everything you can change is in this file. Restart the resource (or the server) after a change.

    Secrets (Discord webhook) are NOT set here: this file is sent to every player.
    Put them in your server.cfg instead, e.g.  set inventory:webhook "https://discord.com/api/webhooks/..."
]]

Config = {}

---------------------------------------------------------------------------------------------------
-- 1. GENERAL
---------------------------------------------------------------------------------------------------

-- Framework:
--   'auto'       : detected at start (qbx_core, qb-core, es_extended, ox_core, ND_Core), else standalone
--   'standalone' : no framework. Players are identified by their license, see Config.Standalone
--   'qb' | 'qbx' | 'esx' | 'ox' | 'nd' : forced
Config.Framework = 'auto'

-- Language of the inventory: 'en', 'fr', 'de', 'es', 'it', 'pt', 'nl', 'pl', 'tr', 'ru', 'zh-cn', 'ja', 'ko'...
-- (files in locales/). nil = the ox_lib language (setr ox:locale "fr" in server.cfg).
Config.Locale = nil

-- Update check: at start, the server asks GitHub for the latest release and prints a line in the
-- server console when a newer version exists. Nothing is downloaded. false = no request to GitHub.
Config.CheckUpdates = true

---------------------------------------------------------------------------------------------------
-- 2. PLAYER INVENTORY
---------------------------------------------------------------------------------------------------

Config.PlayerSlots = 50          -- number of slots of a player
Config.PlayerWeight = 30000      -- max weight of a player, in grams (30000 = 30 kg)
Config.DropSlots = 50            -- slots of an item pile on the ground
Config.DropWeight = 100000       -- max weight of an item pile on the ground, in grams

-- Keys to open the inventory (FiveM key names). Players can rebind them in Settings > Key Bindings > FiveM.
-- 1st = player inventory, 2nd = the other inventory (trunk...), 3rd = hotbar.
Config.Keys = { 'F2', 'K', 'TAB' }

-- Jobs that can open the police evidence lockers and search other players.
Config.PoliceJobs = { 'police', 'sheriff' }

---------------------------------------------------------------------------------------------------
-- 3. BEHAVIOUR
---------------------------------------------------------------------------------------------------

-- The inventory stays open when an item is used (eat, drink, heal, clothes...).
-- Weapons, and the items in Config.CloseOnUse, still close it.
-- false = original ox_inventory behaviour (the item's `close` field decides).
Config.KeepOpenOnUse = true

-- Items that close the inventory when used (they open another screen, a minigame, or are held in hand).
Config.CloseOnUse = {
    'phone', 'radio', 'lockpick', 'advancedlockpick', 'binoculars', 'tunerlaptop',
    'id_card', 'driver_license', 'weaponlicense', 'filled_evidence_bag', 'police_stormram',
    'police_cone', 'police_barrier', 'police_spikestrip',
}
-- Same thing with Lua patterns on the item name ('^veh_' = every item whose name starts with veh_).
Config.CloseOnUsePatterns = { '^veh_', '^firework' }

-- Players can walk while their inventory is open (running, jumping, shooting stay blocked).
Config.WalkWhileOpen = true

-- Blur the game behind the inventory.
Config.ScreenBlur = false

-- Right click > Rename: players can rename their items (the new name is saved on the item).
Config.Rename = {
    Enabled = true,
    MaxLength = 32,     -- max characters of a name
    Cooldown = 1000,    -- ms between two renames of the same player (anti-spam)
}

---------------------------------------------------------------------------------------------------
-- 4. LOOK OF THE INVENTORY  (sizes in vh = % of the screen height, so it looks the same in every resolution)
---------------------------------------------------------------------------------------------------

Config.Theme = {
    Font = 'Poppins',               -- Google Fonts name (Poppins, Roboto, Montserrat, Inter...)

    -- Slots
    SlotSize = 9.1,                 -- size of a slot (vh)
    SlotGap = 0.55,                 -- space between slots (vh)
    Columns = 5,                    -- slots per row
    VisibleRows = 8,                -- rows visible without scrolling
    ItemImageSize = 6,              -- size of the item picture inside a slot (vh)
    SlotRadius = 0,                 -- rounded corners of the slots (px, 0 = square)

    SlotColor = '#000000',          -- colour of an empty / full slot
    SlotOpacity = 0.55,             -- 0 = invisible, 1 = solid colour
    SlotHoverOpacity = 0.65,        -- opacity when the mouse is over a slot
    SlotOutline = '#ffffff',        -- thin line around the slot under the mouse

    LabelColor = '#000000',         -- band with the item name at the bottom of a slot
    LabelOpacity = 0.55,
    TextColor = '#ffffff',
    UppercaseLabels = false,        -- item names in CAPITALS

    -- Right click menu and tooltips
    MenuColor = '#060608',
    MenuOpacity = 0.86,
    MenuButtonColor = '#121214',

    -- Clothing slots around the character
    ClothingSlotSize = 7.3,         -- vh
    ClothingIconSize = 3.4,         -- vh
    ClothingDistance = 11.2,        -- distance between the centre of the screen and each column of clothing slots (% of the screen width)
    ClothingIconColor = '#ffffff',
    WornColor = '#78c896',          -- small lock when the piece is worn
    NotWornColor = '#e5484d',       -- small lock when the piece is removed
}

---------------------------------------------------------------------------------------------------
-- 5. CHARACTER PREVIEW (your character in 3D in the middle of the inventory)
---------------------------------------------------------------------------------------------------

Config.PedPreview = {
    Enabled = true,
    ScreenX = 0.50,             -- horizontal position on screen (0.5 = centre)
    ScreenY = 0.45,             -- vertical position on screen
    Depth = 1.5,                -- distance in front of the camera (metres)
    Scale = 0.85,               -- size of the character (1.0 = bigger)
    FixedCamera = true,         -- keeps the character still on screen when you walk / drive with the inventory open
    FovReference = 50.0,        -- field of view the size is set for (50 = default on-foot camera)
    LeaveFirstPerson = true,    -- switch to 3rd person while the inventory is open

    -- Frozen pose of the character (nil = default standing pose)
    Pose = {
        male = { dict = 'anim@heists@heist_corona@team_idles@male_a', anim = 'idle' },
        female = { dict = 'anim@heists@heist_corona@team_idles@female_a', anim = 'idle' },
        phase = 0.0,
    },

    -- Mouse: hold left click + move = rotate, wheel = zoom
    ZoomStep = 1.18,
    ZoomMax = 3.0,

    -- Light on the character (nil = no light)
    Light = { r = 255, g = 244, b = 229, range = 1.8, intensity = 3.0, front = 0.7, up = 0.35 },
}

---------------------------------------------------------------------------------------------------
-- 6. CLOTHING SLOTS (clothes become items: click a worn piece to take it off, drag it back to wear it)
---------------------------------------------------------------------------------------------------

Config.Clothing = {
    Enabled = true,
    Item = 'clothing',          -- item that holds a piece of clothing (defined in data/items.lua)
    Pictures = true,            -- with pure_clothing: a worn piece shows its picture in its slot (and on its item)
    Animations = true,          -- small animation when a piece is put on / taken off
    DisableRadialClothing = true, -- remove the "Clothing" part of the radial menu (qbx_radialmenu), which undresses without the slots

    -- Slots shown on each side of the character, from top to bottom.
    --   key       : unique name (do not change it once players have clothes)
    --   prop      : GTA prop index (0 hat, 1 glasses, 2 ears, 6 watch, 7 bracelet)
    --   component : GTA component index (1 mask, 3 arms/gloves, 4 legs, 5 bag, 6 shoes, 7 neck, 8 undershirt, 9 vest, 10 decals, 11 torso)
    --   icon      : built-in icon (hat, glasses, mask, ears, neck, watch, bracelet, jacket, shirt, vest, decals, bag, gloves, pants, shoes)
    --               or the link of your own image (nui://my_resource/icons/hat.png, https://...)
    --   weight    : weight of the item in grams
    Slots = {
        { key = 'hat',      side = 'left',  prop = 0,       icon = 'hat',      weight = 150 },
        { key = 'glasses',  side = 'left',  prop = 1,       icon = 'glasses',  weight = 50 },
        { key = 'mask',     side = 'left',  component = 1,  icon = 'mask',     weight = 150 },
        { key = 'ears',     side = 'left',  prop = 2,       icon = 'ears',     weight = 20 },
        { key = 'neck',     side = 'left',  component = 7,  icon = 'neck',     weight = 100 },
        { key = 'watch',    side = 'left',  prop = 6,       icon = 'watch',    weight = 80 },
        { key = 'bracelet', side = 'left',  prop = 7,       icon = 'bracelet', weight = 50 },
        { key = 'jacket',   side = 'right', component = 11, icon = 'jacket',   weight = 600 },
        { key = 'shirt',    side = 'right', component = 8,  icon = 'shirt',    weight = 250 },
        { key = 'vest',     side = 'right', component = 9,  icon = 'vest',     weight = 500 },
        { key = 'decals',   side = 'right', component = 10, icon = 'decals',   weight = 20 },
        { key = 'bag',      side = 'right', component = 5,  icon = 'bag',      weight = 500 },
        { key = 'gloves',   side = 'right', component = 3,  icon = 'gloves',   weight = 100 },
        { key = 'pants',    side = 'right', component = 4,  icon = 'pants',    weight = 500 },
        { key = 'shoes',    side = 'right', component = 6,  icon = 'shoes',    weight = 600 },
    },

    -- Drawable used when a component is taken off (freemode characters). Props are simply removed.
    -- Change them if your clothing packs use other numbers.
    Naked = {
        male =   { [1] = 0, [3] = 15, [4] = 21, [5] = 0, [6] = 34, [7] = 0, [8] = 15, [9] = 0, [10] = 0, [11] = 15 },
        female = { [1] = 0, [3] = 15, [4] = 15, [5] = 0, [6] = 35, [7] = 0, [8] = 14, [9] = 0, [10] = 0, [11] = 15 },
    },

    -- Time (ms) after the player is loaded before the removed clothes are applied again
    -- (your appearance script dresses the character first).
    ApplyDelay = 3000,
}

---------------------------------------------------------------------------------------------------
-- 7. STANDALONE MODE (only used without framework)
---------------------------------------------------------------------------------------------------

Config.Standalone = {
    -- Identifier saved in the database: 'license2', 'license', 'fivem', 'discord'...
    Identifier = 'license',

    -- Groups (jobs) from ACE permissions: a player with the ACE 'pure_inventory.group.police'
    -- is in the group 'police' (grade 0). In server.cfg:
    --   add_ace group.police pure_inventory.group.police allow
    --   add_principal identifier.license:xxxxxxxx group.police
    Groups = { 'police', 'sheriff', 'ambulance', 'mechanic' },

    -- Vehicle trunks and gloveboxes are saved by plate. Unused ones are deleted after this many days.
    VehicleStorageDays = 30,
}

---------------------------------------------------------------------------------------------------
-- 8. ADVANCED (original ox_inventory options, see https://coxdocs.dev/ox_inventory)
---------------------------------------------------------------------------------------------------

Config.Target = false               -- use ox_target / pure-target for shops, stashes, trunks...
Config.GivePlayerList = false       -- "Give" shows a list of nearby players instead of the closest one
Config.WeaponAnims = true           -- animation when a weapon is taken out
Config.ItemNotify = true            -- "Added 1x" / "Removed 1x" pictures at the bottom of the screen
Config.WeaponNotify = true
Config.AimedFiring = false          -- weapons can only shoot while aiming
Config.DisableWeapons = false       -- no weapons from the inventory at all
Config.WeaponMismatch = true        -- remove weapons that are not in the inventory (anti-cheat)
Config.IgnoreWeapons = {}           -- weapons ignored by WeaponMismatch ('WEAPON_PISTOL', ...)
Config.SuppressPickups = true       -- no weapon pickups from the game
Config.DropProps = false            -- show a bag on the ground for item piles
Config.DropModel = 'prop_med_bag_01b'
Config.DisableSetupNotification = true
Config.EnableStealCommand = true    -- /steal on a player with hands up / dead
Config.RandomLoot = true            -- random items in unowned vehicles and dumpsters
Config.RandomPrices = false
Config.EvidenceGrade = 2            -- police grade that can open evidence lockers
Config.TrimPlate = true
Config.BulkStashSave = true
Config.ClearStashes = '6 MONTH'     -- stashes not used for this long are deleted ('' = never)
Config.LogLevel = 1                 -- 0 none, 1 important, 2 everything
Config.VersionCheck = false         -- ox_lib's own update check (same job as Config.CheckUpdates: keep it off)
Config.Accounts = { 'money' }       -- accounts that exist as items
Config.ImagePath = nil              -- folder of the item images (nil = this resource's web/images)
