-- Sinister Zoner — Texas neighborhood HUD zone names
-- Replaces GTA V zone labels with Texas neighborhoods

local zones = {
    -- ===== KILLEEN (Sandy Shores) =====
    { name = "Killeen",              center = vec3(1700, 3580, 35), radius = 150 },
    { name = "Loma Vista",           center = vec3(1175, 2642, 38), radius = 120 },
    { name = "Nolanville",           center = vec3(1698, 4794, 42), radius = 130 },
    { name = "Rancier Ave",          center = vec3(126, 3708, 40),  radius = 80  },
    { name = "Stillhouse Lake",      center = vec3(2012, 4682, 40), radius = 200 },
    { name = "Skylark Field",        center = vec3(1750, 3300, 41), radius = 150 },
    { name = "Ft. Cavazos Range",    center = vec3(2500, 3700, 35), radius = 250 },

    -- ===== FT. WORTH (Paleto Bay) =====
    { name = "Ft. Worth",            center = vec3(-440, 6000, 31), radius = 200 },
    { name = "Stockyards",           center = vec3(-510, 5380, 80), radius = 100 },
    { name = "Eagle Mountain Lake",  center = vec3(140, 6680, 10),  radius = 200 },
    { name = "Lake Worth",           center = vec3(-550, 6550, 10), radius = 150 },
    { name = "Tarrant Woods",        center = vec3(-300, 5600, 150),radius = 250 },

    -- ===== HOUSTON (Los Santos) =====
    { name = "Downtown Houston",     center = vec3(-540, -212, 38), radius = 300 },
    { name = "Third Ward",           center = vec3(90, -1425, 29),  radius = 200 },
    { name = "Acres Homes",          center = vec3(85, -1954, 21),  radius = 200 },
    { name = "Galveston",            center = vec3(-1300, -1400, 4),radius = 250 },
    { name = "The Heights",          center = vec3(1100, -700, 57), radius = 150 },
    { name = "Montrose",             center = vec3(370, -30, 100),  radius = 200 },
    { name = "River Oaks",           center = vec3(-900, 300, 70),  radius = 180 },
    { name = "Sunnyside",            center = vec3(150, -1300, 29), radius = 200 },
    { name = "Channelview",          center = vec3(900, -2300, 30), radius = 250 },
    { name = "Port of Houston",      center = vec3(1300, -3100, 5), radius = 300 },
    { name = "East End",             center = vec3(800, -1500, 30), radius = 200 },
    { name = "Pasadena",             center = vec3(1400, -1200, 30),radius = 180 },

    -- Fallbacks for areas not explicitly mapped
    { name = "Texas Hill Country",   center = vec3(-1500, 2000, 50), radius = 400 },
    { name = "Houston Metro",        center = vec3(0, 0, 50),        radius = 500 },
}

local currentZone = "Sinister State"
local lastZone = ""

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearest = nil
        local nearestDist = 9999

        for _, zone in ipairs(zones) do
            local dist = #(coords - zone.center)
            if dist < zone.radius and dist < nearestDist then
                nearestDist = dist
                nearest = zone.name
            end
        end

        if nearest then
            currentZone = nearest
        else
            currentZone = "Sinister State TX"
        end

        if currentZone ~= lastZone then
            lastZone = currentZone
            -- Pulse effect on zone change
            SendNUIMessage({ action = "updateZone", zone = currentZone })
        end

        Wait(1000)
    end
end)

-- HUD display thread
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            -- Vehicle HUD position (lower-left, above minimap)
            SetTextFont(4)
            SetTextScale(0.38, 0.38)
            SetTextColour(255, 255, 255, 200)
            SetTextEntry("STRING")
            AddTextComponentString(currentZone)
            SetTextOutline()
            DrawText(0.002, 0.932)
        else
            -- On foot HUD position (top-left, below radar)
            SetTextFont(4)
            SetTextScale(0.36, 0.36)
            SetTextColour(255, 255, 255, 200)
            SetTextEntry("STRING")
            AddTextComponentString(currentZone)
            SetTextOutline()
            DrawText(0.002, 0.020)
        end
    end
end)

print("^2[sinister_zoner] ^7" .. #zones .. " Texas neighborhood HUD zones loaded")

