Config = {}

Config.StoreName = "Sinister H-Town RP"
Config.TebexSecret = "8523624d4cbe76e8df96667ca09e3e00afa19685"
Config.TebexStoreUrl = "https://server.tebex.io"
Config.Currency = "$"
Config.Locale = "en-US"

Config.Theme = {
    primary = "#BF5700",
    secondary = "#FF8C42",
    background = "#0d0d14",
    surface = "#1a1a2e",
    text = "#e0e0e0",
    muted = "#6b7280",
    success = "#22c55e",
    danger = "#ef4444",
    warning = "#f59e0b",
}

Config.Database = {
    host = "91.99.71.34",
    port = 3307,
    user = "u10208_WO0ajxNA1S",
    password = "y6fpxyrazMV!!J.F0sdQvGbZ",
    database = "s10208_Sinister",
}

Config.Categories = {
    { id = "vip",          label = "VIP",           icon = "crown",          order = 1 },
    { id = "money",        label = "Money",         icon = "dollar-sign",    order = 2 },
    { id = "vehicles",     label = "Vehicles",      icon = "car",            order = 3 },
    { id = "items",        label = "Items",         icon = "shopping-bag",   order = 4 },
    { id = "jobs",         label = "Jobs",          icon = "briefcase",      order = 5 },
    { id = "gangs",        label = "Gangs",         icon = "users",          order = 6 },
    { id = "customization",label = "Customization", icon = "edit",           order = 7 },
    { id = "utilities",    label = "Utilities",     icon = "settings",       order = 8 },
}

