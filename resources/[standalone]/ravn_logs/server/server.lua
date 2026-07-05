-- =============================================================================
-- ravn_logs - server/server.lua
-- Main server event handlers for logging player actions
-- =============================================================================

local webhook = nil

-- ---------------------------------------------------------------------------
-- CACHED PLAYER INFO (captured on join for disconnect logging)
-- ---------------------------------------------------------------------------
local playerInfoCache = {}

-- ---------------------------------------------------------------------------
-- COOLDOWNS (prevents spam from rapid-fire events)
-- ---------------------------------------------------------------------------
local weaponCooldowns  = {}
local explosionCooldowns = {}
local WPN_COOLDOWN_MS  = 2000
local EXP_COOLDOWN_MS  = 3000

-- ---------------------------------------------------------------------------
-- RESOURCE START / STOP
-- ---------------------------------------------------------------------------

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    print("^2[ravn_logs] ^7Resource starting...")

    -- Load webhook module (requires utils to be loaded first)
    webhook = require("server.webhook")

    -- Ensure NDJSON log directory exists
    RavnUtils.CheckDailyRotation()

    -- Start the webhook queue processor
    webhook.StartQueueProcessor()

    -- Clean up old logs on start
    RavnUtils.CleanupOldLogs(Config.RetentionDays)

    -- Start daily rotation checker (runs every 60 seconds)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000)
            RavnUtils.CheckDailyRotation()
        end
    end)

    -- Start periodic cleanup (every 6 hours)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(21600000) -- 6 hours in ms
            RavnUtils.CleanupOldLogs(Config.RetentionDays)
        end
    end)

    print("^2[ravn_logs] ^7Resource started. Logging " .. GetNumLogTypesEnabled() .. " categories.")
    print("^2[ravn_logs] ^7Log directory: " .. Config.LogDirectory)
    print("^2[ravn_logs] ^7Retention: " .. Config.RetentionDays .. " days")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Process remaining queue items before shutdown
    if webhook then
        local processed = 0
        while #queue > 0 and processed < 50 do
            webhook.ProcessQueue()
            processed = processed + 1
            Citizen.Wait(50)
        end
    end

    print("^3[ravn_logs] ^7Resource stopped.")
end)

-- ---------------------------------------------------------------------------
-- HELPER: Count enabled log types
-- ---------------------------------------------------------------------------
function GetNumLogTypesEnabled()
    local n = 0
    for _, v in pairs(Config.EnabledLogs) do
        if v then n = n + 1 end
    end
    return n
end

