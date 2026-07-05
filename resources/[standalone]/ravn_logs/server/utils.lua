-- =============================================================================
-- ravn_logs - server/utils.lua
-- NDJSON logging, file rotation, cleanup, and utility functions
-- =============================================================================

local utils = {}

-- ---------------------------------------------------------------------------
-- INTERNAL STATE
-- ---------------------------------------------------------------------------
local currentDate   = os.date("%Y-%m-%d")
local logDirectory  = nil
local fileHandles   = {}
local lastCleanup   = nil

-- ---------------------------------------------------------------------------
-- Get absolute path to the log directory
-- ---------------------------------------------------------------------------
local function GetLogDirectory()
    if logDirectory then return logDirectory end
    local resourceName = GetCurrentResourceName()
    logDirectory = ("resources/%s/%s"):format(resourceName, Config.LogDirectory)
    return logDirectory
end

-- ---------------------------------------------------------------------------
-- Ensure the NDJSON log directory exists
-- ---------------------------------------------------------------------------
local function EnsureLogDirectory()
    local dir = GetLogDirectory()
    local f = io.open(dir .. ".dircheck", "w")
    if f then
        f:close()
        os.remove(dir .. ".dircheck")
    end
end

-- ---------------------------------------------------------------------------
-- Check if the date has changed; if so, close all file handles for rotation
-- ---------------------------------------------------------------------------
function utils.CheckDailyRotation()
    local today = os.date("%Y-%m-%d")
    if today ~= currentDate then
        for category, handle in pairs(fileHandles) do
            if handle then
                handle:close()
                fileHandles[category] = nil
            end
        end
        currentDate = today
    end
end

-- ---------------------------------------------------------------------------
-- Get or open the NDJSON file handle for a given category
-- ---------------------------------------------------------------------------
local function GetLogFileHandle(category)
    utils.CheckDailyRotation()
    if fileHandles[category] then
        return fileHandles[category]
    end
    EnsureLogDirectory()
    local dir  = GetLogDirectory()
    local path = ("%s%s_%s.json"):format(dir, currentDate, category)
    local f, err = io.open(path, "a")
    if not f then
        print("[ravn_logs] ERROR: Cannot open log file " .. path .. " - " .. tostring(err))
        return nil
    end
    f:setvbuf("line")
    fileHandles[category] = f
    return f
end

-- ---------------------------------------------------------------------------
-- Write a single JSON line to the NDJSON file for a category
-- ---------------------------------------------------------------------------
function utils.WriteJSONL(category, data)
    if not Config.EnabledLogs[category] then return end
    local f = GetLogFileHandle(category)
    if not f then return end
    local success, encoded = pcall(json.encode, data)
    if not success then
        print("[ravn_logs] ERROR: json.encode failed for category " .. category)
        return
    end
    f:write(encoded .. "\n")
    f:flush()
end

-- ---------------------------------------------------------------------------
-- Clean up old NDJSON log files beyond retention period
-- ---------------------------------------------------------------------------
function utils.CleanupOldLogs(days)
    days = days or Config.RetentionDays
    local dir   = GetLogDirectory()
    local cutoff = os.time() - (days * 86400)

    local listing = io.popen('dir /b "' .. dir .. '" 2>nul')
    if not listing then return end

    local count = 0
    for filename in listing:lines() do
        local path = dir .. filename
        local attr = io.popen('for %A in ("' .. path .. '") do @echo %~tA')
        -- On Windows, we use a simpler approach: attempt to parse date from filename
        local dateStr = filename:match("^(%d%d%d%d%-%d%d%-%d%d)_")
        if dateStr then
            local y, m, d = dateStr:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
            if y and m and d then
                local fileTime = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
                if fileTime and fileTime < cutoff then
                    os.remove(path)
                    count = count + 1
                end
            end
        end
    end
    listing:close()

    if count > 0 then
        print(("[ravn_logs] Cleaned up %d old log file(s)"):format(count))
    end
end

