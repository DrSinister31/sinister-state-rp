local QBCore = exports['qb-core']:GetCoreObject()

local locales = require 'locales.en'

local function L(key, subkey, default)
    return locales.L(key, subkey, default)
end

local playerCount = 0
local autoMsgIndex = 0
local autoMsgTimer = nil
local playerSpamCache = {}

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Wait(1000)
    local count = #GetPlayers()
    playerCount = count

    StartAutoMessages()
    print(string.format('^2[sinister_chat] ^7Sinister H-Town Chat loaded. %d players online.', count))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if autoMsgTimer then
        autoMsgTimer:stop()
        autoMsgTimer = nil
    end
end)

local function GetPlayerFromId(id)
    if QBCore.Functions.GetPlayer then
        return QBCore.Functions.GetPlayer(tonumber(id))
    end
    return QBCore.Functions.GetPlayerBySource and QBCore.Functions.GetPlayerBySource(tonumber(id)) or nil
end

local function GetPlayerNameById(source)
    local Player = GetPlayerFromId(source)
    if Player and Player.PlayerData then
        return ('%s %s'):format(Player.PlayerData.charinfo.firstname or '', Player.PlayerData.charinfo.lastname or '')
    end
    return GetPlayerName(source) or ('ID: ' .. source)
end

local function GetPlayerJob(source)
    local Player = GetPlayerFromId(source)
    if Player and Player.PlayerData then
        return Player.PlayerData.job or {}
    end
    return {}
end

local function GetJobChannelByName(jobName)
    if not jobName then return nil end
    local lower = string.lower(jobName)
    for _, chan in ipairs(Config.JobChannels) do
        if chan.name == lower then
            return chan
        end
    end
    return nil
end

local function GetJobChannelByCommand(cmd)
    local lower = string.lower(cmd)
    for _, chan in ipairs(Config.JobChannels) do
        if string.lower(chan.command) == lower then
            return chan
        end
    end
    return nil
end

local function HasPlayerJob(source, jobName)
    local job = GetPlayerJob(source)
    if not job or not job.name then return false end
    local lower = string.lower(tostring(job.name))
    local target = string.lower(tostring(jobName))
    return lower == target
end

local function IsSpamCheck(source)
    if not source then return false end
    local now = GetGameTimer()
    if playerSpamCache[source] and (now - playerSpamCache[source] < Config.SpamDelay) then
        return true
    end
    playerSpamCache[source] = now
    return false
end

local function SendToAll(data)
    for _, src in ipairs(GetPlayers()) do
        TriggerClientEvent('sinister_chat:receiveMessage', tonumber(src), data)
    end
end

local function SendToJob(jobName, data, source)
    for _, src in ipairs(GetPlayers()) do
        if HasPlayerJob(src, jobName) then
            TriggerClientEvent('sinister_chat:receiveMessage', tonumber(src), data)
        end
    end
end

local function SendToJobChannel(channel, data, source)
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local srcInt = tonumber(src)
        if HasPlayerJob(srcInt, channel.name) then
            TriggerClientEvent('sinister_chat:receiveMessage', srcInt, data)
        end
    end
end

local function SendProximity(source, data, radius)
    local src = tonumber(source)
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)

    for _, target in ipairs(GetPlayers()) do
        local targetSrc = tonumber(target)
        local targetPed = GetPlayerPed(targetSrc)
        local targetCoords = GetEntityCoords(targetPed)
        local dist = #(srcCoords - targetCoords)
        if dist <= radius then
            TriggerClientEvent('sinister_chat:receiveMessage', targetSrc, data)
            if data._3d then
                TriggerClientEvent('sinister_chat:showProximity', targetSrc, {
                    text = data._3d,
                    coords = srcCoords,
                    color = data._3dColor or Config.AccentColor,
                    duration = 6000,
                })
            end
        end
    end
end

