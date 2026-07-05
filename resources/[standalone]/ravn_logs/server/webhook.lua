-- =============================================================================
-- ravn_logs - server/webhook.lua
-- Discord webhook queue system with rate-limit handling and retry logic
-- =============================================================================

local webhook = {}

-- ---------------------------------------------------------------------------
-- QUEUE STATE
-- ---------------------------------------------------------------------------
local queue       = {}          -- { url, payload, retries, category }
local isProcessing = false
local lastSendTime = {}         -- url -> last HTTP send timestamp

-- ---------------------------------------------------------------------------
-- INTERNAL: Enforce rate limit (Config.Queue.MessagesPerMin per URL)
-- ---------------------------------------------------------------------------
local function RateLimitWait(url)
    local last = lastSendTime[url]
    if not last then return end
    local minIntervalMs = math.floor(60000 / Config.Queue.MessagesPerMin)
    local elapsed = GetGameTimer() - last
    if elapsed < minIntervalMs then
        Citizen.Wait(minIntervalMs - elapsed)
    end
end

-- ---------------------------------------------------------------------------
-- INTERNAL: Send a single payload via PerformHttpRequest
-- ---------------------------------------------------------------------------
local function SendPayload(url, payload, timeout)
    timeout = timeout or 5000
    local promise = promise.new()

    PerformHttpRequest(url, function(errCode, responseText, headers, statusCode)
        -- statusCode may be nil in edge cases; treat as failure
        promise:resolve({
            err     = (errCode ~= 200) and errCode or nil,
            status  = statusCode or 0,
            body    = responseText or "",
            headers = headers or {},
        })
    end, "POST", payload, {
        ["Content-Type"] = "application/json",
    }, timeout)

    return promise
end

-- ---------------------------------------------------------------------------
-- INTERNAL: Send with retry (exponential backoff) — synchronous helper
-- ---------------------------------------------------------------------------
local function SendWithRetry(url, payload, maxRetries)
    maxRetries = maxRetries or Config.Queue.MaxRetries
    local attempt = 0
    local delay   = Config.Queue.RetryDelayMs

    while attempt <= maxRetries do
        RateLimitWait(url)

        local p  = SendPayload(url, payload)
        local res = Citizen.Await(p)

        lastSendTime[url] = GetGameTimer()

        if res.err then
            attempt = attempt + 1
            if attempt > maxRetries then
                print(("[ravn_logs] ERROR: Failed after %d retries for %s (HTTP err: %s)"):format(maxRetries, url, res.err))
                return false
            end
            print(("[ravn_logs] Retry %d/%d for %s after %d ms (err: %s)"):format(attempt, maxRetries, url, delay, res.err))
            Citizen.Wait(delay)
            delay = delay * 2
        elseif res.status == 429 then
            attempt = attempt + 1
            if attempt > maxRetries then
                print(("[ravn_logs] ERROR: Rate-limited after %d retries for %s"):format(maxRetries, url))
                return false
            end
            -- Try to parse retry_after from headers, default to delay
            local retryAfter = tonumber(res.headers["Retry-After"] or res.headers["retry-after"]) or (delay / 1000)
            local waitMs = math.floor(retryAfter * 1000)
            print(("[ravn_logs] Rate limited (429) for %s, waiting %d ms (attempt %d/%d)"):format(url, waitMs, attempt, maxRetries))
            Citizen.Wait(waitMs)
        elseif res.status >= 200 and res.status < 300 then
            return true
        else
            attempt = attempt + 1
            if attempt > maxRetries then
                print(("[ravn_logs] ERROR: Failed after %d retries for %s (HTTP %d)"):format(maxRetries, url, res.status))
                return false
            end
            Citizen.Wait(delay)
            delay = delay * 2
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Process the pending queue (called every ProcessInterval ms)
-- ---------------------------------------------------------------------------
function webhook.ProcessQueue()
    if isProcessing then return end
    if #queue == 0 then return end

    isProcessing = true

    -- Dequeue oldest message
    local entry = table.remove(queue, 1)
    if not entry then
        isProcessing = false
        return
    end

    local success = SendWithRetry(entry.url, entry.payload, Config.Queue.MaxRetries)

    if not success then
        print(("[ravn_logs] Dropped message for %s after max retries (category: %s)"):format(entry.url, entry.category or "unknown"))
    end

    isProcessing = false
end

-- ---------------------------------------------------------------------------
-- Enqueue a webhook message
-- ---------------------------------------------------------------------------
function webhook.Enqueue(url, payload, category)
    if not url or url == "" or url:find("PLACEHOLDER") then
        return -- silent skip for unconfigured webhooks
    end

    table.insert(queue, {
        url      = url,
        payload  = payload,
        retries  = 0,
        category = category,
    })
end

