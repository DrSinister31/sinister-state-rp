---Job names must be lower case (top level table key)
---@type table<string, Job>
return {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Freelancer',
                payment = 10
            },
        },
    },
    ['police'] = {
        label = 'Houston PD',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Officer',
                payment = 75
            },
            [2] = {
                name = 'Sergeant',
                payment = 100
            },
            [3] = {
                name = 'Lieutenant',
                payment = 125
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['bcso'] = {
        label = 'Ft. Worth Sheriff',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Officer',
                payment = 75
            },
            [2] = {
                name = 'Sergeant',
                payment = 100
            },
            [3] = {
                name = 'Lieutenant',
                payment = 125
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['sasp'] = {
        label = 'Texas DPS',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Officer',
                payment = 75
            },
            [2] = {
                name = 'Sergeant',
                payment = 100
            },
            [3] = {
                name = 'Lieutenant',
                payment = 125
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Paramedic',
                payment = 75
            },
            [2] = {
                name = 'Doctor',
                payment = 100
            },
            [3] = {
                name = 'Surgeon',
                payment = 125
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        type = 'realestate',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'House Sales',
                payment = 75
            },
            [2] = {
                name = 'Business Sales',
                payment = 100
            },
            [3] = {
                name = 'Broker',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['taxi'] = {
        label = 'Taxi',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Driver',
                payment = 75
            },
            [2] = {
                name = 'Event Driver',
                payment = 100
            },
            [3] = {
                name = 'Sales',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['bus'] = {
        label = 'Bus',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['cardealer'] = {
        label = 'Vehicle Dealer',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 75
            },
            [2] = {
                name = 'Business Sales',
                payment = 100
            },
            [3] = {
                name = 'Finance',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Novice',
                payment = 75
            },
            [2] = {
                name = 'Experienced',
                payment = 100
            },
            [3] = {
                name = 'Advanced',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },



    ['trucker'] = {
        label = 'Trucker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['tow'] = {
        label = 'Towing',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['garbage'] = {
        label = 'Garbage',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Collector',
                payment = 50
            },
        },
    },
    ['vineyard'] = {
        label = 'Vineyard',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Picker',
                payment = 50
            },
        },
    },
    ['hotdog'] = {
        label = 'Hotdog',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Sales',
                payment = 50
            },
        },
    },

    



    -- ===== SINISTER STATE DOJ / LEGAL JOBS =====
    ['judge'] = {
        label = 'Texas District Judge',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Magistrate',
                payment = 150
            },
            [1] = {
                name = 'District Judge',
                payment = 250
            },
            [2] = {
                name = 'Superior Judge',
                payment = 350
            },
            [3] = {
                name = 'Appellate Judge',
                payment = 450
            },
            [4] = {
                name = 'Chief Justice',
                isboss = true,
                payment = 600
            },
        },
    },
    ['prosecutor'] = {
        label = 'Travis County Prosecutor',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Legal Intern',
                payment = 75
            },
            [1] = {
                name = 'Assistant DA',
                payment = 150
            },
            [2] = {
                name = 'Deputy DA',
                payment = 225
            },
            [3] = {
                name = 'District Attorney',
                payment = 350
            },
            [4] = {
                name = 'Chief Prosecutor',
                isboss = true,
                payment = 500
            },
        },
    },
    ['publicdefender'] = {
        label = 'Travis County Public Defender',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Legal Intern',
                payment = 75
            },
            [1] = {
                name = 'Junior Defender',
                payment = 125
            },
            [2] = {
                name = 'Public Defender',
                payment = 200
            },
            [3] = {
                name = 'Sr. Public Defender',
                payment = 300
            },
            [4] = {
                name = 'Chief Defender',
                isboss = true,
                payment = 450
            },
        },
    },
    ['courtclerk'] = {
        label = 'Travis County Court Clerk',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Clerk Assistant',
                payment = 60
            },
            [1] = {
                name = 'Court Clerk',
                payment = 100
            },
            [2] = {
                name = 'Sr. Court Clerk',
                payment = 150
            },
            [3] = {
                name = 'Chief Clerk',
                isboss = true,
                payment = 200
            },
        },
    },
    ['bailiff'] = {
        label = 'Travis County Bailiff',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Deputy Bailiff',
                payment = 80
            },
            [1] = {
                name = 'Bailiff',
                payment = 120
            },
            [2] = {
                name = 'Sr. Bailiff',
                payment = 180
            },
            [3] = {
                name = 'Chief Bailiff',
                isboss = true,
                payment = 250
            },
        },
    },
    ['paralegal'] = {
        label = 'Texas Paralegal',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Legal Assistant',
                payment = 50
            },
            [1] = {
                name = 'Paralegal',
                payment = 80
            },
            [2] = {
                name = 'Sr. Paralegal',
                payment = 120
            },
        },
    },
    ['lawyer'] = {
        label = 'Texas Attorney',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Junior Associate',
                payment = 75
            },
            [1] = {
                name = 'Associate',
                payment = 125
            },
            [2] = {
                name = 'Senior Associate',
                payment = 200
            },
            [3] = {
                name = 'Partner',
                payment = 350
            },
            [4] = {
                name = 'Managing Partner',
                isboss = true,
                payment = 500
            },
        },
    },
    ['reporter'] = {
        label = 'Texas Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Intern',
                payment = 40
            },
            [1] = {
                name = 'Journalist',
                payment = 75
            },
            [2] = {
                name = 'Staff Reporter',
                payment = 125
            },
            [3] = {
                name = 'Senior Reporter',
                payment = 200
            },
            [4] = {
                name = 'Editor-in-Chief',
                isboss = true,
                payment = 300
            },
        },
    },


-- ===== SINISTER STATE CUSTOM JOBS =====
    ['fib'] = {
        label = 'Federal Investigation Bureau',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Recruit', payment = 150 },
            [1] = { name = 'Agent', payment = 200 },
            [2] = { name = 'Special Agent', payment = 250 },
            [3] = { name = 'Senior Agent', payment = 300 },
            [4] = { name = 'Asst. Director', payment = 400 },
            [5] = { name = 'Director', payment = 500, isboss = true },
        },
    },
    ['military'] = {
        label = 'Texas National Guard',
        type = 'leo',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Private', payment = 100 },
            [1] = { name = 'Specialist', payment = 150 },
            [2] = { name = 'Sergeant', payment = 200 },
            [3] = { name = 'Lieutenant', payment = 250 },
            [4] = { name = 'Captain', payment = 300 },
            [5] = { name = 'Major', payment = 400 },
            [6] = { name = 'Colonel', payment = 500, isboss = true },
        },
    },
    ['atc'] = {
        label = 'Air Traffic Control',
        type = 'none',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Trainee', payment = 100 },
            [1] = { name = 'Controller', payment = 200 },
            [2] = { name = 'Sr. Controller', payment = 300 },
            [3] = { name = 'Tower Chief', payment = 400, isboss = true },
        },
    },
    ['fire'] = {
        label = 'Texas Fire & Rescue',
        type = 'ems',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Probationary', payment = 100 },
            [1] = { name = 'Firefighter', payment = 200 },
            [2] = { name = 'Engineer', payment = 250 },
            [3] = { name = 'Lieutenant', payment = 300 },
            [4] = { name = 'Captain', payment = 400 },
            [5] = { name = 'Battalion Chief', payment = 500, isboss = true },
        },
    },

}