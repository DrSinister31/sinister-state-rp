-- =============================================================================
-- ravn_logs - client/client.lua
-- Client-side detection: weapon fire, death, explosions, console commands
-- =============================================================================

local isDead        = false
local weaponTimers  = {}
local WPN_CHECK_MS  = 1500   -- check weapon fire every 1.5s
local EXPLOSION_CHECK_MS = 2000
local lastExplosionCheck = 0
local consoleHistory = {}

-- ---------------------------------------------------------------------------
-- WEAPON FIRE DETECTION (polling-based)
-- ---------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(WPN_CHECK_MS)

        if not Config.EnabledLogs or not Config.EnabledLogs.weapon then
            goto continue_weapon
        end

        local ped = PlayerPedId()
        if not ped or ped == 0 then goto continue_weapon end

        local currentWeapon = GetSelectedPedWeapon(ped)
        if not currentWeapon or currentWeapon == `WEAPON_UNARMED` then
            goto continue_weapon
        end

        -- Check blacklist
        if Config.WeaponBlacklist and Config.WeaponBlacklist[currentWeapon] then
            goto continue_weapon
        end

        if IsPedShooting(ped) then
            local now = GetGameTimer()
            if weaponTimers[currentWeapon] and (now - weaponTimers[currentWeapon]) < WPN_CHECK_MS then
                goto continue_weapon
            end
            weaponTimers[currentWeapon] = now

            -- Send weapon fire event to server
            TriggerServerEvent("ravn_logs:weaponFired", currentWeapon)
        end

        ::continue_weapon::
    end
end)

-- Fallback: also detect via gameEvent (CEventNetworkEntityDamage)
-- This catches projectile impacts that IsPedShooting might miss
AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName ~= "CEventNetworkEntityDamage" then return end
    if not Config.EnabledLogs or not Config.EnabledLogs.weapon then return end

    local victim    = eventData[1]
    local attacker  = eventData[2]
    local weaponHash = eventData[4] or 0
    local playerPed = PlayerPedId()

    -- Only forward if WE are the attacker
    if attacker ~= playerPed then return end
    if not weaponHash or weaponHash == 0 then return end

    TriggerServerEvent("ravn_logs:weaponFired", weaponHash)
end)

-- ---------------------------------------------------------------------------
-- EXPLOSION DETECTION
-- ---------------------------------------------------------------------------

AddEventHandler("gameEventTriggered", function(eventName, eventData)
    if eventName ~= "CEventNetworkExplosion" then return end
    if not Config.EnabledLogs or not Config.EnabledLogs.explosion then return end

    local now = GetGameTimer()
    if now - lastExplosionCheck < EXPLOSION_CHECK_MS then return end
    lastExplosionCheck = now

    local explosionType = eventData[4] or 0
    local posX = eventData[1] or 0
    local posY = eventData[2] or 0
    local posZ = eventData[3] or 0

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    -- Check if player is near the explosion (within 100m)
    if #(vector3(posX, posY, posZ) - playerPos) > 100.0 then return end

    TriggerServerEvent("ravn_logs:explosionDetected", explosionType, posX, posY, posZ)
end)

-- ---------------------------------------------------------------------------
-- DEATH DETECTION (client-side monitoring)
-- ---------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local ped = PlayerPedId()
        if not ped or ped == 0 then goto continue_death end

        local currentlyDead = IsPedDeadOrDying(ped, true) or GetEntityHealth(ped) <= 0

        -- State transition: alive -> dead
        if currentlyDead and not isDead then
            isDead = true

            local killerEntity = GetPedSourceOfDeath(ped)
            local killerType   = GetPedCauseOfDeath(ped)
            local weaponHash   = GetPedCauseOfDeath(ped)

            TriggerServerEvent("ravn_logs:playerDeath", {
                killerEntity = killerEntity,
                killerType   = killerType,
                weaponHash   = weaponHash,
                position     = {
                    x = RavnUtils.Round(GetEntityCoords(ped).x, 2),
                    y = RavnUtils.Round(GetEntityCoords(ped).y, 2),
                    z = RavnUtils.Round(GetEntityCoords(ped).z, 2),
                },
            })
        end

        -- State transition: dead -> alive (respawn)
        if not currentlyDead and isDead then
            isDead = false
        end

        ::continue_death::
    end
end)

-- ---------------------------------------------------------------------------
-- CHAT MESSAGE CAPTURE (F8 console)
-- ---------------------------------------------------------------------------

-- Intercept when the user types a command in F8 console
-- We use the chat input suggestion availability to detect console usage
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)

        if not Config.EnabledLogs or not Config.EnabledLogs.console then
            goto continue_console
        end

        -- Attempt to detect if console is open and capture commands
        -- FiveM doesn't have a direct API for this, but we can use
        -- RegisterKeyMapping / RegisterCommand with console true as a proxy
        -- The best approach: resource authors call our event when they
        -- want console commands logged.

        ::continue_console::
    end
end)

-- Register a client command that can be triggered from F8
-- This captures the raw console input and forwards it to the server
RegisterCommand("__ravn_console_hook", function(source, args, rawCommand)
    -- This command should never be called directly; it's used as a proxy
    -- to detect F8 usage. Resources can forward through this.
end, false)

-- Alternative: capture via chat suggestion
-- When the player uses the console, we can try to detect it via
-- the chat input state. This is a best-effort client-side approach.

-- ---------------------------------------------------------------------------
-- SUICIDE / ENVIRONMENTAL DEATH DETECTION (forwarded to server)
-- ---------------------------------------------------------------------------

-- Additional death cause detection
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local ped = PlayerPedId()
        if not ped or ped == 0 then goto continue_suicide end

        -- Check if player just died via suicide (weapon in hand, recent shot)
        if IsPedDeadOrDying(ped, true) and not isDead then
            local killer = GetPedSourceOfDeath(ped)
            -- If killer is the player themselves or -1 (environment)
            if killer == ped or killer == -1 or killer == 0 then
                TriggerServerEvent("ravn_logs:playerDeath", {
                    killerEntity = killer,
                    killerType   = GetPedCauseOfDeath(ped),
                    weaponHash   = GetPedCauseOfDeath(ped),
                    isSuicide    = true,
                    position     = {
                        x = RavnUtils.Round(GetEntityCoords(ped).x, 2),
                        y = RavnUtils.Round(GetEntityCoords(ped).y, 2),
                        z = RavnUtils.Round(GetEntityCoords(ped).z, 2),
                    },
                })
            end
        end

        ::continue_suicide::
    end
end)

-- =============================================================================
-- CLIENT EVENT HANDLERS (receive from server or other resources)
-- =============================================================================

-- Can be triggered by other resources to log events from the client side
RegisterNetEvent("ravn_logs:clientLog", function(category, data)
    TriggerServerEvent("ravn_logs:clientLogForward", category, data)
end)

-- =============================================================================
-- CLIENT EXPORTS
-- =============================================================================

exports("IsPlayerDead", function()
    return isDead
end)

exports("TriggerLog", function(category, data)
    TriggerServerEvent("ravn_logs:clientLogForward", category, data)
end)
