-- ============================================================================
-- SINISTER INTERACT — Texas Interaction Wheel
-- ============================================================================

local isOpen = false

-- ============================================================================
-- JOB-SMART ACTIONS
-- ============================================================================

local function getJobActions()
    local player = exports.qbx_core:GetPlayer(cache.playerId)
    if not player or not player.PlayerData.job then return {} end

    local job = player.PlayerData.job.name
    local onduty = player.PlayerData.job.onduty

    local actions = {
        -- LEO Actions
        police = {
            { title = 'Cuff Nearest', icon = 'handcuffs', onSelect = function() ExecuteCommand('cuff') end },
            { title = 'Search Player', icon = 'magnifying-glass', onSelect = function() ExecuteCommand('search') end },
            { title = 'Jail Player', icon = 'lock', onSelect = function() ExecuteCommand('jail') end },
            { title = 'Place Spike Strip', icon = 'triangle-exclamation', onSelect = function() TriggerServerEvent('spike_strips:deploy') end },
            { title = 'Check License', icon = 'id-card', onSelect = function() ExecuteCommand('license') end },
            { title = 'Police Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        bcso = { -- same as police, auto-routed
            { title = 'Cuff Nearest', icon = 'handcuffs', onSelect = function() ExecuteCommand('cuff') end },
            { title = 'Search Player', icon = 'magnifying-glass', onSelect = function() ExecuteCommand('search') end },
            { title = 'Jail Player', icon = 'lock', onSelect = function() ExecuteCommand('jail') end },
            { title = 'Check License', icon = 'id-card', onSelect = function() ExecuteCommand('license') end },
            { title = 'Sheriff Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        sasp = {
            { title = 'Cuff Nearest', icon = 'handcuffs', onSelect = function() ExecuteCommand('cuff') end },
            { title = 'Speed Check', icon = 'gauge-high', onSelect = function() ExecuteCommand('plate') end },
            { title = 'Place Spike Strip', icon = 'triangle-exclamation', onSelect = function() TriggerServerEvent('spike_strips:deploy') end },
            { title = 'DPS Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        fib = {
            { title = 'Cuff Nearest', icon = 'handcuffs', onSelect = function() ExecuteCommand('cuff') end },
            { title = 'Federal Seizure', icon = 'briefcase', onSelect = function() ExecuteCommand('seize') end },
            { title = 'Investigate', icon = 'fingerprint', onSelect = function() ExecuteCommand('evidence') end },
            { title = 'FIB Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        -- EMS Actions
        ambulance = {
            { title = 'Diagnose', icon = 'stethoscope', onSelect = function() ExecuteCommand('checkin') end },
            { title = 'Apply Bandage', icon = 'bandage', onSelect = function() ExecuteCommand('bandage') end },
            { title = 'Revive', icon = 'heart-pulse', onSelect = function() ExecuteCommand('revive') end },
            { title = 'EMS Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        fire = {
            { title = 'Extract Victim', icon = 'person-drowning', onSelect = function() ExecuteCommand('extract') end },
            { title = 'Fire Hose', icon = 'fire', onSelect = function() print('fire hose') end },
            { title = 'Fire Radio', icon = 'walkie-talkie', onSelect = function() ExecuteCommand('radio') end },
        },
        -- Civilian Jobs
        mechanic = {
            { title = 'Repair Vehicle', icon = 'wrench', onSelect = function() ExecuteCommand('repair') end },
            { title = 'Tow Vehicle', icon = 'tow-truck', onSelect = function() ExecuteCommand('tow') end },
        },
        trucker = {
            { title = 'Start Route', icon = 'route', onSelect = function() ExecuteCommand('truckroute') end },
            { title = 'Load Cargo', icon = 'boxes-stacked', onSelect = function() ExecuteCommand('loadcargo') end },
        },
        lumberjack = {
            { title = 'Chop Tree', icon = 'tree', onSelect = function() ExecuteCommand('choptree') end },
            { title = 'Load Logs', icon = 'boxes-stacked', onSelect = function() ExecuteCommand('loadlogs') end },
            { title = 'Join Crew', icon = 'people-group', onSelect = function() ExecuteCommand('joincrew') end },
        },
        oiljob = {
            { title = 'Start Drill', icon = 'oil-well', onSelect = function() ExecuteCommand('drill') end },
            { title = 'Pump Oil', icon = 'faucet-drip', onSelect = function() ExecuteCommand('pump') end },
        },
        realestate = {
            { title = 'Show Property', icon = 'house', onSelect = function() ExecuteCommand('showhouse') end },
            { title = 'Sell Property', icon = 'hand-holding-dollar', onSelect = function() ExecuteCommand('sellproperty') end },
        },
        taxi = {
            { title = 'Accept Fare', icon = 'taxi', onSelect = function() ExecuteCommand('taxi') end },
            { title = 'Set Fare', icon = 'dollar-sign', onSelect = function() ExecuteCommand('fare') end },
        },
        tow = {
            { title = 'Tow Vehicle', icon = 'tow-truck', onSelect = function() ExecuteCommand('tow') end },
            { title = 'Impound', icon = 'car-on', onSelect = function() ExecuteCommand('impound') end },
        },
        carwash = {
            { title = 'Wash Vehicle', icon = 'droplet', onSelect = function() ExecuteCommand('wash') end },
            { title = 'Start Shift', icon = 'clock', onSelect = function() ExecuteCommand('startshift') end },
            { title = 'Boss Menu', icon = 'user-tie', onSelect = function() ExecuteCommand('bossmenu') end },
        },
    }

    return actions[job] or {}
end

-- ============================================================================
-- MAIN INTERACTION WHEEL
-- ============================================================================

local function openInteractionMenu()
    local menuOptions = {
        -- Universal Actions
        {
            title = 'Emotes',
            icon = 'face-smile',
            onSelect = function() ExecuteCommand('emotes') end,
        },
        {
            title = 'Animations',
            icon = 'person-walking',
            onSelect = function() ExecuteCommand('e') end,
        },
        {
            title = 'Carry Player',
            icon = 'people-carry-box',
            onSelect = function() ExecuteCommand('carry') end,
        },
        {
            title = 'Give Keys',
            icon = 'key',
            onSelect = function() ExecuteCommand('givekeys') end,
        },
        {
            title = 'Set GPS',
            icon = 'map-pin',
            onSelect = function()
                local waypoint = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypoint) then
                    SetNewWaypoint(GetBlipCoords(waypoint))
                end
            end,
        },
        {
            title = 'Quick /me',
            icon = 'comment',
            onSelect = function()
                local input = lib.inputDialog('Quick /me', { { type = 'input', label = 'Action', placeholder = 'scratches his head' } })
                if input then ExecuteCommand('me ' .. input[1]) end
            end,
        },
        {
            title = 'Quick /do',
            icon = 'comment-dots',
            onSelect = function()
                local input = lib.inputDialog('Quick /do', { { type = 'input', label = 'Description', placeholder = 'the door is locked' } })
                if input then ExecuteCommand('do ' .. input[1]) end
            end,
        },
    }

    -- Clock In/Out (all jobs)
    table.insert(menuOptions, {
        title = 'Clock In / Out',
        icon = 'clock',
        onSelect = function() ExecuteCommand('clockin') end,
    })

    -- 911 for civilians, radio for LEO
    table.insert(menuOptions, {
        title = 'Emergency / 911',
        icon = 'phone',
        onSelect = function() ExecuteCommand('911') end,
    })

    -- Drug dealer interaction
    table.insert(menuOptions, {
        title = 'Check Dealers',
        icon = 'users',
        onSelect = function() ExecuteCommand('dealers') end,
    })

    -- Job-specific actions
    local jobActions = getJobActions()
    for _, action in ipairs(jobActions) do
        table.insert(menuOptions, action)
    end

    -- Open menu
    lib.registerContext({
        id = 'sinister_interact',
        title = 'Sinister H-Town',
        options = menuOptions,
    })
    lib.showContext('sinister_interact')
    isOpen = true
end

-- ============================================================================
-- KEYBIND + COMMAND
-- ============================================================================

RegisterCommand('interact', function()
    openInteractionMenu()
end, false)

RegisterKeyMapping('interact', 'Texas Interaction Wheel', 'keyboard', 'F9')

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        isOpen = false
    end
end)

print('^2[sinister_interact] ^7Texas interaction wheel ready — press F9')
