-- Sinister State TX — Texas-themed map blips for all MLOs and key locations
CreateThread(function()
    local blips = {
        -- ===== GOVERNMENT / EMERGENCY =====
        { name = "Travis County Courthouse",       coords = vec3(243.5, -1086.0, 29.3),  sprite = 60,   color = 0,  scale = 0.9 },
        { name = "Sandy Shores Fire & Rescue",     coords = vec3(1693.5, 3580.5, 35.5), sprite = 942,  color = 1,  scale = 0.8 },
        { name = "Fort Zancudo Military Police",   coords = vec3(-2350.0, 3250.0, 32.8),sprite = 60,   color = 26, scale = 0.8 },
        { name = "Sandy Shores Park Ranger",       coords = vec3(1616.0, 3705.0, 34.5),  sprite = 60,   color = 52, scale = 0.7 },
        { name = "Grapeseed Rural Health Clinic",  coords = vec3(1697.5, 4793.5, 41.9),  sprite = 61,   color = 1,  scale = 0.8 },

        -- ===== MEDICAL =====
        { name = "Texas Health Presbyterian Hospital", coords = vec3(360.0, -1420.0, 29.3), sprite = 61, color = 1,  scale = 1.0 },
        { name = "Pillbox Hill Medical",               coords = vec3(340.0, -1395.0, 32.5), sprite = 61, color = 25, scale = 0.9 },

        -- ===== COMMERCIAL / BUSINESSES =====
        { name = "Wash-a-Teria Laundromat",       coords = vec3(896.93, -1032.22, 34.97),sprite = 52,   color = 0,  scale = 0.7 },
        { name = "Armadillo Motor Inn",            coords = vec3(313.38, -225.20, 54.21),  sprite = 524,  color = 0,  scale = 0.7 },
        { name = "Pipe Down Cigar Co.",            coords = vec3(440.0, -980.0, 30.3),     sprite = 93,   color = 0,  scale = 0.6 },
        { name = "Pipe Down — Mirror Park",       coords = vec3(1100.0, -700.0, 57.0),     sprite = 93,   color = 0,  scale = 0.6 },
        { name = "Globe Oil Fuel Depot",           coords = vec3(640.66, 276.22, 103.15),  sprite = 361,  color = 0,  scale = 0.7 },
        { name = "Lone Star Postal & Freight",    coords = vec3(-310.53, -1288.27, 31.24), sprite = 525,  color = 0,  scale = 0.7 },
        { name = "Silicon Prairie Hackerspace",    coords = vec3(450.0, -1500.0, 29.0),     sprite = 304,  color = 0,  scale = 0.6 },
        { name = "Lone Star Realty & Trust",      coords = vec3(-790.0, -720.0, 28.2),     sprite = 350,  color = 0,  scale = 0.7 },
        { name = "Bert's Truck & Diesel Rental",  coords = vec3(-50.0, -1100.0, 26.5),     sprite = 357,  color = 0,  scale = 0.7 },
        { name = "Yellow Rose Ranch Estate",      coords = vec3(-2990.0, 4520.0, 5.2),     sprite = 948,  color = 0,  scale = 0.6 },

        -- ===== CRIMINAL / UNDERWORLD =====
        { name = "Mosley's Auto & Chop Shop",     coords = vec3(540.0, -200.0, 54.0),      sprite = 402,  color = 0,  scale = 0.7 },
        { name = "The Chemical Co.",               coords = vec3(980.0, -2300.0, 30.5),     sprite = 499,  color = 0,  scale = 0.6 },
        { name = "The Spot (Weed Shop)",           coords = vec3(150.0, -1300.0, 29.0),     sprite = 140,  color = 2,  scale = 0.5 },

        -- ===== JOB LOCATIONS =====
        { name = "City Hall — Job Center",          coords = vec3(-540.58, -212.02, 37.65),  sprite = 419,  color = 0,  scale = 0.9 },
        { name = "Houston PD HQ",                   coords = vec3(440.0, -980.0, 30.3),      sprite = 60,   color = 3,  scale = 0.9 },
        { name = "Ft. Worth Sheriff Office",        coords = vec3(-440.0, 6000.0, 31.0),     sprite = 60,   color = 52, scale = 0.8 },
        { name = "Texas DPS Headquarters",          coords = vec3(2400.0, 3100.0, 48.0),     sprite = 60,   color = 0,  scale = 0.8 },
        { name = "FIB Houston Field Office",        coords = vec3(150.0, -740.0, 42.0),      sprite = 60,   color = 38, scale = 0.7 },
        { name = "Fort Zancudo — Texas National Guard", coords = vec3(-2200.0, 3250.0, 32.0), sprite = 137, color = 26, scale = 0.9 },
        { name = "Houston International ATC Tower", coords = vec3(-1050.0, -2800.0, 13.0),   sprite = 307,  color = 0,  scale = 0.8 },
        { name = "Texas Fire & Rescue HQ",          coords = vec3(210.0, -1650.0, 29.0),     sprite = 942,  color = 1,  scale = 0.8 },
        { name = "Houston Medical Center",          coords = vec3(300.0, -1450.0, 29.0),     sprite = 61,   color = 25, scale = 0.9 },

        -- ===== TEXAS LANDMARKS =====
        { name = "Pink Cage Motel (Spawn)",        coords = vec3(325.0, -210.0, 54.0),      sprite = 524,  color = 46, scale = 0.7 },
        { name = "Houston International Airport",   coords = vec3(-1040.0, -2750.0, 13.0),   sprite = 90,   color = 0,  scale = 0.9 },
        { name = "Fort Worth Regional Airport",     coords = vec3(1750.0, 3300.0, 41.0),     sprite = 90,   color = 0,  scale = 0.8 },
        { name = "Killeen Desert Airstrip",         coords = vec3(2100.0, 4800.0, 41.0),     sprite = 90,   color = 0,  scale = 0.7 },
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

    print("^2[sinister_blips] ^7" .. #blips .. " Texas-themed blips loaded")
end)
