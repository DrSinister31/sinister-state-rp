local QBCore = exports['qb-core']:GetCoreObject()

local chatOpen = false
local chatFocused = false
local chatHistory = {}
local messageIdCounter = 0
local currentChannel = 'global'
local channelPrefix = ''
local playerName = ''
local playerJob = nil
local chatReady = false
local pendingMessages = {}
local onlineCount = 0

local function GenerateMessageId()
    messageIdCounter = messageIdCounter + 1
    return messageIdCounter
end

local function DebugPrint(msg)
    if GetConvar('sinister_chat_debug', 'false') == 'true' then
        print('[sinister_chat:client] ' .. tostring(msg))
    end
end

local function FormatMessage(data)
    if not data then return end
    if not data.id then
        data.id = GenerateMessageId()
    end
    if not data.timestamp then
        data.timestamp = os.date('%H:%M')
    end
    data.channel = data.channel or currentChannel
    data.fading = false
    data.fadeStart = nil
    return data
end

local function AddToHistory(data)
    data = FormatMessage(data)
    table.insert(chatHistory, data)
    if #chatHistory > Config.MaxMessages then
        table.remove(chatHistory, 1)
    end
end

local function SendToNUI(data)
    if not chatReady then
        table.insert(pendingMessages, data)
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'addMessage', data = data })
    SetNuiFocus(false, false)
end

RegisterNetEvent('sinister_chat:receiveMessage', function(data)
    if not data then return end
    data = FormatMessage(data)
    AddToHistory(data)

    if not chatReady then
        table.insert(pendingMessages, data)
        return
    end

    if chatOpen then
        SetNuiFocus(true, true)
    end
    SendNUIMessage({ action = 'addMessage', data = data })
    if not chatOpen then
        SetNuiFocus(false, false)
    end

    if data.type == 'ooc' then
        PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
    end
end)

RegisterNetEvent('sinister_chat:showProximity', function(data)
    if not data then return end
    if data.text then
        Draw3DText(data.coords.x, data.coords.y, data.coords.z, data.text, data.color or Config.AccentColor, data.duration or 6000)
    end
end)

RegisterNetEvent('sinister_chat:showHelp', function(lines)
    for _, line in ipairs(lines) do
        TriggerEvent('sinister_chat:receiveMessage', line)
    end
end)

function Draw3DText(x, y, z, text, color, duration)
    local alpha = 255
    local tick = 0
    local maxTicks = duration or 6000

    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        while tick < maxTicks do
            local elapsed = GetGameTimer() - startTime
            tick = elapsed
            if elapsed > (maxTicks - 2000) then
                alpha = math.max(0, 255 - ((elapsed - (maxTicks - 2000)) / 2000) * 255)
            end

            local camCoords = GetGameplayCamCoords()
            local dist = #(vector3(x, y, z) - camCoords)
            if dist < 30.0 then
                Draw3DTextInternal(x, y, z + 0.0, text, color, math.floor(alpha))
            end

            Wait(0)
        end
    end)
end

function Draw3DTextInternal(x, y, z, text, color, alpha)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(
        tonumber(string.sub(color, 2, 3), 16),
        tonumber(string.sub(color, 4, 5), 16),
        tonumber(string.sub(color, 6, 7), 16),
        alpha
    )
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370.0
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, math.floor(alpha * 0.55))
    ClearDrawOrigin()
end

local function ParseCommand(message)
    if not message or string.sub(message, 1, 1) ~= Config.ChatPrefix then
        return nil, message
    end

    local spacePos = string.find(message, ' ')
    local command, args
    if spacePos then
        command = string.lower(string.sub(message, 2, spacePos - 1))
        args = string.sub(message, spacePos + 1)
    else
        command = string.lower(string.sub(message, 2))
        args = ''
    end

    return command, args
end

local function ExecuteCommand(command, args)
    if not command then
        if args and string.len(args) > 0 then
            TriggerServerEvent('sinister_chat:sendMessage', {
                message = args,
                channel = currentChannel,
            })
        end
        return
    end

    if Config.AllowedCommands[command] then
        if command == 'help' then
            TriggerServerEvent('sinister_chat:requestHelp')
            return
        end
        if command == 'clear' then
            chatHistory = {}
            if chatReady then
                SendNUIMessage({ action = 'clearChat' })
            end
            return
        end
        if command == 'jobs' then
            TriggerEvent('sinister_chat:receiveMessage', {
                type = 'system',
                message = '--- Texas Job Channels ---',
                sender = '[SYSTEM]',
            })
            for _, chan in ipairs(Config.JobChannels) do
                TriggerEvent('sinister_chat:receiveMessage', {
                    type = 'system',
                    message = string.format('%s %s (%s)', chan.command, chan.label, chan.name),
                    sender = '[SYSTEM]',
                })
            end
            return
        end
        if command == 'players' then
            TriggerEvent('sinister_chat:receiveMessage', {
                type = 'system',
                message = string.format('%d players online.', #GetActivePlayers()),
                sender = '[SYSTEM]',
            })
            return
        end

        if string.len(args) < 1 then
            TriggerEvent('sinister_chat:receiveMessage', {
                type = 'error',
                message = string.format('Usage: /%s [message]', command),
                sender = '[SYSTEM]',
            })
            return
        end

        TriggerServerEvent('sinister_chat:sendMessage', {
            message = args,
            channel = command,
        })
        return
    end

    local jobChan = nil
    for _, chan in ipairs(Config.JobChannels) do
        if string.lower(chan.command) == '/' .. command then
            jobChan = chan
            break
        end
    end

    if jobChan then
        if string.len(args) < 1 then
            currentChannel = 'job'
            channelPrefix = string.format('[%s]', string.upper(jobChan.name))
            SendNUIMessage({
                action = 'setChannel',
                channel = 'job',
                label = jobChan.label,
                prefix = channelPrefix,
                color = jobChan.color,
            })
            TriggerEvent('sinister_chat:receiveMessage', {
                type = 'system',
                message = string.format('You are now chatting in %s channel.', jobChan.label),
                sender = '[SYSTEM]',
            })
            return
        end

        TriggerServerEvent('sinister_chat:sendMessage', {
            message = args,
            channel = 'job',
            job = jobChan.name,
        })
        return
    end

    TriggerEvent('sinister_chat:receiveMessage', {
        type = 'error',
        message = string.format('Command "%s" not found. Try /help', command),
        sender = '[ERROR]',
    })
end

local function OpenChat()
    if chatOpen then return end
    chatOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, false)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
    end

    SendNUIMessage({
        action = 'openChat',
        history = chatHistory,
        channel = currentChannel,
        prefix = channelPrefix,
    })
