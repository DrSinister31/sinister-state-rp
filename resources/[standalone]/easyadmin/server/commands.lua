-- ============================================================================
--  EasyAdmin — Server Commands
--  Sinister H-Town RP
-- ============================================================================

local function Notify(src, msg, ntype)
    TriggerClientEvent("easyadmin:notify", src, msg, ntype or "info")
end

local function HasPermission(src, perm)
    if IsPlayerAceAllowed(src, "group.admin") then return true end
    if IsPlayerAceAllowed(src, "group.moderator") then
        return Config.Permissions.moderator[perm] == true
    end
    return false
end

local function GetTargetFromArg(arg)
    local t = tonumber(arg)
    if not t then
        for _, p in ipairs(GetPlayers()) do
            if GetPlayerName(tonumber(p)):lower():find(arg:lower(), 1, true) then
                return tonumber(p)
            end
        end
        return nil
    end
    return t
end

-- ============================================================================
--  /kick [id] [reason]
-- ============================================================================
RegisterCommand(Config.Commands.kick:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canKick") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /kick [id] [reason]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    local reason = ""
    for i = 2, #args do reason = reason .. args[i] .. " " end
    reason = reason:gsub("^%s*(.-)%s*$", "%1")
    if reason == "" then reason = Config.BanSystem.defaultBanReason end

    local targetName = GetPlayerName(target)
    DropPlayer(target, "Kicked by " .. (src > 0 and GetPlayerName(src) or "Console") .. ": " .. reason)
    Notify(src, targetName .. " has been kicked.", "success")
    TriggerEvent("easyadmin:server:adminLog", "KICK", src, targetName, reason)
end, false)

-- ============================================================================
--  /ban [id] [duration_days] [reason]
-- ============================================================================
RegisterCommand(Config.Commands.ban:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canBan") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /ban [id] [duration_days] [reason] (0 = perma)", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    local duration = tonumber(args[2]) or 0
    if duration < 0 then duration = 0 end
    if duration == 0 and src > 0 and not HasPermission(src, "canPermBan") then
        Notify(src, "You do not have permission for permanent bans.", "error")
        return
    end

    local reason = ""
    for i = 3, #args do reason = reason .. args[i] .. " " end
    reason = reason:gsub("^%s*(.-)%s*$", "%1")
    if reason == "" then reason = Config.BanSystem.defaultBanReason end

    local targetIds = {}
    for i = 0, GetNumPlayerIdentifiers(target) - 1 do
        targetIds[#targetIds + 1] = GetPlayerIdentifier(target, i)
    end

    local banData = {
        identifiers = targetIds,
        name = GetPlayerName(target),
        reason = reason,
        duration = duration,
        bannedBy = src > 0 and GetPlayerName(src) or "Console",
        bannerIdentifier = src > 0 and GetPlayerIdentifiers(src)[1] or "console",
        ip = "0.0.0.0"
    }

    TriggerEvent("easyadmin:server:executeBan", target, banData)
    Notify(src, GetPlayerName(target) .. " banned (" .. (duration == 0 and "permanent" or duration .. " days") .. ").", "success")
end, false)

-- ============================================================================
--  /unban [identifier]
-- ============================================================================
RegisterCommand(Config.Commands.unban:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canUnban") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /unban [identifier]", "error")
        return
    end
    local identifier = args[1]
    TriggerEvent("easyadmin:server:executeUnban", src, identifier)
end, false)

-- ============================================================================
--  /mute [id] [duration_seconds]
-- ============================================================================
RegisterCommand(Config.Commands.mute:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canMute") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /mute [id] [duration_seconds]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    local duration = tonumber(args[2]) or 300
    TriggerEvent("easyadmin:server:mute", src, target, duration)
end, false)

-- ============================================================================
--  /tp [id] — teleport to player
-- ============================================================================
RegisterCommand(Config.Commands.tp:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canTeleport") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /tp [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:tp", src, target)
end, false)

