-- =============================================================================
-- ravn_logs Configuration for Sinister H-Town RP
-- =============================================================================
-- This resource logs player actions to Discord webhooks and NDJSON files with
-- daily rotation. Queue-based webhook delivery prevents rate-limiting.
--
-- SETUP INSTRUCTIONS:
--   1. Create the following Discord channels (or use existing ones):
--        #kill-logs     – player deaths, suicides, environmental kills
--        #chat-logs     – all in-game chat (/ooc, /me, /scene, /twt, etc.)
--        #join-leave    – player connections and disconnections
--        #admin-logs    – staff commands and administrative actions
--   2. In each channel, create a webhook (Channel Settings > Integrations >
--      Webhooks > New Webhook). Copy each webhook URL below.
--   3. Ensure the resource has server-console Ace permissions if logging
--      console commands:  add_ace resource.ravn_logs command allow
--   4. Adjust retention_days, queue settings, and enabled log types below.
-- =============================================================================

Config = Config or {}

-- ---------------------------------------------------------------------------
-- DISCORD WEBHOOKS (REQUIRED – replace with your actual webhook URLs)
-- ---------------------------------------------------------------------------
Config.Webhooks = {
    killLogs      = "https://discord.com/api/webhooks/PLACEHOLDER_KILL",
    chatLogs      = "https://discord.com/api/webhooks/PLACEHOLDER_CHAT",
    joinLeave     = "https://discord.com/api/webhooks/PLACEHOLDER_JOINLEAVE",
    adminLogs     = "https://discord.com/api/webhooks/PLACEHOLDER_ADMIN",
}

-- ---------------------------------------------------------------------------
-- LOG RETENTION
-- ---------------------------------------------------------------------------
Config.RetentionDays = 30          -- NDJSON files older than this get deleted

-- ---------------------------------------------------------------------------
-- NDJSON DIRECTORY (relative to this resource)
-- ---------------------------------------------------------------------------
Config.LogDirectory  = "logs/"

-- ---------------------------------------------------------------------------
-- ENABLED LOG TYPES (set to false to disable any category)
-- ---------------------------------------------------------------------------
Config.EnabledLogs = {
    kill      = true,    -- player deaths (PVP, NPC, vehicle, self, environmental)
    chat      = true,    -- /ooc, /me, /scene, /twt, and other chat messages
    joinLeave = true,    -- player connect / disconnect events
    admin     = true,    -- administrative actions and commands
    weapon    = true,    -- weapon fire events
    explosion = true,    -- explosion events
    console   = true,    -- F8 console command usage
}

-- ---------------------------------------------------------------------------
-- WEBHOOK QUEUE SYSTEM
-- ---------------------------------------------------------------------------
Config.Queue = {
    MaxRetries      = 3,       -- max delivery attempts before dropping a message
    RetryDelayMs    = 5000,    -- base delay between retries (exponential backoff)
    MessagesPerMin  = 25,      -- rate-limit-safe messages per minute per webhook
    ProcessInterval = 1000,    -- how often the queue processor runs (ms)
}

-- ---------------------------------------------------------------------------
-- SERVER IDENTITY
-- ---------------------------------------------------------------------------
Config.ServerName = "Sinister H-Town RP"

-- ---------------------------------------------------------------------------
-- EMBED COLORS (decimal)
-- ---------------------------------------------------------------------------
Config.Colors = {
    kill      = 0xFF0000,   -- red
    chat      = 0x00AAFF,   -- blue
    join      = 0x00FF00,   -- green
    leave     = 0xFFA500,   -- orange
    admin     = 0xFF00FF,   -- magenta
    weapon    = 0xFF4500,   -- orange-red
    explosion = 0xFFD700,   -- gold
    console   = 0x888888,   -- grey
}

-- ---------------------------------------------------------------------------
-- CHAT CHANNELS TO LOG (case-insensitive prefix match)
-- ---------------------------------------------------------------------------
Config.ChatChannels = {
    "ooc",
    "/ooc",
    "me",
    "/me",
    "scene",
    "/scene",
    "twt",
    "/twt",
    "do",
    "/do",
    "dispatch",
    "/dispatch",
    "news",
    "/news",
    "darkweb",
    "/darkweb",
    "anon",
    "/anon",
    "tweet",
    "/tweet",
    "ad",
    "/ad",
    "advert",
    "/advert",
    "broadcast",
    "/broadcast",
}

-- ---------------------------------------------------------------------------
-- WEAPON BLACKLIST (weapon hashes to ignore)
-- ---------------------------------------------------------------------------
Config.WeaponBlacklist = {
    [`WEAPON_UNARMED`]          = true,
    [`WEAPON_SNOWBALL`]         = true,
    [`WEAPON_FIREEXTINGUISHER`] = true,
    [`WEAPON_PETROLCAN`]        = true,
    [`WEAPON_STUNGUN`]          = true,
    [`WEAPON_FLARE`]            = true,
    [`WEAPON_FLASHLIGHT`]       = true,
    [`WEAPON_NIGHTSTICK`]       = true,
    [`WEAPON_KNUCKLE`]          = true,
}

-- ---------------------------------------------------------------------------
-- DEATH CAUSE MAPPING (gameEvent death hashes -> human-readable labels)
-- ---------------------------------------------------------------------------
Config.DeathCauses = {
    [0x9BA13115] = "Vehicle Crash",
    [0xBD38A7B5] = "Drowning",
    [0x8A2F118F] = "Falling",
    [0xD6B161C3] = "Fire",
    [0x8CDB732E] = "Explosion",
    [0x1BEA214C] = "Melee",
    [0x8043EAE5] = "Pistol",
    [0x607012D2] = "SMG",
    [0xABF93CA1] = "Rifle",
    [0xCA0FB106] = "Shotgun",
    [0xDC0E096A] = "Sniper",
    [0x4D597EB9] = "Heavy Weapon",
    [0x8CDB728E] = "Explosive",
    [0x7BE1C58D] = "Blade",
}

-- ---------------------------------------------------------------------------
-- ADMIN COMMANDS TO LOG (pattern match on command name)
-- ---------------------------------------------------------------------------
Config.AdminCommands = {
    "kick",
    "ban",
    "warn",
    "mute",
    "freeze",
    "bring",
    "goto",
    "revive",
    "slay",
    "noclip",
    "god",
    "tp",
    "setjob",
    "setgang",
    "removemoney",
    "addmoney",
    "setmoney",
    "clearinv",
    "giveitem",
    "removeitem",
    "setgroup",
    "spectate",
}
