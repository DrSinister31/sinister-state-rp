Config = {
    Debug = false,

    Fuel = "cdn-fuel", -- Fuel script.
    Notify = "qb", -- Notify script

    Anim = { -- Animations duration in seconds
        Pickup = 1.5,
        Dropoff = 1.5,
        Loading = 3.0
    },

    Job = { -- Job information
        Pay         = { min = 580, max = 850 }, -- Pay per drop
        Drops       = { min = 8,  max = 15 }, -- Amount of drops per job
        Damage      = { enabled = true, chance = 50, amount = 5.0 }, -- Whether damage is enabled, chance of breaking a box and the amount of damage required
        Bonus       = { enabled = true, percentage = 10 }, -- Bonus upon completion and percentage, damage must be enabled.
        Cooldown    = { enabled = true, min = 10, max = 15 }, -- Whether you want jobs to automatically repopulate or have a cooldown before they are added back. (In minutes)
    },

    Location = { -- Job location
        blip = {
            show = true, -- Enable or Disable blip
            coords = vector3(-717.82, -2470.02, 13.95), -- Location of the blip.
            label = "Alpha Mail Couriers", -- Blip label
            sprite = 616, -- Blip sprite (https://docs.fivem.net/docs/game-references/blips/)
            color = 29, -- Color of blip
            scale = 0.7, -- Size of the blip
            display = 6 -- How you want the blip displayed (https://docs.fivem.net/natives/?_0x9029B2F3DA924928)
        },
        model  = "s_m_m_gardener_01", -- Ped model
        coords = vector4(-717.82, -2470.02, 13.95, 331.43), -- Location of ped and job menu
    },

    Deposit = true, -- If you want to use a deposit for the rentals.
    Return = {coords = vector4(-691.21, -2471.66, 13.82, 58.46), x = 25, y = 30}, -- Vehicle return location
    Vehicles = { -- Vehicles used for the job
        { 
            model = "nspeedo", -- Vehicle spawn code
            title = "Vapid Speedo", -- Vehicle title
            desc = "A durable and reliable van, perfect for transporting goods across the city.", -- Vehicle description
            spawns = { -- Spawn locations
                vector4(-694.81, -2455.01, 13.64, 148.94),
                vector4(-684.77, -2460.57, 13.64, 150.57)
            },
            capacity = 10, -- Vehicle package capacity
            deposit = 1000 -- Deposit for renting vehicle
        },
    },

    Length = math.random(10, 20), -- Amount of jobs generated per restart.
    Cooldown = 2, -- Cooldown if job is cancelled to prevent spam.  
    Jobs = { -- Jobs for the job list.
        [1] = {
            title = "PostOp", -- Job title
            livery = 4, -- Livery index for vehicles (Starts at 0)
            pickups = { -- Pickup locations
                [1] = vector4(-409.48, -2800.86, 6.0, 315.63),
                [2] = vector4(-414.76, -2795.28, 6.0, 316.32),
                [3] = vector4(-411.77, -2797.74, 6.0, 312.65),
            },
            dropoffs = { -- Dropoff locations
                [1] = vector4(868.97, -1639.88, 30.33, 270.29),
                [2] = vector4(-1040.41, -1475.23, 5.57, 213.88),
                [3] = vector4(-1268.91, -877.8, 11.93, 39.36),
                [4] = vector4(-1534.61, -422.26, 35.59, 52.71),
                [5] = vector4(81.52, 274.7, 110.21, 340.86),
                [6] = vector4(-47.15, -584.73, 37.95, 252.26),
                [7] = vector4(84.84, -1404.88, 29.4, 121.12),
                [8] = vector4(192.32, -1883.26, 25.05, 334.23),
                [9] = vector4(965.31, -542.13, 59.52, 32.1),
                [10] = vector4(772.59, -152.15, 74.42, 330.45),
                [11] = vector4(-1062.59, 437.73, 73.86, 280.08),
                [12] = vector4(-654.82, -931.72, 22.62, 96.36),
            }
        },
		[2] = {
            title = "Atomic",
            livery = 1,
            pickups = {
                [1] = vector4(478.08, -1893.14, 26.09, 293.76),
                [2] = vector4(476.18, -1889.36, 26.09, 294.92),
            },
            dropoffs = {
                [1] = vector4(-327.04, -1345.8, 31.63, 273.06),
                [2] = vector4(-229.67, -1377.31, 31.26, 212.89),
                [3] = vector4(-80.98, -1326.09, 29.26, 94.89),
                [4] = vector4(163.87, -1675.07, 29.77, 142.34),
                [5] = vector4(869.2, -1055.99, 29.44, 85.02),
                [6] = vector4(-1433.84, -447.8, 35.8, 30.82),
                [7] = vector4(1136.75, -775.47, 57.61, 1.9),
                [8] = vector4(2747.72, 3464.08, 55.73, 248.1),
                [9] = vector4(1189.39, 2650.78, 37.84, 136.21),
                [10] = vector4(-2208.66, 4245.96, 47.6, 41.15),
                [11] = vector4(-356.36, -125.14, 38.7, 70.41),
            }
        },
		[3] = {
            title = "GoPostal",
            livery = 3,
            pickups = {
                [1] = vector4(60.92, 124.89, 79.23, 160.58),
                [2] = vector4(64.14, 123.58, 79.16, 157.17),
                [3] = vector4(67.82, 122.38, 79.14, 166.59),
            },
            dropoffs = {
				[1] = vector4(215.74, 620.59, 187.61, 75.61),
				[2] = vector4(8.53, 540.16, 176.03, 330.83),
				[3] = vector4(-173.99, 970.09, 237.3, 267.83),
                [4] = vector4(-566.22, 761.55, 185.43, 49.54),
                [5] = vector4(-692.71, 984.7, 238.35, 14.59),
                [6] = vector4(-1065.12, 726.98, 165.47, 26.67),
                [7] = vector4(-1294.35, 454.81, 97.49, 3.52),
                [8] = vector4(-967.86, 509.51, 81.67, 145.67),
                [9] = vector4(-1026.07, 360.47, 71.36, 250.0),
                [10] = vector4(-1629.67, 36.66, 62.94, 333.39),
                [11] = vector4(-1896.61, 134.23, 81.79, 304.53),
                [12] = vector4(-1940.53, 387.07, 96.51, 184.06),
            }
        },
		[4] = {
            title = "Alpha Mail Couriers",
            livery = 6,
            pickups = {
                [1] = vector4(-738.11, -2471.58, 13.94, 63.72),
                [2] = vector4(-739.72, -2474.32, 13.94, 61.1),
                [3] = vector4(-741.75, -2478.02, 13.94, 62.47),
            },
            dropoffs = {
                [1] = vector4(-1031.88, -1620.44, 5.01, 215.36),
				[2] = vector4(-1372.53, -900.87, 12.47, 37.75),
				[3] = vector4(-1090.72, -926.09, 3.14, 28.97),
                [4] = vector4(-903.36, -1005.51, 2.15, 26.57),
                [5] = vector4(-1022.78, -896.62, 5.42, 35.74),
                [6] = vector4(1295.49, -1739.56, 54.27, 292.52),
                [7] = vector4(1437.42, -1492.0, 63.62, 162.78),
                [8] = vector4(1245.27, -1626.67, 53.28, 30.61),
                [9] = vector4(1328.58, -536.03, 72.44, 68.07),
                [10] = vector4(1367.3, -606.35, 74.71, 2.48),
                [11] = vector4(850.43, -532.66, 57.93, 265.0),
                [12] = vector4(997.11, -729.39, 57.82, 309.3),
            }
        },
    },
}