-- ---------------------------------------------------------------------------
-- HELPER: Check if a chat message matches a configured channel
-- ---------------------------------------------------------------------------
local function GetChatChannel(message)
    if not message then return nil end
    local msgLower = message:gsub("^%s+", ""):lower()
    for _, channel in ipairs(Config.ChatChannels) do
        local chLower = channel:lower()
        if msgLower:sub(1, #chLower) == chLower then
            return channel:gsub("^/", "")
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- HELPER: Check if a command is an admin command to log
-- ---------------------------------------------------------------------------
local function IsAdminCommand(cmd)
    cmd = cmd:lower():gsub("^/", "")
    for _, ac in ipairs(Config.AdminCommands) do
        if cmd == ac then return true end
    end
    return false
end

-- =============================================================================
-- PLAYER JOIN / DISCONNECT
-- =============================================================================

AddEventHandler("playerJoining", function()
    local src = source
    local info = RavnUtils.GetPlayerInfo(src)

    -- Cache player info for use on disconnect
    playerInfoCache[src] = info

    -- Log join to both Discord and NDJSON
    if webhook then
        webhook.LogEvent("joinLeave", nil, {
            playerInfo = info,
            action     = "join",
            reason     = nil,
        })
    end

    print(("[ravn_logs] %s (%s) connected"):format(info.name, RavnUtils.GetShortIdentifier(info)))
end)

AddEventHandler("playerDropped", function(reason)
    local src  = source
    local info = playerInfoCache[src]
    if not info then
        info = {
            id        = src,
            name      = GetPlayerName(src) or "Unknown",
            license   = "unknown",
            ip        = "0.0.0.0",
            identifiers = {},
        }
    end

    local dropReason = reason or "Unknown"
    -- TxAdmin sometimes provides the reason as the first arg
    if dropReason == "Exiting" or dropReason == "" then
        dropReason = "Disconnected"
    end

    -- Log disconnect to both Discord and NDJSON
    if webhook then
        webhook.LogEvent("joinLeave", nil, {
            playerInfo = info,
            action     = "leave",
            reason     = dropReason,
        })
    end

    -- Clear weapon cooldowns for this player
    weaponCooldowns[src] = nil
    explosionCooldowns[src] = nil
    playerInfoCache[src] = nil

    print(("[ravn_logs] %s (%s) disconnected: %s"):format(info.name, RavnUtils.GetShortIdentifier(info), dropReason))
end)

-- =============================================================================
-- DEATH DETECTION (via gameEventTriggered)
-- =============================================================================

-- CEVENT_NETWORK_PLAYER_DEATH
-- Parameters: playerId (victim), killerId, damageTypeHash

local deathEventRegistered = false

-- Early load detection: catch deaths before QBCore is fully loaded
AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName ~= "CEventNetworkPlayerDeath" then return end
    if not Config.EnabledLogs.kill then return end

    local victimId = eventData[1]
    local killerId = eventData[2]
    local deathHash = eventData[3]

    if not victimId then return end

    -- Find source for victim
    local victimSrc = nil
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerServerId(playerId) and GetPlayerPed(playerId) == victimId then
            victimSrc = tonumber(playerId)
            break
        end
    end

    if not victimSrc then return end

    local victimInfo = RavnUtils.GetPlayerInfo(victimSrc)

    -- Determine killer
    local killerInfo = nil
    local isNPC      = false
    local isSuicide  = false
    local isVehicle  = false

    if killerId == -1 or killerId == victimId or not killerId then
        isSuicide = true
        killerInfo = victimInfo
    elseif killerId < 0 or killerId > 256 then
        -- Probable vehicle or environmental
        isVehicle = true
        killerInfo = { name = "Vehicle / Environment", license = "N/A", ip = "0.0.0.0" }
    elseif not IsPedAPlayer(killerId) then
        isNPC = true
        killerInfo = { name = "NPC (" .. GetPedType(killerId) .. ")", license = "N/A", ip = "0.0.0.0" }
    else
        -- Killer is a player
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerPed(playerId) == killerId then
                local kSrc = tonumber(playerId)
                killerInfo = RavnUtils.GetPlayerInfo(kSrc)
                break
            end
        end
        if not killerInfo then
            killerInfo = { name = "Unknown Player", license = "unknown", ip = "0.0.0.0" }
        end
    end

    -- Map death cause
    local causeLabel = Config.DeathCauses[deathHash] or ("0x%X"):format(deathHash or 0)

    -- Get weapon used
    local weaponLabel = causeLabel
    if not isSuicide and not isNPC and not isVehicle then
        if killerId and killerId > 0 then
            local weaponHash = GetPedCauseOfDeath(victimId)
            if weaponHash and weaponHash ~= 0 then
                weaponLabel = RavnUtils.GetWeaponName(weaponHash)
            end
        end
    end

    -- Cooldown check to prevent duplicate events
    local cooldownKey = ("death_%d_%d"):format(victimSrc, GetGameTimer())
    if deathCooldown and deathCooldown[victimSrc] and GetGameTimer() - deathCooldown[victimSrc] < 3000 then
        return
    end
    if not deathCooldown then deathCooldown = {} end
    deathCooldown[victimSrc] = GetGameTimer()

    if webhook then
        webhook.LogEvent("kill", nil, {
            victimInfo  = victimInfo,
            killerInfo  = killerInfo,
            weaponLabel = weaponLabel,
            cause       = causeLabel,
            isNPC       = isNPC,
            isSuicide   = isSuicide,
            isVehicle   = isVehicle,
        })
    end
end)

-- =============================================================================
-- WEAPON FIRE DETECTION
-- =============================================================================

