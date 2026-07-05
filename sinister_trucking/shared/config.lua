Config = {}

Config.CompanyName = "Lone Star Logistics"
Config.BurntOrange = "#BF5700"
Config.DarkBg = "#0d0d14"

Config.DepotLocation = vec3(2140.0, 4798.0, 40.0)
Config.DepotHeading = 90.0
Config.DepotLabel = "Killeen Distribution Center"

Config.VehicleModel = "hauler"
Config.VehicleLivery = 0

Config.Grades = {
    { name = "Trainee", payment = 1500, minExp = 0 },
    { name = "Driver", payment = 2250, minExp = 10 },
    { name = "Senior Driver", payment = 2750, minExp = 30 },
    { name = "Fleet Manager", payment = 3500, minExp = 60 },
}

Config.Routes = {
    {
        id = "gulf_coast",
        name = "Gulf Coast Run",
        description = "Houston ↔ Galveston",
        pickup = vec3(880.0, -2250.0, 30.0),
        pickupLabel = "Houston Port Terminal",
        dropoff = vec3(-1250.0, -1480.0, 4.0),
        dropoffLabel = "Galveston Shipping Co.",
        basePay = 1500,
        distanceBonus = 800,
    },
    {
        id = "hill_country",
        name = "Hill Country Haul",
        description = "Ft. Worth ↔ Killeen",
        pickup = vec3(-400.0, 6100.0, 31.0),
        pickupLabel = "Ft. Worth Rail Yard",
        dropoff = vec3(1700.0, 3580.0, 35.0),
        dropoffLabel = "Killeen Industrial Park",
        basePay = 2000,
        distanceBonus = 1000,
    },
    {
        id = "panhandle",
        name = "Panhandle Express",
        description = "Paleto ↔ Sandy Shores",
        pickup = vec3(140.0, 6680.0, 14.0),
        pickupLabel = "North Paleto Supply",
        dropoff = vec3(2500.0, 3700.0, 35.0),
        dropoffLabel = "Sandy Shores Depot",
        basePay = 1800,
        distanceBonus = 1200,
    },
    {
        id = "bayou",
        name = "Bayou Transport",
        description = "Third Ward ↔ Docks",
        pickup = vec3(90.0, -1425.0, 29.0),
        pickupLabel = "Third Ward Warehouse",
        dropoff = vec3(1300.0, -3100.0, 5.0),
        dropoffLabel = "Port of Houston Docks",
        basePay = 1600,
        distanceBonus = 900,
    },
}

Config.Trailers = {
    "trailersmall2",
    "trailerlarge",
    "tanker",
    "tr2",
    "tr3",
    "tr4",
}

Config.VehicleColors = {
    primary = { 255, 191, 87 },
    secondary = { 255, 251, 235 },
}
