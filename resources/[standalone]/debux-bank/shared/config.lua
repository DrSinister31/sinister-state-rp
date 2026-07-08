Config = {}

------------------------------------------------------------------------------------

Config.Mysql = "mysql-async" -- mysql-async , ghmattimysql, oxmysql
Config.Framework = "auto" -- Determines which framework to use: auto, esx, or qb
Config.Distance = 3
Config.Atms = { 'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm' }
Config.Bank = {
    vector3(150.266, -1040.203, 29.374),
    vector3(314.187, -278.621, 54.170),
    vector3(-351.534, -49.529, 49.042),
    vector3(-1212.980, -330.841, 37.787),
    vector3(-2962.582, 482.627, 15.703),
    vector3(1175.0643310547, 2706.6435546875, 38.094036102295),
    vector3(241.727, 220.706, 106.286),
    vector3(-112.202, 6469.295, 31.626)
}

Config.Blip = {
    name = 'Bank',
    sprite = 108,
    color = 2,
    scale = 0.55
}

Config.Langs = {
    ["OpenBank"] = "[E] - Open Bank",
    ["OpenAtm"] = "[E] - Open Atm",
    ["NoMoney"] = "Enough Money",
    ["Succes"] = "Successfully executed",
    ["Transfer"] = "Money has entered your bank account",
    ["Transferme"] = "You can't send money to yourself",
}