-- CEventNetworkEntityDamage can detect weapon impacts
AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName ~= "CEventNetworkEntityDamage" then return end
    if not Config.EnabledLogs.weapon then return end

    local victimEntity = eventData[1]
    local attackerEntity = eventData[2]
    local weaponHash = eventData[4] or 0

    -- Ignore unarmed and blacklisted weapons
    if Config.WeaponBlacklist[weaponHash] then return end

    -- Find the attacker player
    local attackerSrc = nil
    if IsPedAPlayer(attackerEntity) then
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerPed(playerId) == attackerEntity then
                attackerSrc = tonumber(playerId)
                break
            end
        end
    end

    if not attackerSrc then return end

    -- Cooldown per player to avoid spam
    local now = GetGameTimer()
    if weaponCooldowns[attackerSrc] and (now - weaponCooldowns[attackerSrc]) < WPN_COOLDOWN_MS then
        return
    end
    weaponCooldowns[attackerSrc] = now

    local playerInfo  = RavnUtils.GetPlayerInfo(attackerSrc)
    local weaponLabel = RavnUtils.GetWeaponName(weaponHash)

    if webhook then
        webhook.LogEvent("weapon", nil, {
            playerInfo  = playerInfo,
            weaponLabel = weaponLabel,
            weaponHash  = weaponHash,
        })
    end
end)

-- =============================================================================
-- EXPLOSION DETECTION
-- =============================================================================

AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName ~= "CEventNetworkExplosion" then return end
    if not Config.EnabledLogs.explosion then return end

    -- eventData: [1] = posX, [2] = posY, [3] = posZ, [4] = explosionType, [5] = damageScale, [6] = isAudible, [7] = isInvisible, [8] = ownerNetId
    local explosionType = eventData[4] or 0
    local ownerNetId    = eventData[8]

    if not IsPlayerAPlayer(ownerNetId) and ownerNetId ~= -1 then return end

    local ownerSrc = nil
    if ownerNetId and ownerNetId > 0 then
        local ownerEntity = NetworkGetEntityFromNetworkId(ownerNetId)
        if IsPedAPlayer(ownerEntity) then
            for _, playerId in ipairs(GetPlayers()) do
                if GetPlayerPed(playerId) == ownerEntity then
                    ownerSrc = tonumber(playerId)
                    break
                end
            end
        end
    end

    if not ownerSrc then
        -- Try to find nearby players (within 50m) who may have caused it
        local expPos = vector3(eventData[1] or 0, eventData[2] or 0, eventData[3] or 0)
        local closestSrc = nil
        local closestDist = 50.0

        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)
            local pedPos = GetEntityCoords(ped)
            local dist = #(pedPos - expPos)
            if dist < closestDist then
                closestDist = dist
                closestSrc = tonumber(playerId)
            end
        end

        if closestSrc then
            ownerSrc = closestSrc
        end
    end

    if not ownerSrc then return end

    local now = GetGameTimer()
    if explosionCooldowns[ownerSrc] and (now - explosionCooldowns[ownerSrc]) < EXP_COOLDOWN_MS then
        return
    end
    explosionCooldowns[ownerSrc] = now

    local playerInfo = RavnUtils.GetPlayerInfo(ownerSrc)

    if webhook then
        webhook.LogEvent("explosion", nil, {
            playerInfo    = playerInfo,
            explosionType = explosionType,
            isCaused      = true,
        })
    end
end)

-- =============================================================================
-- CHAT MESSAGE LOGGING
-- =============================================================================

-- Native chatMessage event (built into FiveM)
AddEventHandler("chatMessage", function(source, playerName, message)
    if not Config.EnabledLogs.chat then return end

    local src  = source
    local info = RavnUtils.GetPlayerInfo(src)

    -- Determine channel from message prefix
    local channel = GetChatChannel(message)
    if not channel then
        channel = "global"
    else
        -- Strip channel prefix from display message
        -- (we still log the full message)
    end

    if webhook then
        webhook.LogEvent("chat", nil, {
            playerInfo = info,
            channel    = channel,
            message    = message,
        })
    end
end)

-- =============================================================================
-- QBCore / QBox CHAT HOOKS
-- =============================================================================

