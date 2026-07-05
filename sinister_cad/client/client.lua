local isNuiOpen = false
local pendingCallbacks = {}

local zones = {
    { name = "Houston",    county = "Harris County",   center = vec3(0, 0, 50),      radius = 3000 },
    { name = "Fort Worth", county = "Tarrant County",  center = vec3(-440, 6000, 31), radius = 2000 },
    { name = "Killeen",    county = "Bell County",     center = vec3(1700, 3580, 35), radius = 2000 },
}
local currentZone = "Wilderness"

local function detectZone()
    local coords = GetEntityCoords(PlayerPedId())
    local nearest, nearestDist = nil, 9999
    for _, z in ipairs(zones) do
        local dist = #(coords - z.center)
        if dist < z.radius and dist < nearestDist then
            nearestDist = dist
            nearest = z
        end
    end
    currentZone = nearest and nearest.name or "Wilderness"
    return currentZone
end

Citizen.CreateThread(function()
    while true do
        local prev = currentZone
        local zone = detectZone()
        if zone ~= prev then
            LocalPlayer.state:set("cad:officer_zone", zone, true)
        end
        Wait(isNuiOpen and 1000 or 5000)
    end
end)

RegisterNUICallback("setNuiFocus", function(data, cb)
    isNuiOpen = not not (data.hasFocus)
    SetNuiFocus(data.hasFocus, data.cursor)
    cb("ok")
end)

RegisterNUICallback("closeNui", function(_, cb)
    isNuiOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("cad:getZone", function(_, cb)
    cb({ zone = currentZone })
end)

RegisterNetEvent("sinister_cad:proxyResponse", function(requestId, result)
    local cb = pendingCallbacks[requestId]
    if cb then pendingCallbacks[requestId] = nil; cb(result) end
end)

RegisterNUICallback("cad_proxy", function(data, cb)
    local requestId = data.id
    pendingCallbacks[requestId] = cb
    TriggerServerEvent("sinister_cad:proxyRequest", requestId, data.payload or {})
    Citizen.SetTimeout(15000, function()
        if pendingCallbacks[requestId] then pendingCallbacks[requestId] = nil; cb({ _error = "Timed out" }) end
    end)
end)

RegisterNUICallback("checkAuth", function(_, cb)
    local player = exports.qbx_core:GetPlayer(cache.playerId)
    if not player then cb({ authorized = false, job = nil, type = nil }); return end
    local job = player.PlayerData.job
    cb({
        authorized = true,
        job = job.name,
        jobType = job.type,
        grade = job.grade and job.grade.level or 0,
    })
end)

RegisterNUICallback("cad:scanPlate", function(_, cb)
    local ped = PlayerPedId(); local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 15.0, 0, 71)
    if vehicle == 0 then cb({ error = "No vehicle nearby" }); return end
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
    cb({ plate = plate, model = model, speed = speed, vehicle = vehicle })
end)

RegisterNUICallback("cad:getSpeed", function(_, cb)
    local ped = PlayerPedId(); local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 15.0, 0, 71)
    if vehicle == 0 then cb({ error = "No vehicle nearby" }); return end
    local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
    local plate = GetVehicleNumberPlateText(vehicle)
    local limit = 60
    local street = GetStreetNameFromCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(street[1])
    local street2 = GetStreetNameFromHashKey(street[2])
    local location = street1 .. (street2 ~= "" and " / " .. street2 or "")
    cb({ speed = speed, plate = plate, limit = limit, location = location, over = speed > limit + 20 })
end)

print("^2[sinister_cad] ^7Client ready")
