local activeJob = nil
local currentArea = nil
local jobVehicle = nil
local jobBlip = nil
local atPickup = false
local atDropoff = false

local depotPoint = lib.points.new({
    coords = Config.DepotLocation,
    distance = 30.0,
})

function depotPoint:onEnter()
    lib.showTextUI("[E] Lone Star Movers\n" .. Config.Slogan)
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
    SetBlipSprite(blip, 525)
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
        { title = "Request Moving Truck", description = "Spawn a Lone Star Movers Boxville",
            onSelect = function() TriggerServerEvent("sinister_movers:spawnVehicle") end },
    }
    for _, area in ipairs(Config.ServiceAreas) do
        options[#options + 1] = {
            title = area.label,
            description = "$" .. area.basePay .. " moving job",
            onSelect = function()
                if activeJob then
                    lib.notify({ title = "Lone Star Movers", description = "Finish your current job first.", type = "error" })
                    return
                end
                TriggerServerEvent("sinister_movers:startJob", area.id)
            end,
        }
    end
    if activeJob then
        options[#options + 1] = { title = "Cancel Job", description = "Abandon current move",
            onSelect = function() CancelJob() end }
    end
    lib.registerContext({ id = "lsm_menu", title = Config.CompanyName, menu = "lsm_menu", options = options })
    lib.showContext("lsm_menu")
end

RegisterNetEvent("sinister_movers:jobStarted", function(area, workerName)
    currentArea = area
    activeJob = true

    if jobBlip then RemoveBlip(jobBlip) end
    jobBlip = AddBlipForCoord(area.pickup.x, area.pickup.y, area.pickup.z)
    SetBlipSprite(jobBlip, 525)
    SetBlipDisplay(jobBlip, 4)
    SetBlipScale(jobBlip, 1.0)
    SetBlipColour(jobBlip, 5)
    SetBlipRoute(jobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pickup: " .. area.label)
    EndTextCommandSetBlipName(jobBlip)

    lib.notify({
        title = "Lone Star Movers",
        description = "New job! Pickup at " .. area.label .. " | " .. Config.Slogan,
        type = "success",
        duration = 7000,
    })
end)

CreateThread(function()
    while true do
        Citizen.Wait(500)
        if activeJob and currentArea then
            local coords = GetEntityCoords(cache.ped)
            local distToPickup = #(coords - currentArea.pickup)
            local distToDropoff = #(coords - currentArea.dropoff)

            if distToPickup < 30.0 and IsPedInAnyVehicle(cache.ped, false) then
                if not atPickup then
                    atPickup = true
                    lib.showTextUI("[E] Load furniture at " .. currentArea.label)
                end
                if IsControlJustPressed(0, 38) then
                    if lib.progressBar({
                        duration = 5000,
                        label = "Loading furniture...",
                        useWhileDead = false,
                        canCancel = true,
                    }) then
                        TriggerServerEvent("sinister_movers:pickupComplete")
                        if jobBlip then RemoveBlip(jobBlip) end
                        jobBlip = AddBlipForCoord(currentArea.dropoff.x, currentArea.dropoff.y, currentArea.dropoff.z)
                        SetBlipSprite(jobBlip, 525)
                        SetBlipDisplay(jobBlip, 4)
                        SetBlipScale(jobBlip, 1.0)
                        SetBlipColour(jobBlip, 2)
                        SetBlipRoute(jobBlip, true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString("Dropoff: " .. currentArea.label)
                        EndTextCommandSetBlipName(jobBlip)
                    end
                end
            elseif distToPickup >= 30.0 and atPickup then
                atPickup = false
                lib.hideTextUI()
            end

            if distToDropoff < 30.0 and currentArea then
                if not atDropoff then
                    atDropoff = true
                    lib.showTextUI("[E] Unload furniture at " .. currentArea.label)
                end
                if IsControlJustPressed(0, 38) then
                    if lib.progressBar({
                        duration = 5000,
                        label = "Unloading furniture...",
                        useWhileDead = false,
                        canCancel = true,
                    }) then
                        TriggerServerEvent("sinister_movers:completeJob")
                        activeJob = nil
                        currentArea = nil
                        atPickup = false
                        atDropoff = false
                        if jobBlip then RemoveBlip(jobBlip); jobBlip = nil end
                        lib.hideTextUI()
                    end
                end
            elseif distToDropoff >= 30.0 and atDropoff then
                atDropoff = false
                lib.hideTextUI()
            end
        end
    end
end)

function CancelJob()
    activeJob = nil
    currentArea = nil
    atPickup = false
    atDropoff = false
    if jobBlip then RemoveBlip(jobBlip); jobBlip = nil end
    lib.hideTextUI()
    TriggerServerEvent("sinister_movers:cancelJob")
    lib.notify({ title = "Lone Star Movers", description = "Job cancelled.", type = "inform" })
end

RegisterNetEvent("sinister_movers:vehicleSpawned", function(netId)
    local veh = NetToVeh(netId)
    if veh and veh ~= 0 then
        SetPedIntoVehicle(cache.ped, veh, -1)
        jobVehicle = veh
        SetVehicleEngineOn(veh, true, true, false)
        lib.notify({ title = "Lone Star Movers", description = "Truck ready. Select a job at the depot.", type = "success" })
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_movers] ^7Lone Star Movers client ready")
    end
end)