end

local function CloseChat()
    if not chatOpen then return end
    chatOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'closeChat' })
end

RegisterNUICallback('sendMessage', function(data, cb)
    if not data or not data.message then
        cb('ok')
        return
    end

    local command, args = ParseCommand(data.message)
    ExecuteCommand(command, args)
    cb('ok')
end)

RegisterNUICallback('chatReady', function(data, cb)
    chatReady = true

    local plyData = QBCore.Functions.GetPlayerData()
    if plyData then
        playerName = string.format('%s %s', plyData.charinfo.firstname or '', plyData.charinfo.lastname or '')
        playerJob = plyData.job
    end

    QBCore.Functions.TriggerCallback('sinister_chat:init', function(initData)
        if initData and initData.player then
            playerName = initData.player.name
            playerJob = initData.player.job
            onlineCount = initData.onlineCount or 0
        end

        SendNUIMessage({
            action = 'initComplete',
            config = initData and initData.config or Config,
            player = initData and initData.player or { name = playerName, job = playerJob },
            channels = initData and initData.channels or Config.JobChannels,
            allowedCommands = initData and initData.allowedCommands or Config.AllowedCommands,
        })

        for _, msg in ipairs(pendingMessages) do
            SendNUIMessage({ action = 'addMessage', data = msg })
        end
        pendingMessages = {}
    end)

    cb('ok')
end)

RegisterNUICallback('closeChat', function(data, cb)
    CloseChat()
    cb('ok')
end)

RegisterNUICallback('getCommandSuggestions', function(data, cb)
    local suggestions = {}

    for cmd, _ in pairs(Config.AllowedCommands) do
        suggestions[#suggestions + 1] = {
            command = Config.ChatPrefix .. cmd,
            label = cmd,
            type = 'global',
        }
    end

    for _, chan in ipairs(Config.JobChannels) do
        suggestions[#suggestions + 1] = {
            command = chan.command,
            label = chan.label,
            type = 'job',
            color = chan.color,
        }
    end

    cb({ suggestions = suggestions })
end)

RegisterNUICallback('selectChannel', function(data, cb)
    if data and data.channel then
        currentChannel = data.channel
        channelPrefix = data.prefix or ''
        SendNUIMessage({
            action = 'setChannel',
            channel = data.channel,
            label = data.label,
            prefix = data.prefix,
            color = data.color,
        })
    end
    cb('ok')
end)

CreateThread(function()
    Wait(2000)

    for i = 1, 12 do
        local found = false
        for k, v in pairs(KeybindHandlers) do
            if type(v) == 'table' and v.key == 't' then
                found = true
                break
            end
        end
        if not found then
            RegisterKeyMapping('+sinister_chat_open', 'Open Chat', 'keyboard', 'T')
        end
        Wait(1000)
    end

    RegisterCommand('+sinister_chat_open', function()
        OpenChat()
    end, false)

    RegisterCommand('-sinister_chat_open', function()
    end, false)

    TriggerEvent('chat:removeSuggestion', '/tpm', '/admin')
end)

CreateThread(function()
    while true do
        Wait(0)
        if chatOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 246, true)
            EnableControlAction(0, 44, true)
            EnableControlAction(0, 32, true)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(50)
        local feed = {}
        for i = 1, math.min(#chatHistory, 8) do
            local idx = #chatHistory - 8 + i
            if idx >= 1 then
                feed[#feed + 1] = chatHistory[idx]
            end
        end
        if #feed > 0 then
            for _, msg in ipairs(feed) do
                local alpha = 180
                if chatOpen then alpha = 255 end
                local displayText = ''
                if msg.prefix then
                    displayText = msg.prefix .. ' '
                end
                displayText = displayText .. (msg.sender or '') .. ': ' .. (msg.message or '')
                if msg.type == 'me' then
                    displayText = msg.sender .. ' ' .. (msg.message or '')
                elseif msg.type == 'do' then
                    displayText = msg.message or ''
                end
                SetTextFont(0)
                SetTextScale(0.28, 0.28)
                SetTextColour(255, 255, 255, alpha)
                SetTextDropshadow(1, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 100)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(displayText)
                EndTextCommandDisplayText(0.005, 0.01 * (i - 1), 0)
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    chatReady = false
    chatHistory = {}
    pendingMessages = {}
    currentChannel = 'global'
    channelPrefix = ''
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    local plyData = QBCore.Functions.GetPlayerData()
    if plyData then
        playerName = string.format('%s %s', plyData.charinfo.firstname or '', plyData.charinfo.lastname or '')
        playerJob = plyData.job
    end
    SendNUIMessage({ action = 'playerLoaded', player = { name = playerName, job = playerJob } })
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
    SendNUIMessage({ action = 'jobUpdate', job = job })
end)
