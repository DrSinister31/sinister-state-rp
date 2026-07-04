-- Sinister Zoner — Texas neighborhood names on map
-- Replaces GTA V zone labels with Texas neighborhoods

local zones = {
    -- ===== KILLEEN (Sandy Shores) =====
    { name = "Killeen",              center = vec3(1700, 3580, 35), radius = 150, display = "Downtown Killeen" },
    { name = "Loma Vista",           center = vec3(1175, 2642, 38), radius = 120, display = "Loma Vista (Harmony)" },
    { name = "Nolanville",           center = vec3(1698, 4794, 42), radius = 130, display = "Nolanville (Grapeseed)" },
    { name = "Rancho Rancier",       center = vec3(126, 3708, 40),  radius = 80,  display = "Rancier Ave (Stab City)" },
    { name = "Stillhouse Lake",      center = vec3(2012, 4682, 40), radius = 200, display = "Stillhouse Lake" },
    { name = "Skylark Field",        center = vec3(1750, 3300, 41), radius = 150, display = "Skylark Field Airport" },
    { name = "Fort Cavazos",         center = vec3(2500, 3700, 35), radius = 250, display = "Fort Cavazos Training Range" },

    -- ===== FT. WORTH (Paleto Bay) =====
    { name = "Fort Worth",           center = vec3(-440, 6000, 31), radius = 200, display = "Ft. Worth" },
    { name = "Stockyards",           center = vec3(-510, 5380, 80), radius = 100, display = "Stockyards District" },
    { name = "Eagle Mountain Lake",  center = vec3(140, 6680, 10),  radius = 200, display = "Eagle Mountain Lake" },
    { name = "Lake Worth",           center = vec3(-550, 6550, 10), radius = 150, display = "Lake Worth" },
    { name = "Tarrant Woods",        center = vec3(-300, 5600, 150),radius = 250, display = "Tarrant Woods" },

    -- ===== HOUSTON (Los Santos) =====
    { name = "Downtown Houston",     center = vec3(-540, -212, 38), radius = 300, display = "Downtown Houston" },
    { name = "Third Ward",           center = vec3(90, -1425, 29),  radius = 200, display = "Third Ward" },
    { name = "Acres Homes",          center = vec3(85, -1954, 21),  radius = 200, display = "Acres Homes" },
    { name = "Galveston",            center = vec3(-1300, -1400, 4),radius = 250, display = "Galveston Beach" },
    { name = "The Heights",          center = vec3(1100, -700, 57), radius = 150, display = "The Heights" },
    { name = "Montrose",             center = vec3(370, -30, 100),  radius = 200, display = "Montrose" },
    { name = "River Oaks",           center = vec3(-900, 300, 70),  radius = 180, display = "River Oaks" },
    { name = "Sunnyside",            center = vec3(150, -1300, 29), radius = 200, display = "Sunnyside" },
    { name = "Channelview",          center = vec3(900, -2300, 30), radius = 250, display = "Channelview" },
    { name = "Port of Houston",      center = vec3(1300, -3100, 5), radius = 300, display = "Port of Houston" },
    { name = "East End",             center = vec3(800, -1500, 30), radius = 200, display = "East End (La Mesa)" },
    { name = "Pasadena",             center = vec3(1400, -1200, 30),radius = 180, display = "Pasadena (El Burro)" },
}

local activeZone = nil
local lastZoneTime = 0

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
            if not activeZone or activeZone.name ~= nearest.name then
                local now = GetGameTimer()
                if now - lastZoneTime > 5000 then
                    lastZoneTime = now
                    activeZone = nearest
                    lib.showTextUI("[E] " .. nearest.display, {
                        position = "top-center",
                        icon = "location-dot",
                        style = { backgroundColor = "#BF5700", color = "white" }
                    })
                    SetTimeout(4000, function() lib.hideTextUI() end)
                end
            end
        else
            activeZone = nil
        end

        Wait(2000)
    end
end)

print("^2[sinister_zoner] ^7" .. #zones .. " Texas neighborhood zones loaded")
