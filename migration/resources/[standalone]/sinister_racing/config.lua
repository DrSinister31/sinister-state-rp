Config = {}

Config.UIColor = "#BF5700"

Config.RaceOrganizer = {
	coords = vec4(935.0, -150.0, 74.0, 110.0),
	model = "s_m_y_dealer_01",
}

Config.RequiredPolice = 0

Config.WagerCurrency = "dirty_money"

Config.AllowedVehicleClass = "muscle"

Config.VehicleClasses = {
	muscle = {
		0, 1, 2, 3, 4, 5, 6, 7,
	},
}

Config.MinRacers = 2
Config.MaxRacers = 8

Config.EntryFee = {
	min = 500,
	max = 5000,
	presets = { 500, 1000, 2500, 5000 },
}

Config.CooldownMinutes = 5

Config.PoliceAlertChance = 25
Config.PoliceAlertFormat = "🚨 STREET RACING — %s detected in %s area"

Config.CheckpointRadius = 12.0
Config.FinishRadius = 20.0
Config.RaceTimeout = 15

Config.ReputationGain = {
	win = 15,
	podium = 8,
	finish = 3,
}

Config.RaceRoutes = {
	{
		id = "galveston_drag",
		name = "Galveston Drag",
		label = "Beachfront sprint along the Galveston coast",
		minRep = 0,
		checkpoints = {
			vec3(-1700.0, 2320.0, 1.0),
			vec3(-1580.0, 2250.0, 1.0),
			vec3(-1450.0, 2180.0, 1.0),
			vec3(-1350.0, 2100.0, 1.0),
		},
	},
	{
		id = "killeen_dust_sprint",
		name = "Killeen Dust Sprint",
		label = "Desert drag through Killeen dust bowl",
		minRep = 0,
		checkpoints = {
			vec3(1950.0, 3850.0, 33.0),
			vec3(2100.0, 3700.0, 33.0),
			vec3(2250.0, 3550.0, 33.0),
			vec3(2400.0, 3400.0, 20.0),
			vec3(2200.0, 3300.0, 30.0),
		},
	},
	{
		id = "third_ward_circuit",
		name = "Third Ward Circuit",
		label = "Downtown loop through Third Ward streets",
		minRep = 5,
		checkpoints = {
			vec3(280.0, -1600.0, 33.0),
			vec3(400.0, -1400.0, 33.0),
			vec3(500.0, -1200.0, 33.0),
			vec3(350.0, -1000.0, 33.0),
			vec3(150.0, -1200.0, 33.0),
			vec3(100.0, -1500.0, 33.0),
		},
	},
	{
		id = "ft_worth_mountain_pass",
		name = "Ft. Worth Mountain Pass",
		label = "Hill country run through Ft. Worth backroads",
		minRep = 10,
		checkpoints = {
			vec3(-350.0, 6150.0, 32.0),
			vec3(-500.0, 6000.0, 60.0),
			vec3(-650.0, 5850.0, 80.0),
			vec3(-500.0, 5700.0, 50.0),
			vec3(-300.0, 5800.0, 40.0),
		},
	},
	{
		id = "bayou_backroads",
		name = "Bayou Backroads",
		label = "Swamp-side twisty run along the bayou",
		minRep = 15,
		checkpoints = {
			vec3(1500.0, 5200.0, 5.0),
			vec3(1700.0, 5000.0, 5.0),
			vec3(1900.0, 4800.0, 5.0),
			vec3(1800.0, 4600.0, 10.0),
			vec3(1600.0, 4500.0, 8.0),
		},
	},
}