local function GetPlayerIdentifiers(source)
    local ids = {}
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        ids[#ids + 1] = id
    end
    return ids
end

QBCore.Functions.CreateCallback('sinister_chat:init', function(source, cb)
    local Player = GetPlayerFromId(source)
    local playerData = {}
    if Player and Player.PlayerData then
        playerData = {
            name = ('%s %s'):format(Player.PlayerData.charinfo.firstname or '', Player.PlayerData.charinfo.lastname or ''),
            job = Player.PlayerData.job or {},
            source = source,
        }
    else
        playerData = {
            name = GetPlayerName(source) or ('ID: ' .. source),
            job = {},
            source = source,
        }
    end

    cb({
        config = {
            prefix = Config.ChatPrefix,
            accentColor = Config.AccentColor,
            darkBg = Config.DarkBackground,
            maxMessages = Config.MaxMessages,
            fadeTimer = Config.FadeTimer,
            emojiSupport = Config.EmojiSupport,
            resizable = Config.Resizable,
            maxLength = Config.MaxMessageLength,
        },
        player = playerData,
        channels = Config.JobChannels,
        allowedCommands = Config.AllowedCommands,
        onlineCount = playerCount,
    })
end)

RegisterNetEvent('sinister_chat:sendMessage', function(data)
    local src = source
    if not data or not data.message or string.len(data.message) < 1 then
        TriggerClientEvent('sinister_chat:receiveMessage', src, {
            type = 'error',
            message = L('errors', 'empty_message', 'You cannot send an empty message.'),
            sender = L('chat', 'system_prefix', '[SYSTEM]'),
        })
        return
    end

    if string.len(data.message) > Config.MaxMessageLength then
        TriggerClientEvent('sinister_chat:receiveMessage', src, {
            type = 'error',
            message = L('errors', 'message_too_long', 'Your message is too long.'),
            sender = L('chat', 'system_prefix', '[SYSTEM]'),
        })
        return
    end

    if IsSpamCheck(src) then
        TriggerClientEvent('sinister_chat:receiveMessage', src, {
            type = 'error',
            message = L('errors', 'spam_warning', 'Please wait before sending another message.'),
            sender = L('chat', 'system_prefix', '[SYSTEM]'),
        })
        return
    end

    local playerName = GetPlayerNameById(src)
    local playerJob = GetPlayerJob(src)
    local message = data.message
    local channel = data.channel or 'global'

    if channel == 'global' then
        SendToAll({
            type = 'normal',
            message = message,
            sender = playerName,
            source = src,
        })

    elseif channel == 'ooc' or channel == 'ooc_proximity' then
        local prefix = L('chat', 'ooc_prefix', '[OOC]')
        local fullMsg = message
        SendToAll({
            type = 'ooc',
            message = fullMsg,
            sender = playerName,
            source = src,
            prefix = prefix,
        })

    elseif channel == 'me' then
        local fullMsg = string.format('%s %s', playerName, message)
        SendProximity(src, {
            type = 'me',
            message = message,
            sender = playerName,
            source = src,
            _3d = fullMsg,
            _3dColor = '#BF5700',
        }, Config.ProximityMeDistance or 15.0)

    elseif channel == 'do' then
        local fullMsg = string.format('%s %s', playerName, message)
        SendProximity(src, {
            type = 'do',
            message = message,
            sender = playerName,
            source = src,
            _3d = fullMsg,
            _3dColor = '#95A5A6',
        }, Config.ProximityDoDistance or 15.0)

    elseif channel == 'twt' then
        SendToAll({
            type = 'twt',
            message = message,
            sender = playerName,
            source = src,
            prefix = L('chat', 'twt_prefix', '[TWT]'),
        })

    elseif channel == 'news' then
        SendToAll({
            type = 'news',
            message = message,
            sender = playerName,
            source = src,
            prefix = L('chat', 'news_prefix', '[NEWS]'),
        })

    elseif channel == 'advert' then
        SendToAll({
            type = 'advert',
            message = message,
            sender = playerName,
            source = src,
            prefix = L('chat', 'advert_prefix', '[AD]'),
        })

    elseif channel == 'anon' then
        SendToAll({
            type = 'anon',
            message = message,
            sender = L('chat', 'anon_prefix', '[ANON]'),
            source = 0,
        })

    elseif channel == 'darkweb' then
        local playersOnDW = {}
        for _, tgt in ipairs(GetPlayers()) do
            local tgtInt = tonumber(tgt)
            local tgtPlayer = GetPlayerFromId(tgtInt)
            if tgtPlayer and tgtPlayer.PlayerData and tgtPlayer.PlayerData.metadata and tgtPlayer.PlayerData.metadata.darkweb then
                playersOnDW[#playersOnDW + 1] = tgtInt
            end
        end
        for _, tgtInt in ipairs(playersOnDW) do
            TriggerClientEvent('sinister_chat:receiveMessage', tgtInt, {
                type = 'darkweb',
                message = message,
                sender = L('chat', 'darkweb_prefix', '[DW]'),
                source = 0,
            })
        end

    elseif channel == 'job' then
        local jobChan = GetJobChannelByName(data.job)
        if not jobChan then
            TriggerClientEvent('sinister_chat:receiveMessage', src, {
                type = 'error',
                message = L('errors', 'command_not_found', 'Job channel not found.'),
                sender = L('chat', 'system_prefix', '[SYSTEM]'),
            })
            return
        end
        if not HasPlayerJob(src, jobChan.name) then
            TriggerClientEvent('sinister_chat:receiveMessage', src, {
                type = 'error',
                message = L('chat', 'not_in_job', 'You are not on duty for this job.'),
                sender = L('chat', 'system_prefix', '[SYSTEM]'),
            })
            return
        end
        local prefix = string.format(L('chat', 'job_prefix', '[%s]'), string.upper(jobChan.name))
        SendToJobChannel(jobChan, {
            type = 'job',
            message = message,
            sender = playerName,
            source = src,
            jobName = jobChan.name,
            color = jobChan.color,
            prefix = prefix,
        }, src)

    else
        local jobCmd = GetJobChannelByCommand(channel)
        if jobCmd then
            if not HasPlayerJob(src, jobCmd.name) then
                TriggerClientEvent('sinister_chat:receiveMessage', src, {
                    type = 'error',
                    message = L('chat', 'not_in_job', 'You are not on duty for this job.'),
                    sender = L('chat', 'system_prefix', '[SYSTEM]'),
                })
                return
            end
            local prefix = string.format(L('chat', 'job_prefix', '[%s]'), string.upper(jobCmd.name))
            SendToJobChannel(jobCmd, {
                type = 'job',
                message = message,
                sender = playerName,
                source = src,
                jobName = jobCmd.name,
                color = jobCmd.color,
                prefix = prefix,
            }, src)
        else
            if Config.AllowedCommands[channel] then
                SendToAll({
                    type = channel,
                    message = message,
                    sender = playerName,
                    source = src,
                })
            else
                TriggerClientEvent('sinister_chat:receiveMessage', src, {
                    type = 'error',
                    message = string.format(L('errors', 'command_not_found', 'Command "%s" not found.'), channel),
                    sender = L('chat', 'system_prefix', '[SYSTEM]'),
                })
            end
        end
    end
end)

RegisterNetEvent('sinister_chat:requestHelp', function()
    local src = source
    local helpLines = {}
    helpLines[#helpLines + 1] = { type = 'system', message = L('help', 'title', 'Commands:') }
    for cmd, desc in pairs(L('help')) do
        if type(desc) == 'string' and desc ~= '' then
            helpLines[#helpLines + 1] = { type = 'system', message = string.format('%s — %s', cmd, desc) }
        end
    end
    for i = 1, #helpLines do
        helpLines[i].message = helpLines[i].message
    end
    TriggerClientEvent('sinister_chat:showHelp', src, helpLines)
end)

function StartAutoMessages()
    if autoMsgTimer then
        autoMsgTimer:stop()
        autoMsgTimer = nil
    end

    local function sendNext()
        autoMsgIndex = autoMsgIndex + 1
        if autoMsgIndex > #Config.AutoMessages then
            autoMsgIndex = 1
        end
        local msg = Config.AutoMessages[autoMsgIndex]
        if msg then
            for _, src in ipairs(GetPlayers()) do
                TriggerClientEvent('sinister_chat:receiveMessage', tonumber(src), {
                    type = 'auto',
                    message = msg,
                    sender = L('chat', 'auto_msg_prefix', '[SINISTER]'),
                    source = 0,
                })
            end
        end
    end

    autoMsgTimer = exports['qb-core']:CreateTimer(Config.AutoMessageInterval, function()
        autoMsgTimer = nil
        sendNext()
        autoMsgTimer = exports['qb-core']:CreateTimer(Config.AutoMessageInterval, function()
            autoMsgTimer = nil
            sendNext()
        end)
    end)
end

exports('getOnlineCount', function()
    return playerCount
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    deferrals.defer()
    Wait(0)
    deferrals.done()
end)

AddEventHandler('playerJoining', function(source)
    Wait(500)
    local name = GetPlayerName(source)
    playerCount = #GetPlayers()
    SendToAll({
        type = 'system',
        message = string.format(L('chat', 'join_message', '%s has arrived in Sinister H-Town.'), name),
        sender = L('chat', 'system_prefix', '[SYSTEM]'),
        source = 0,
    })
end)

AddEventHandler('playerDropped', function(reason)
    Wait(0)
    playerCount = #GetPlayers()
    if playerCount < 0 then playerCount = 0 end
    if reason and reason ~= '' then
        SendToAll({
            type = 'system',
            message = string.format(L('chat', 'leave_message', '%s has left Sinister H-Town.'), reason),
            sender = L('chat', 'system_prefix', '[SYSTEM]'),
            source = 0,
        })
    end
end)

local heartbeat = CreateVar('ChatHeartbeat', 0)
SetInterval(function()
    heartbeat = heartbeat + 1
end, 60000)
