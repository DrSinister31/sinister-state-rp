-- ============================================================================
--  EasyAdmin — Client Core
--  Sinister H-Town RP
-- ============================================================================

local isAdmin = false
local isModerator = false
local adminRole = ""
local permissions = {}
local isNoclipActive = false
local noclipSpeed = 2.0
local isFrozen = false
local playerList = {}
local resourceList = {}
local banList = {}
local reportList = {}
local isGuiOpen = false
local noclipCam = nil
local pollTimer = nil

-- ============================================================================
--  Utility Functions
-- ============================================================================

local function Notify(message, notifyType)
    notifyType = notifyType or "info"
    SendNUIMessage({
        action = "notify",
        message = message,
        type = notifyType
    })
end

local function DebugPrint(...)
    -- print("[EasyAdmin]", ...)
end

-- ============================================================================
--  NUI Open/Close
-- ============================================================================

local function OpenGui()
    if isGuiOpen then return end

    if not isAdmin and not isModerator then
        TriggerServerEvent("easyadmin:server:openGui")
        return
    end

    isGuiOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent("easyadmin:server:openGui")
    SendNUIMessage({ action = "open" })
    DebugPrint("GUI opened")

    if pollTimer then
        pollTimer = nil
    end
    pollTimer = SetInterval(function()
        if isGuiOpen then
            TriggerServerEvent("easyadmin:server:refreshData")
            if adminRole == "admin" then
                TriggerServerEvent("easyadmin:server:requestBanlist")
            end
            if adminRole == "admin" or isModerator then
                TriggerServerEvent("easyadmin:server:requestReports")
            end
        end
    end, Config.NUI.pollInterval)
end

local function CloseGui()
    if not isGuiOpen then return end
    isGuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    DebugPrint("GUI closed")

    if pollTimer then
        ClearInterval(pollTimer)
        pollTimer = nil
    end
end

RegisterNUICallback("close", function(data, cb)
    CloseGui()
    cb("ok")
end)

RegisterNUICallback("refresh", function(data, cb)
    TriggerServerEvent("easyadmin:server:refreshData")
    TriggerServerEvent("easyadmin:server:requestBanlist")
    TriggerServerEvent("easyadmin:server:requestReports")
    cb("ok")
end)

-- ============================================================================
--  NUI Action Callbacks
-- ============================================================================

RegisterNUICallback("kick", function(data, cb)
    TriggerServerEvent("easyadmin:server:kick", tonumber(data.targetId), data.reason)
    cb("ok")
end)

RegisterNUICallback("ban", function(data, cb)
    TriggerServerEvent("easyadmin:server:ban", tonumber(data.targetId), tonumber(data.duration) or 0, data.reason)
    cb("ok")
end)

RegisterNUICallback("mute", function(data, cb)
    TriggerServerEvent("easyadmin:server:mute", tonumber(data.targetId), tonumber(data.duration) or 300)
    cb("ok")
end)

