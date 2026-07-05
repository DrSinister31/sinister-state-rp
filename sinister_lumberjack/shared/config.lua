Config = {}

Config.CompanyName = "Piney Woods Logging Co."
Config.BurntOrange = "#BF5700"
Config.DarkBg = "#0d0d14"

Config.SawmillLocation = vec3(1697.0, 4888.0, 41.0)
Config.SawmillHeading = 180.0
Config.SawmillLabel = "Killeen Lumber Mill"

Config.ForestLocation = vec3(-530.0, 5390.0, 70.0)
Config.ForestLabel = "Paleto Forest (Piney Woods)"

Config.VehicleModel = "bodhi2"
Config.TruckSpawnCoords = vec3(-520.0, 5370.0, 68.0)

Config.Upgrades = {
    speed = { name = "Speed", desc = "Swing faster", costs = { 250, 500, 1000, 2000 }, maxLevel = 5 },
    aim = { name = "Aim", desc = "Bigger target circle", costs = { 300, 600, 1200, 2400 }, maxLevel = 5 },
    yield = { name = "Yield", desc = "Earn more per log", costs = { 400, 800, 1600, 3200 }, maxLevel = 5 },
    load = { name = "Load", desc = "Carry more logs, move faster", costs = { 350, 700, 1400, 2800 }, maxLevel = 4 },
}

Config.Experience = {
    perLog = 10,
    perTree = 25,
    perDelivery = 50,
    teamMultiplier = 0.25,
    levels = {
        { name = "Rookie Woodcutter", min = 0, unlockRoutes = 1, unlockUpgrades = 1 },
        { name = "Apprentice Logger", min = 100, unlockRoutes = 2, unlockUpgrades = 1 },
        { name = "Journeyman", min = 300, unlockRoutes = 2, unlockUpgrades = 2 },
        { name = "Senior Lumberjack", min = 700, unlockRoutes = 3, unlockUpgrades = 3 },
        { name = "Master Logger", min = 1500, unlockRoutes = 3, unlockUpgrades = 4 },
        { name = "Piney Woods Legend", min = 3000, unlockRoutes = 4, unlockUpgrades = 5 },
    },
}

Config.Trees = {
    {
        id = "oak1", label = "Oak", pos = vec3(-530.0, 5395.0, 68.0),
        health = 100, fallDir = vec3(1.0, 0.5, 0.0), basePay = 45,
    },
    {
        id = "oak2", label = "Oak", pos = vec3(-510.0, 5410.0, 68.0),
        health = 100, fallDir = vec3(-0.5, -1.0, 0.0), basePay = 45,
    },
    {
        id = "oak3", label = "Oak", pos = vec3(-545.0, 5380.0, 67.0),
        health = 100, fallDir = vec3(0.0, -1.0, 0.0), basePay = 45,
    },
    {
        id = "pine1", label = "Pine", pos = vec3(-500.0, 5430.0, 70.0),
        health = 75, fallDir = vec3(1.0, 0.0, 0.0), basePay = 35,
    },
    {
        id = "pine2", label = "Pine", pos = vec3(-480.0, 5400.0, 69.0),
        health = 75, fallDir = vec3(-1.0, 0.5, 0.0), basePay = 35,
    },
    {
        id = "pine3", label = "Pine", pos = vec3(-560.0, 5420.0, 68.0),
        health = 75, fallDir = vec3(0.5, 1.0, 0.0), basePay = 35,
    },
    {
        id = "oak4", label = "Oak", pos = vec3(-540.0, 5350.0, 65.0),
        health = 120, fallDir = vec3(-1.0, 0.0, 0.0), basePay = 50,
    },
    {
        id = "pine4", label = "Pine", pos = vec3(-490.0, 5370.0, 66.0),
        health = 80, fallDir = vec3(0.0, 1.0, 0.0), basePay = 35,
    },
    {
        id = "oak5", label = "Oak", pos = vec3(-470.0, 5440.0, 71.0),
        health = 100, fallDir = vec3(1.0, -0.5, 0.0), basePay = 45,
    },
    {
        id = "pine5", label = "Pine", pos = vec3(-520.0, 5330.0, 64.0),
        health = 70, fallDir = vec3(-0.5, -0.5, 0.0), basePay = 30,
    },
}

Config.Minigame = {
    targetRadius = 0.12,
    targetSpeed = 1.2,
    hitWindow = 0.35,
    axeDamage = 20,
    shakeIntensity = 0.5,
}