-- Hook into common QBCore chat events
RegisterNetEvent("qb-chat:server:chatMessage", function(data)
    if not Config.EnabledLogs.chat then return end
    local src = source

    local info    = RavnUtils.GetPlayerInfo(src)
    local message = type(data) == "table" and (data.message or data.msg or "") or tostring(data)
    local channel = type(data) == "table" and (data.channel or "global") or "global"

    if webhook then
        webhook.LogEvent("chat", nil, {
            playerInfo = info,
            channel    = channel,
            message    = message,
        })
    end
end)

-- Hook into chat:server:sendMessage (some chat resources use this)
RegisterNetEvent("chat:server:sendMessage", function(message, channel)
    if not Config.EnabledLogs.chat then return end
    local src = source

    local info = RavnUtils.GetPlayerInfo(src)

    if webhook then
        webhook.LogEvent("chat", nil, {
            playerInfo = info,
            channel    = channel or "global",
            message    = message or "",
        })
    end
end)

-- =============================================================================
-- ADMIN COMMAND LOGGING
-- =============================================================================

-- Hook into common admin command events
RegisterNetEvent("qb-admin:server:logAction", function(action, targetName, details)
    if not Config.EnabledLogs.admin then return end
    local src = source

    local adminInfo = RavnUtils.GetPlayerInfo(src)

    if webhook then
        webhook.LogEvent("admin", nil, {
            adminInfo  = adminInfo,
            action     = action,
            targetName = targetName,
            details    = details,
        })
    end
end)

-- Generic admin logging event for custom admin scripts
RegisterNetEvent("ravn_logs:adminAction", function(action, targetName, details)
    if not Config.EnabledLogs.admin then return end
    local src = source

    local adminInfo = RavnUtils.GetPlayerInfo(src)

    if webhook then
        webhook.LogEvent("admin", nil, {
            adminInfo  = adminInfo,
            action     = action,
            targetName = targetName,
            details    = details,
        })
    end
end)

-- =============================================================================
-- F8 CONSOLE COMMAND LOGGING
-- =============================================================================

-- We hook into the native RegisterCommand to capture all registered commands
-- that are used via the F8 console. This runs after all other resources have
-- registered their commands, capturing their usage.

Citizen.CreateThread(function()
    -- Wait a bit for all resources to load
    Citizen.Wait(5000)

    if not Config.EnabledLogs.console then return end

    -- Since FiveM doesn't provide a global command-use event, we register
    -- our own hook that resources can trigger, AND we use a client-driven
    -- approach: when a player types in F8 and presses enter, the client
    -- forwards it to us.

    print("[ravn_logs] Console command logging enabled (client-driven)")
end)

-- Server-received console commands from client
RegisterNetEvent("ravn_logs:consoleCommand", function(commandName, fullCommand)
    if not Config.EnabledLogs.console then return end
    local src = source

    local info = RavnUtils.GetPlayerInfo(src)

    -- Filter: only log if it matches an admin command pattern
    if IsAdminCommand(commandName) or fullCommand:len() > 3 then
        if webhook then
            webhook.LogEvent("console", nil, {
                playerInfo  = info,
                commandName = commandName,
                fullCommand = fullCommand,
            })
        end
    end
end)

-- =============================================================================
-- EXPORT: Allow other resources to trigger logs
-- =============================================================================

exports("LogEvent", function(category, data)
    if not webhook then return end
    webhook.LogEvent(category, nil, data)
end)

exports("LogAdminAction", function(src, action, targetName, details)
    if not webhook then return end
    if not Config.EnabledLogs.admin then return end

    local adminInfo = RavnUtils.GetPlayerInfo(src)

    webhook.LogEvent("admin", nil, {
        adminInfo  = adminInfo,
        action     = action,
        targetName = targetName,
        details    = details,
    })
end)

exports("LogChat", function(src, channel, message)
    if not webhook then return end
    if not Config.EnabledLogs.chat then return end

    local info = RavnUtils.GetPlayerInfo(src)

    webhook.LogEvent("chat", nil, {
        playerInfo = info,
        channel    = channel,
        message    = message,
    })
end)

-- =============================================================================
-- DEATH COOLDOWN TABLE (must be after handler usage)
-- =============================================================================
deathCooldown = deathCooldown or {}
