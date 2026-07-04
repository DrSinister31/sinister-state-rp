local isNuiOpen = false

RegisterNetEvent("sinister_apps:openNui", function(app, data)
    SetNuiFocus(true, true)
    isNuiOpen = true
    if app == "banking" then
        SendNUIMessage({ type = "loadBusinessBanking", citizenid = data.citizenid })
    elseif app == "syntok" then
        SendNUIMessage({ type = "loadSyntok" })
    end
end)

-- NUI → Server proxy bridge
RegisterNUICallback("proxyRequest", function(data, cb)
    local requestId = data.id
    local app = data.app
    local payload = data.payload or {}
    TriggerServerEvent("sinister_apps:proxyRequest", requestId, app, payload)
    -- Wait for server response via client event, max 10 second timeout
    local responded = false
    local listener
    listener = RegisterNetEvent("sinister_apps:proxyResponse", function(rid, result)
        if rid == requestId and not responded then
            responded = true
            RemoveEventHandler(listener)
            cb(result)
        end
    end)
    Citizen.SetTimeout(10000, function()
        if not responded then
            responded = true
            RemoveEventHandler(listener)
            cb({ _error = "Request timed out" })
        end
    end)
end)

RegisterNUICallback("appClosed", function(_, cb)
    SetNuiFocus(false, false)
    isNuiOpen = false
    cb("ok")
end)

RegisterNUICallback("appOpened", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("setGPS", function(data, cb)
    SetNewWaypoint(data.x, data.y)
    cb("ok")
end)

Citizen.CreateThread(function()
    while true do
        if isNuiOpen and IsControlJustPressed(0, 177) then
            SetNuiFocus(false, false)
            isNuiOpen = false
            SendNUIMessage({ type = "closeApp" })
        end
        Wait(0)
    end
end)
