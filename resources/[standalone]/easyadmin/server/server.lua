-- ============================================================================
--  EasyAdmin — Server Core
--  Sinister H-Town RP
-- ============================================================================

local activeMutes = {}
local frozenPlayers = {}
local reportsCache = {}
local bansCache = {}
local lastBanSync = 0
local lastReportSync = 0
local cacheTTL = 30

-- ============================================================================
--  Utility Functions
-- ============================================================================

local function GetPlayerIdentifiers(src)
    local ids = {}
    local count = GetNumPlayerIdentifiers(src)
    for i = 0, count - 1 do
        local id = GetPlayerIdentifier(src, i)
        ids[#ids + 1] = id
    end
    return ids
end

local function GetPlayerByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local ids = GetPlayerIdentifiers(tonumber(playerId))
        for _, id in ipairs(ids) do
            if id == identifier then
                return tonumber(playerId)
            end
        end
    end
    return nil
end

local function HasPermission(src, permission)
    if IsPlayerAceAllowed(src, "group.admin") then
        return true
    end
    if IsPlayerAceAllowed(src, "group.moderator") then
        local modPerms = Config.Permissions.moderator
        if modPerms[permission] then
            return true
        end
    end
    if IsPlayerAceAllowed(src, Config.Permissions.admin.ace) then
        return true
    end
    if IsPlayerAceAllowed(src, Config.Permissions.moderator.ace) then
        local modPerms = Config.Permissions.moderator
        if modPerms[permission] then
            return true
        end
    end
    return false
end

local function GetPlayerName(src)
    return GetPlayerName(src) or "Unknown"
end

local function GetHighestRole(src)
    if IsPlayerAceAllowed(src, "group.admin") or IsPlayerAceAllowed(src, Config.Permissions.admin.ace) then
        return "admin"
    end
    if IsPlayerAceAllowed(src, "group.moderator") or IsPlayerAceAllowed(src, Config.Permissions.moderator.ace) then
        return "moderator"
    end
    return "user"
end

local function Notify(src, message, notifyType)
    notifyType = notifyType or "info"
    TriggerClientEvent("easyadmin:notify", src, message, notifyType)
end

local function AdminLog(action, adminSrc, targetInfo, details)
    if not Config.Logging.enabled then return end
    local adminName = adminSrc and GetPlayerName(adminSrc) or "Console"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s -> %s | %s",
        timestamp, action, adminName, targetInfo or "N/A", details or "")
    print("^2[EasyAdmin]^7 " .. logEntry)

    if Config.Logging.webhookURL ~= "" then
        PerformHttpRequest(Config.Logging.webhookURL, function(err, text, headers) end, "POST",
            json.encode({ content = "```\n" .. logEntry .. "\n```" }),
            { ["Content-Type"] = "application/json" })
    end
end

-- ============================================================================
--  Player Management
-- ============================================================================

local function GetOnlinePlayers()
    local players = {}
    local playerList = GetPlayers()
    for _, playerId in ipairs(playerList) do
        local src = tonumber(playerId)
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        players[#players + 1] = {
            id = src,
            name = GetPlayerName(src),
            identifiers = GetPlayerIdentifiers(src),
            ping = GetPlayerPing(src),
            coords = { x = math.floor(coords.x), y = math.floor(coords.y), z = math.floor(coords.z) },
            isFrozen = frozenPlayers[src] or false,
            isMuted = activeMutes[src] and true or false,
            role = GetHighestRole(src)
        }
    end
    return players
end