-- ============================================================================
--  /bring [id] — bring player to admin
-- ============================================================================
RegisterCommand(Config.Commands.bring:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canTeleport") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /bring [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:bring", src, target)
end, false)

-- ============================================================================
--  /goto [id] — same as /tp
-- ============================================================================
RegisterCommand(Config.Commands.goto:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canTeleport") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /goto [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:goto", src, target)
end, false)

-- ============================================================================
--  /slap [id] [damage]
-- ============================================================================
RegisterCommand(Config.Commands.slap:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canSlap") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /slap [id] [damage]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    local damage = tonumber(args[2]) or 0
    TriggerEvent("easyadmin:server:slap", src, target, damage)
end, false)

-- ============================================================================
--  /freeze [id] — toggle freeze
-- ============================================================================
RegisterCommand(Config.Commands.freeze:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canFreeze") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /freeze [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:freeze", src, target)
end, false)

-- ============================================================================
--  /screenshot [id]
-- ============================================================================
RegisterCommand(Config.Commands.screenshot:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canScreenshot") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /screenshot [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:screenshot", src, target)
end, false)

-- ============================================================================
--  /revive [id]
-- ============================================================================
RegisterCommand(Config.Commands.revive:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canRevive") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /revive [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:revive", src, target)
end, false)

-- ============================================================================
--  /heal [id]
-- ============================================================================
RegisterCommand(Config.Commands.heal:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canHeal") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /heal [id]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:heal", src, target)
end, false)

-- ============================================================================
--  /noclip
-- ============================================================================
RegisterCommand(Config.Commands.noclip:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canNoclip") then
        Notify(src, "No permission.", "error")
        return
    end
    TriggerEvent("easyadmin:server:noclip", src)
end, false)

-- ============================================================================
--  /announce [message]
-- ============================================================================
RegisterCommand(Config.Commands.announce:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canAnnounce") then
        Notify(src, "No permission.", "error")
        return
    end
    if not args[1] then
        Notify(src, "Usage: /announce [message]", "error")
        return
    end
    local message = ""
    for i = 1, #args do message = message .. args[i] .. " " end
    message = message:gsub("^%s*(.-)%s*$", "%1")
    TriggerEvent("easyadmin:server:announce", src, message)
end, false)

-- ============================================================================
--  /players
-- ============================================================================
RegisterCommand(Config.Commands.players:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canViewAllPlayers") then return end
    local players = GetPlayers()
    local msg = "Online Players (" .. #players .. "):\n"
    for _, p in ipairs(players) do
        local pid = tonumber(p)
        msg = msg .. "[" .. pid .. "] " .. GetPlayerName(pid) .. " | Ping: " .. GetPlayerPing(pid) .. "\n"
    end
    Notify(src, msg, "info")
end, false)

-- ============================================================================
--  /admin — opens GUI
-- ============================================================================
RegisterCommand(Config.Commands.admin:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if src > 0 and not HasPermission(src, "canViewAllPlayers") then
        Notify(src, "You do not have permission.", "error")
        return
    end
    TriggerEvent("easyadmin:server:openGui", src)
end, false)

-- ============================================================================
--  /report [id] [message] — player report
-- ============================================================================
RegisterCommand(Config.Commands.report:gsub("/", ""), function(source, args, rawCommand)
    local src = source
    if not args[1] then
        Notify(src, "Usage: /report [id] [message]", "error")
        return
    end
    local target = GetTargetFromArg(args[1])
    if not target then
        Notify(src, "Player not found.", "error")
        return
    end
    local message = ""
    for i = 2, #args do message = message .. args[i] .. " " end
    message = message:gsub("^%s*(.-)%s*$", "%1")
    if #message < Config.Reports.minMessageLength then
        Notify(src, "Message must be at least " .. Config.Reports.minMessageLength .. " characters.", "error")
        return
    end
    TriggerEvent("easyadmin:server:createReport", src, target, message, args[1])
end, false)
