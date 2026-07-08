local activeDeliveries = {}
local playerGrades = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getCid(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid
end

local function getPlayerGrade(cid)
    return playerGrades[cid] or 0
end

local function getGradeByExp(exp)
    local grade = 0
    for i, g in ipairs(Config.Grades) do
        if exp >= g.minExp then
            grade = i - 1
        end
    end
    return grade
end

local function getPayForDelivery(cid)
    local grade = getPlayerGrade(cid)
    local gradeData = Config.Grades[grade + 1]
    return gradeData and gradeData.payment or Config.Grades[1].payment
end

RegisterNetEvent("sinister_trucking:startDelivery", function(routeId)
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if activeDeliveries[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Lone Star Logistics", description = "You already have an active delivery.", type = "error"
        })
        return
    end
    local route = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == routeId then route = r; break end
    end
    if not route then return end
    activeDeliveries[cid] = { routeId = routeId, startTime = os.time() }
    TriggerClientEvent("sinister_trucking:deliveryStarted", src, route)
end)

RegisterNetEvent("sinister_trucking:completeDelivery", function(routeId)
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if not activeDeliveries[cid] or activeDeliveries[cid].routeId ~= routeId then return end

    local route = nil
    for _, r in ipairs(Config.Routes) do
        if r.id == routeId then route = r; break end
    end
    if not route then return end

    local grade = getPlayerGrade(cid)
    local gradeData = Config.Grades[grade + 1]
    local pay = Config.Grades[1].payment
    if gradeData then pay = gradeData.payment end

    local distance = route.distanceBonus or 500
    local totalPay = pay + distance

    exports.qbx_core.Functions.AddMoney(src, "bank", totalPay)

    activeDeliveries[cid] = nil

    local expGain = 1
    if not playerGrades[cid] then playerGrades[cid] = 0 end
    playerGrades[cid] = playerGrades[cid] + expGain
    local newGrade = getGradeByExp(playerGrades[cid])
    local newGradeName = Config.Grades[newGrade + 1].name

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Lone Star Logistics",
        description = "Delivery complete! Paid $" .. totalPay .. " | Grade: " .. newGradeName,
        type = "success",
        duration = 6000,
    })
end)

RegisterNetEvent("sinister_trucking:cancelDelivery", function()
    local src = source
    local cid = getCid(src)
    if cid and activeDeliveries[cid] then
        activeDeliveries[cid] = nil
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Lone Star Logistics", description = "Delivery cancelled.", type = "inform"
        })
    end
end)

RegisterNetEvent("sinister_trucking:requestStatus", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    local grade = getPlayerGrade(cid)
    local gradeData = Config.Grades[grade + 1]
    local hasActive = activeDeliveries[cid] ~= nil
    local nextGrade = nil
    for _, g in ipairs(Config.Grades) do
        if g.minExp > (playerGrades[cid] or 0) then
            nextGrade = g
            break
        end
    end
    TriggerClientEvent("sinister_trucking:receiveStatus", src, {
        grade = gradeData and gradeData.name or "Trainee",
        gradeLevel = grade + 1,
        experience = playerGrades[cid] or 0,
        hasActiveDelivery = hasActive,
        nextGrade = nextGrade and nextGrade.name or "Max",
        nextGradeExp = nextGrade and nextGrade.minExp or nil,
    })
end)

RegisterNetEvent("sinister_trucking:spawnVehicle", function()
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

    SetVehicleColours(veh, Config.VehicleColors.primary, Config.VehicleColors.secondary)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent("sinister_trucking:vehicleSpawned", src, netId)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_trucking] ^7Lone Star Logistics ready — " .. #Config.Routes .. " routes")
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    if activeDeliveries[cid] then
        activeDeliveries[cid] = nil
    end
end)
