-- syntok client
local isNuiOpen = false
local pendingCallbacks = {}

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

RegisterNetEvent("sinister_syntok:proxyResponse", function(requestId, result)
    local cb = pendingCallbacks[requestId]
    if cb then pendingCallbacks[requestId] = nil; cb(result) end
end)

RegisterNUICallback("syntok_proxy", function(data, cb)
    local requestId = data.id
    pendingCallbacks[requestId] = cb
    TriggerServerEvent("sinister_syntok:proxyRequest", requestId, data.payload or {})
    Citizen.SetTimeout(15000, function()
        if pendingCallbacks[requestId] then pendingCallbacks[requestId] = nil; cb({ _error = "Timed out" }) end
    end)
end)

print("^2[sinister_syntok] ^7Client ready")