local function GetPlayerInfo(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    return {
        id = src,
        name = GetPlayerName(src),
        identifiers = GetPlayerIdentifiers(src),
        ping = GetPlayerPing(src),
        coords = vec3(coords.x, coords.y, coords.z),
        isFrozen = frozenPlayers[src] or false,
        isMuted = activeMutes[src] and true or false,
        role = GetHighestRole(src),
        health = GetEntityHealth(ped),
        maxHealth = GetEntityMaxHealth(ped),
        armor = GetPedArmour(ped)
    }
end

-- ============================================================================
--  Resource Management
-- ============================================================================

local function HandleResourceAction(src, resource, action)
    if not Config.Resources.allowStart and action == "start" then
        Notify(src, "Resource starting is disabled.", "error")
        return false
    end
    if not Config.Resources.allowStop and action == "stop" then
        Notify(src, "Resource stopping is disabled.", "error")
        return false
    end
    if not Config.Resources.allowRestart and action == "restart" then
        Notify(src, "Resource restarting is disabled.", "error")
        return false
    end

    for _, protected in ipairs(Config.Resources.protectedResources) do
        if resource == protected then
            Notify(src, "Resource '" .. resource .. "' is protected and cannot be " .. action .. "ed.", "error")
            return false
        end
    end

    if action == "start" then
        StartResource(resource)
    elseif action == "stop" then
        StopResource(resource)
    elseif action == "restart" then
        StopResource(resource)
        Citizen.Wait(1000)
        StartResource(resource)
    end

    AdminLog("RESOURCE_" .. action:upper(), src, resource, "")
    Notify(src, "Resource '" .. resource .. "' " .. action .. "ed successfully.", "success")
    return true
end

local function GetResourceList()
    local resources = {}
    local count = GetNumResources()
    for i = 0, count - 1 do
        local name = GetResourceByFindIndex(i)
        local state = GetResourceState(name)
        resources[#resources + 1] = {
            name = name,
            state = state,
            isProtected = false
        }
    end
    for _, res in ipairs(resources) do
        for _, protected in ipairs(Config.Resources.protectedResources) do
            if res.name == protected then
                res.isProtected = true
                break
            end
        end
    end
    table.sort(resources, function(a, b) return a.name:lower() < b.name:lower() end)
    return resources
end

-- ============================================================================
--  Mute System
-- ============================================================================

local function MutePlayer(src, targetSrc, duration)
    activeMutes[targetSrc] = {
        mutedBy = src,
        mutedAt = os.time(),
        duration = duration
    }
    TriggerClientEvent("easyadmin:playerMuted", targetSrc, true)
    AdminLog("MUTE", src, GetPlayerName(targetSrc), "Duration: " .. (duration == 0 and "permanent" or duration .. "s"))

    if duration > 0 then
        Citizen.SetTimeout(duration * 1000, function()
            if activeMutes[targetSrc] then
                activeMutes[targetSrc] = nil
                TriggerClientEvent("easyadmin:playerMuted", targetSrc, false)
            end
        end)
    end
end

local function UnmutePlayer(src, targetSrc)
    if activeMutes[targetSrc] then
        activeMutes[targetSrc] = nil
        TriggerClientEvent("easyadmin:playerMuted", targetSrc, false)
        AdminLog("UNMUTE", src, GetPlayerName(targetSrc), "")
        return true
    end
    return false
end

local function IsPlayerMuted(targetSrc)
    return activeMutes[targetSrc] ~= nil
end

exports("IsPlayerMuted", IsPlayerMuted)

-- ============================================================================
--  Freeze System
-- ============================================================================

local function ToggleFreeze(src, targetSrc)
    local ped = GetPlayerPed(targetSrc)
    if frozenPlayers[targetSrc] then
        frozenPlayers[targetSrc] = nil
        FreezeEntityPosition(ped, false)
        TriggerClientEvent("easyadmin:freezeState", targetSrc, false)
        Notify(src, GetPlayerName(targetSrc) .. " has been unfrozen.", "success")
        AdminLog("UNFREEZE", src, GetPlayerName(targetSrc), "")
    else
        frozenPlayers[targetSrc] = true
        FreezeEntityPosition(ped, true)
        TriggerClientEvent("easyadmin:freezeState", targetSrc, true)
        Notify(src, GetPlayerName(targetSrc) .. " has been frozen.", "success")
        AdminLog("FREEZE", src, GetPlayerName(targetSrc), "")
    end
end

-- ============================================================================
--  Teleport System
-- ============================================================================

local function TeleportToPlayer(src, targetSrc)
    local targetPed = GetPlayerPed(targetSrc)
    local targetCoords = GetEntityCoords(targetPed)
    local adminPed = GetPlayerPed(src)
    SetEntityCoords(adminPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    Notify(src, "Teleported to " .. GetPlayerName(targetSrc), "success")
    AdminLog("TELEPORT_TO", src, GetPlayerName(targetSrc), "")
end

local function BringPlayer(src, targetSrc)
    local adminPed = GetPlayerPed(src)
    local adminCoords = GetEntityCoords(adminPed)
    local targetPed = GetPlayerPed(targetSrc)
    SetEntityCoords(targetPed, adminCoords.x + 2.0, adminCoords.y, adminCoords.z, false, false, false, false)
    Notify(src, GetPlayerName(targetSrc) .. " has been brought to you.", "success")
    Notify(targetSrc, "You have been teleported by an admin.", "info")
    AdminLog("BRING", src, GetPlayerName(targetSrc), "")
end

local function GotoPlayer(src, targetSrc)
    TeleportToPlayer(src, targetSrc)
end

-- ============================================================================
--  Slap System
-- ============================================================================

local function SlapPlayer(src, targetSrc, damage)
    damage = tonumber(damage) or 0
    local targetPed = GetPlayerPed(targetSrc)
    if damage > 0 then
        local health = GetEntityHealth(targetPed)
        SetEntityHealth(targetPed, math.max(0, health - damage))
    end
    ApplyDamageToPed(targetPed, 1, false)
    local vel = GetEntityVelocity(targetPed)
    SetEntityVelocity(targetPed, vel.x + math.random(-5, 5), vel.y + math.random(-5, 5), vel.z + 15.0)
    Notify(src, GetPlayerName(targetSrc) .. " has been slapped.", "success")
    Notify(targetSrc, "You have been slapped by an admin.", "warning")
    AdminLog("SLAP", src, GetPlayerName(targetSrc), "Damage: " .. damage)
end

-- ============================================================================
--  Screen Capture
-- ============================================================================

local function RequestScreenshot(src, targetSrc)
    if not Config.Screenshots.enabled then
        Notify(src, "Screenshots are disabled.", "error")
        return
    end
    TriggerClientEvent("easyadmin:requestScreenshot", targetSrc, src)
    Notify(src, "Requesting screenshot from " .. GetPlayerName(targetSrc) .. "...", "info")
    AdminLog("SCREENSHOT", src, GetPlayerName(targetSrc), "")
end

-- ============================================================================
--  Heal / Revive
-- ============================================================================

local function HealPlayer(src, targetSrc)
    local ped = GetPlayerPed(targetSrc)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    TriggerClientEvent("easyadmin:healEffect", targetSrc)
    Notify(src, GetPlayerName(targetSrc) .. " has been healed.", "success")
    Notify(targetSrc, "You have been healed by an admin.", "info")
    AdminLog("HEAL", src, GetPlayerName(targetSrc), "")
end

local function RevivePlayer(src, targetSrc)
    local ped = GetPlayerPed(targetSrc)
    local coords = GetEntityCoords(ped)
    TriggerClientEvent("easyadmin:revivePlayer", targetSrc, coords)
    Notify(src, GetPlayerName(targetSrc) .. " has been revived.", "success")
    Notify(targetSrc, "You have been revived by an admin.", "info")
    AdminLog("REVIVE", src, GetPlayerName(targetSrc), "")
end

-- ============================================================================
--  Noclip
-- ============================================================================

local function ToggleNoclip(src)
    TriggerClientEvent("easyadmin:toggleNoclip", src)
    Notify(src, "Noclip toggled.", "info")
    AdminLog("NOCLIP_TOGGLE", src, "", "")
end

-- ============================================================================
--  Announce
-- ============================================================================

local function SendAnnouncement(src, message)
    local senderName = src > 0 and GetPlayerName(src) or Config.ServerName
    TriggerClientEvent("chat:addMessage", -1, {
        color = { 191, 87, 0 },
        multiline = true,
        args = { "[" .. Config.ServerName .. " Announcement]", message }
    })
    TriggerClientEvent("easyadmin:announce", -1, senderName, message)
    AdminLog("ANNOUNCE", src, "All", message)
end

-- ============================================================================
--  Debug/Server Helpers
-- ============================================================================

local function GetServerInfo()
    return {
        name = Config.ServerName,
        onlinePlayers = #GetPlayers(),
        maxPlayers = GetConvarInt("sv_maxClients", 32),
        uptime = GetConvar("sv_uptime", "Unknown"),
        version = GetConvar("sv_version", "Unknown"),
        resources = GetNumResources(),
        oneSync = GetConvar("onesync", "off"),
    }
end

-- ============================================================================
--  Server Events
-- ============================================================================

RegisterNetEvent("easyadmin:server:openGui", function()
    local src = source
    if not HasPermission(src, "canViewAllPlayers") then
        Notify(src, "You do not have permission to open the admin panel.", "error")
        return
    end
    local players = GetOnlinePlayers()
    local resources = GetResourceList()
    local role = GetHighestRole(src)
    local perms = Config.Permissions[role] or Config.Permissions.moderator
    TriggerClientEvent("easyadmin:client:openGui", src, players, resources, role, perms)
end)

RegisterNetEvent("easyadmin:server:refreshData", function()
    local src = source
    if not HasPermission(src, "canViewAllPlayers") then return end
    local players = GetOnlinePlayers()
    local resources = GetResourceList()
    TriggerClientEvent("easyadmin:client:updatePlayers", src, players)
    TriggerClientEvent("easyadmin:client:updateResources", src, resources)
end)

RegisterNetEvent("easyadmin:server:getPlayerInfo", function(targetId)
    local src = source
    if not HasPermission(src, "canViewAllPlayers") then return end
    local info = GetPlayerInfo(tonumber(targetId))
    TriggerClientEvent("easyadmin:client:playerInfo", src, info)
end)

RegisterNetEvent("easyadmin:server:resourceAction", function(resource, action)
    local src = source
    if not HasPermission(src, "canManageResources") then
        Notify(src, "You do not have permission to manage resources.", "error")
        return
    end
    HandleResourceAction(src, resource, action)
end)

RegisterNetEvent("easyadmin:server:screenshotResponse", function(imageData, targetSrc)
    local src = source
    if not HasPermission(src, "canScreenshot") then return end
    AdminLog("SCREENSHOT_RESULT", targetSrc, GetPlayerName(src), "")
    local admins = GetOnlinePlayers()
    for _, admin in ipairs(admins) do
        if HasPermission(admin.id, "canScreenshot") then
            TriggerClientEvent("easyadmin:client:screenshotResult", admin.id, GetPlayerName(targetSrc), imageData)
        end
    end
end)

RegisterNetEvent("easyadmin:server:editPermissions", function(targetDiscord, aceGroup)
    local src = source
    if not HasPermission(src, "canEditPermissions") then
        Notify(src, "You do not have permission to edit permissions.", "error")
        return
    end
    local fullIdentifier = "identifier.discord:" .. targetDiscord
    ExecuteCommand("remove_principal " .. fullIdentifier .. " group.user")
    ExecuteCommand("add_principal " .. fullIdentifier .. " " .. aceGroup)
    ExecuteCommand("add_principal identifier.discord:" .. targetDiscord .. " " .. aceGroup)
    AdminLog("PERM_EDIT", src, targetDiscord, "Group: " .. aceGroup)
    Notify(src, "Permissions updated for discord ID: " .. targetDiscord, "success")
end)

-- ============================================================================
--  Client Callbacks
-- ============================================================================

RegisterNetEvent("easyadmin:server:kick", function(targetId, reason)
    local src = source
    if not HasPermission(src, "canKick") then
        Notify(src, "You do not have permission to kick players.", "error")
        return
    end
    reason = reason or Config.BanSystem.defaultBanReason
    local targetName = GetPlayerName(tonumber(targetId))
    DropPlayer(tonumber(targetId), "Kicked by " .. GetPlayerName(src) .. ": " .. reason)
    AdminLog("KICK", src, targetName, reason)
    Notify(src, targetName .. " has been kicked.", "success")
end)

RegisterNetEvent("easyadmin:server:ban", function(targetId, duration, reason)
    local src = source
    if duration == 0 and not HasPermission(src, "canPermBan") then
        Notify(src, "You do not have permission to permanently ban players.", "error")
        return
    end
    if duration > 0 and not HasPermission(src, "canBan") then
        Notify(src, "You do not have permission to ban players.", "error")
        return
    end
    local targetSrc = tonumber(targetId)
    local targetIds = GetPlayerIdentifiers(targetSrc)
    local targetName = GetPlayerName(targetSrc)
    reason = reason or Config.BanSystem.defaultBanReason

    local banData = {
        identifiers = targetIds,
        name = targetName,
        reason = reason,
        duration = tonumber(duration) or 0,
        bannedBy = GetPlayerName(src),
        bannerIdentifier = GetPlayerIdentifiers(src)[1] or "",
        ip = "0.0.0.0"
    }

    TriggerEvent("easyadmin:server:executeBan", targetSrc, banData)
    AdminLog("BAN", src, targetName, "Duration: " .. (duration == 0 and "permanent" or duration .. " days") .. " | " .. reason)
end)

RegisterNetEvent("easyadmin:server:mute", function(targetId, duration)
    local src = source
    if not HasPermission(src, "canMute") then
        Notify(src, "You do not have permission to mute players.", "error")
        return
    end
    MutePlayer(src, tonumber(targetId), tonumber(duration) or 300)
    Notify(src, GetPlayerName(tonumber(targetId)) .. " has been muted.", "success")
end)

RegisterNetEvent("easyadmin:server:unmute", function(targetId)
    local src = source
    if not HasPermission(src, "canMute") then return end
    if UnmutePlayer(src, tonumber(targetId)) then
        Notify(src, GetPlayerName(tonumber(targetId)) .. " has been unmuted.", "success")
    end
end)

RegisterNetEvent("easyadmin:server:tp", function(targetId)
    local src = source
    if not HasPermission(src, "canTeleport") then return end
    TeleportToPlayer(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:bring", function(targetId)
    local src = source
    if not HasPermission(src, "canTeleport") then return end
    BringPlayer(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:goto", function(targetId)
    local src = source
    if not HasPermission(src, "canTeleport") then return end
    GotoPlayer(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:slap", function(targetId, damage)
    local src = source
    if not HasPermission(src, "canSlap") then return end
    SlapPlayer(src, tonumber(targetId), tonumber(damage) or 0)
end)

RegisterNetEvent("easyadmin:server:freeze", function(targetId)
    local src = source
    if not HasPermission(src, "canFreeze") then return end
    ToggleFreeze(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:screenshot", function(targetId)
    local src = source
    if not HasPermission(src, "canScreenshot") then return end
    RequestScreenshot(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:revive", function(targetId)
    local src = source
    if not HasPermission(src, "canRevive") then return end
    RevivePlayer(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:heal", function(targetId)
    local src = source
    if not HasPermission(src, "canHeal") then return end
    HealPlayer(src, tonumber(targetId))
end)

RegisterNetEvent("easyadmin:server:noclip", function()
    local src = source
    if not HasPermission(src, "canNoclip") then return end
    ToggleNoclip(src)
end)

RegisterNetEvent("easyadmin:server:announce", function(message)
    local src = source
    if not HasPermission(src, "canAnnounce") then return end
    SendAnnouncement(src, message)
end)

RegisterNetEvent("easyadmin:server:getServerInfo", function()
    local src = source
    if not HasPermission(src, "canEditServerConfig") then return end
    local info = GetServerInfo()
    TriggerClientEvent("easyadmin:client:serverInfo", src, info)
end)

RegisterNetEvent("easyadmin:server:getConvars", function()
    local src = source
    if not HasPermission(src, "canEditServerConfig") then return end
    local convars = {
        { key = "sv_maxClients", value = GetConvar("sv_maxClients", "32"), label = "Max Players" },
        { key = "sv_hostname", value = GetConvar("sv_hostname", ""), label = "Server Hostname" },
        { key = "sv_licenseKeyToken", value = "***", label = "License Key", sensitive = true },
        { key = "tags", value = GetConvar("tags", ""), label = "Server Tags" },
        { key = "sv_projectName", value = GetConvar("sv_projectName", ""), label = "Project Name" },
        { key = "sv_projectDesc", value = GetConvar("sv_projectDesc", ""), label = "Project Description" },
    }
    TriggerClientEvent("easyadmin:client:convars", src, convars)
end)

RegisterNetEvent("easyadmin:server:setConvar", function(key, value)
    local src = source
    if not HasPermission(src, "canEditServerConfig") then
        Notify(src, "You do not have permission to edit server configuration.", "error")
        return
    end
    SetConvar(key, value)
    AdminLog("CONVAR_SET", src, key, value)
    Notify(src, "Convar '" .. key .. "' updated.", "success")
end)

RegisterNetEvent("easyadmin:server:requestBanlist", function()
    local src = source
    if not HasPermission(src, "canBanlist") then return end
    TriggerEvent("easyadmin:server:getBanlist", src)
end)

RegisterNetEvent("easyadmin:server:requestReports", function()
    local src = source
    if not HasPermission(src, "canViewReports") then return end
    TriggerEvent("easyadmin:server:getReports", src)
end)

-- ============================================================================
--  Chat Mute Hook
-- ============================================================================

AddEventHandler("chatMessage", function(source, name, message)
    if IsPlayerMuted(source) then
        TriggerClientEvent("chat:addMessage", source, {
            color = { 255, 0, 0 },
            args = { "[System]", "You are muted and cannot send messages." }
        })
        CancelEvent()
    end
end)

-- ============================================================================
--  Player Join Hook for Ban Check
-- ============================================================================

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    deferrals.update("Checking ban status...")

    if Config.BanSystem.checkOnJoin then
        local ids = GetPlayerIdentifiers(src)
        for _, id in ipairs(ids) do
            if bansCache[id] then
                local ban = bansCache[id]
                if ban.duration == 0 or (os.time() - ban.createdAt) < (ban.duration * 86400) then
                    local title = ban.duration == 0 and Config.BanSystem.permaBanMessageTitle or Config.BanSystem.tempBanMessageTitle
                    deferrals.done(title .. "\n\nReason: " .. ban.reason .. "\nBanned by: " .. ban.bannedBy .. "\nExpires: " .. (ban.duration == 0 and "Never" or os.date("%Y-%m-%d %H:%M:%S", ban.createdAt + (ban.duration * 86400))))
                    return
                end
            end
        end
    end

    deferrals.done()
end)

-- ============================================================================
--  Banlist Cache Refresh
-- ============================================================================

RegisterNetEvent("easyadmin:server:refreshBanCache", function(bans)
    bansCache = {}
    for _, ban in ipairs(bans) do
        for _, id in ipairs(ban.identifiers) do
            bansCache[id] = ban
        end
    end
    lastBanSync = os.time()
end)

-- Exports
exports("GetOnlinePlayers", GetOnlinePlayers)
exports("HasPermission", HasPermission)
exports("GetPlayerInfo", GetPlayerInfo)
exports("IsPlayerMuted", IsPlayerMuted)
exports("GetHighestRole", GetHighestRole)
exports("AdminLog", AdminLog)
