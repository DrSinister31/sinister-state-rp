local pendingCallbacks = {}

RegisterNetEvent("sinister_underworld:proxyResponse", function(requestId, result)
    local cb = pendingCallbacks[requestId]
    if cb then pendingCallbacks[requestId] = nil; cb(result) end
end)

RegisterNUICallback("uw_proxy", function(data, cb)
    local requestId = data.id
    pendingCallbacks[requestId] = cb
    TriggerServerEvent("sinister_underworld:proxyRequest", requestId, data.payload or {})
    Citizen.SetTimeout(15000, function()
        if pendingCallbacks[requestId] then pendingCallbacks[requestId] = nil; cb({ _error = "Timed out" }) end
    end)
end)

RegisterNUICallback("checkAuth", function(_, cb)
    local player = exports.qbx_core:GetPlayer(cache.playerId)
    if not player then cb({ authorized = false }); return end
    local job = player.PlayerData.job
    local gang = player.PlayerData.gang
    cb({
        authorized = true,
        job = job.name,
        gang = gang and gang.name or nil,
        citizenid = player.PlayerData.citizenid,
    })
end)

print("^5[sinister_underworld] ^7Client ready")
