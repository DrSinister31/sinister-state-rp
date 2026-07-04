-- Sinister Zoner — Texas county + neighborhood HUD
-- Displays: COUNTY NAME on top line, neighborhood below

local zones = {
    -- ===== BELL COUNTY (Killeen / Sandy Shores) =====
    { name = "Downtown Killeen",    county = "Bell County",       center = vec3(1700, 3580, 35), radius = 150 },
    { name = "Loma Vista",          county = "Bell County",       center = vec3(1175, 2642, 38), radius = 120 },
    { name = "Nolanville",          county = "Bell County",       center = vec3(1698, 4794, 42), radius = 130 },
    { name = "Rancier Ave",         county = "Bell County",       center = vec3(126, 3708, 40),  radius = 80  },
    { name = "Stillhouse Lake",     county = "Bell County",       center = vec3(2012, 4682, 40), radius = 200 },
    { name = "Skylark Field",       county = "Bell County",       center = vec3(1750, 3300, 41), radius = 150 },
    { name = "Lackland AFB",        county = "Bell County",       center = vec3(2500, 3700, 25), radius = 300 },

    -- ===== TARRANT COUNTY (Ft. Worth / Paleto Bay) =====
    { name = "Ft. Worth",           county = "Tarrant County",    center = vec3(-440, 6000, 31), radius = 200 },
    { name = "Stockyards",          county = "Tarrant County",    center = vec3(-510, 5380, 80), radius = 100 },
    { name = "Eagle Mountain Lake", county = "Tarrant County",    center = vec3(140, 6680, 10),  radius = 200 },
    { name = "Lake Worth",          county = "Tarrant County",    center = vec3(-550, 6550, 10), radius = 150 },
    { name = "Tarrant Woods",       county = "Tarrant County",    center = vec3(-300, 5600, 150),radius = 250 },

    -- ===== HARRIS COUNTY (Houston / Los Santos) =====
    { name = "Downtown Houston",    county = "Harris County",     center = vec3(-540, -212, 38), radius = 300 },
    { name = "Third Ward",          county = "Harris County",     center = vec3(90, -1425, 29),  radius = 200 },
    { name = "Acres Homes",         county = "Harris County",     center = vec3(85, -1954, 21),  radius = 200 },
    { name = "The Heights",         county = "Harris County",     center = vec3(1100, -700, 57), radius = 150 },
    { name = "Montrose",            county = "Harris County",     center = vec3(370, -30, 100),  radius = 200 },
    { name = "River Oaks",          county = "Harris County",     center = vec3(-900, 300, 70),  radius = 180 },
    { name = "Sunnyside",           county = "Harris County",     center = vec3(150, -1300, 29), radius = 200 },
    { name = "East End",            county = "Harris County",     center = vec3(800, -1500, 30), radius = 200 },
    { name = "Pasadena",            county = "Harris County",     center = vec3(1400, -1200, 30),radius = 180 },
    { name = "Port of Houston",     county = "Harris County",     center = vec3(1300, -3100, 5), radius = 300 },
    { name = "Channelview",         county = "Harris County",     center = vec3(900, -2300, 30), radius = 250 },

    -- ===== GALVESTON COUNTY =====
    { name = "Galveston",           county = "Galveston County",  center = vec3(-1300, -1400, 4),radius = 300 },

    -- Fallbacks
    { name = "Texas Hill Country",  county = "Central Texas",     center = vec3(-1500, 2000, 50),radius = 500 },
    { name = "Harris County Metro", county = "Harris County",     center = vec3(0, 0, 50),        radius = 600 },
}

local currentZone = "Sinister State"
local currentCounty = "Texas"
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
                nearest = zone
            end
        end

        if nearest then
            currentZone = nearest.name
            currentCounty = nearest.county
        else
            currentZone = "Sinister State"
            currentCounty = "Texas"
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
            -- Vehicle HUD: county on top, zone below (above minimap, lower-left)
            SetTextFont(4)
            SetTextScale(0.42, 0.42)
            SetTextColour(191, 87, 0, 220)
            SetTextEntry("STRING")
            AddTextComponentString(currentCounty)
            SetTextOutline()
            DrawText(0.002, 0.935)

            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 180)
            SetTextEntry("STRING")
            AddTextComponentString(currentZone)
            SetTextOutline()
            DrawText(0.002, 0.953)
        else
            -- On foot HUD: county top-left, zone below
            SetTextFont(4)
            SetTextScale(0.40, 0.40)
            SetTextColour(191, 87, 0, 220)
            SetTextEntry("STRING")
            AddTextComponentString(currentCounty)
            SetTextOutline()
            DrawText(0.002, 0.015)

            SetTextFont(4)
            SetTextScale(0.33, 0.33)
            SetTextColour(255, 255, 255, 180)
            SetTextEntry("STRING")
            AddTextComponentString(currentZone)
            SetTextOutline()
            DrawText(0.002, 0.032)
        end
    end
end)

print("^2[sinister_zoner] ^7" .. #zones .. " Texas county + neighborhood zones loaded")


