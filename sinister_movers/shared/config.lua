Config = {}

Config.CompanyName = "Lone Star Movers"
Config.Slogan = "We Haul Texas-Sized Loads"
Config.BurntOrange = "#BF5700"
Config.DarkBg = "#0d0d14"

Config.DepotLocation = vec3(-50.0, -1100.0, 26.5)
Config.DepotHeading = 90.0

Config.VehicleModel = "boxville4"
Config.VehicleLivery = 0

Config.PayRange = { min = 1500, max = 3000 }

Config.ServiceAreas = {
    {
        id = "houston_legion",
        label = "Houston — Legion Square",
        pickup = vec3(195.0, -920.0, 30.0),
        dropoff = vec3(320.0, -980.0, 29.0),
        basePay = 2000,
    },
    {
        id = "houston_davis",
        label = "Houston — Davis/Sunnyside",
        pickup = vec3(320.0, -1450.0, 29.0),
        dropoff = vec3(160.0, -1500.0, 28.0),
        basePay = 1850,
    },
    {
        id = "ftworth_paleto",
        label = "Ft. Worth — Paleto Bay",
        pickup = vec3(-440.0, 6000.0, 31.0),
        dropoff = vec3(-350.0, 6250.0, 29.0),
        basePay = 2500,
    },
    {
        id = "ftworth_stockyards",
        label = "Ft. Worth — Stockyards",
        pickup = vec3(-510.0, 5380.0, 80.0),
        dropoff = vec3(-300.0, 5500.0, 60.0),
        basePay = 2200,
    },
    {
        id = "killeen_downtown",
        label = "Killeen — Downtown",
        pickup = vec3(1700.0, 3580.0, 35.0),
        dropoff = vec3(1850.0, 3700.0, 33.0),
        basePay = 2300,
    },
    {
        id = "killeen_harmony",
        label = "Killeen — Loma Vista",
        pickup = vec3(1175.0, 2642.0, 37.0),
        dropoff = vec3(1300.0, 2700.0, 38.0),
        basePay = 1750,
    },
}

Config.Uniform = {
    male = {
        tshirt = { 15, 3 },
        torso = { 42, 3 },
        legs = { 24, 3 },
        shoes = { 25, 0 },
    },
    female = {
        tshirt = { 15, 3 },
        torso = { 46, 3 },
        legs = { 24, 3 },
        shoes = { 25, 0 },
    },
}