RegisterNUICallback("unmute", function(data, cb)
    TriggerServerEvent("easyadmin:server:unmute", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("tp", function(data, cb)
    TriggerServerEvent("easyadmin:server:tp", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("bring", function(data, cb)
    TriggerServerEvent("easyadmin:server:bring", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("goto", function(data, cb)
    TriggerServerEvent("easyadmin:server:goto", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("slap", function(data, cb)
    TriggerServerEvent("easyadmin:server:slap", tonumber(data.targetId), tonumber(data.damage) or 0)
    cb("ok")
end)

RegisterNUICallback("freeze", function(data, cb)
    TriggerServerEvent("easyadmin:server:freeze", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("screenshot", function(data, cb)
    TriggerServerEvent("easyadmin:server:screenshot", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("revive", function(data, cb)
    TriggerServerEvent("easyadmin:server:revive", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("heal", function(data, cb)
    TriggerServerEvent("easyadmin:server:heal", tonumber(data.targetId))
    cb("ok")
end)

RegisterNUICallback("noclip", function(data, cb)
    TriggerServerEvent("easyadmin:server:noclip")
    cb("ok")
end)

RegisterNUICallback("announce", function(data, cb)
    TriggerServerEvent("easyadmin:server:announce", data.message)
    cb("ok")
end)

RegisterNUICallback("resourceAction", function(data, cb)
    TriggerServerEvent("easyadmin:server:resourceAction", data.resource, data.action)
    cb("ok")
end)

RegisterNUICallback("editPermissions", function(data, cb)
    TriggerServerEvent("easyadmin:server:editPermissions", data.targetDiscord, data.aceGroup)
    cb("ok")
end)

RegisterNUICallback("setConvar", function(data, cb)
    TriggerServerEvent("easyadmin:server:setConvar", data.key, data.value)
    cb("ok")
end)

RegisterNUICallback("getServerInfo", function(data, cb)
    TriggerServerEvent("easyadmin:server:getServerInfo")
    TriggerServerEvent("easyadmin:server:getConvars")
    cb("ok")
end)

RegisterNUICallback("resolveReport", function(data, cb)
    TriggerServerEvent("easyadmin:server:resolveReport", tonumber(data.reportId), data.resolution)
    cb("ok")
end)

RegisterNUICallback("getBanHistory", function(data, cb)
    TriggerServerEvent("easyadmin:server:getBanHistory", data.identifier)
    cb("ok")
end)

-- ============================================================================
--  Server Event Handlers
-- ============================================================================

RegisterNetEvent("easyadmin:client:openGui", function(players, resources, role, perms)
    adminRole = role
    isAdmin = (role == "admin")
    isModerator = (role == "moderator")
    permissions = perms or {}
    playerList = players or {}
    resourceList = resources or {}

    SendNUIMessage({
        action = "loadData",
        players = playerList,
        resources = resourceList,
        role = adminRole,
        permissions = permissions
    })

    SetNuiFocus(true, true)
    isGuiOpen = true
end)

RegisterNetEvent("easyadmin:client:updatePlayers", function(players)
    playerList = players or {}
    if isGuiOpen then
        SendNUIMessage({
            action = "updatePlayers",
            players = playerList
        })
    end
end)

RegisterNetEvent("easyadmin:client:updateResources", function(resources)
    resourceList = resources or {}
    if isGuiOpen then
        SendNUIMessage({
            action = "updateResources",
            resources = resourceList
        })
    end
end)

RegisterNetEvent("easyadmin:client:banlist", function(bans)
    banList = bans or {}
    if isGuiOpen then
        SendNUIMessage({
            action = "updateBans",
            bans = banList
        })
    end
end)

RegisterNetEvent("easyadmin:client:banHistory", function(identifier, history)
    if isGuiOpen then
        SendNUIMessage({
            action = "updateBanHistory",
            identifier = identifier,
            history = history
        })
    end
end)

RegisterNetEvent("easyadmin:client:updateReports", function(reports)
    reportList = reports or {}
    if isGuiOpen then
        SendNUIMessage({
            action = "updateReports",
            reports = reportList
        })
    end
end)

RegisterNetEvent("easyadmin:client:playerInfo", function(info)
    if isGuiOpen then
        SendNUIMessage({
            action = "playerInfo",
            info = info
        })
    end
end)

RegisterNetEvent("easyadmin:client:serverInfo", function(info)
    if isGuiOpen then
        SendNUIMessage({
            action = "serverInfo",
            info = info
        })
    end
end)

RegisterNetEvent("easyadmin:client:convars", function(convars)
    if isGuiOpen then
        SendNUIMessage({
            action = "convars",
            convars = convars
        })
    end
end)

RegisterNetEvent("easyadmin:client:screenshotResult", function(targetName, imageData)
    if isGuiOpen then
        SendNUIMessage({
            action = "screenshotResult",
            targetName = targetName,
            imageData = imageData
        })
    end
end)

RegisterNetEvent("easyadmin:client:banCacheUpdate", function(bans)
    banList = bans or {}
end)

RegisterNetEvent("easyadmin:client:reportHistory", function(identifier, history)
    if isGuiOpen then
        SendNUIMessage({
            action = "updateReportHistory",
            identifier = identifier,
            history = history
        })
    end
end)

-- ============================================================================
--  Notifications
-- ============================================================================

RegisterNetEvent("easyadmin:notify", function(message, notifyType)
    Notify(message, notifyType)
end)

-- ============================================================================
--  Freeze Handling
-- ============================================================================

RegisterNetEvent("easyadmin:freezeState", function(state)
    isFrozen = state
    if state then
        TriggerEvent("chat:addMessage", {
            color = { 255, 100, 0 },
            args = { "[EasyAdmin]", "You have been frozen by an admin." }
        })
    else
        TriggerEvent("chat:addMessage", {
            color = { 0, 255, 0 },
            args = { "[EasyAdmin]", "You have been unfrozen." }
        })
    end
end)

-- ============================================================================
--  Mute Handling
-- ============================================================================

RegisterNetEvent("easyadmin:playerMuted", function(state)
    if state then
        TriggerEvent("chat:addMessage", {
            color = { 255, 100, 0 },
            args = { "[EasyAdmin]", "You have been muted by an admin." }
        })
    else
        TriggerEvent("chat:addMessage", {
            color = { 0, 255, 0 },
            args = { "[EasyAdmin]", "You have been unmuted." }
        })
    end
end)

-- ============================================================================
--  Heal / Revive Effects
-- ============================================================================

RegisterNetEvent("easyadmin:healEffect", function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
end)

RegisterNetEvent("easyadmin:revivePlayer", function(coords)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetPedArmour(ped, 100)
end)

-- ============================================================================
--  Noclip System
-- ============================================================================

local function StartNoclip()
    local ped = PlayerPedId()
    isNoclipActive = true
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEveryoneIgnorePlayer(ped, true)
    SetPoliceIgnorePlayer(ped, true)

    if not noclipCam then
        local coords = GetEntityCoords(ped)
        noclipCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(noclipCam, coords.x, coords.y, coords.z)
        SetCamRot(noclipCam, 0.0, 0.0, GetEntityHeading(ped), 2)
        RenderScriptCams(true, true, 1000, true, true)
        SetCamActive(noclipCam, true)
    end

    Citizen.CreateThread(function()
        local localNoclipCam = noclipCam
        while isNoclipActive and localNoclipCam == noclipCam do
            Citizen.Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)  -- Look left-right
            EnableControlAction(0, 2, true)  -- Look up-down
            EnableControlAction(0, 32, true) -- W
            EnableControlAction(0, 33, true) -- S
            EnableControlAction(0, 34, true) -- A
            EnableControlAction(0, 35, true) -- D
            EnableControlAction(0, 21, true) -- Shift
            EnableControlAction(0, 19, true) -- Alt
            EnableControlAction(0, 249, true) -- PTT
            EnableControlAction(0, 289, true) -- F2 (for toggle)

            local loc = GetCamCoord(localNoclipCam)
            local rot = GetCamRot(localNoclipCam, 2)
            local speed = noclipSpeed

            if IsDisabledControlPressed(0, 21) then speed = speed * 2.0 end
            if IsDisabledControlPressed(0, 19) then speed = speed * 0.25 end

            local xMult, yMult, zMult = 0.0, 0.0, 0.0
            if IsDisabledControlPressed(0, 32) then yMult = 1.0 end
            if IsDisabledControlPressed(0, 33) then yMult = -1.0 end
            if IsDisabledControlPressed(0, 34) then xMult = -1.0 end
            if IsDisabledControlPressed(0, 35) then xMult = 1.0 end

            local headingRad = math.rad(rot.z)
            local newX = loc.x + ((xMult * math.cos(headingRad)) - (yMult * math.sin(headingRad))) * speed * 0.1
            local newY = loc.y + ((xMult * math.sin(headingRad)) + (yMult * math.cos(headingRad))) * speed * 0.1
            local newZ = loc.z + zMult * speed * 0.1

            if IsDisabledControlPressed(0, 21) and IsDisabledControlPressed(0, 32) then
                newZ = loc.z + 0.5
            end

            local heading = GetGameplayCamRelativeHeading()
            SetCamCoord(localNoclipCam, newX, newY, newZ)
            SetEntityCoords(PlayerPedId(), newX, newY, newZ - 1.0, false, false, false, false)
        end
    end)
end

local function StopNoclip()
    local ped = PlayerPedId()
    isNoclipActive = false
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEveryoneIgnorePlayer(ped, false)
    SetPoliceIgnorePlayer(ped, false)

    if noclipCam then
        local coords = GetCamCoord(noclipCam)
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(noclipCam, true)
        noclipCam = nil
        SetEntityCoords(ped, coords.x, coords.y, coords.z - 1.0, false, false, false, false)
    end
end

RegisterNetEvent("easyadmin:toggleNoclip", function()
    if isNoclipActive then
        StopNoclip()
    else
        StartNoclip()
    end
end)

-- ============================================================================
--  Screenshot System
-- ============================================================================

RegisterNetEvent("easyadmin:requestScreenshot", function(requestingSrc)
    exports["screenshot-basic"]:requestClientScreenshot(requestingSrc, {
        fileName = "easyadmin_screenshot_" .. os.time() .. ".jpg",
        encoding = "jpg",
        quality = Config.Screenshots.quality or 80
    }, function(error, data)
        if not error then
            TriggerServerEvent("easyadmin:server:screenshotResponse", data, requestingSrc)
        end
    end)
end)

-- ============================================================================
--  Announce Event
-- ============================================================================

RegisterNetEvent("easyadmin:announce", function(senderName, message)
    TriggerEvent("chat:addMessage", {
        color = { 191, 87, 0 },
        multiline = true,
        args = { "[" .. senderName .. "]", message }
    })
end)

-- ============================================================================
--  Keybinding (F1 to open admin panel)
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 288) then -- F1 key
            TriggerServerEvent("easyadmin:server:openGui")
        end
    end
end)

-- ============================================================================
--  NUI Focus Control (ESC to close)
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if isGuiOpen then
            if IsControlJustReleased(0, 322) then -- ESC
                CloseGui()
            end
        end
    end
end)

-- ============================================================================
--  Disable control actions while GUI is open
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isGuiOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- PTT
            EnableControlAction(0, 289, true) -- F2
            EnableControlAction(0, 322, true) -- ESC
            if IsControlJustReleased(0, 289) then -- F2 to close
                CloseGui()
            end
        end
    end
end)
