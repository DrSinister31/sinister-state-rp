Config = {}

Config.UIColor = "#BF5700"

Config.Stations = {
	{
		id = "hill_country_still",
		name = "Hill Country Still",
		coords = vec3(1950.0, 3850.0, 33.0),
		category = "Bayou Brewing",
		categoryIcon = "fa-solid fa-whiskey-glass",
		recipes = {
			{
				id = "hill_country_shine",
				name = "Hill Country Shine",
				time = 15000,
				ingredients = {
					{ item = "weed_brick", count = 2 },
					{ item = "water", count = 1 },
				},
				result = { item = "moonshine", count = 1 },
			},
		},
	},
	{
		id = "third_ward_lab",
		name = "Third Ward Lab",
		coords = vec3(280.0, -1600.0, 33.0),
		category = "Texas Pharmaceuticals",
		categoryIcon = "fa-solid fa-flask",
		recipes = {
			{
				id = "bluebonnet_batch",
				name = "Bluebonnet Batch",
				time = 20000,
				ingredients = {
					{ item = "weed_brick", count = 3 },
					{ item = "meth", count = 1 },
					{ item = "water", count = 1 },
				},
				result = { item = "meth", count = 3 },
			},
			{
				id = "third_ward_cook",
				name = "Third Ward Cook",
				time = 18000,
				ingredients = {
					{ item = "crack", count = 1 },
					{ item = "meth", count = 1 },
				},
				result = { item = "crack", count = 3 },
			},
			{
				id = "bayou_blend",
				name = "Bayou Blend",
				time = 25000,
				ingredients = {
					{ item = "weed_brick", count = 5 },
				},
				result = { item = "weed_concentrate", count = 1 },
			},
		},
	},
	{
		id = "lone_star_forge",
		name = "Lone Star Forge",
		coords = vec3(-350.0, 6150.0, 32.0),
		category = "Lone Star Arsenal",
		categoryIcon = "fa-solid fa-hammer",
		recipes = {
			{
				id = "lone_star_forge_lockpick",
				name = "Lone Star Forge",
				time = 12000,
				ingredients = {
					{ item = "iron", count = 1 },
					{ item = "steel", count = 1 },
				},
				result = { item = "advancedlockpick", count = 1 },
			},
			{
				id = "texas_iron",
				name = "Texas Iron",
				time = 30000,
				ingredients = {
					{ item = "iron", count = 5 },
					{ item = "steel", count = 2 },
				},
				result = { item = "thermite", count = 1 },
			},
		},
	},
}

Config.NotifyIcon = "fa-solid fa-gears"
Config.NotifyPosition = "top-right"
