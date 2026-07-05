-- ============================================================================
--  EasyAdmin — NUI Callbacks & Integration
--  Sinister H-Town RP
-- ============================================================================

local isGuiOpen = false
local cachedPlayerList = {}
local cachedResourceList = {}
local cachedBanList = {}
local cachedReportList = {}

-- ============================================================================
--  Teleport Confirmations
-- ============================================================================

RegisterNUICallback("confirmTeleport", function(data, cb)
    local targetId = tonumber(data.targetId)
    local mode = data.mode or "goto"

    if mode == "goto" or mode == "tp" then
        TriggerServerEvent("easyadmin:server:tp", targetId)
    elseif mode == "bring" then
        TriggerServerEvent("easyadmin:server:bring", targetId)
    end

    cb("ok")
end)

-- ============================================================================
--  Modal Confirmation Callbacks
-- ============================================================================

RegisterNUICallback("confirmAction", function(data, cb)
    local action = data.action
    local targetId = tonumber(data.targetId)

    if action == "kick" then
        TriggerServerEvent("easyadmin:server:kick", targetId, data.reason or "No reason provided")
    elseif action == "ban" then
        TriggerServerEvent("easyadmin:server:ban", targetId, tonumber(data.duration) or 0, data.reason or "No reason provided")
    elseif action == "mute" then
        TriggerServerEvent("easyadmin:server:mute", targetId, tonumber(data.duration) or 300)
    elseif action == "slap" then
        TriggerServerEvent("easyadmin:server:slap", targetId, tonumber(data.damage) or 0)
    elseif action == "freeze" then
        TriggerServerEvent("easyadmin:server:freeze", targetId)
    elseif action == "revive" then
        TriggerServerEvent("easyadmin:server:revive", targetId)
    elseif action == "heal" then
        TriggerServerEvent("easyadmin:server:heal", targetId)
    elseif action == "screenshot" then
        TriggerServerEvent("easyadmin:server:screenshot", targetId)
    end

    cb("ok")
end)

-- ============================================================================
--  Player Search Callback
-- ============================================================================

RegisterNUICallback("searchPlayers", function(data, cb)
    local query = (data.query or ""):lower()
    local results = {}
    for _, player in ipairs(cachedPlayerList) do
        if player.name:lower():find(query, 1, true) or tostring(player.id) == query then
            results[#results + 1] = player
        end
    end
    cb(json.encode(results))
end)

-- ============================================================================
--  Ban Search Callback
-- ============================================================================

RegisterNUICallback("searchBans", function(data, cb)
    local query = (data.query or ""):lower()
    local results = {}
    for _, ban in ipairs(cachedBanList) do
        if ban.name:lower():find(query, 1, true) or tostring(ban.id) == query then
            results[#results + 1] = ban
        end
    end
    cb(json.encode(results))
end)

-- ============================================================================
--  Report Search Callback
-- ============================================================================

RegisterNUICallback("searchReports", function(data, cb)
    local query = (data.query or ""):lower()
    local results = {}
    for _, report in ipairs(cachedReportList) do
        if report.reporterName:lower():find(query, 1, true) or
           (report.targetName and report.targetName:lower():find(query, 1, true)) or
           report.message:lower():find(query, 1, true) then
            results[#results + 1] = report
        end
    end
    cb(json.encode(results))
end)

-- ============================================================================
--  Get Player Details
-- ============================================================================

RegisterNUICallback("getPlayerDetails", function(data, cb)
    local targetId = tonumber(data.targetId)
    TriggerServerEvent("easyadmin:server:getPlayerInfo", targetId)
    cb("ok")
end)

-- ============================================================================
--  Copy to Clipboard (via NUI)
-- ============================================================================

RegisterNUICallback("copyToClipboard", function(data, cb)
    SendNUIMessage({
        action = "copyToClipboard",
        text = data.text or ""
    })
    cb("ok")
end)

-- ============================================================================
--  Cache Update Handlers
-- ============================================================================

RegisterNetEvent("easyadmin:client:updatePlayers", function(players)
    cachedPlayerList = players or {}
    if not isGuiOpen then return end
    SendNUIMessage({
        action = "updatePlayers",
        players = cachedPlayerList
    })
end)

RegisterNetEvent("easyadmin:client:updateResources", function(resources)
    cachedResourceList = resources or {}
    if not isGuiOpen then return end
    SendNUIMessage({
        action = "updateResources",
        resources = cachedResourceList
    })
end)

RegisterNetEvent("easyadmin:client:banlist", function(bans)
    cachedBanList = bans or {}
    if not isGuiOpen then return end
    SendNUIMessage({
        action = "updateBans",
        bans = cachedBanList
    })
end)

RegisterNetEvent("easyadmin:client:updateReports", function(reports)
    cachedReportList = reports or {}
    if not isGuiOpen then return end
    SendNUIMessage({
        action = "updateReports",
        reports = cachedReportList
    })
end)

-- ============================================================================
--  Progress Bar Integration (minimal — can be extended)
-- ============================================================================

RegisterNUICallback("showProgress", function(data, cb)
    local label = data.label or "Processing..."
    local duration = tonumber(data.duration) or 2000

    if Config.NUI.progressBarEnabled then
        -- Placeholder for qb-progressbar or ox_progressbar integration
        -- exports["progressbar"]:Progress({
        --     name = "easyadmin_progress",
        --     duration = duration,
        --     label = label,
        --     useWhileDead = false,
        --     canCancel = true,
        -- })
    else
        SendNUIMessage({
            action = "progressBar",
            label = label,
            duration = duration
        })
    end

    cb("ok")
end)

-- ============================================================================
--  Toast Notification Display
-- ============================================================================

RegisterNetEvent("easyadmin:notify", function(message, notifyType)
    SendNUIMessage({
        action = "notify",
        message = message,
        type = notifyType or "info"
    })
end)

-- ============================================================================
--  Settings Save
-- ============================================================================

RegisterNUICallback("saveUserSettings", function(data, cb)
    local settings = data.settings or {}
    SendNUIMessage({
        action = "settingsSaved",
        settings = settings
    })
    cb("ok")
end)

-- ============================================================================
--  GUI State Tracking
-- ============================================================================

RegisterNUICallback("guiOpened", function(data, cb)
    isGuiOpen = true
    cb("ok")
end)

RegisterNUICallback("guiClosed", function(data, cb)
    isGuiOpen = false
    cb("ok")
end)
