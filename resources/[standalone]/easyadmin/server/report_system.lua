-- ============================================================================
--  EasyAdmin — Report System (MariaDB via oxmysql)
--  Sinister H-Town RP
-- ============================================================================

local dbConfig = Config.Database
local reportTable = dbConfig.reportTable
local tableCreated = false
local playerCooldowns = {}

-- ============================================================================
--  Database Helpers
-- ============================================================================

local function CreateReportTable()
    if tableCreated then return end
    local query = [[
        CREATE TABLE IF NOT EXISTS `]] .. reportTable .. [[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `reporterName` VARCHAR(255) NOT NULL,
            `reporterId` INT NOT NULL,
            `reporterIdentifiers` LONGTEXT DEFAULT NULL,
            `targetName` VARCHAR(255) DEFAULT NULL,
            `targetId` INT DEFAULT NULL,
            `targetIdentifiers` LONGTEXT DEFAULT NULL,
            `message` TEXT NOT NULL,
            `category` VARCHAR(100) DEFAULT 'Other',
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `assignedTo` VARCHAR(255) DEFAULT NULL,
            `resolution` TEXT DEFAULT NULL,
            `createdAt` INT NOT NULL,
            `resolvedAt` INT DEFAULT NULL,
            `resolvedBy` VARCHAR(255) DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    MySQL.query(query, {}, function(result)
        tableCreated = true
        print("^2[EasyAdmin]^7 Report table '" .. reportTable .. "' ready.")
    end)
end

local function GetPendingReports()
    local p = promise.new()
    MySQL.query("SELECT * FROM `" .. reportTable .. "` WHERE `status` = 'pending' ORDER BY `createdAt` DESC", {},
        function(result)
            p:resolve(result or {})
        end)
    return Citizen.Await(p)
end

local function NotifyAdmins(message, notifyType)
    local players = GetPlayers()
    for _, p in ipairs(players) do
        local src = tonumber(p)
        if IsPlayerAceAllowed(src, "group.admin") or IsPlayerAceAllowed(src, "group.moderator") then
            TriggerClientEvent("easyadmin:notify", src, message, notifyType or "info")
            TriggerClientEvent("chat:addMessage", src, {
                color = { 191, 87, 0 },
                args = { "[EasyAdmin Report]", message }
            })
        end
    end
end

-- ============================================================================
--  Report Creation
-- ============================================================================

RegisterNetEvent("easyadmin:server:createReport", function(src, targetSrc, message, rawTarget)
    local reporterSrc = src
    if playerCooldowns[reporterSrc] and os.time() - playerCooldowns[reporterSrc] < Config.Reports.cooldown then
        TriggerClientEvent("easyadmin:notify", reporterSrc, "Please wait before submitting another report.", "error")
        return
    end

    if #message < Config.Reports.minMessageLength then
        TriggerClientEvent("easyadmin:notify", reporterSrc, "Message too short (min " .. Config.Reports.minMessageLength .. " chars).", "error")
        return
    end

    if #message > Config.Reports.maxMessageLength then
        TriggerClientEvent("easyadmin:notify", reporterSrc, "Message too long (max " .. Config.Reports.maxMessageLength .. " chars).", "error")
        return
    end

    local reporterName = GetPlayerName(reporterSrc)
    local reporterIds = {}
    for i = 0, GetNumPlayerIdentifiers(reporterSrc) - 1 do
        reporterIds[#reporterIds + 1] = GetPlayerIdentifier(reporterSrc, i)
    end

    local targetName = GetPlayerName(targetSrc)
    local targetIds = {}
    for i = 0, GetNumPlayerIdentifiers(targetSrc) - 1 do
        targetIds[#targetIds + 1] = GetPlayerIdentifier(targetSrc, i)
    end

    local query = [[
        INSERT INTO `]] .. reportTable .. [[`
        (`reporterName`, `reporterId`, `reporterIdentifiers`, `targetName`, `targetId`, `targetIdentifiers`,
         `message`, `category`, `status`, `createdAt`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
    ]]
    local params = {
        reporterName,
        reporterSrc,
        json.encode(reporterIds),
        targetName,
        targetSrc,
        json.encode(targetIds),
        message,
        "Other",
        os.time()
    }

    MySQL.insert(query, params, function(insertId)
        if insertId then
            playerCooldowns[reporterSrc] = os.time()
            TriggerClientEvent("easyadmin:notify", reporterSrc, "Report #" .. insertId .. " submitted.", "success")

            if Config.Reports.notifyAdmins then
                NotifyAdmins("New report #" .. insertId .. " from " .. reporterName .. " against " .. targetName .. ": " .. message:sub(1, 80) .. (message:len() > 80 and "..." or ""), "warning")
            end

            local admins = {}
            local players = GetPlayers()
            for _, p in ipairs(players) do
                local psrc = tonumber(p)
                if IsPlayerAceAllowed(psrc, "group.admin") or IsPlayerAceAllowed(psrc, "group.moderator") then
                    admins[#admins + 1] = psrc
                end
            end
            for _, adminSrc in ipairs(admins) do
                local pendingReports = GetPendingReports()
                TriggerClientEvent("easyadmin:client:updateReports", adminSrc, pendingReports)
            end
        end
    end)
end)

-- ============================================================================
--  Get Reports
-- ============================================================================

RegisterNetEvent("easyadmin:server:getReports", function(src)
    local reports = GetPendingReports()
    TriggerClientEvent("easyadmin:client:updateReports", src, reports)
end)

-- ============================================================================
--  Resolve Report
-- ============================================================================

RegisterNetEvent("easyadmin:server:resolveReport", function(reportId, resolution)
    local src = source
    if not IsPlayerAceAllowed(src, "group.admin") and not IsPlayerAceAllowed(src, "group.moderator") then
        TriggerClientEvent("easyadmin:notify", src, "No permission to resolve reports.", "error")
        return
    end

    local adminName = GetPlayerName(src)
    local query = [[
        UPDATE `]] .. reportTable .. [[`
        SET `status` = 'resolved', `resolvedAt` = ?, `resolvedBy` = ?, `resolution` = ?
        WHERE `id` = ?
    ]]
    local params = { os.time(), adminName, resolution or "Resolved", reportId }

    MySQL.update(query, params, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            TriggerClientEvent("easyadmin:notify", src, "Report #" .. reportId .. " resolved.", "success")

            local pendingReports = GetPendingReports()
            local players = GetPlayers()
            for _, p in ipairs(players) do
                local psrc = tonumber(p)
                if IsPlayerAceAllowed(psrc, "group.admin") or IsPlayerAceAllowed(psrc, "group.moderator") then
                    TriggerClientEvent("easyadmin:client:updateReports", psrc, pendingReports)
                end
            end
        end
    end)
end)

-- ============================================================================
--  Get Report History
-- ============================================================================

RegisterNetEvent("easyadmin:server:getReportHistory", function(src, targetIdentifier)
    local query = "SELECT * FROM `" .. reportTable .. "` WHERE JSON_CONTAINS(`reporterIdentifiers`, ?) OR JSON_CONTAINS(`targetIdentifiers`, ?) ORDER BY `createdAt` DESC LIMIT 50"
    MySQL.query(query, { json.encode(targetIdentifier), json.encode(targetIdentifier) }, function(result)
        TriggerClientEvent("easyadmin:client:reportHistory", src, targetIdentifier, result or {})
    end)
end)

-- ============================================================================
--  Chat /report command (client-triggered)
-- ============================================================================

RegisterNetEvent("easyadmin:server:chatReport", function(targetId, message)
    local src = source
    local target = tonumber(targetId)
    if not target then
        TriggerClientEvent("easyadmin:notify", src, "Player not found.", "error")
        return
    end
    if GetPlayerPing(target) == 0 then
        TriggerClientEvent("easyadmin:notify", src, "Player not found.", "error")
        return
    end
    TriggerEvent("easyadmin:server:createReport", src, target, message, tostring(targetId))
end)

-- ============================================================================
--  Initialization
-- ============================================================================

Citizen.CreateThread(function()
    CreateReportTable()
    print("^2[EasyAdmin]^7 Report system initialized.")
end)

AddEventHandler("onServerResourceStart", function(resourceName)
    if resourceName == "oxmysql" or resourceName == GetCurrentResourceName() then
        Citizen.Wait(2000)
        CreateReportTable()
    end
end)
