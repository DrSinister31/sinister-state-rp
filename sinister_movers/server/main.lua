local activeJobs = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getCid(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid
end

RegisterNetEvent("sinister_movers:startJob", function(areaId)
    local src = source
    local cid = getCid(src)
    if not cid then return end

    if activeJobs[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Lone Star Movers", description = "You already have an active moving job.", type = "error"
        })
        return
    end

    local area = nil
    for _, a in ipairs(Config.ServiceAreas) do
        if a.id == areaId then area = a; break end
    end
    if not area then return end

    local player = getPlayer(src)
    local name = player and (player.PlayerData.charinfo.firstname or "Worker") or "Worker"

    activeJobs[cid] = {
        areaId = areaId,
        startTime = os.time(),
        pickupComplete = false,
    }

    TriggerClientEvent("sinister_movers:jobStarted", src, area, name)
end)

RegisterNetEvent("sinister_movers:pickupComplete", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if not activeJobs[cid] then return end
    activeJobs[cid].pickupComplete = true
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Lone Star Movers", description = "Furniture loaded! Head to the dropoff.", type = "success", duration = 5000
    })
end)

RegisterNetEvent("sinister_movers:completeJob", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if not activeJobs[cid] then return end

    local jobData = activeJobs[cid]
    local area = nil
    for _, a in ipairs(Config.ServiceAreas) do
        if a.id == jobData.areaId then area = a; break end
    end

    local pay = area and area.basePay or Config.PayRange.min
    local efficiency = jobData.pickupComplete and 1.0 or 0.7
    local totalPay = math.floor(pay * efficiency)

    exports.qbx_core.Functions.AddMoney(src, "bank", totalPay)
    activeJobs[cid] = nil

    local player = getPlayer(src)
    local name = player and (player.PlayerData.charinfo.firstname or "Partner") or "Partner"

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Lone Star Movers",
        description = "Job complete! Paid $" .. totalPay .. " | " .. Config.Slogan,
        type = "success",
        duration = 6000,
    })
end)

RegisterNetEvent("sinister_movers:cancelJob", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    activeJobs[cid] = nil
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Lone Star Movers", description = "Job cancelled.", type = "inform"
    })
end)

RegisterNetEvent("sinister_movers:spawnVehicle", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end

    local vehHash = GetHashKey(Config.VehicleModel)
    RequestModel(vehHash)
    while not HasModelLoaded(vehHash) do Citizen.Wait(10) end

    local coords = Config.DepotLocation
    local heading = Config.DepotHeading

    local veh = CreateVehicleServer(vehHash, "automobile", coords.x, coords.y, coords.z, heading)
    while not DoesEntityExist(veh) do Citizen.Wait(10) end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent("sinister_movers:vehicleSpawned", src, netId)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_movers] ^7Lone Star Movers ready — " .. #Config.ServiceAreas .. " service areas | " .. Config.Slogan)
    end
end)

AddEventHandler("QBCore:Server:PlayerUnloaded", function(player)
    local cid = player.PlayerData.citizenid
    if activeJobs[cid] then activeJobs[cid] = nil end
end)