-- ---------------------------------------------------------------------------
-- Start the queue processor loop
-- ---------------------------------------------------------------------------
function webhook.StartQueueProcessor()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Queue.ProcessInterval)
            webhook.ProcessQueue()
        end
    end)
end

-- =============================================================================
-- EMBED BUILDERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Build a kill embed
-- ---------------------------------------------------------------------------
function webhook.BuildKillEmbed(victimInfo, killerInfo, weaponLabel, cause, isNPC, isSuicide, isVehicle)
    local victimName   = victimInfo and victimInfo.name or "Unknown"
    local victimLic    = victimInfo and victimInfo.license or "unknown"
    local killerName   = killerInfo and killerInfo.name or "Unknown"
    local killerLic    = killerInfo and killerInfo.license or "unknown"
    local victimIP     = victimInfo and RavnUtils.MaskIP(victimInfo.ip) or "N/A"
    local killerIP     = killerInfo and RavnUtils.MaskIP(killerInfo.ip) or "N/A"
    local timestamp    = RavnUtils.FormatTimestamp()

    local title        = "Player Death"
    local color        = Config.Colors.kill

    if isSuicide then
        title = "Suicide / Self-Inflicted Death"
        color = 0x9932CC
    elseif isNPC then
        title = "Player Killed by NPC"
        color = 0xCC6600
    elseif isVehicle then
        title = "Player Killed by Vehicle"
        color = 0xFF6600
    end

    local embed = {
        {
            ["title"]       = title,
            ["color"]       = color,
            ["timestamp"]   = timestamp,
            ["footer"]      = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Victim",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(victimName, victimLic:sub(1, 8), victimIP),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Killer",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(killerName, killerLic:sub(1, 8), killerIP),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Weapon",
                    ["value"]  = weaponLabel or cause or "Unknown",
                    ["inline"] = true,
                },
            },
        },
    }

    -- Add position fields if available
    if victimInfo and victimInfo.position then
        embed[1].fields[#embed[1].fields + 1] = {
            ["name"]   = "Location (Victim)",
            ["value"]  = ("X: %.2f | Y: %.2f | Z: %.2f"):format(victimInfo.position.x, victimInfo.position.y, victimInfo.position.z),
            ["inline"] = false,
        }
    end

    return {
        ["username"]   = Config.ServerName .. " - Kill Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build a chat embed
-- ---------------------------------------------------------------------------
function webhook.BuildChatEmbed(playerInfo, channel, message)
    local name      = playerInfo and playerInfo.name or "Unknown"
    local license   = playerInfo and playerInfo.license or "unknown"
    local ip        = playerInfo and RavnUtils.MaskIP(playerInfo.ip) or "N/A"
    local timestamp = RavnUtils.FormatTimestamp()

    local embed = {
        {
            ["title"]     = "Chat Message",
            ["color"]     = Config.Colors.chat,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Player",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(name, license:sub(1, 8), ip),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Channel",
                    ["value"]  = ("`%s`"):format(channel:upper()),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Message",
                    ["value"]  = message:len() > 1024 and message:sub(1, 1021) .. "..." or message,
                    ["inline"] = false,
                },
            },
        },
    }

    return {
        ["username"]   = Config.ServerName .. " - Chat Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build a join/leave embed
-- ---------------------------------------------------------------------------
function webhook.BuildJoinLeaveEmbed(playerInfo, action, reason)
    local name      = playerInfo and playerInfo.name or "Unknown"
    local license   = playerInfo and playerInfo.license or "unknown"
    local ip        = playerInfo and RavnUtils.MaskIP(playerInfo.ip) or "N/A"
    local discord   = playerInfo and playerInfo.discord or "unknown"
    local steam     = playerInfo and playerInfo.steam or "unknown"
    local timestamp = RavnUtils.FormatTimestamp()

    local title  = action == "join" and "Player Connected" or "Player Disconnected"
    local color  = action == "join" and Config.Colors.join or Config.Colors.leave
    local header = action == "join" and "Join" or "Leave"

    local embed = {
        {
            ["title"]     = title,
            ["color"]     = color,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Player",
                    ["value"]  = ("**%s**"):format(name),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Action",
                    ["value"]  = header,
                    ["inline"] = true,
                },
                {
                    ["name"]   = "License",
                    ["value"]  = ("`%s`"):format(license:sub(1, 8)),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "IP",
                    ["value"]  = ("`%s`"):format(ip),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Discord",
                    ["value"]  = ("`%s`"):format(discord ~= "unknown" and "<@" .. discord .. ">" or "N/A"),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Steam HEX",
                    ["value"]  = ("`%s`"):format(steam ~= "unknown" and steam or "N/A"),
                    ["inline"] = true,
                },
            },
        },
    }

    if action ~= "join" and reason and reason ~= "" then
        embed[1].fields[#embed[1].fields + 1] = {
            ["name"]   = "Disconnect Reason",
            ["value"]  = reason,
            ["inline"] = false,
        }
    end

    return {
        ["username"]   = Config.ServerName .. " - Join/Leave",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build an admin action embed
-- ---------------------------------------------------------------------------
function webhook.BuildAdminEmbed(adminInfo, action, targetName, details)
    local adminName = adminInfo and adminInfo.name or "Unknown"
    local adminLic  = adminInfo and adminInfo.license or "unknown"
    local adminIP   = adminInfo and RavnUtils.MaskIP(adminInfo.ip) or "N/A"
    local timestamp = RavnUtils.FormatTimestamp()

    local embed = {
        {
            ["title"]     = "Admin Action",
            ["color"]     = Config.Colors.admin,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Admin",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(adminName, adminLic:sub(1, 8), adminIP),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Action",
                    ["value"]  = ("`%s`"):format(action:upper()),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Target",
                    ["value"]  = targetName or "N/A",
                    ["inline"] = true,
                },
            },
        },
    }

    if details then
        embed[1].fields[#embed[1].fields + 1] = {
            ["name"]   = "Details",
            ["value"]  = details:len() > 1024 and details:sub(1, 1021) .. "..." or details,
            ["inline"] = false,
        }
    end

    return {
        ["username"]   = Config.ServerName .. " - Admin Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build a weapon fire embed
-- ---------------------------------------------------------------------------
function webhook.BuildWeaponEmbed(playerInfo, weaponLabel, weaponHash)
    local name      = playerInfo and playerInfo.name or "Unknown"
    local license   = playerInfo and playerInfo.license or "unknown"
    local ip        = playerInfo and RavnUtils.MaskIP(playerInfo.ip) or "N/A"
    local timestamp = RavnUtils.FormatTimestamp()

    local embed = {
        {
            ["title"]     = "Weapon Fired",
            ["color"]     = Config.Colors.weapon,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Player",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(name, license:sub(1, 8), ip),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Weapon",
                    ["value"]  = ("`%s`"):format(weaponLabel),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Hash",
                    ["value"]  = ("`0x%X`"):format(weaponHash),
                    ["inline"] = true,
                },
            },
        },
    }

    if playerInfo and playerInfo.position then
        embed[1].fields[#embed[1].fields + 1] = {
            ["name"]   = "Location",
            ["value"]  = ("X: %.2f | Y: %.2f | Z: %.2f"):format(playerInfo.position.x, playerInfo.position.y, playerInfo.position.z),
            ["inline"] = false,
        }
    end

    return {
        ["username"]   = Config.ServerName .. " - Weapon Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build an explosion embed
-- ---------------------------------------------------------------------------
function webhook.BuildExplosionEmbed(playerInfo, explosionType, isCaused)
    local name      = playerInfo and playerInfo.name or "Unknown"
    local license   = playerInfo and playerInfo.license or "unknown"
    local ip        = playerInfo and RavnUtils.MaskIP(playerInfo.ip) or "N/A"
    local timestamp = RavnUtils.FormatTimestamp()
    local expLabel  = ("Explosion Type %d"):format(explosionType or -1)

    local embed = {
        {
            ["title"]     = "Explosion Detected",
            ["color"]     = Config.Colors.explosion,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = isCaused and "Caused By" or "Nearby Player",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(name, license:sub(1, 8), ip),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Explosion Type",
                    ["value"]  = ("`%s`"):format(expLabel),
                    ["inline"] = true,
                },
            },
        },
    }

    if playerInfo and playerInfo.position then
        embed[1].fields[#embed[1].fields + 1] = {
            ["name"]   = "Location",
            ["value"]  = ("X: %.2f | Y: %.2f | Z: %.2f"):format(playerInfo.position.x, playerInfo.position.y, playerInfo.position.z),
            ["inline"] = false,
        }
    end

    return {
        ["username"]   = Config.ServerName .. " - Explosion Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Build a console command embed
-- ---------------------------------------------------------------------------
function webhook.BuildConsoleEmbed(playerInfo, commandName, fullCommand)
    local name      = playerInfo and playerInfo.name or "Unknown"
    local license   = playerInfo and playerInfo.license or "unknown"
    local ip        = playerInfo and RavnUtils.MaskIP(playerInfo.ip) or "N/A"
    local timestamp = RavnUtils.FormatTimestamp()

    local embed = {
        {
            ["title"]     = "Console Command Used",
            ["color"]     = Config.Colors.console,
            ["timestamp"] = timestamp,
            ["footer"]    = {
                ["text"] = Config.ServerName,
            },
            ["fields"] = {
                {
                    ["name"]   = "Player",
                    ["value"]  = ("**%s**\nLicense: `%s`\nIP: `%s`"):format(name, license:sub(1, 8), ip),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Command",
                    ["value"]  = ("`%s`"):format(commandName),
                    ["inline"] = true,
                },
                {
                    ["name"]   = "Full Input",
                    ["value"]  = ("`%s`"):format(fullCommand:len() > 1018 and fullCommand:sub(1, 1015) .. "..." or fullCommand),
                    ["inline"] = false,
                },
            },
        },
    }

    return {
        ["username"]   = Config.ServerName .. " - Console Logs",
        ["avatar_url"] = "",
        ["embeds"]     = embed,
    }
end

-- ---------------------------------------------------------------------------
-- Convenience: log to both Discord and NDJSON in one call
-- ---------------------------------------------------------------------------
function webhook.LogEvent(category, embedBuilder, data)
    if not Config.EnabledLogs[category] then return end

    local webhookUrl = nil
    local embedPayload = nil
    local jsonData = nil

    -- Map category to webhook URL and build embed
    if category == "kill" or category == "death" then
        webhookUrl   = Config.Webhooks.killLogs
        embedPayload = webhook.BuildKillEmbed(
            data.victimInfo,
            data.killerInfo,
            data.weaponLabel,
            data.cause,
            data.isNPC,
            data.isSuicide,
            data.isVehicle
        )
    elseif category == "chat" then
        webhookUrl   = Config.Webhooks.chatLogs
        embedPayload = webhook.BuildChatEmbed(data.playerInfo, data.channel, data.message)
    elseif category == "joinLeave" then
        webhookUrl   = Config.Webhooks.joinLeave
        embedPayload = webhook.BuildJoinLeaveEmbed(data.playerInfo, data.action, data.reason)
    elseif category == "admin" then
        webhookUrl   = Config.Webhooks.adminLogs
        embedPayload = webhook.BuildAdminEmbed(data.adminInfo, data.action, data.targetName, data.details)
    elseif category == "weapon" then
        webhookUrl   = Config.Webhooks.killLogs
        embedPayload = webhook.BuildWeaponEmbed(data.playerInfo, data.weaponLabel, data.weaponHash)
    elseif category == "explosion" then
        webhookUrl   = Config.Webhooks.killLogs
        embedPayload = webhook.BuildExplosionEmbed(data.playerInfo, data.explosionType, data.isCaused)
    elseif category == "console" then
        webhookUrl   = Config.Webhooks.adminLogs
        embedPayload = webhook.BuildConsoleEmbed(data.playerInfo, data.commandName, data.fullCommand)
    end

    -- Queue to Discord
    if webhookUrl and embedPayload then
        local success, payloadStr = pcall(json.encode, embedPayload)
        if success then
            webhook.Enqueue(webhookUrl, payloadStr, category)
        else
            print("[ravn_logs] ERROR: Failed to encode embed payload for category " .. category)
        end
    end

    -- Write to NDJSON
    jsonData = {
        timestamp = RavnUtils.FormatTimestamp(),
        category  = category,
    }

    -- Merge event-specific data
    if data.victimInfo then
        jsonData.victim = {
            name      = data.victimInfo.name,
            license   = data.victimInfo.license,
            steam     = data.victimInfo.steam,
            position  = data.victimInfo.position,
        }
    end
    if data.killerInfo then
        jsonData.killer = {
            name      = data.killerInfo.name,
            license   = data.killerInfo.license,
            steam     = data.killerInfo.steam,
            position  = data.killerInfo.position,
        }
    end
    if data.weaponLabel then jsonData.weapon = data.weaponLabel end
    if data.weaponHash then jsonData.weaponHash = data.weaponHash end
    if data.cause then jsonData.cause = data.cause end
    if data.isNPC ~= nil then jsonData.isNPC = data.isNPC end
    if data.isSuicide ~= nil then jsonData.isSuicide = data.isSuicide end
    if data.isVehicle ~= nil then jsonData.isVehicle = data.isVehicle end
    if data.channel then jsonData.channel = data.channel end
    if data.message then jsonData.message = data.message end
    if data.action then jsonData.action = data.action end
    if data.reason then jsonData.reason = data.reason end
    if data.targetName then jsonData.target = data.targetName end
    if data.details then jsonData.details = data.details end
    if data.commandName then jsonData.command = data.commandName end
    if data.fullCommand then jsonData.fullCommand = data.fullCommand end
    if data.explosionType then jsonData.explosionType = data.explosionType end
    if data.isCaused ~= nil then jsonData.isCaused = data.isCaused end
    if data.playerInfo then
        jsonData.player = {
            name    = data.playerInfo.name,
            license = data.playerInfo.license,
            steam   = data.playerInfo.steam,
        }
    end

    RavnUtils.WriteJSONL(category, jsonData)
end

-- ---------------------------------------------------------------------------
-- Return module
-- ---------------------------------------------------------------------------
return webhook
