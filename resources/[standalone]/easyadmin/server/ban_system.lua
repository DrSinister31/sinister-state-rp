-- ============================================================================
--  EasyAdmin — Ban System (MariaDB via oxmysql)
--  Sinister H-Town RP
-- ============================================================================

local dbConfig = Config.Database
local banTable = dbConfig.banTable
local tableCreated = false
local banCacheInitialized = false

-- ============================================================================
--  Database Helpers
-- ============================================================================

local function CreateBanTable()
    if tableCreated then return end
    local query = [[
        CREATE TABLE IF NOT EXISTS `]] .. banTable .. [[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifiers` LONGTEXT NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `reason` TEXT NOT NULL,
            `duration` INT NOT NULL DEFAULT 0,
            `bannedBy` VARCHAR(255) NOT NULL DEFAULT 'Console',
            `bannerIdentifier` VARCHAR(255) DEFAULT '',
            `ip` VARCHAR(45) DEFAULT '0.0.0.0',
            `active` TINYINT(1) NOT NULL DEFAULT 1,
            `createdAt` INT NOT NULL,
            `unbannedAt` INT DEFAULT NULL,
            `unbannedBy` VARCHAR(255) DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    MySQL.query(query, {}, function(result)
        tableCreated = true
        print("^2[EasyAdmin]^7 Ban table '" .. banTable .. "' ready.")
    end)
end

local function GetActiveBans()
    local p = promise.new()
    MySQL.query("SELECT * FROM `" .. banTable .. "` WHERE `active` = 1 ORDER BY `createdAt` DESC", {},
        function(result)
            p:resolve(result or {})
        end)
    return Citizen.Await(p)
end

local function RefreshBanCache()
    local bans = GetActiveBans()
    local cache = {}
    for _, ban in ipairs(bans) do
        if ban.identifiers then
            local ids = json.decode(ban.identifiers)
            if ids then
                ban.decodedIdentifiers = ids
                for _, id in ipairs(ids) do
                    cache[id] = ban
                end
            end
        end
    end
    TriggerEvent("easyadmin:server:refreshBanCache", bans)
    TriggerClientEvent("easyadmin:client:banCacheUpdate", -1, bans)
    banCacheInitialized = true
    return bans
end

-- ============================================================================
--  Ban Operations
-- ============================================================================

RegisterNetEvent("easyadmin:server:executeBan", function(targetSrc, banData)
    local targetName = GetPlayerName(targetSrc)
    local identifiers = banData.identifiers or {}
    local idsJson = json.encode(identifiers)
    local duration = banData.duration or 0
    local reason = banData.reason or Config.BanSystem.defaultBanReason
    local bannedBy = banData.bannedBy or "Console"
    local bannerIdentifier = banData.bannerIdentifier or ""
    local ip = banData.ip or "0.0.0.0"
    local createdAt = os.time()

    local query = [[
        INSERT INTO `]] .. banTable .. [[`
        (`identifiers`, `name`, `reason`, `duration`, `bannedBy`, `bannerIdentifier`, `ip`, `active`, `createdAt`)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
    ]]
    local params = { idsJson, targetName, reason, duration, bannedBy, bannerIdentifier, ip, createdAt }

    MySQL.insert(query, params, function(insertId)
        if insertId then
            print("^2[EasyAdmin]^7 Ban #" .. insertId .. " created for " .. targetName)
        end

        -- Evasion check — ban all matching identifiers
        if Config.BanSystem.evasionDetection then
            for _, id in ipairs(identifiers) do
                local targetPlayer = nil
                for _, p in ipairs(GetPlayers()) do
                    for i = 0, GetNumPlayerIdentifiers(tonumber(p)) - 1 do
                        if GetPlayerIdentifier(tonumber(p), i) == id then
                            targetPlayer = tonumber(p)
                            break
                        end
                    end
                    if targetPlayer then break end
                end
                if targetPlayer and targetPlayer ~= targetSrc then
                    local evasionDuration = Config.BanSystem.evasionDuration or 0
                    local evasionBanData = {
                        identifiers = {},
                        name = GetPlayerName(targetPlayer),
                        reason = "Ban evasion (linked to " .. targetName .. ")",
                        duration = evasionDuration,
                        bannedBy = bannedBy,
                        bannerIdentifier = bannerIdentifier,
                        ip = "0.0.0.0"
                    }
                    for j = 0, GetNumPlayerIdentifiers(targetPlayer) - 1 do
                        evasionBanData.identifiers[#evasionBanData.identifiers + 1] = GetPlayerIdentifier(targetPlayer, j)
                    end
                    TriggerEvent("easyadmin:server:executeBan", targetPlayer, evasionBanData)
                end
            end
        end

        local banMessage = Config.BanSystem.banMessageTitle .. "\n\nReason: " .. reason
        if duration > 0 then
            banMessage = banMessage .. "\nDuration: " .. duration .. " days"
            banMessage = banMessage .. "\nExpires: " .. os.date("%Y-%m-%d %H:%M:%S", createdAt + (duration * 86400))
        else
            banMessage = banMessage .. "\nThis is a permanent ban."
        end
        banMessage = banMessage .. "\nBanned by: " .. bannedBy

        DropPlayer(targetSrc, banMessage)

        Citizen.Wait(2000)
        RefreshBanCache()
    end)
end)

RegisterNetEvent("easyadmin:server:executeUnban", function(src, identifier)
    local query = "UPDATE `" .. banTable .. "` SET `active` = 0, `unbannedAt` = ?, `unbannedBy` = ? WHERE JSON_CONTAINS(`identifiers`, ?) AND `active` = 1"
    local params = { os.time(), src > 0 and GetPlayerName(src) or "Console", json.encode(identifier) }

    MySQL.update(query, params, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            Notify(src, "Player with identifier '" .. identifier .. "' has been unbanned.", "success")
        else
            Notify(src, "No active ban found for identifier '" .. identifier .. "'.", "error")
        end
        RefreshBanCache()
    end)
end)

local function Notify(src, msg, ntype)
    TriggerClientEvent("easyadmin:notify", src, msg, ntype or "info")
end

-- ============================================================================
--  Banlist for Admin Panel
-- ============================================================================

RegisterNetEvent("easyadmin:server:getBanlist", function(src)
    local bans = GetActiveBans()
    TriggerClientEvent("easyadmin:client:banlist", src, bans)
end)

RegisterNetEvent("easyadmin:server:getBanHistory", function(src, targetIdentifier)
    local query = "SELECT * FROM `" .. banTable .. "` WHERE JSON_CONTAINS(`identifiers`, ?) ORDER BY `createdAt` DESC"
    MySQL.query(query, { json.encode(targetIdentifier) }, function(result)
        TriggerClientEvent("easyadmin:client:banHistory", src, targetIdentifier, result or {})
    end)
end)

-- ============================================================================
--  Player Join Ban Check
-- ============================================================================

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    deferrals.update("Verifying identity...")

    local playerIdentifiers = {}
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        playerIdentifiers[#playerIdentifiers + 1] = GetPlayerIdentifier(src, i)
    end

    if Config.BanSystem.checkOnJoin then
        local bans = GetActiveBans()

        for _, ban in ipairs(bans) do
            if ban.identifiers then
                local banIds = json.decode(ban.identifiers)
                if banIds then
                    for _, bid in ipairs(banIds) do
                        for _, pid in ipairs(playerIdentifiers) do
                            if bid == pid then
                                if ban.duration == 0 then
                                    deferrals.done(Config.BanSystem.permaBanMessageTitle ..
                                        "\n\nReason: " .. (ban.reason or "No reason") ..
                                        "\nBanned by: " .. (ban.bannedBy or "Unknown") ..
                                        "\nBan ID: #" .. (ban.id or "N/A"))
                                    CancelEvent()
                                    return
                                else
                                    local expiry = ban.createdAt + (ban.duration * 86400)
                                    if os.time() < expiry then
                                        deferrals.done(Config.BanSystem.tempBanMessageTitle ..
                                            "\n\nReason: " .. (ban.reason or "No reason") ..
                                            "\nBanned by: " .. (ban.bannedBy or "Unknown") ..
                                            "\nExpires: " .. os.date("%Y-%m-%d %H:%M:%S", expiry) ..
                                            "\nBan ID: #" .. (ban.id or "N/A"))
                                        CancelEvent()
                                        return
                                    else
                                        MySQL.update("UPDATE `" .. banTable .. "` SET `active` = 0 WHERE `id` = ?",
                                            { ban.id }, function() end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    deferrals.done()
end)

-- ============================================================================
--  Temp Ban Expiry Cleanup (runs every 60 seconds)
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local bans = GetActiveBans()
        local now = os.time()

        for _, ban in ipairs(bans) do
            if ban.duration > 0 then
                local expiry = ban.createdAt + (ban.duration * 86400)
                if now >= expiry then
                    MySQL.update("UPDATE `" .. banTable .. "` SET `active` = 0 WHERE `id` = ?",
                        { ban.id }, function(rowsChanged)
                            if rowsChanged and rowsChanged > 0 then
                                print("^3[EasyAdmin]^7 Temp ban #" .. ban.id .. " for " .. (ban.name or "Unknown") .. " expired.")
                            end
                        end)
                end
            end
        end

        if bans and #bans > 0 then
            RefreshBanCache()
        end
    end
end)

-- ============================================================================
--  Initialization
-- ============================================================================

Citizen.CreateThread(function()
    CreateBanTable()
    Citizen.Wait(1000)
    RefreshBanCache()
    print("^2[EasyAdmin]^7 Ban system initialized with " .. #(GetActiveBans()) .. " active bans.")
end)

AddEventHandler("onServerResourceStart", function(resourceName)
    if resourceName == "oxmysql" or resourceName == GetCurrentResourceName() then
        Citizen.Wait(2000)
        CreateBanTable()
        RefreshBanCache()
    end
end)
