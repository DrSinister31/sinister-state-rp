local activeDelivery = nil
local deliveryVehicle = nil
local deliveryBlip = nil
local atPickup = false
local atDropoff = false
local currentRoute = nil

local depotPoint = lib.points.new({
    coords = Config.DepotLocation,
    distance = 30.0,
})

function depotPoint:onEnter()
    lib.showTextUI("[E] Lone Star Logistics\nView routes | Request truck")
end

function depotPoint:onExit()
    lib.hideTextUI()
end

function depotPoint:nearby()
    if IsControlJustPressed(0, 38) then
        OpenDepotMenu()
    end
end

CreateThread(function()
    local blip = AddBlipForCoord(Config.DepotLocation.x, Config.DepotLocation.y, Config.DepotLocation.z)
    SetBlipSprite(blip, 477)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 47)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.CompanyName)
    EndTextCommandSetBlipName(blip)
end)

function OpenDepotMenu()
    local options = {
        { title = "Request Truck", description = "Spawn a Lone Star Logistics hauler",
            onSelect = function() TriggerServerEvent("sinister_trucking:spawnVehicle") end },
        { title = "Check Status", description = "View your grade and experience",
            onSelect = function() TriggerServerEvent("sinister_trucking:requestStatus") end },
        { title = "Gulf Coast Run", description = "Houston ↔ Galveston | $" .. Config.Routes[1].basePay .. "+",
            onSelect = function() StartRoute("gulf_coast") end },
        { title = "Hill Country Haul", description = "Ft. Worth ↔ Killeen | $" .. Config.Routes[2].basePay .. "+",
            onSelect = function() StartRoute("hill_country") end },
        { title = "Panhandle Express", description = "Paleto ↔ Sandy Shores | $" .. Config.Routes[3].basePay .. "+",
            onSelect = function() StartRoute("panhandle") end },
        { title = "Bayou Transport", description = "Third Ward ↔ Docks | $" .. Config.Routes[4].basePay .. "+",
            onSelect = function() StartRoute("bayou") end },
    }
    if activeDelivery then
        options[#options + 1] = { title = "Cancel Delivery", description = "Abandon current route",
            onSelect = function() CancelDelivery() end }
    end
    lib.registerContext({ id = "lsl_menu", title = Config.CompanyName, menu = "lsl_menu", options = options })
    lib.showContext("lsl_menu")
end

function StartRoute(routeId)
    if activeDelivery then
        lib.notify({ title = "Lone Star Logistics", description = "Finish or cancel your current delivery first.", type = "error" })
        return
    end
    local route = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == routeId then route = r; break end
    end
    if not route then return end
    currentRoute = route
    TriggerServerEvent("sinister_trucking:startDelivery", routeId)
end

RegisterNetEvent("sinister_trucking:deliveryStarted", function(route)
    currentRoute = route
    activeDelivery = true

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(route.pickup.x, route.pickup.y, route.pickup.z)
    SetBlipSprite(deliveryBlip, 514)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 1.0)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pickup: " .. route.pickupLabel)
    EndTextCommandSetBlipName(deliveryBlip)

    lib.notify({ title = "Lone Star Logistics", description = "Route: " .. route.name .. " | Pickup at " .. route.pickupLabel, type = "success", duration = 7000 })
end)

CreateThread(function()
    while true do
        Citizen.Wait(500)
        if activeDelivery and currentRoute then
            local coords = GetEntityCoords(cache.ped)
            local distToPickup = #(coords - currentRoute.pickup)
            local distToDropoff = #(coords - currentRoute.dropoff)

            if distToPickup < 30.0 and IsPedInAnyVehicle(cache.ped, false) then
                if not atPickup then
                    atPickup = true
                    lib.showTextUI("[E] Load cargo at " .. currentRoute.pickupLabel)
                end
                if IsControlJustPressed(0, 38) then
                    if deliveryBlip then RemoveBlip(deliveryBlip) end
                    deliveryBlip = AddBlipForCoord(currentRoute.dropoff.x, currentRoute.dropoff.y, currentRoute.dropoff.z)
                    SetBlipSprite(deliveryBlip, 514)
                    SetBlipDisplay(deliveryBlip, 4)
                    SetBlipScale(deliveryBlip, 1.0)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Dropoff: " .. currentRoute.dropoffLabel)
                    EndTextCommandSetBlipName(deliveryBlip)
                    lib.notify({ title = "Lone Star Logistics", description = "Cargo loaded! Head to " .. currentRoute.dropoffLabel, type = "success" })
                end
            elseif distToPickup >= 30.0 and atPickup then
                atPickup = false
                lib.hideTextUI()
            end

            if distToDropoff < 40.0 and currentRoute then
                if not atDropoff then
                    atDropoff = true
                    lib.showTextUI("[E] Unload cargo at " .. currentRoute.dropoffLabel)
                end
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("sinister_trucking:completeDelivery", currentRoute.id)
                    activeDelivery = nil
                    currentRoute = nil
                    atPickup = false
                    atDropoff = false
                    if deliveryBlip then RemoveBlip(deliveryBlip); deliveryBlip = nil end
                    lib.hideTextUI()
                end
            elseif distToDropoff >= 40.0 and atDropoff then
                atDropoff = false
                lib.hideTextUI()
            end
        end
    end
end)

function CancelDelivery()
    activeDelivery = nil
    currentRoute = nil
    atPickup = false
    atDropoff = false
    if deliveryBlip then RemoveBlip(deliveryBlip); deliveryBlip = nil end
    lib.hideTextUI()
    TriggerServerEvent("sinister_trucking:cancelDelivery")
    lib.notify({ title = "Lone Star Logistics", description = "Delivery cancelled.", type = "inform" })
end

RegisterNetEvent("sinister_trucking:receiveStatus", function(data)
    local msg = data.grade .. " (Level " .. data.gradeLevel .. ")\n"
    msg = msg .. "Experience: " .. data.experience .. " deliveries\n"
    msg = msg .. "Next: " .. data.nextGrade
    if data.nextGradeExp then msg = msg .. " (at " .. data.nextGradeExp .. ")" end
    if data.hasActiveDelivery then msg = msg .. "\nActive delivery in progress" end
    lib.notify({ title = "Lone Star Logistics — Status", description = msg, type = "inform", duration = 8000 })
end)

RegisterNetEvent("sinister_trucking:vehicleSpawned", function(netId)
    local veh = NetToVeh(netId)
    if veh and veh ~= 0 then
        SetPedIntoVehicle(cache.ped, veh, -1)
        deliveryVehicle = veh
        SetVehicleEngineOn(veh, true, true, false)
        lib.notify({ title = "Lone Star Logistics", description = "Truck ready. Select a route at the depot.", type = "success" })
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_trucking] ^7Lone Star Logistics client ready")
    end
end)
