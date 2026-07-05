-- ============================================================================
-- SINISTER TUTORIALS — Client
-- ============================================================================

local activeTutorial = nil
local activePhase = 1
local mentorPed = nil
local listening = false
local phaseComplete = false
local waypointHandle = nil

-- ============================================================================
-- NPC SPAWNING
-- ============================================================================

local function spawnMentor(tutorial)
    local model = GetHashKey(tutorial.mentorModel)
    local coords = tutorial.mentorCoords
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, true, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)
    return ped
end

-- ============================================================================
-- DIALOGUE + OBJECTIVE DISPLAY
-- ============================================================================

local function showPhase(phase)
    -- Kill old waypoint
    if waypointHandle then
        SetWaypointOff()
        waypointHandle = nil
    end

    -- Set new waypoint
    if phase.waypoint then
        SetNewWaypoint(phase.waypoint.x, phase.waypoint.y)
    end

    -- Show objective UI
    lib.notify({
        title = phase.title,
        description = phase.objective .. '\n' .. (phase.keybinds or ''),
        type = 'inform',
        duration = 10000,
    })

    -- Show dialogue from mentor
    if phase.dialogue then
        TriggerEvent('chat:addMessage', {
            color = { 191, 87, 0 },
            multiline = true,
            args = { 'Training Sergeant', phase.dialogue },
        })
    end

    phaseComplete = false
    if phase.completeOn == 'timer' then
        SetTimeout(phase.completeTime or 5000, function()
            phaseComplete = true
        end)
    end
end

-- ============================================================================
-- COMMAND LISTENER
-- ============================================================================

RegisterNetEvent('sinister_tutorials:commandUsed', function(command)
    if not activeTutorial then return end
    local phase = Config.Tutorials[activeTutorial].phases[activePhase]
    if phase and phase.completeOn == 'command' and phase.completeCommand == command then
        phaseComplete = true
    end
end)

-- ============================================================================
-- TUTORIAL START
-- ============================================================================

RegisterNetEvent('sinister_tutorials:start', function(tutorialId)
    local tutorial = Config.Tutorials[tutorialId]
    if not tutorial then
        lib.notify({ title = 'Tutorials', description = 'Tutorial not found.', type = 'error' })
        return
    end

    activeTutorial = tutorialId
    activePhase = 1

    -- Spawn mentor
    mentorPed = spawnMentor(tutorial)

    -- Add target interaction
    exports.ox_target:addLocalEntity(mentorPed, {
        {
            name = 'tutorial_talk',
            label = 'Speak to Training Officer',
            icon = 'fa-solid fa-comments',
            onSelect = function()
                local phase = tutorial.phases[activePhase]
                if phase then
                    showPhase(phase)
                end
            end,
            canInteract = function()
                return activeTutorial ~= nil
            end,
        },
    })

    lib.notify({
        title = 'Tutorial Started',
        description = tutorial.label .. '\nSpeak to your training officer to begin.',
        type = 'success',
        duration = 8000,
    })
end)

-- ============================================================================
-- PHASE ADVANCEMENT LOOP
-- ============================================================================

CreateThread(function()
    while true do
        Wait(500)
        if activeTutorial and phaseComplete then
            local tutorial = Config.Tutorials[activeTutorial]
            activePhase = activePhase + 1

            if activePhase > #tutorial.phases then
                -- Tutorial complete
                TriggerServerEvent('sinister_tutorials:complete', activeTutorial)
                lib.notify({
                    title = 'Tutorial Complete!',
                    description = tutorial.label .. '\nYou earned $' .. tutorial.reward .. '. Good luck out there.',
                    type = 'success',
                    duration = 10000,
                })
                -- Clean up
                if mentorPed and DoesEntityExist(mentorPed) then
                    exports.ox_target:removeLocalEntity(mentorPed)
                    DeleteEntity(mentorPed)
                end
                if waypointHandle then
                    SetWaypointOff()
                    waypointHandle = nil
                end
                activeTutorial = nil
                activePhase = 1
                mentorPed = nil
            else
                -- Next phase
                local phase = tutorial.phases[activePhase]
                if phase then
                    showPhase(phase)
                end
            end
        end
    end
end)

-- ============================================================================
-- COMMANDS
-- ============================================================================

RegisterCommand('tutorial', function(source, args)
    local job = args[1]
    if not job then
        lib.notify({
            title = 'Tutorials Available',
            description = '/tutorial police | sasp | fib | ambulance | lumberjack | trucking | carwash | oiljob | dealing | racing',
            type = 'inform',
            duration = 10000,
        })
        return
    end
    TriggerServerEvent('sinister_tutorials:requestTutorial', job)
end, false)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if mentorPed and DoesEntityExist(mentorPed) then DeleteEntity(mentorPed) end
        if waypointHandle then SetWaypointOff() end
    end
end)

print('^2[sinister_tutorials] ^7Client ready — F9 for interact, /tutorial [job] to start')