Config.Packages = {

    -- VIP
    { name = "VIP Silver",        category = "vip", price = 9.99,  description = "Silver VIP access with priority queue and daily bonus.",  reward = { type = "vip", tier = "silver" } },
    { name = "VIP Gold",          category = "vip", price = 19.99, description = "Gold VIP with increased daily bonus and chat perks.",    reward = { type = "vip", tier = "gold" } },
    { name = "VIP Platinum",      category = "vip", price = 39.99, description = "Platinum VIP with exclusive vehicle spawns and more.",   reward = { type = "vip", tier = "platinum" } },
    { name = "VIP Diamond",       category = "vip", price = 69.99, description = "Diamond VIP with all perks, custom tags, and more.",     reward = { type = "vip", tier = "diamond" } },

    -- Money
    { name = "$10,000 Cash",      category = "money", price = 4.99,  description = "In-game cash deposit of $10,000.",     reward = { type = "money", amount = 10000 } },
    { name = "$50,000 Cash",      category = "money", price = 9.99,  description = "In-game cash deposit of $50,000.",     reward = { type = "money", amount = 50000 } },
    { name = "$100,000 Cash",     category = "money", price = 14.99, description = "In-game cash deposit of $100,000.",    reward = { type = "money", amount = 100000 } },
    { name = "$500,000 Cash",     category = "money", price = 34.99, description = "In-game cash deposit of $500,000.",    reward = { type = "money", amount = 500000 } },
    { name = "$1,000,000 Cash",   category = "money", price = 59.99, description = "In-game cash deposit of $1,000,000.",  reward = { type = "money", amount = 1000000 } },

    -- Vehicles
    { name = "Custom Vehicle Import",   category = "vehicles", price = 14.99, description = "Import a custom vehicle of your choice.",    reward = { type = "vehicle", class = "custom" } },
    { name = "Luxury Vehicle Import",   category = "vehicles", price = 24.99, description = "Import a luxury-class vehicle.",             reward = { type = "vehicle", class = "luxury" } },
    { name = "Supercar Import",         category = "vehicles", price = 44.99, description = "Import a top-tier supercar.",                reward = { type = "vehicle", class = "supercar" } },

    -- Items (Weapon Packs)
    { name = "Weapon Pack: Pistol",     category = "items", price = 9.99,  description = "Pistol, 50 rounds, and a suppressor.",            reward = { type = "item", items = { { name = "weapon_pistol", amount = 1 }, { name = "pistol_ammo", amount = 50 }, { name = "suppressor", amount = 1 } } } },
    { name = "Weapon Pack: SMG",        category = "items", price = 14.99, description = "SMG, 120 rounds, and extended clip.",             reward = { type = "item", items = { { name = "weapon_smg", amount = 1 }, { name = "smg_ammo", amount = 120 } } } },
    { name = "Weapon Pack: Rifle",      category = "items", price = 19.99, description = "Assault rifle, 150 rounds, and scope.",           reward = { type = "item", items = { { name = "weapon_assaultrifle", amount = 1 }, { name = "rifle_ammo", amount = 150 }, { name = "scope", amount = 1 } } } },
    { name = "Weapon Pack: Heavy",      category = "items", price = 29.99, description = "Heavy rifle, 200 rounds, grip, and scope.",       reward = { type = "item", items = { { name = "weapon_heavyrifle", amount = 1 }, { name = "rifle_ammo", amount = 200 }, { name = "grip", amount = 1 }, { name = "scope", amount = 1 } } } },

    -- Jobs
    { name = "Job: Police Officer",      category = "jobs",  price = 4.99,  description = "Whitelist access to the LSPD as an Officer.",        reward = { type = "job", job = "police", grade = 1 } },
    { name = "Job: EMS",                 category = "jobs",  price = 4.99,  description = "Whitelist access to EMS as a Paramedic.",            reward = { type = "job", job = "ambulance", grade = 1 } },
    { name = "Job: Mechanic",            category = "jobs",  price = 4.99,  description = "Whitelist access to the Mechanic job.",               reward = { type = "job", job = "mechanic", grade = 1 } },
    { name = "Job: Lawyer",              category = "jobs",  price = 4.99,  description = "Whitelist access to the Lawyer job.",                 reward = { type = "job", job = "lawyer", grade = 1 } },
    { name = "Job: Real Estate Agent",   category = "jobs",  price = 4.99,  description = "Whitelist access to the Real Estate Agent job.",     reward = { type = "job", job = "realestate", grade = 1 } },

    -- Gangs
    { name = "Gang: Ballas",        category = "gangs", price = 9.99,  description = "Join the Ballas gang with rank access.",            reward = { type = "gang", gang = "ballas", grade = 1 } },
    { name = "Gang: Vagos",         category = "gangs", price = 9.99,  description = "Join the Vagos gang with rank access.",            reward = { type = "gang", gang = "vagos", grade = 1 } },
    { name = "Gang: Grove Street",  category = "gangs", price = 9.99,  description = "Join the Grove Street Families with rank access.",  reward = { type = "gang", gang = "grove", grade = 1 } },
    { name = "Gang: Cartel",        category = "gangs", price = 14.99, description = "Join the Cartel with high-tier rank access.",      reward = { type = "gang", gang = "cartel", grade = 2 } },

    -- Customization
    { name = "Name Change Token",       category = "customization", price = 4.99,  description = "Token to change your character's name once.",       reward = { type = "namechange" } },
    { name = "Custom License Plate",    category = "customization", price = 7.99,  description = "Redeem for a custom license plate on your vehicle.", reward = { type = "platechange" } },
    { name = "Appearance Reset Token",  category = "customization", price = 4.99,  description = "Reset your character's appearance at next spawn.",  reward = { type = "appearance" } },
}

Config.PurchaseCheckInterval = 60000
Config.LogFile = "sinister_purchases.log"
Config.QueueProcessingInterval = 15000

Config.Commands = {
    openStore = "buy",
    redeem = "redeem",
    adminCheck = "checkpending",
}

Config.Notifications = {
    pendingPurchase = "You have %d unredeemed store purchase(s)! Use /redeem to claim them.",
    purchaseRedeemed = "Purchase '%s' has been redeemed successfully.",
    purchaseFailed = "Failed to redeem purchase '%s'. Please contact an admin.",
    noPending = "You have no pending purchases to redeem.",
    storeClosed = "Store closed.",
    checkoutComplete = "Thank you for your purchase! Your items will be delivered shortly.",
    webhookInvalid = "Invalid purchase verification.",
    queueProcessed = "Processed %d pending purchase(s).",
}
