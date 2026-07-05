Config = {}

-- ============================================================================
-- SINISTER AIRDROPS — Texas Drop Zones
-- ============================================================================

Config.Zones = {
	{
		id = "killeen_dust_bowl",
		label = "Killeen Dust Bowl",
		coords = vec3(1898.0, 3872.0, 34.0),
		restrictedToCayo = false,
	},
	{
		id = "galveston_docks",
		label = "Galveston Docks",
		coords = vec3(-1700.0, 2320.0, 1.0),
		restrictedToCayo = false,
	},
	{
		id = "ft_worth_hills",
		label = "Ft. Worth Hills",
		coords = vec3(-350.0, 6150.0, 80.0),
		restrictedToCayo = false,
	},
	{
		id = "third_ward_alley",
		label = "Third Ward Alley",
		coords = vec3(280.0, -1600.0, 30.0),
		restrictedToCayo = false,
	},
	{
		id = "montrose_heights",
		label = "Montrose Heights",
		coords = vec3(380.0, 650.0, 225.0),
		restrictedToCayo = false,
	},
	{
		id = "bayou_landing",
		label = "Bayou Landing",
		coords = vec3(1500.0, 5200.0, 5.0),
		restrictedToCayo = false,
	},
}

-- ============================================================================
-- Loot Tables
-- ============================================================================

Config.Loot = {
	Common = {
		{ item = "dirty_money", min = 50, max = 200, chance = 85 },
		{ item = "armor", min = 1, max = 1, chance = 70 },
		{ item = "bandage", min = 1, max = 3, chance = 65 },
		{ item = "pistol_ammo", min = 10, max = 30, chance = 60 },
	},
	Uncommon = {
		{ item = "weed_brick", min = 1, max = 2, chance = 45 },
		{ item = "meth", min = 2, max = 5, chance = 40 },
		{ item = "crack", min = 1, max = 3, chance = 40 },
		{ item = "rifle_ammo", min = 10, max = 25, chance = 35 },
	},
	Rare = {
		{ item = "coke", min = 1, max = 2, chance = 20 },
		{ item = "advancedlockpick", min = 1, max = 1, chance = 15 },
		{ item = "thermite", min = 1, max = 1, chance = 10 },
	},
}

-- ============================================================================
-- Plane / Visual Config
-- ============================================================================

Config.PlaneModel = "cuban800"
Config.PlaneBlipSprite = 307
Config.PlaneBlipColor = 1
Config.PlaneBlipLabel = "Unregistered Aircraft — Houston Airspace"
Config.CrateModel = "prop_box_wood05a"
Config.ParachuteModel = "p_parachute_s"
Config.SmokeColor = { r = 255, g = 0, b = 0 }
Config.FlareItem = "weapon_flare"

-- ============================================================================
-- Kamikaze Mode
-- ============================================================================

Config.KamikazeChance = 1
Config.KamikazeName = "KILLEEN CROP DUSTER"

-- ============================================================================
-- Timing
-- ============================================================================

Config.CrateOpenTime = 15000
Config.CrateStayTime = 300000
Config.CooldownPerZone = 30
Config.AutoDropInterval = 45
Config.MinPlayersForAuto = 2

-- ============================================================================
-- Alerts
-- ============================================================================

Config.DiscordWebhook = ""
Config.DiscordAlertFormat = "☠️ SUSPICIOUS AIRCRAFT: Unregistered plane dropping cargo near {zone} — all units intercept"

Config.NotifyJobs = {}
Config.NotifyGangs = {}
