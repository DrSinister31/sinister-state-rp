--- Sinister H-Town RP Chat Configuration
---
--- SETUP NOTES:
---   - Disable qbx_chat_theme: remove or comment out 'ensure qbx_chat_theme' from server.cfg
---   - Comment out default chat ensure in server.cfg if present
---   - This resource replaces the default FiveM chat entirely
---
--- QBCore / QBox Shared Config

Config = Config or {}

---@type string
Config.ChatPrefix = '/'

---@type string
Config.AccentColor = '#BF5700'

---@type string
Config.DarkBackground = '#0d0d14'

---@type number
Config.MaxMessages = 100

---@type number
Config.FadeTimer = 15

---@type boolean
Config.EmojiSupport = true

---@type boolean
Config.Resizable = true

---@type number
Config.MaxMessageLength = 256

---@type number
Config.SpamDelay = 1000

---@type table<number, string>
Config.AutoMessages = {
    [1] = 'Welcome to Sinister H-Town RP — Respect the RP!',
    [2] = 'Texas jobs available — /jobs to check listings',
    [3] = 'New to the city? Read the rules at discord.gg/sinisterhtown',
    [4] = 'Having fun? Bring your friends to Sinister H-Town RP!',
    [5] = 'Keep it Texas — Y\'all drive safe out there, partner!',
}

---@type number
Config.AutoMessageInterval = 300000

---@type table
Config.AllowedCommands = {
    ['ooc'] = true,
    ['me'] = true,
    ['do'] = true,
    ['twt'] = true,
    ['news'] = true,
    ['advert'] = true,
    ['anon'] = true,
    ['darkweb'] = true,
    ['help'] = true,
    ['clear'] = true,
    ['jobs'] = true,
    ['players'] = true,
}

---@type table<number, table>
Config.JobChannels = {
    { name = 'police',     label = 'Police',       command = '/pd',         color = '#5B9BD5' },
    { name = 'ambulance',  label = 'Ambulance',    command = '/ems',        color = '#E74C3C' },
    { name = 'mechanic',   label = 'Mechanic',     command = '/mech',       color = '#F39C12' },
    { name = 'taxi',       label = 'Taxi',         command = '/taxi',       color = '#F1C40F' },
    { name = 'realtor',    label = 'Real Estate',  command = '/realestate', color = '#1ABC9C' },
    { name = 'judge',      label = 'Judge',        command = '/judge',      color = '#9B59B6' },
    { name = 'lawyer',     label = 'Lawyer',       command = '/lawyer',     color = '#8E44AD' },
    { name = 'reporter',   label = 'Reporter',     command = '/reporter',   color = '#2ECC71' },
    { name = 'cardealer',  label = 'Car Dealer',   command = '/cardealer',  color = '#3498DB' },
    { name = 'busdriver',  label = 'Bus Driver',   command = '/bus',        color = '#E67E22' },
    { name = 'trucker',    label = 'Trucker',      command = '/trucker',    color = '#D35400' },
    { name = 'lumberjack', label = 'Lumberjack',   command = '/lumberjack', color = '#6D4C41' },
    { name = 'miner',      label = 'Miner',        command = '/miner',      color = '#7F8C8D' },
    { name = 'fisherman',  label = 'Fisherman',    command = '/fisherman',  color = '#5DADE2' },
    { name = 'hunter',     label = 'Hunter',       command = '/hunter',     color = '#A93226' },
    { name = 'farmer',     label = 'Farmer',       command = '/farmer',     color = '#27AE60' },
    { name = 'bartender',  label = 'Bartender',    command = '/bartender',  color = '#F4D03F' },
    { name = 'unicorn',    label = 'Unicorn',      command = '/unicorn',    color = '#FF69B4' },
    { name = 'burgerbarn', label = 'Burger Barn',  command = '/burgerbarn', color = '#E59866' },
    { name = 'brewstop',   label = 'Brew Stop',    command = '/brewstop',   color = '#A0522D' },
    { name = 'autoshop',   label = 'Auto Shop',    command = '/autoshop',   color = '#C0392B' },
    { name = 'customs',    label = 'Customs',      command = '/customs',    color = '#16A085' },
}

---@type table<string, string>
Config.ProximityTypes = {
    ['me'] = 'me',
    ['do'] = 'do',
    ['ooc'] = 'ooc',
}

---@type number
Config.ProximityDistance = 20.0

---@type number
Config.ProximityMeDistance = 15.0

---@type number
Config.ProximityDoDistance = 15.0

---@type number
Config.ProximityOOCDistance = 5.0
