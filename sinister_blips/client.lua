-- Sinister State TX — Texas neighborhood-themed map blips
CreateThread(function()
    local blips = {
        -- ===== KILLEEN (Sandy Shores) =====
        { name = "Downtown Killeen",                  coords = vec3(1700.0, 3580.0, 35.5),  sprite = 60,  color = 52, scale = 0.8 },
        { name = "Loma Vista (Harmony)",               coords = vec3(1175.0, 2642.0, 37.8),  sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Nolanville (Grapeseed)",             coords = vec3(1697.5, 4793.5, 41.9),  sprite = 40,  color = 52, scale = 0.7 },
        { name = "Rancier Ave (Stab City)",            coords = vec3(126.0, 3708.0, 39.9),   sprite = 408, color = 1,  scale = 0.6 },
        { name = "Stillhouse Lake",                    coords = vec3(2012.0, 4682.0, 40.0),   sprite = 68,  color = 3,  scale = 0.7 },
        { name = "Skylark Field",                      coords = vec3(1750.0, 3300.0, 41.0),   sprite = 90,  color = 0,  scale = 0.7 },
        { name = "Fort Cavazos Range",                 coords = vec3(2500.0, 3700.0, 35.0),   sprite = 141, color = 26, scale = 0.8 },
        { name = "Killeen Park Ranger",                coords = vec3(1616.0, 3705.0, 34.5),   sprite = 60,  color = 52, scale = 0.7 },
        { name = "Nolanville Fire & Rescue",           coords = vec3(1693.5, 3580.5, 35.5),   sprite = 942, color = 1,  scale = 0.8 },
        { name = "Nolanville Rural Clinic",            coords = vec3(1697.5, 4793.5, 41.9),   sprite = 61,  color = 1,  scale = 0.8 },

        -- ===== FT. WORTH (Paleto Bay) =====
        { name = "Ft. Worth Downtown",                 coords = vec3(-440.0, 6000.0, 31.0),    sprite = 60,  color = 52, scale = 0.9 },
        { name = "Ft. Worth Sheriff Office",           coords = vec3(-440.0, 6000.0, 31.0),    sprite = 60,  color = 52, scale = 0.8 },
        { name = "Stockyards (Sawmill)",               coords = vec3(-510.0, 5380.0, 80.0),    sprite = 484, color = 0,  scale = 0.7 },
        { name = "Eagle Mountain Lake (Procopio)",     coords = vec3(140.0, 6680.0, 10.0),     sprite = 68,  color = 3,  scale = 0.7 },
        { name = "Lake Worth (Catfish View)",          coords = vec3(-550.0, 6550.0, 10.0),    sprite = 68,  color = 3,  scale = 0.6 },
        { name = "Tarrant Woods",                      coords = vec3(-300.0, 5600.0, 150.0),   sprite = 71,  color = 2,  scale = 0.7 },
        { name = "Ft. Worth Regional Airport",         coords = vec3(1750.0, 3300.0, 41.0),    sprite = 90,  color = 0,  scale = 0.8 },

        -- ===== HOUSTON (Los Santos) =====
        { name = "Travis County Courthouse",           coords = vec3(243.5, -1086.0, 29.3),    sprite = 60,  color = 0,  scale = 0.9 },
        { name = "Houston PD HQ",                      coords = vec3(440.0, -980.0, 30.3),     sprite = 60,  color = 3,  scale = 0.9 },
        { name = "FIB Houston Field Office",           coords = vec3(150.0, -740.0, 42.0),     sprite = 60,  color = 38, scale = 0.7 },
        { name = "Houston Medical Center",             coords = vec3(300.0, -1450.0, 29.0),    sprite = 61,  color = 25, scale = 0.9 },
        { name = "City Hall",                          coords = vec3(-540.58, -212.02, 37.65), sprite = 419, color = 0,  scale = 0.9 },
        { name = "Third Ward (Strawberry)",            coords = vec3(90.0, -1425.0, 29.0),     sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Acres Homes (Grove Street)",         coords = vec3(85.0, -1954.0, 21.0),     sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Galveston Beach (Vespucci)",         coords = vec3(-1300.0, -1400.0, 4.0),   sprite = 68,  color = 3,  scale = 0.8 },
        { name = "The Heights (Mirror Park)",          coords = vec3(1100.0, -700.0, 57.0),    sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Montrose (Vinewood)",                coords = vec3(370.0, -30.0, 100.0),     sprite = 40,  color = 0,  scale = 0.7 },
        { name = "River Oaks (Rockford Hills)",        coords = vec3(-900.0, 300.0, 70.0),     sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Sunnyside (Davis)",                  coords = vec3(150.0, -1300.0, 29.0),    sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Channelview (Cypress Flats)",        coords = vec3(900.0, -2300.0, 30.0),    sprite = 40,  color = 0,  scale = 0.7 },
        { name = "Port of Houston",                    coords = vec3(1300.0, -3100.0, 5.0),    sprite = 67,  color = 3,  scale = 0.8 },
        { name = "Houston International Airport",      coords = vec3(-1040.0, -2750.0, 13.0),  sprite = 90,  color = 0,  scale = 0.9 },

        -- ===== STATEWIDE =====
        { name = "Texas DPS Headquarters",             coords = vec3(2400.0, 3100.0, 48.0),    sprite = 60,  color = 0,  scale = 0.8 },
{ name = "Lackland AFB",                      coords = vec3(-2200.0, 3250.0, 32.0),   sprite = 137, color = 26, scale = 0.9 },
        { name = "Texas Fire & Rescue HQ",             coords = vec3(210.0, -1650.0, 29.0),    sprite = 942, color = 1,  scale = 0.8 },
        { name = "ATC Tower (Houston Intl)",           coords = vec3(-1050.0, -2800.0, 13.0),  sprite = 307, color = 0,  scale = 0.8 },

        -- ===== BUSINESSES =====
        { name = "Pipe Down Cigar Co.",                coords = vec3(440.0, -980.0, 30.3),     sprite = 93,  color = 0,  scale = 0.6 },
        { name = "Pipe Down — The Heights",            coords = vec3(1100.0, -700.0, 57.0),     sprite = 93,  color = 0,  scale = 0.6 },
        { name = "Globe Oil Fuel Depot",               coords = vec3(640.66, 276.22, 103.15),  sprite = 361, color = 0,  scale = 0.7 },
        { name = "Lone Star Postal & Freight",         coords = vec3(-310.53, -1288.27, 31.24),sprite = 525, color = 0,  scale = 0.7 },
        { name = "Mosley's Auto & Chop Shop",          coords = vec3(540.0, -200.0, 54.0),     sprite = 402, color = 0,  scale = 0.7 },
        { name = "The Chemical Co.",                   coords = vec3(980.0, -2300.0, 30.5),     sprite = 499, color = 0,  scale = 0.6 },
        { name = "Lone Star Realty & Trust",           coords = vec3(-790.0, -720.0, 28.2),    sprite = 350, color = 0,  scale = 0.7 },
        { name = "Bert's Truck & Diesel Rental",       coords = vec3(-50.0, -1100.0, 26.5),    sprite = 357, color = 0,  scale = 0.7 },
        { name = "Yellow Rose Ranch Estate",           coords = vec3(-2990.0, 4520.0, 5.2),    sprite = 948, color = 0,  scale = 0.6 },
        { name = "Pink Cage Motel (Spawn)",            coords = vec3(325.0, -210.0, 54.0),     sprite = 524, color = 46, scale = 0.7 },
    }

    for _, b in ipairs(blips) do
        local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, b.scale)
        SetBlipColour(blip, b.color)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(b.name)
        EndTextCommandSetBlipName(blip)
    end

    print("^2[sinister_blips] ^7" .. #blips .. " Texas neighborhood blips loaded")
end)
