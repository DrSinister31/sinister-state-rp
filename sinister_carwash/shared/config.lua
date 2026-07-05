Config = {}

Config.BusinessName = "Texas Suds Car Wash"
Config.BossMenuTitle = "Texas Suds Management"
Config.BurntOrange = "#BF5700"
Config.DarkBg = "#0d0d14"

Config.MaxNPCS = 3

Config.Tiers = {
    {
        name = "Basic Rinse",
        percentage = 0.40,
        repair = false,
        price = 250,
        npcTime = 15000,
        supplyCost = 5,
    },
    {
        name = "Texas Two-Step",
        percentage = 0.75,
        repair = true,
        price = 500,
        npcTime = 25000,
        supplyCost = 10,
    },
    {
        name = "Lone Star Supreme",
        percentage = 1.0,
        repair = true,
        price = 800,
        npcTime = 35000,
        supplyCost = 15,
    },
}

Config.NPCNames = {
    male = { "Bubba", "Earl", "Cletus" },
    female = { "Darlene" },
}

Config.NPCPedModels = {
    male = "a_m_y_business_01",
    female = "a_f_y_business_01",
}

Config.SupplyPack = {
    price = 200,
    units = 50,
}

Config.NPCSalary = 75

Config.Locations = {
    {
        id = "legion",
        label = "Legion Square (Houston)",
        coords = vec3(160.5, -986.0, 29.5),
        washCoords = vec3(171.0, -987.0, 29.5),
        heading = 340.0,
        blip = true,
    },
    {
        id = "paleto",
        label = "Paleto (Ft. Worth)",
        coords = vec3(83.0, 6317.0, 31.2),
        washCoords = vec3(90.0, 6323.0, 31.2),
        heading = 340.0,
        blip = true,
    },
    {
        id = "sandy",
        label = "Sandy Shores (Killeen)",
        coords = vec3(1978.0, 3750.0, 32.0),
        washCoords = vec3(1985.0, 3755.0, 32.0),
        heading = 340.0,
        blip = true,
    },
}

Config.PressureWasher = {
    model = "prop_cs_power_cord",
    zones = {
        { name = "Hood", offset = vec3(0.0, 2.5, 0.9), size = vec3(1.5, 0.3, 0.6) },
        { name = "Left Side", offset = vec3(-1.2, 0.0, 0.5), size = vec3(0.3, 3.0, 0.8) },
        { name = "Right Side", offset = vec3(1.2, 0.0, 0.5), size = vec3(0.3, 3.0, 0.8) },
        { name = "Roof", offset = vec3(0.0, 0.0, 1.4), size = vec3(1.5, 2.0, 0.3) },
        { name = "Trunk", offset = vec3(0.0, -2.5, 0.9), size = vec3(1.5, 0.3, 0.6) },
    },
    minigameKeys = { "E", "Q", "R", "F" },
    durationPerZone = 3000,
}
