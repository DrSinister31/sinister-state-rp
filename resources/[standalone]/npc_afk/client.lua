local isAFK = false
local lastActivityTime = 0
local afkVehicle = nil

function setAFKMode()
    local ped = PlayerPedId()
    if isAFK then return end

    isAFK = true

    if Config.InvincibleWhileAFK then
        SetEntityInvincible(ped, true)
    end

    if IsPedInAnyVehicle(ped, false) then
        afkVehicle = GetVehiclePedIsIn(ped, false)

        -- Ensure player is in driver seat
        if GetPedInVehicleSeat(afkVehicle, -1) ~= ped then
            TaskWarpPedIntoVehicle(ped, afkVehicle, -1)
        end

        -- Start driving like an NPC
        TaskVehicleDriveWander(ped, afkVehicle, 20.0, 786603)
    else
        afkVehicle = nil
        ClearPedTasksImmediately(ped)
        TaskWanderStandard(ped, 10.0, 10)
    end

    TriggerEvent('chat:addMessage', {
        args = { '^3[AFK]^0 You have been set to NPC mode. Type ^2/back^0 to return.' }
    })
end

function returnFromAFK()
    local ped = PlayerPedId()
    if not isAFK then return end

    -- Clear AI tasks (including driving) but don't kick player out of vehicle
    ClearPedTasks(ped)

    if afkVehicle and DoesEntityExist(afkVehicle) then
        -- Warp player back into the vehicle driver seat
        TaskWarpPedIntoVehicle(ped, afkVehicle, -1)
    end

    if Config.InvincibleWhileAFK then
        SetEntityInvincible(ped, false)
    end

    afkVehicle = nil
    isAFK = false

    TriggerEvent('chat:addMessage', {
        args = { '^2[AFK]^0 You are now back in control.' }
    })
end

RegisterCommand("afk", function()
    setAFKMode()
end)

RegisterCommand("back", function()
    returnFromAFK()
end)

-- Track player activity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if not isAFK then
            local ped = PlayerPedId()
            local speed = GetEntitySpeed(ped)

            if speed > 0.1 or
               IsControlPressed(0, 1) or IsControlPressed(0, 2) or IsControlPressed(0, 24) or
               IsControlPressed(0, 32) or IsControlPressed(0, 33) or
               IsControlPressed(0, 34) or IsControlPressed(0, 35) then
                lastActivityTime = GetGameTimer()
            end
        end
    end
end)

-- Auto AFK timer check
Citizen.CreateThread(function()
    lastActivityTime = GetGameTimer()
    while true do
        Citizen.Wait(10000)
        if not isAFK then
            local idleTime = (GetGameTimer() - lastActivityTime) / 1000
            if idleTime >= (Config.AFKTimeout * 60) then
                setAFKMode()
            end
        end
    end
end)

-- Draw AFK tag above player
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isAFK then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            DrawText3D(coords.x, coords.y, coords.z + 1.0, "~r~[AFK]")
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        local playerName = GetPlayerName(PlayerId())
        local idleTime = math.floor((GetGameTimer() - lastActivityTime) / 1000)
        local afkText = string.format("~r~[AFK] %s (Inactive: %d sec)", playerName, idleTime)

        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 0, 0, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(afkText)
        DrawText(_x, _y)

        local factor = (string.len(afkText)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end
