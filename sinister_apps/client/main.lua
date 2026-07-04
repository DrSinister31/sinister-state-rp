local isNuiOpen = false

RegisterNetEvent("sinister_apps:openNui", function(app, data)
    SetNuiFocus(true, true)
    isNuiOpen = true
    SendNUIMessage({ type = "openApp", app = app, data = data })
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
