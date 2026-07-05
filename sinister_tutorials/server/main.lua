-- ============================================================================
-- SINISTER TUTORIALS — Server
-- ============================================================================

local completedTutorials = {}

-- ============================================================================
-- REQUEST TUTORIAL
-- ============================================================================

RegisterNetEvent('sinister_tutorials:requestTutorial', function(job)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local tutorial = Config.Tutorials[job]
    if not tutorial then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Tutorials',
            description = 'No tutorial available for: ' .. (job or 'nil') .. '\nTry: police, sasp, fib, ambulance, lumberjack, trucking, carwash, oiljob, dealing, racing',
            type = 'error',
        })
        return
    end

    -- Check job requirement
    if tutorial.jobRequired then
        local playerJob = player.PlayerData.job and player.PlayerData.job.name
        if playerJob ~= tutorial.jobRequired then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Tutorials',
                description = 'You must be a ' .. tutorial.jobRequired .. ' to take this tutorial. Currently: ' .. (playerJob or 'unemployed'),
                type = 'error',
            })
            return
        end
    end

    -- Already completed?
    local cid = player.PlayerData.citizenid
    local key = cid .. ':' .. job
    if completedTutorials[key] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Tutorials',
            description = 'You\'ve already completed ' .. tutorial.label .. '. Take it again? Use /tutorial ' .. job .. ' again.',
            type = 'inform',
        })
        -- Allow retake
    end

    TriggerClientEvent('sinister_tutorials:start', src, job)
end)

-- ============================================================================
-- COMPLETE TUTORIAL
-- ============================================================================

RegisterNetEvent('sinister_tutorials:complete', function(job)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local tutorial = Config.Tutorials[job]
    if not tutorial then return end

    -- Pay reward
    player.Functions.AddMoney('bank', tutorial.reward, 'tutorial-completion')
    local cid = player.PlayerData.citizenid
    completedTutorials[cid .. ':' .. job] = true

    -- Log
    print('[sinister_tutorials] ' .. GetPlayerName(src) .. ' completed ' .. tutorial.label)
end)

-- ============================================================================
-- COMMAND RELAY (client tells server what command was used)
-- ============================================================================

RegisterNetEvent('sinister_tutorials:commandUsed', function(command)
    local src = source
    TriggerClientEvent('sinister_tutorials:commandUsed', src, command)
end)

-- For police / ambulance / job commands to trigger tutorial progress
local tutorialCommands = {
    'cuff', 'jail', 'uofreport', 'revive', 'checkin', 'evidence', 'federal', 'seize',
    'choptree', 'loadlogs', 'truckroute', 'loadcargo', 'wash', 'bossmenu',
    'drill', 'pump', 'drugspots', 'joinrace', 'raceleaderboard', 'plate', 'spike',
}

for _, cmd in ipairs(tutorialCommands) do
    RegisterCommand(cmd, function(source, args, raw)
        local src = source
        if src > 0 then
            TriggerClientEvent('sinister_tutorials:commandUsed', src, cmd)
        end
    end, true) -- true = restricted (existing command)
end

print('^2[sinister_tutorials] ^7Server ready — ' .. tablelength(Config.Tutorials) .. ' tutorials available')

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
