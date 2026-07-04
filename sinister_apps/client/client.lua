local pendingCallbacks = {}

RegisterNetEvent("sinister_apps:proxyResponse", function(requestId, result)
    local cb = pendingCallbacks[requestId]
    if cb then
        pendingCallbacks[requestId] = nil
        cb(result)
    end
end)

RegisterNUICallback("sinister_proxy", function(data, cb)
    local requestId = data.id
    pendingCallbacks[requestId] = cb
    TriggerServerEvent("sinister_apps:proxyRequest", requestId, data.app, data.payload or {})
    Citizen.SetTimeout(15000, function()
        if pendingCallbacks[requestId] then
            pendingCallbacks[requestId] = nil
            cb({ _error = "Request timed out" })
        end
    end)
end)

RegisterNUICallback("setGPS", function(data, cb)
    SetNewWaypoint(data.x, data.y)
    cb("ok")
end)

RegisterNUICallback("cad:scanPlate", function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 15.0, 0, 71)
    if vehicle == 0 then
        cb({ error = "No vehicle nearby" })
        return
    end
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
    cb({ plate = plate, model = model, speed = speed, vehicle = vehicle })
end)

RegisterNUICallback("cad:getSpeed", function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 15.0, 0, 71)
    if vehicle == 0 then
        cb({ error = "No vehicle nearby" })
        return
    end
    local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
    local plate = GetVehicleNumberPlateText(vehicle)
    local limit = 60
    local street = GetStreetNameFromCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(street[1])
    local street2 = GetStreetNameFromHashKey(street[2])
    local location = street1 .. (street2 ~= "" and " / " .. street2 or "")
    cb({ speed = speed, plate = plate, limit = limit, location = location, over = speed > limit + 20 })
end)

print("^2[sinister_apps] ^7Client ready (CAD scanner included)")