-- ---------------------------------------------------------------------------
-- Get comprehensive player info
-- ---------------------------------------------------------------------------
function utils.GetPlayerInfo(src)
    local info = {
        id          = src,
        name        = GetPlayerName(src) or "Unknown",
        identifiers = {},
        ip          = "0.0.0.0",
        license     = "unknown",
        steam       = "unknown",
        discord     = "unknown",
        xbl         = "unknown",
        liveid      = "unknown",
        fivem       = "unknown",
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local ident = GetPlayerIdentifier(src, i)
        if ident then
            local prefix, value = ident:match("^(%w+):(.+)$")
            if prefix and value then
                info.identifiers[#info.identifiers + 1] = ident
                local lower = prefix:lower()
                if lower == "license" then
                    info.license = value
                elseif lower == "steam" then
                    info.steam = value
                elseif lower == "discord" then
                    info.discord = value
                elseif lower == "xbl" then
                    info.xbl = value
                elseif lower == "live" then
                    info.liveid = value
                elseif lower == "fivem" then
                    info.fivem = value
                elseif lower == "ip" then
                    info.ip = value
                end
            end
        end
    end

    -- Try getting IP from player endpoint if not already set
    if info.ip == "0.0.0.0" then
        local rawEndpoint = GetPlayerEndpoint(src)
        if rawEndpoint then
            local ipPart = rawEndpoint:match("^(%d+%.%d+%.%d+%.%d+)")
            if ipPart then
                info.ip = ipPart
            end
        end
    end

    -- Get ped/player position
    local ped = GetPlayerPed(src)
    if ped and ped > 0 then
        local coords = GetEntityCoords(ped)
        if coords then
            info.position = {
                x = utils.Round(coords.x, 2),
                y = utils.Round(coords.y, 2),
                z = utils.Round(coords.z, 2),
            }
        end
    end

    return info
end

-- ---------------------------------------------------------------------------
-- Mask an IP address for privacy (show first two octets only)
-- ---------------------------------------------------------------------------
function utils.MaskIP(ip)
    if not ip or ip == "0.0.0.0" then return "N/A" end
    return ip:gsub("(%d+)%.(%d+)%.%d+%.%d+", "%1.%2.xxx.xxx")
end

-- ---------------------------------------------------------------------------
-- Round a number to n decimal places
-- ---------------------------------------------------------------------------
function utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- ---------------------------------------------------------------------------
-- Format a server timestamp (ISO-8601-ish, local time)
-- ---------------------------------------------------------------------------
function utils.FormatTimestamp(ts)
    ts = ts or os.time()
    return os.date("%Y-%m-%dT%H:%M:%S", ts)
end

-- ---------------------------------------------------------------------------
-- Format a server timestamp for display (human readable)
-- ---------------------------------------------------------------------------
function utils.FormatTimestampReadable(ts)
    ts = ts or os.time()
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- ---------------------------------------------------------------------------
-- Get the weapon name from a weapon hash
-- ---------------------------------------------------------------------------
function utils.GetWeaponName(hash)
    if type(hash) ~= "number" then return "Unknown" end
    local label  = GetWeaponNameFromHash and GetWeaponNameFromHash(hash) or nil
    local weapon = label or tostring(hash)
    return weapon
end

-- ---------------------------------------------------------------------------
-- Get short identifier for display (first 8 chars of license)
-- ---------------------------------------------------------------------------
function utils.GetShortIdentifier(info)
    if not info then return "???" end
    local lic = info.license or "unknown"
    if #lic > 8 then lic = lic:sub(1, 8) end
    return lic
end

-- ---------------------------------------------------------------------------
-- Determine if a death was self-inflicted
-- ---------------------------------------------------------------------------
function utils.IsSuicide(killerSrc, victimSrc)
    return killerSrc == victimSrc or killerSrc == -1
end

-- ---------------------------------------------------------------------------
-- Null-safe table merge
-- ---------------------------------------------------------------------------
function utils.Merge(a, b)
    local t = {}
    if a then for k, v in pairs(a) do t[k] = v end end
    if b then for k, v in pairs(b) do t[k] = v end end
    return t
end

-- =============================================================================
-- CLIENT-SHARED FUNCTIONS (strip server-only APIs for client use)
-- =============================================================================

if IsDuplicityVersion then
    -- SERVER: Export utility table
    _G.RavnUtils = utils
else
    -- CLIENT: Provide stub functions that work on client
    local clientUtils = {}
    function clientUtils.FormatTimestamp(ts)
        ts = ts or os.time()
        return os.date("%Y-%m-%dT%H:%M:%S", ts)
    end
    function clientUtils.FormatTimestampReadable(ts)
        ts = ts or os.time()
        return os.date("%Y-%m-%d %H:%M:%S", ts)
    end
    function clientUtils.Round(num, decimals)
        local mult = 10 ^ (decimals or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    function clientUtils.GetWeaponName(hash)
        if type(hash) ~= "number" then return "Unknown" end
        local label = Citizen.InvokeNative(0xBF0FD6E56C964FCB, hash, 0) or tostring(hash)
        return label
    end
    _G.RavnUtils = clientUtils
end
