Config = {}

Config.CompanyName = "Texas Crude Co."
Config.BossMenuTitle = "Texas Crude Operations"
Config.BurntOrange = "#BF5700"
Config.DarkBg = "#0d0d14"

Config.RigLocation = vec3(2577.0, 3953.0, 62.0)
Config.RigHeading = 0.0

Config.FieldZones = {
    { coords = vec3(2577.0, 3953.0, 20.0), label = "Well #1 — East Field", action = "pump" },
    { coords = vec3(2620.0, 3980.0, 20.0), label = "Well #2 — North Slope", action = "pump" },
    { coords = vec3(2530.0, 3920.0, 20.0), label = "Well #3 — West Ridge", action = "pump" },
    { coords = vec3(2595.0, 3900.0, 20.0), label = "Well #4 — South Basin", action = "pump" },
    { coords = vec3(2650.0, 3950.0, 20.0), label = "Refinery Station A", action = "refine" },
    { coords = vec3(2500.0, 3980.0, 20.0), label = "Storage Tank Farm", action = "store" },
}

Config.Grades = {
    { name = "Roughneck", payment = 350, cyclesToPromote = 5 },
    { name = "Drill Operator", payment = 500, cyclesToPromote = 10 },
    { name = "Field Supervisor", payment = 650, cyclesToPromote = 20 },
    { name = "Rig Manager", payment = 800, cyclesToPromote = 99 },
}

Config.Equipment = {
    hardhat = "prop_hard_hat_01",
    wrench = "prop_wrench_01",
}

Config.PayPerCycle = { 500, 600, 700, 800 }

Config.CycleDuration = 12000
Config.WorkerAnim = { dict = "amb@world_human_const_drill_01", clip = "base" }
Config.WrenchAnim = { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", clip = "machinic_loop_mechandplayer" }
