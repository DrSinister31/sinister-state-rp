local pendingCallbacks = {}

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
