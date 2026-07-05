Config = {}

-- ============================================================================
-- SINISTER ROBBERIES — Texas Hold-Up Config
-- ============================================================================

Config.RequiredPolice = 0

Config.TexasHeatCooldown = 15

Config.RobTime = 20000

Config.PoliceAlertFormat = "🚨 211 IN PROGRESS — %s at %s"

Config.RobberyTypes = {
	{
		type = "liquor_store",
		label = "Liquor Store Hold-Up",
		icon = "fa-solid fa-store",
		locations = {
			{ coords = vec3(1135.0, -982.0, 46.0), name = "Davis Liquor" },
			{ coords = vec3(-1222.0, -907.0, 12.0), name = "Vespucci Spirits" },
			{ coords = vec3(-1487.0, -379.0, 40.0), name = "Morningwood Bottle Shop" },
			{ coords = vec3(-2968.0, 391.0, 15.0), name = "Chumash Liquor" },
		},
		rewards = {
			dirtyMoney = { min = 300, max = 800 },
			items = {},
		},
	},
	{
		type = "bayou_dock",
		label = "Bayou Dock Theft",
		icon = "fa-solid fa-anchor",
		locations = {
			{ coords = vec3(1500.0, 5200.0, 5.0), name = "Bayou Landing Pier" },
			{ coords = vec3(1700.0, 4800.0, 2.0), name = "Alamo Sea Dock" },
		},
		rewards = {
			dirtyMoney = { min = 500, max = 1500 },
			items = {
				{ item = "weed_brick", min = 1, max = 2, chance = 50 },
			},
		},
	},
	{
		type = "killeen_station",
		label = "Killeen Gas Station Stick-Up",
		icon = "fa-solid fa-gas-pump",
		locations = {
			{ coords = vec3(1950.0, 3740.0, 32.0), name = "Killeen 24/7 Stop" },
			{ coords = vec3(1680.0, 3600.0, 35.0), name = "Sandy Shores Fuel" },
		},
		rewards = {
			dirtyMoney = { min = 200, max = 600 },
			items = {
				{ item = "pistol_ammo", min = 6, max = 18, chance = 60 },
				{ item = "radio", min = 1, max = 1, chance = 25 },
			},
		},
	},
	{
		type = "montrose_jewelry",
		label = "Montrose Jewelry Heist",
		icon = "fa-solid fa-gem",
		locations = {
			{ coords = vec3(-630.0, -230.0, 38.0), name = "Montrose Vangelico" },
			{ coords = vec3(380.0, 650.0, 225.0), name = "Montrose Heights Jewel" },
		},
		rewards = {
			dirtyMoney = { min = 1000, max = 3000 },
			items = {
				{ item = "advancedlockpick", min = 1, max = 1, chance = 30 },
				{ item = "crack", min = 1, max = 2, chance = 35 },
			},
		},
	},
	{
		type = "ft_worth_bank",
		label = "Ft. Worth Bank Job",
		icon = "fa-solid fa-building-columns",
		locations = {
			{ coords = vec3(-350.0, 6150.0, 30.0), name = "Ft. Worth Savings" },
			{ coords = vec3(-110.0, 6470.0, 31.0), name = "Paleto Fleeca" },
		},
		rewards = {
			dirtyMoney = { min = 2000, max = 6000 },
			items = {
				{ item = "thermite", min = 1, max = 1, chance = 25 },
				{ item = "coke", min = 1, max = 3, chance = 30 },
				{ item = "rifle_ammo", min = 15, max = 30, chance = 40 },
			},
		},
	},
}
