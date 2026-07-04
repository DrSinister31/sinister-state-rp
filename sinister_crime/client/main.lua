-- Sinister Crime — Client (Drug spot markers + dealing UI)

local activeSpots = {}
local dealingActive = false
local currentSpot = nil
local sellingInterval = 5000

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    loadSpots()
end)

function loadSpots()
    -- Request spots from server via Supabase
    lib.callback("sinister_crime:getSpots", false, function(spots)
        for _, point in ipairs(activeSpots) do
            point:remove()
        end
        activeSpots = {}

        for _, spot in ipairs(spots) do
            local coords = spot.coords
            local point = lib.points.new({
                coords = vec3(coords.x, coords.y, coords.z),
                distance = 3.0,
            })

            function point:onEnter()
                currentSpot = spot
                if not dealingActive then
                    lib.showTextUI("[E] Sell Drugs — " .. spot.label .. "\nZone: " .. spot.zone_name)
                end
            end

            function point:onExit()
                currentSpot = nil
                if not dealingActive then
                    lib.hideTextUI()
                end
            end

            function point:nearby()
                if currentSpot and IsControlJustPressed(0, 38) then
                    if dealingActive then
                        -- Stop dealing
                        dealingActive = false
                        TriggerServerEvent("sinister_crime:stopDealing")
                        lib.hideTextUI()
                    else
                        -- Start dealing menu
                        openDealingMenu(currentSpot)
                    end
                end
            end

            activeSpots[#activeSpots + 1] = point
        end
    end)
end

function openDealingMenu(spot)
    local options = {}
    for drug, data in pairs({
        weed = "Weed — $200 base",
        cocaine = "Cocaine — $500 base",
        meth = "Meth — $800 base",
        heroin = "Heroin — $1200 base",
        fentanyl = "Fentanyl — $2000 base",
    }) do
        table.insert(options, {
            title = drug:gsub("^%l", string.upper),
            description = data,
            icon = "fa-solid fa-cannabis",
            event = "sinister_crime:startDealing",
            args = { spot = spot, drug = drug },
        })
    end

    lib.registerContext({
        id = "sinister_crime_deal_menu",
        title = "Sell at " .. spot.label,
        options = options,
    })
    lib.showContext("sinister_crime_deal_menu")
end

RegisterNetEvent("sinister_crime:startDealing", function(data)
    local qualityMenu = {
        { title = "Dirty (Street Cut)", description = "60% price, 140% alert", event = "sinister_crime:confirmDeal", args = { spot = data.spot, drug = data.drug, quality = "dirty" } },
        { title = "Standard", description = "100% price, baseline alert", event = "sinister_crime:confirmDeal", args = { spot = data.spot, drug = data.drug, quality = "standard" } },
        { title = "Clean (Pharma)", description = "150% price, 70% alert", event = "sinister_crime:confirmDeal", args = { spot = data.spot, drug = data.drug, quality = "clean" } },
        { title = "Premium (Lab Pure)", description = "250% price, 40% alert", event = "sinister_crime:confirmDeal", args = { spot = data.spot, drug = data.drug, quality = "premium" } },
    }

    lib.registerContext({
        id = "sinister_crime_quality_menu",
        title = "Quality — " .. data.drug:gsub("^%l", string.upper),
        options = qualityMenu,
    })
    lib.showContext("sinister_crime_quality_menu")
end)

RegisterNetEvent("sinister_crime:confirmDeal", function(data)
    dealingActive = true
    currentSpot = data.spot
    TriggerServerEvent("sinister_crime:setupDealer", data.spot.id, data.drug, data.quality)

    -- Auto-sell loop
    Citizen.CreateThread(function()
        while dealingActive and currentSpot do
            Wait(sellingInterval)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local spotCoords = data.spot.coords
            local dist = #(coords - vec3(spotCoords.x, spotCoords.y, spotCoords.z))

            if dist > 5.0 then
                dealingActive = false
                TriggerServerEvent("sinister_crime:stopDealing")
                lib.hideTextUI()
                lib.notify({ title = "Dealing", description = "Left the spot. Packed up.", type = "error" })
                break
            end

            local qty = math.random(1, 3)
            TriggerServerEvent("sinister_crime:sellDrugs", data.spot.id, data.drug, qty, data.quality)
            lib.showTextUI("[H] Selling " .. data.drug .. " (x" .. qty .. ")\nZone: " .. data.spot.zone_name .. " | Press E to stop")
        end
    end)
end)

-- Callback to get spots from Supabase
lib.callback.register("sinister_crime:getSpots", function()
    local p = promise.new()
    PerformHttpRequest(GetConvar("sinister_apps:supabase_url", "") .. "/rest/v1/drug_spots?select=*&active=eq.true",
        function(code, data)
            if code == 200 and data then
                p:resolve(json.decode(data))
            else
                p:resolve({})
            end
        end, "GET", "", {
            ["apikey"] = GetConvar("sinister_apps:supabase_key", ""),
            ["Authorization"] = "Bearer " .. GetConvar("sinister_apps:supabase_key", ""),
        })
    return Citizen.Await(p)
end)

print("^5[sinister_crime] ^7Client ready — " .. #activeSpots .. " drug spots loaded")
