Config = Config or {}

-- ============================================================================
-- DRUG DEALER SYSTEM
-- ============================================================================

Config.DrugTypes = {
    ['weed_brick'] = {
        label = 'Weed Brick',
        price = 325,
        risk = 1,
        emoji = '🌿',
    },
    ['meth'] = {
        label = 'Meth',
        price = 800,
        risk = 3,
        emoji = '🧪',
    },
    ['coke'] = {
        label = 'Coke',
        price = 1800,
        risk = 4,
        emoji = '❄️',
    },
    ['crack'] = {
        label = 'Crack',
        price = 500,
        risk = 3,
        emoji = '💎',
    },
    ['weed_concentrate'] = {
        label = 'Bayou Blend',
        price = 900,
        risk = 2,
        emoji = '🫧',
    },
    ['moonshine'] = {
        label = 'Hill Country Shine',
        price = 400,
        risk = 2,
        emoji = '🥃',
    },
}

Config.DrugBuyMultiplier = 0.7   -- Dealers buy at 70% of street price
Config.DrugSellMultiplier = 1.3  -- Dealers sell at 130% of street price

-- ============================================================================
-- WEAPON DEALER SYSTEM
-- ============================================================================

Config.WeaponTiers = {
    ['Tier 1 — Street'] = {
        minRep = 0,
        items = {
            { name = 'weapon_combatpistol',  label = 'Combat Pistol',  price = 5000 },
            { name = 'weapon_pistol50',      label = 'Desert Eagle',   price = 8000 },
            { name = 'weapon_knife',         label = 'Combat Knife',   price = 500 },
            { name = 'weapon_bat',           label = 'Baseball Bat',   price = 300 },
            { name = 'pistol_ammo',          label = 'Pistol Ammo x30', price = 300 },
        },
    },
    ['Tier 2 — Hustler'] = {
        minRep = 200,
        items = {
            { name = 'weapon_smg',           label = 'SMG',            price = 15000 },
            { name = 'weapon_pumpshotgun',   label = 'Pump Shotgun',   price = 12000 },
            { name = 'weapon_machinepistol', label = 'Machine Pistol', price = 10000 },
            { name = 'smg_ammo',             label = 'SMG Ammo x30',   price = 500 },
            { name = 'shotgun_shells',       label = 'Shotgun Shells x10', price = 400 },
            { name = 'armor',                label = 'Body Armor',     price = 2000 },
        },
    },
    ['Tier 3 — Enforcer'] = {
        minRep = 800,
        items = {
            { name = 'weapon_assaultrifle',  label = 'Assault Rifle',  price = 35000 },
            { name = 'weapon_carbinerifle',  label = 'Carbine Rifle',  price = 30000 },
            { name = 'weapon_heavypistol',   label = 'Heavy Pistol',   price = 12000 },
            { name = 'weapon_molotov',       label = 'Molotov',         price = 1500 },
            { name = 'rifle_ammo',           label = 'Rifle Ammo x30',  price = 800 },
            { name = 'thermite',             label = 'Thermite',        price = 5000 },
            { name = 'advancedlockpick',     label = 'Advanced Lockpick', price = 2500 },
        },
    },
}

Config.WeaponJobBlacklist = { 'police', 'bcso', 'sasp', 'fib', 'military', 'ambulance', 'fire' }

-- ============================================================================
-- DEALER NPC SYSTEM
-- ============================================================================

Config.DealerPeds = {
    'g_m_y_famdnf_01',
    'g_m_y_mexgoose_01',
    'g_m_y_salvagoon_01',
    'g_m_y_strpunk_01',
    'g_m_y_korean_02',
    'u_m_y_baygor',
    'u_m_y_hippie_01',
    'u_m_y_staggrm_01',
}

Config.StreetDealerLocations = {
    -- Third Ward (Davis)
    { coords = vec4(94.5, -1730.0, 29.5, 320.0), zone = 'Third Ward' },
    { coords = vec4(110.0, -1780.0, 29.5, 45.0),  zone = 'Third Ward' },
    { coords = vec4(60.0, -1830.0, 27.0, 180.0),  zone = 'Third Ward' },
    -- Montrose (Vinewood)
    { coords = vec4(320.0, -111.0, 68.0, 160.0),  zone = 'Montrose' },
    { coords = vec4(280.0, -187.0, 54.0, 90.0),    zone = 'Montrose' },
    -- Killeen (Sandy Shores)
    { coords = vec4(1970.0, 3720.0, 33.0, 300.0),  zone = 'Killeen' },
    { coords = vec4(1680.0, 3590.0, 35.5, 210.0),  zone = 'Killeen' },
    -- Docks
    { coords = vec4(920.0, -3230.0, 6.0, 270.0),   zone = 'Galveston Docks' },
    { coords = vec4(720.0, -3150.0, 6.0, 90.0),    zone = 'Galveston Docks' },
    -- Ft. Worth (Paleto)
    { coords = vec4(-150.0, 6480.0, 31.5, 45.0),   zone = 'Ft. Worth' },
}

Config.GunDealerLocations = {
    { coords = vec4(830.0, -2160.0, 29.5, 90.0),  zone = 'South Houston' },
    { coords = vec4(1330.0, -1730.0, 52.5, 0.0),   zone = 'East Houston' },
    { coords = vec4(1960.0, 3760.0, 33.0, 90.0),   zone = 'Killeen' },
}

Config.DealerRecruitCost = 5000       -- Cost to recruit a dealer
Config.DealerDailyWage = 1000         -- Daily wage per dealer
Config.MaxDealersPerPlayer = 3        -- Max dealers one player can recruit
Config.PoliceAlertChance = 25         -- % chance police get alerted during transaction

-- Rival dealers
Config.RivalSpawnChance = 15          -- % chance rival dealer spawns at spot
Config.RivalAggroRange = 15.0
Config.RivalFightReward = 500         -- dirty_money reward for killing rival

-- ============================================================================
-- INTEGRATION
-- ============================================================================

Config.UseTarget = true               -- Use ox_target for interactions
Config.Debug = false
