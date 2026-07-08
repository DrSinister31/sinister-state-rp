---@diagnostic disable: undefined-global
-- ════════════════════════════════════════════════════════════════════════════════
-- rde_aipd | CLIENT | crime.lua
-- Realistic Witness-Based Crime System — ox_core Edition
-- ════════════════════════════════════════════════════════════════════════════════
--
-- FEATURES:
--  ✅ Zeuge muss 911-Call VOLLSTÄNDIG abschließen → erst dann Wanted Level
--  ✅ Zeuge töten/einschüchtern unterbricht den Call → kein Wanted Level
--  ✅ Area-basierte Handy-Wahrscheinlichkeit (Stadt hoch, Wildnis niedrig)
--  ✅ Line-of-Sight Prüfung für Zeugen
--  ✅ Vollständige Crime Detection: Schießen, Fahrzeugdiebstahl, Unfall,
--     Einbruch, Vandalismus, Assault, Mord
--  ✅ Wanted Level Decay wenn Polizei keine Sichtlinie hat
--  ✅ Rein ox_core – kein ESX
--
-- ✅ FIX #27 (1.0.1-alpha): Locale-Loading via ox_lib (alle Notifications i18n)
-- ✅ FIX #28 (1.0.1-alpha): Admin-Block respektiert nun Config.AdminSettings.exemptFromWanted
--                          (vorher: ALLE Crimes für Admins hard-geblockt → kein Zeuge wurde gesucht)
--
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- LOCALE LOADER (FIX #27)
-- ════════════════════════════════════════════════════════════════════════════════
local Locale = lib.load('locales.' .. GetConvar('ox:locale', 'en')) or {}
local function L(key, ...)
    local s = Locale[key]
    if not s then return key end
    if select('#', ...) > 0 then return s:format(...) end
    return s
end

local cache = {ped = 0, coords = vector3(0, 0, 0), vehicle = 0, inVehicle = false}

local crimeState = {
    isPoliceNearby    = false,
    cooldowns         = {},
    currentArea       = 'URBAN',
    areaMultiplier    = 1.0,
    isAdmin           = false,
    playerLoaded      = false,
    systemInitialized = false,
    lastSeenByCop     = 0,
    decayActive       = false,
    copsCanSeePlayer  = false,
    lastAreaCheck     = 0,
    lastPoliceCheck   = 0,
    -- ── v2.0: Combat Suppression Tracking ────────────────────────────────────
    lastShotFired     = 0,  -- GetGameTimer() bei letztem Schuss/Angriff
}

-- Telefon-Wahrscheinlichkeit je nach Gebiet — v2.0: deutlich realistischer
local PhoneChanceByArea = {
    CITY_CENTER = 0.60,  -- war 0.90 — nicht jeder greift sofort zum Handy
    URBAN       = 0.50,  -- war 0.85 — 50% ist realistisch
    SUBURBAN    = 0.35,  -- war 0.70
    RURAL       = 0.20,  -- war 0.45
    WILDERNESS  = 0.06,  -- war 0.15 — in der Wildnis fast niemand
}

local CallDuration = {min = 5000, max = 9000}  -- war 3000-6000: mehr Eingreif-Fenster

-- Guard flags — verhindern doppelte Threads
local crimeThreadStarted  = false
local decayThreadStarted  = false
local vehicleThreadStarted = false

-- ════════════════════════════════════════════════════════════════════════════════
-- CACHE THREAD
-- ════════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        cache.ped = PlayerPedId()
        if DoesEntityExist(cache.ped) then
            cache.coords    = GetEntityCoords(cache.ped)
            cache.vehicle   = GetVehiclePedIsIn(cache.ped, false)
            cache.inVehicle = cache.vehicle ~= 0
        end
        Wait(500)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

local function Debug(...)
    if Config.Debug then
        print('^3[Crime | Client]^7', ...)
    end
end

local function IsCrimeOnCooldown(crimeType)
    local cfg = Config.CrimeTypes[crimeType]
    if not cfg then return true end
    local cd = cfg.cooldown or 30000
    return crimeState.cooldowns[crimeType] and (GetGameTimer() - crimeState.cooldowns[crimeType]) < cd
end

local function GetCurrentArea()
    if not Config.Areas then return 'URBAN', 1.0 end
    for _, area in pairs(Config.Areas) do
        if #(cache.coords - area.coords) <= area.radius then
            local mult = Config.WitnessSystem
                and Config.WitnessSystem.areaMultipliers
                and Config.WitnessSystem.areaMultipliers[area.type]
                or 1.0
            return area.type, mult
        end
    end
    return 'URBAN', 1.0
end

local function CheckPoliceProximity()
    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) and GetPedType(ped) == 6 then
            if #(cache.coords - GetEntityCoords(ped)) <= 150.0 then
                return true
            end
        end
    end
    return false
end

local function GetWantedLevel()
    -- ✅ FIX: Server setzt wantedLevel auf Entity(ped).state, NICHT auf LocalPlayer.state!
    -- LocalPlayer.state.wantedLevel war IMMER nil → 0 → Decay + LOS-Check waren tot
    local ped = cache.ped
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local ok, val = pcall(function()
            return Entity(ped).state.wantedLevel
        end)
        if ok and val and type(val) == 'number' then return val end
    end
    return 0
end

-- ════════════════════════════════════════════════════════════════════════════════
-- LINE-OF-SIGHT
-- ════════════════════════════════════════════════════════════════════════════════

local function HasLineOfSight(fromCoords, toCoords, maxDistance)
    maxDistance = maxDistance or 60.0
    if #(fromCoords - toCoords) > maxDistance then return false end

    local ray = StartShapeTestRay(
        fromCoords.x, fromCoords.y, fromCoords.z + 1.0,
        toCoords.x,   toCoords.y,   toCoords.z + 1.0,
        -1, cache.ped, 0
    )
    local _, hit, _, _, entityHit = GetShapeTestResult(ray)
    return not (hit and entityHit ~= cache.ped)
end

local function CheckCopsLineOfSight()
    if GetWantedLevel() == 0 then return false end

    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) and GetPedType(ped) == 6 then
            local copCoords = GetEntityCoords(ped)
            local dist      = #(cache.coords - copCoords)
            if dist <= 120.0 and HasLineOfSight(copCoords, cache.coords, 120.0) then
                local heading   = GetEntityHeading(ped)
                local angle     = math.deg(math.atan2(
                    cache.coords.y - copCoords.y,
                    cache.coords.x - copCoords.x
                ))
                local diff = math.abs(heading - angle) % 360
                if diff < 120 or diff > 240 then
                    return true, ped, dist
                end
            end
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- WITNESS SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

-- ── v2.0: Tageszeit-Modifikator ──────────────────────────────────────────────
-- Nachts gibt es deutlich weniger Zeugen (weniger Menschen draußen).
local function GetTimeOfDayModifier()
    local h  = GetClockHours()
    local ws = Config.WitnessSystem or {}
    if h >= (ws.nightHoursStart or 22) or h < (ws.nightHoursEnd or 6) then
        return ws.nightTimeModifier or 0.60
    end
    if h >= 18 then return 0.85 end
    return 1.0
end

-- ── v2.0: Combat-Suppression ─────────────────────────────────────────────────
-- Aktives Feuergefecht → Zeugen ducken sich statt zu rufen.
local function IsCombatSuppressed()
    local ws = Config.WitnessSystem or {}
    if not ws.combatSuppression then return false end
    if crimeState.lastShotFired == 0 then return false end
    return (GetGameTimer() - crimeState.lastShotFired) < (ws.combatSuppressionWindow or 5000)
end

-- ── v2.0: WitnessCanCall ─────────────────────────────────────────────────────
-- Filtert nur NPCs raus die PHYSISCH nicht rufen können.
-- Flüchtende NPCs sind KEINE harten Filter mehr — jemand der wegrennt kann trotzdem
-- 911 rufen. `IsPedFleeing` wird stattdessen als Soft-Modifier in GetNearbyWitnesses
-- verwendet (halbe Phone-Chance). Das war der Hauptfehler: GTA setzt sofort alle
-- NPCs in Flee-Mode nach einem Crime → mit Hard-Filter = 0 Zeugen guaranteed.
local function WitnessCanCall(witnessPed)
    if not DoesEntityExist(witnessPed) then return false end
    if IsPedDeadOrDying(witnessPed, true) then return false end
    -- Ragdoll: liegt am Boden → kann nicht rufen
    if IsPedRagdoll(witnessPed) then return false end
    -- Aktiver Nahkampf → beschäftigt
    if IsPedInMeleeCombat(witnessPed) then return false end
    -- Schwer verletzt: unter ~20% Basis-HP (NPC-HP ~100-200; 50 = sicher tot/sterbend)
    if GetEntityHealth(witnessPed) < 50 then return false end
    -- Sehr schnelles Fahrzeug: >80 km/h = zu abgelenkt/gefährlich
    local veh = GetVehiclePedIsIn(witnessPed, false)
    if veh ~= 0 and GetEntitySpeed(veh) * 3.6 > 80.0 then return false end
    return true
end



-- ✅ FIX #31 (1.0.2-alpha): NPC sieht den Crime nur wenn er Sichtlinie hat UND
-- der Crime im Sichtfeld liegt. Vorher: jeder NPC im Radius war "Zeuge" — selbst
-- der NPC der hinter ner Wand stand oder dem Spieler den Rücken zukehrte.
--
-- ✅ FIX #40 (1.0.2-alpha hotfix): FOV-Mathe komplett umgestellt auf Forward-Vector
-- Dot-Product. Vorher: atan2+90 Hack der bei "Crime nördlich von Zeuge" ein angle
-- von 180 statt 0 lieferte → ALLE NPCs die nordwärts schauten wurden rejected.
-- Praktischer Effekt: man fuhr durch Vinewood vorbei an NPCs auf dem Gehweg
-- (die alle nordwärts liefen) und KEINER war Zeuge.
--
-- Außerdem: Default FOV 220° war zu strikt für Drive-By Szenarien.
-- Jetzt 280° default (nur direkt hinter dem NPC = blind), kann aber per Config
-- runtergeschraubt werden für strengere Realismus-Setups.
local witnessRejectStats = {fov = 0, los = 0, lastReset = 0}

local function WitnessCanSee(witnessPed, crimeCoords)
    local cfg = Config.WitnessSystem
    if not cfg or not cfg.requireLineOfSight then return true end
    if not DoesEntityExist(witnessPed) then return false end

    local witnessCoords = GetEntityCoords(witnessPed)

    -- ──── (0) PROXIMITY GRACE — sehr nahe NPCs hören & spüren immer ───────────
    -- v2.0: Grace 8m (war 12m im Original, wir hatten 5m gesetzt — zu klein).
    local grace = cfg.proximityGraceDistance or 8.0  -- war 5.0
    local dx    = crimeCoords.x - witnessCoords.x
    local dy    = crimeCoords.y - witnessCoords.y
    local dz    = crimeCoords.z - witnessCoords.z
    local dist3D = math.sqrt(dx*dx + dy*dy + dz*dz)
    local closeProximity = dist3D <= grace

    -- ──── (a) FIELD OF VIEW — Forward-Vector Dot-Product ──────────────────────
    -- v2.0: FOV 240° (war 320° original). 240° = NPC ist nur direkt hinter sich blind.
    -- 180° war zu strikt: flüchtende NPCs (Rücken zum Crime) wurden alle rejected.
    local fov = cfg.fieldOfView or 240.0  -- war 180.0 (zu strikt), original war 320.0
    if fov < 359.0 and not closeProximity then
        local fwd = GetEntityForwardVector(witnessPed)
        local dist2D = math.sqrt(dx*dx + dy*dy)
        if dist2D > 0.01 then
            local dot = (fwd.x * dx + fwd.y * dy) / dist2D
            local cosHalfFov = math.cos(math.rad(fov / 2.0))
            if dot < cosHalfFov then
                witnessRejectStats.fov = witnessRejectStats.fov + 1
                return false
            end
        end
    end

    -- ──── (b) LINE OF SIGHT — World-Geometry-Only Raycast ─────────────────────
    if not closeProximity then
        local ray = StartExpensiveSynchronousShapeTestLosProbe(
            witnessCoords.x, witnessCoords.y, witnessCoords.z + 1.0,
            crimeCoords.x,   crimeCoords.y,   crimeCoords.z   + 1.0,
            1, witnessPed, 0
        )
        local _, hit = GetShapeTestResult(ray)
        if hit then
            witnessRejectStats.los = witnessRejectStats.los + 1
            return false
        end
    end

    return true
end

local function GetNearbyWitnesses(coords, radius, excludePed)
    local cfg      = Config.WitnessSystem or {}
    local areaType = crimeState.currentArea

    -- ── v2.0: Basis Phone-Chance × Tageszeit × Combat-Suppression ─────────────
    local baseChance   = PhoneChanceByArea[areaType] or 0.50
    local timeModifier = GetTimeOfDayModifier()
    local phoneChance  = baseChance * timeModifier

    if IsCombatSuppressed() then
        local mult = cfg.combatSuppressionMultiplier or 0.20
        phoneChance = phoneChance * mult
        Debug(('⚔ Combat Suppression — Phone Chance × %.2f'):format(mult))
    end

    local result = {npcs = {}, players = {}}

    local startFov, startLos = witnessRejectStats.fov, witnessRejectStats.los

    local excludeId = excludePed and DoesEntityExist(excludePed) and excludePed or nil

    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped)
            and ped ~= excludeId
            and not IsPedAPlayer(ped)
            and not IsPedDeadOrDying(ped, true)
        then
            local pedType = GetPedType(ped)
            if pedType ~= 6 and pedType ~= 27 and pedType ~= 28 then
                local pedCoords = GetEntityCoords(ped)
                local distance  = #(coords - pedCoords)
                if distance <= radius then
                    -- ✅ v2.0: WitnessCanCall — physisch fähig zu rufen?
                    if WitnessCanCall(ped) then
                        if WitnessCanSee(ped, coords) then
                            -- Flüchtende NPCs: halbe Chance — sie sind abgelenkt,
                            -- aber können trotzdem rufen (Hauptfehler war Hard-Filter).
                            local effectiveChance = phoneChance
                            if IsPedFleeing(ped) then effectiveChance = effectiveChance * 0.5 end
                            result.npcs[#result.npcs + 1] = {
                                ped          = ped,
                                distance     = distance,
                                hasPhone     = math.random() < effectiveChance,
                                awareness    = math.random(60, 100) / 100,
                                callDuration = math.random(
                                    cfg.callDurationMin or CallDuration.min,
                                    cfg.callDurationMax or CallDuration.max
                                ),
                            }
                        end
                    end
                end
            end
        end
    end

    if cfg.playersAsAutoWitnesses then
        for _, pid in ipairs(GetActivePlayers()) do
            if pid ~= PlayerId() then
                local targetPed = GetPlayerPed(pid)
                if DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                    local dist = #(coords - GetEntityCoords(targetPed))
                    if dist <= radius and WitnessCanSee(targetPed, coords) then
                        result.players[#result.players + 1] = {
                            player   = pid,
                            distance = dist,
                            hasPhone = true,
                        }
                    end
                end
            end
        end
    end

    local fovRej = witnessRejectStats.fov - startFov
    local losRej = witnessRejectStats.los - startLos
    local withPhone = 0
    for _, w in ipairs(result.npcs) do if w.hasPhone then withPhone = withPhone + 1 end end

    Debug(('Witnesses: %d NPC (%d mit Telefon) | %d Player | Chance: %.0f%% (×%.2f Tageszeit%s) | Rejected: %d FOV / %d LOS'):format(
        #result.npcs, withPhone, #result.players,
        phoneChance * 100, timeModifier,
        IsCombatSuppressed() and ' ×COMBAT' or '',
        fovRej, losRej
    ))
    return result
end

-- Findet den besten NPC-Zeugen mit Telefon.
-- BEWUSST EINFACH gehalten: StartShapeTestRay ist asynchron und liefert im
-- selben Frame kein zuverlässiges Ergebnis → kein Raycast hier.
-- Die phone-Wahrscheinlichkeit (area-basiert) ist die einzige Hürde.
local function FindBestCaller(witnesses, crimeCoords)
    -- Bevorzuge den nächsten NPC mit Telefon der noch lebt
    local bestNPC, bestDist = nil, math.huge
    for _, w in ipairs(witnesses.npcs) do
        if w.hasPhone
            and DoesEntityExist(w.ped)
            and not IsPedDeadOrDying(w.ped, true)
        then
            if w.distance < bestDist then
                bestNPC  = w
                bestDist = w.distance
            end
        end
    end

    if bestNPC then
        Debug(('FindBestCaller: NPC-Zeuge gewählt | %.1fm | hasPhone=true'):format(bestDist))
        return bestNPC
    end

    -- Spieler-Zeuge als Fallback
    for _, w in ipairs(witnesses.players) do
        Debug('FindBestCaller: Spieler-Zeuge als Fallback gewählt')
        return w
    end

    Debug(('FindBestCaller: kein Zeuge – %d NPCs geprüft (ohne Telefon oder tot)'):format(#witnesses.npcs))
    return nil
end

-- ════════════════════════════════════════════════════════════════════════════════
-- VEHICLE CO-OCCUPANCY (1.0.2-alpha)
-- ════════════════════════════════════════════════════════════════════════════════
--
-- Wenn der Crime in einem Fahrzeug passiert, sammle die Server-IDs aller
-- Mitfahrer ein. Der Server propagiert dann den Wanted Level auf sie.
--
local function GetVehicleCoOccupantServerIds()
    if not Config.VehicleCoOccupancy or not Config.VehicleCoOccupancy.enabled then return {} end
    if not cache.inVehicle or not DoesEntityExist(cache.vehicle) then return {} end

    local ids   = {}
    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(cache.vehicle))
    -- Seats: -1 = driver, 0..n = passengers
    for seat = -1, maxSeats - 2 do
        local seatPed = GetPedInVehicleSeat(cache.vehicle, seat)
        if seatPed and seatPed ~= 0 and seatPed ~= cache.ped
            and DoesEntityExist(seatPed) and IsPedAPlayer(seatPed)
        then
            local otherPlayer = NetworkGetPlayerIndexFromPed(seatPed)
            if otherPlayer ~= -1 then
                local serverId = GetPlayerServerId(otherPlayer)
                if serverId and serverId > 0 then
                    ids[#ids + 1] = serverId
                end
            end
        end
    end
    return ids
end

-- ════════════════════════════════════════════════════════════════════════════════
-- WITNESS VISUAL TEARDOWN — sicheres Cleanup für Phone-Prop + Blip
-- ════════════════════════════════════════════════════════════════════════════════
local function TeardownWitnessVisuals(visuals)
    if not visuals then return end
    if visuals.phone and DoesEntityExist(visuals.phone) then
        DetachEntity(visuals.phone, true, true)
        DeleteObject(visuals.phone)
    end
    if visuals.blip and DoesBlipExist(visuals.blip) then
        RemoveBlip(visuals.blip)
    end
    if visuals.pulseThreadId then
        visuals.pulseStop = true
    end
    if visuals.callerPed and DoesEntityExist(visuals.callerPed) then
        ClearPedTasks(visuals.callerPed)
        -- ✅ FIX #45 (1.0.2-alpha hotfix4): Mission-Entity-Lock wieder lösen
        -- damit die Engine den NPC wieder normal streamen/despawnen kann.
        -- Sonst hätten wir nach jedem Call leichende Geist-NPCs in der Welt.
        SetBlockingOfNonTemporaryEvents(visuals.callerPed, false)
        SetEntityAsMissionEntity(visuals.callerPed, false, true)
        SetPedAsNoLongerNeeded(visuals.callerPed)
    end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 911-CALL SEQUENZ — Sichtbar, unterbrechbar, immersiv
-- ════════════════════════════════════════════════════════════════════════════════
--
-- DAS IST DAS HERZSTÜCK:
-- 1. Zeuge schaut den Spieler an (Reaktion)
-- 2. Spawnt sichtbares Handy in der Hand des Zeugen
-- 3. Setzt Blip über den Kopf des Zeugen
-- 4. Spielt Dial-Anim, dann Talk-Anim
-- 5. Erst nach komplettem Call → Wanted Level
-- 6. Wird der Zeuge erledigt → kompletter Teardown, kein Wanted Level
--
-- ════════════════════════════════════════════════════════════════════════════════

local function Execute911CallSequence(caller, crimeType, crimeCoords, crimeLevel, witnessCount)
    local cfg             = Config.WitnessSystem or {}
    local isPlayerWitness = caller.player ~= nil
    local callerPed       = (not isPlayerWitness) and caller.ped or nil
    local callDuration    = caller.callDuration or math.random(
        cfg.callDurationMin or CallDuration.min,
        cfg.callDurationMax or CallDuration.max
    )
    local reactionDelay   = math.random(
        cfg.reactionMin or 800,
        cfg.reactionMax or 2000
    )
    local intimidateDist  = cfg.intimidationDistance or 8.0

    local coOccupants = GetVehicleCoOccupantServerIds()

    local visuals = {
        phone         = nil,
        blip          = nil,
        callerPed     = callerPed,
        pulseStop     = false,
    }

    -- Helper: Zeuge noch am Leben?
    local function CallerAlive()
        if not callerPed then return true end
        return DoesEntityExist(callerPed) and not IsPedDeadOrDying(callerPed, true)
    end

    -- Helper: Spieler nähert sich bedrohlich?
    local function PlayerIntimidating()
        if not callerPed or not DoesEntityExist(callerPed) then return false end
        return #(GetEntityCoords(callerPed) - cache.coords) < intimidateDist
    end

    -- Helper: Zeuge unterbrochen — aufräumen + Server informieren
    local function HandleInterruption(reason)
        if callerPed and DoesEntityExist(callerPed) then
            ClearPedTasks(callerPed)
            if reason == 'intimidated' then
                TaskSmartFleePed(callerPed, cache.ped, 200.0, -1, false, false)
            end
            SetBlockingOfNonTemporaryEvents(callerPed, false)
            SetEntityAsMissionEntity(callerPed, false, true)
            SetPedAsNoLongerNeeded(callerPed)
            visuals.callerPed = nil
        end
        TeardownWitnessVisuals(visuals)
        TriggerServerEvent('police:crimeDetectedNoWitness', crimeType, crimeCoords)
        if reason == 'intimidated' then
            lib.notify({ type='success', description=L('witness_intimidated'), duration=3000, icon='eye-off' })
        else
            lib.notify({ type='success', description=L('witness_killed_during_call'), duration=3000 })
        end
    end

    CreateThread(function()
        -- ✅ FIX #45: Caller gegen Engine-Despawn pinnen
        if callerPed and DoesEntityExist(callerPed) then
            SetEntityAsMissionEntity(callerPed, true, true)
            SetBlockingOfNonTemporaryEvents(callerPed, true)
            SetPedKeepTask(callerPed, true)
        end

        -- ──────── 1. REAKTIONSPHASE — Zeuge schaut Spieler an ─────────────────
        if callerPed then
            TaskLookAtEntity(callerPed, cache.ped, reactionDelay + 1000, 2048, 3)
        end
        Wait(reactionDelay)

        if not CallerAlive() then
            Debug('Zeuge vor Panikphase gestorben')
            HandleInterruption('dead')
            return
        end

        -- ──────── 2. PANIK-PHASE (v2.0 NEU) ──────────────────────────────────
        -- Zeuge zögert, weicht zurück — BEVOR er das Handy rausholt.
        -- Spieler kann in dieser Zeit den Zeugen einschüchtern (< 8m = Flucht).
        local panicMin      = cfg.panicDelay and cfg.panicDelay.min or 1500
        local panicMax      = cfg.panicDelay and cfg.panicDelay.max or 3500
        local panicDuration = math.random(panicMin, panicMax)

        if callerPed and DoesEntityExist(callerPed) then
            -- Leicht vom Spieler zurückweichen
            local witnessPos = GetEntityCoords(callerPed)
            local toPlayer   = cache.coords - witnessPos
            local len        = math.sqrt(toPlayer.x * toPlayer.x + toPlayer.y * toPlayer.y)
            if len > 0.5 then
                local backPos = witnessPos + vector3(
                    (-toPlayer.x / len) * 2.5,
                    (-toPlayer.y / len) * 2.5,
                    0
                )
                TaskGoToCoordAnyMeans(callerPed, backPos.x, backPos.y, backPos.z, 1.5, 0, 0, 786603, 0)
            end
        end

        -- Panik-Phase Monitor (alle 200ms prüfen)
        local panicStart = GetGameTimer()
        local interrupted = nil
        while (GetGameTimer() - panicStart) < panicDuration do
            Wait(200)
            if not CallerAlive() then interrupted = 'dead'; break end
            if PlayerIntimidating() then interrupted = 'intimidated'; break end
        end

        if interrupted then
            Debug('Zeuge während Panikphase: ' .. interrupted)
            HandleInterruption(interrupted)
            return
        end

        -- ──────── 3. HANDY-PROP SPAWNEN ────────────────────────────────────────
        if callerPed and cfg.visiblePhoneCall ~= false then
            local phoneModel = joaat(cfg.phonePropModel or 'prop_npc_phone_02')
            RequestModel(phoneModel)
            local timeout = 0
            while not HasModelLoaded(phoneModel) and timeout < 60 do
                Wait(20); timeout = timeout + 1
            end
            if HasModelLoaded(phoneModel) then
                local pedCoords = GetEntityCoords(callerPed)
                local phoneObj  = CreateObject(phoneModel, pedCoords.x, pedCoords.y, pedCoords.z + 0.2, true, true, false)
                if DoesEntityExist(phoneObj) then
                    AttachEntityToEntity(phoneObj, callerPed, GetPedBoneIndex(callerPed, 28422),
                        0.0, 0.0, 0.025,
                        10.0, 160.0, 0.0,
                        true, true, false, true, 1, true)
                    visuals.phone = phoneObj
                end
                SetModelAsNoLongerNeeded(phoneModel)
            end
        end

        -- ──────── 4. CALLER-BLIP ───────────────────────────────────────────────
        if callerPed and cfg.callerBlip and cfg.callerBlip.enabled then
            local b = AddBlipForEntity(callerPed)
            if DoesBlipExist(b) then
                SetBlipSprite(b,    cfg.callerBlip.sprite or 280)
                SetBlipColour(b,    cfg.callerBlip.color  or 1)
                SetBlipScale(b,     cfg.callerBlip.scale  or 0.8)
                SetBlipAsShortRange(b, cfg.callerBlip.shortRange or false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("📞 Zeuge ruft 911")
                EndTextCommandSetBlipName(b)
                visuals.blip = b
                if cfg.callerBlip.pulseAlpha then
                    CreateThread(function()
                        while not visuals.pulseStop and DoesBlipExist(b) do
                            SetBlipAlpha(b, 255); Wait(400)
                            SetBlipAlpha(b, 120); Wait(400)
                        end
                    end)
                end
            end
        end

        lib.notify({ type='warning', description=L('witness_dialing'), duration=2500, icon='phone' })

        -- ──────── 5. DIAL-ANIM ────────────────────────────────────────────────
        if callerPed and DoesEntityExist(callerPed) then
            local dialDict = 'cellphone@'
            RequestAnimDict(dialDict)
            local timeout = 0
            while not HasAnimDictLoaded(dialDict) and timeout < 100 do Wait(10); timeout = timeout + 1 end
            if HasAnimDictLoaded(dialDict) then
                TaskPlayAnim(callerPed, dialDict, 'cellphone_text_in', 8.0, -8.0, 1200, 50, 0, false, false, false)
            end
        end

        Wait(1200)

        -- Check #2 — während Dial + Einschüchterung
        if not CallerAlive() then HandleInterruption('dead'); return end
        if PlayerIntimidating() then HandleInterruption('intimidated'); return end

        -- ──────── 6. TALK-ANIM ────────────────────────────────────────────────
        if callerPed and DoesEntityExist(callerPed) then
            local talkDict = 'cellphone@'
            if HasAnimDictLoaded(talkDict) then
                TaskPlayAnim(callerPed, talkDict, 'cellphone_call_listen_base', 8.0, -8.0, -1, 49, 0, false, false, false)
            end
        end

        -- ──────── 7. CALL-WAIT — mit laufendem Interruption-Monitor ──────────
        -- Alle 400ms prüfen — Spieler kann bis zum letzten Moment eingreifen.
        local remaining = callDuration - 1200
        if remaining > 0 then
            local talkStart  = GetGameTimer()
            local talkInterrupt = nil
            while (GetGameTimer() - talkStart) < remaining do
                Wait(400)
                if not CallerAlive() then talkInterrupt = 'dead'; break end
                if PlayerIntimidating() then talkInterrupt = 'intimidated'; break end
            end
            if talkInterrupt then
                Debug('Zeuge während Talk: ' .. talkInterrupt)
                HandleInterruption(talkInterrupt)
                return
            end
        end

        -- ──────── 8. CALL ERFOLGREICH ─────────────────────────────────────────
        Debug(('911-Call abgeschlossen! Crime: %s'):format(crimeType))

        TriggerServerEvent('police:reportCrime', {
            type          = crimeType,
            coords        = crimeCoords,
            level         = crimeLevel,
            witnessCount  = witnessCount,
            crimeTime     = GetGameTimer(),
            callCompleted = true,
            coOccupants   = coOccupants,
            witness       = {
                distance       = caller.distance or 0,
                isPlayerCaller = isPlayerWitness,
            },
        })

        TriggerServerEvent('police:nostr:crime', crimeType, crimeState.currentArea, true)

        SetTimeout(2000, function() TeardownWitnessVisuals(visuals) end)
    end)
end


-- ════════════════════════════════════════════════════════════════════════════════
-- LOG CRIME — Hauptfunktion
-- ════════════════════════════════════════════════════════════════════════════════

function LogCrime(crimeType, coords, force, victimPed)
    if not crimeState.systemInitialized then
        Debug('System noch nicht initialisiert')
        return false
    end

    -- ✅ FIX #28: Nur blocken wenn Admin TATSÄCHLICH exempt ist (Config-Setting respektieren!)
    -- Vorher: jeder Admin → ALLE Crimes geblockt → kein Zeuge wurde je gesucht.
    -- Jetzt: nur wenn Config.AdminSettings.exemptFromWanted = true → blocken.
    -- Sonst: normaler Crime-Flow (Witness → 911-Call → Wanted Level).
    if crimeState.isAdmin and not force
        and Config.AdminSettings
        and Config.AdminSettings.exemptFromWanted
    then
        Debug(('Admin-Verbrechen unterdrückt (exemptFromWanted=true): %s'):format(crimeType))
        return false
    end

    local crimeConfig = Config.CrimeTypes[crimeType]
    if not crimeConfig then
        Debug(('Unbekannter Crime-Typ: %s'):format(crimeType))
        return false
    end

    if not force and IsCrimeOnCooldown(crimeType) then
        return false
    end

    if not DoesEntityExist(cache.ped) then return false end

    -- Cooldown sofort setzen
    crimeState.cooldowns[crimeType] = GetGameTimer()

    local crimeCoords  = coords or cache.coords
    local crimeLevel   = crimeConfig.level or 1
    local currentWanted = GetWantedLevel()

    -- Additives Wanted-Level-System
    if currentWanted > 0 then
        if crimeLevel < currentWanted then
            Debug(('%s ignoriert (Level %d < aktuell %d)'):format(crimeType, crimeLevel, currentWanted))
            return false
        elseif crimeLevel == currentWanted then
            crimeLevel = math.min(5, currentWanted + 1)
        end
    end
    crimeLevel = math.min(crimeLevel, 5)

    -- Zeuge-Radius je nach Schwere
    local baseRadius = (Config.WitnessSystem and Config.WitnessSystem.baseDistance) or 50.0
    local severity   = crimeConfig.severity or 'medium'
    local radius     = baseRadius * (
        severity == 'critical' and 1.8 or
        severity == 'high'     and 1.4 or
        1.0
    )

    local witnesses = GetNearbyWitnesses(crimeCoords, radius, victimPed)
    local withPhone = 0
    for _, w in ipairs(witnesses.npcs) do
        if w.hasPhone then withPhone = withPhone + 1 end
    end
    Debug(('LogCrime %s | %d NPCs gefunden | %d mit Telefon | %d Spieler | Area: %s'):format(
        crimeType, #witnesses.npcs, withPhone, #witnesses.players, crimeState.currentArea
    ))
    local caller    = FindBestCaller(witnesses, crimeCoords)

    -- ✅ FIX #42 (1.0.2-alpha hotfix2): Delayed Re-Scan.
    -- Wenn beim ersten Scan kein Zeuge da war, scannen wir nochmal nach 2-3s.
    -- Realistisches Szenario: Schuss fällt → NPCs hören das → laufen zum Tatort →
    -- werden JETZT Zeugen. Vorher: "kein Zeuge im exakten Moment des Crimes" =
    -- never wanted. Jetzt: NPCs die nach der Tat ankommen werden erfasst.
    if not caller then
        local rescans  = Config.WitnessSystem and Config.WitnessSystem.delayedRescans or 1  -- war 2
        local rescanMs = Config.WitnessSystem and Config.WitnessSystem.delayedRescanInterval or 4000  -- war 2500
        if rescans > 0 then
            CreateThread(function()
                for attempt = 1, rescans do
                    Wait(rescanMs)
                    -- Crime ist veraltet wenn der Spieler tot/verhaftet ist oder schon Wanted
                    if WantedSystem and WantedSystem.isArrested then return end
                    if WantedSystem and WantedSystem.isDead     then return end
                    local nowWanted = WantedSystem and WantedSystem.level or 0
                    if nowWanted > 0 and nowWanted >= crimeLevel then return end

                    -- Re-Scan mit gleichen Coords (Tatort-Position)
                    local w2 = GetNearbyWitnesses(crimeCoords, radius, victimPed)
                    local c2 = FindBestCaller(w2, crimeCoords)
                    if c2 then
                        Debug(('%s: Re-Scan #%d hat Zeuge gefunden!'):format(crimeType, attempt))
                        local tw = #w2.npcs + #w2.players
                        lib.notify({
                            type        = 'warning',
                            description = L('witness_spotted_you', crimeConfig.description or crimeType),
                            duration    = 3000,
                        })
                        Execute911CallSequence(c2, crimeType, crimeCoords, crimeLevel, tw)
                        return
                    end
                    Debug(('%s: Re-Scan #%d/%d auch leer'):format(crimeType, attempt, rescans))
                end
                -- Alle Re-Scans leer → JETZT erst das "No witnesses" Event/Notif
                TriggerServerEvent('police:crimeDetectedNoWitness', crimeType, crimeCoords)
                TriggerServerEvent('police:nostr:crime', crimeType, crimeState.currentArea, false)
                lib.notify({
                    type        = 'success',
                    description = L('no_witnesses_nearby'),
                    duration    = 2500,
                })
            end)
        else
            -- Re-Scans deaktiviert → altes Verhalten
            TriggerServerEvent('police:crimeDetectedNoWitness', crimeType, crimeCoords)
            TriggerServerEvent('police:nostr:crime', crimeType, crimeState.currentArea, false)
            lib.notify({
                type        = 'success',
                description = L('no_witnesses_nearby'),
                duration    = 2500,
            })
        end
        Debug(('%s: kein Zeuge im ersten Scan, Re-Scan-Loop gestartet'):format(crimeType))
        return false
    end

    -- Zeuge gefunden → 911-Call starten
    local totalWitnesses = #witnesses.npcs + #witnesses.players

    Debug(('%s: Zeuge gefunden (%.0fm) – 911-Call läuft...'):format(crimeType, caller.distance or 0))

    lib.notify({
        type        = 'warning',
        description = L('witness_spotted_you', crimeConfig.description or crimeType),
        duration    = 3000,
    })

    Execute911CallSequence(caller, crimeType, crimeCoords, crimeLevel, totalWitnesses)
    return true
end

-- ════════════════════════════════════════════════════════════════════════════════
-- WANTED LEVEL DECAY
-- ════════════════════════════════════════════════════════════════════════════════

local decayConfig = {
    enabled         = true,
    checkInterval   = 2000,
    timeBeforeDecay = 15000,
    decayInterval   = 20000,
    lastDecayTime   = 0,
}

local function StartWantedDecaySystem()
    if decayThreadStarted then return end
    decayThreadStarted = true

    CreateThread(function()
        while true do
            Wait(decayConfig.checkInterval)
            if not decayConfig.enabled then goto continue end

            -- BUG FIX: Do NOT decay while arrested/surrendered.
            -- Race condition: GetWantedLevel() returns >0 in the ~6500ms window between
            -- TriggerServerEvent('police:syncArrest') and lib.callback.await('police:arrestPlayer').
            -- If decay fires here, server state.level hits 0 before arrestPlayer callback
            -- arrives → server rejects arrest (level<=0 && !isJailed) → no jail teleport.
            if WantedSystem and (WantedSystem.isArrested or WantedSystem.isSurrendered) then
                crimeState.decayActive = false
                goto continue
            end

            local wantedLevel = GetWantedLevel()
            if wantedLevel > 0 then
                local canSee = CheckCopsLineOfSight()
                crimeState.copsCanSeePlayer = canSee

                if canSee then
                    crimeState.lastSeenByCop = GetGameTimer()
                    crimeState.decayActive   = false
                else
                    local timeSince = GetGameTimer() - crimeState.lastSeenByCop

                    if timeSince >= decayConfig.timeBeforeDecay then
                        if not crimeState.decayActive then
                            crimeState.decayActive    = true
                            decayConfig.lastDecayTime = GetGameTimer()
                            lib.notify({
                                type        = 'inform',
                                description = L('wanted_decay_start'),
                                duration    = 3000,
                            })
                        end

                        if (GetGameTimer() - decayConfig.lastDecayTime) >= decayConfig.decayInterval then
                            if GetWantedLevel() > 0 then
                                TriggerServerEvent('police:decayWantedLevel')
                                decayConfig.lastDecayTime = GetGameTimer()
                            else
                                crimeState.decayActive = false
                            end
                        end
                    end
                end
            else
                crimeState.decayActive   = false
                crimeState.lastSeenByCop = 0
            end

            ::continue::
        end
    end)
    Debug('Wanted Decay System gestartet')
end

-- ════════════════════════════════════════════════════════════════════════════════
-- STATEBAG SYNC
-- ════════════════════════════════════════════════════════════════════════════════

-- ✅ FIX #12: StateBag Handler ENTFERNT — main.lua hat den korrekten entity-basierten Handler.
-- Der alte Handler hier nutzte 'player:X' Format, aber ox_core setzt StateBags auf Entity(ped).
-- Doppelter Handler wäre sowieso redundant.

-- ════════════════════════════════════════════════════════════════════════════════
-- MURDER / ASSAULT — gameEventTriggered
-- ════════════════════════════════════════════════════════════════════════════════

AddEventHandler('gameEventTriggered', function(name, args)
    if not crimeState.systemInitialized or not crimeState.playerLoaded then return end
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim     = args[1]
    local attacker   = args[2]
    local isFatal    = args[6]

    if attacker ~= cache.ped or victim == cache.ped then return end
    if not DoesEntityExist(victim) then return end

    -- ── v2.0: Combat Suppression Tracking ────────────────────────────────────
    -- Jeder Angriff setzt den Timer → supprimiert Zeugen-Calls während Feuergefecht.
    crimeState.lastShotFired = GetGameTimer()

    local victimType = GetPedType(victim)

    if isFatal == 1 or IsEntityDead(victim) then
        if victimType == 6 then
            -- Cop getötet: force=true BLEIBT — andere Cops wissen es sofort.
            LogCrime('MURDER_COP', nil, true, victim)
            TriggerServerEvent('police:nostr:copKilled')
        elseif IsPedAPlayer(victim) or (victimType ~= 27 and victimType ~= 28) then
            -- ✅ v2.0: Mord braucht jetzt EINEN ZEUGEN — kein force=true mehr!
            -- Mord in einer leeren Gasse = kein Wanted Level (realistisch).
            -- 500ms Delay: NPCs eine Schrecksekunde geben zum Reagieren.
            CreateThread(function()
                Wait(500)
                LogCrime('MURDER', nil, false, victim)
            end)
        end
    else
        if victimType == 6 then
            LogCrime('ASSAULT_COP', nil, false, victim)
        elseif IsPedAPlayer(victim) or (victimType ~= 27 and victimType ~= 28) then
            LogCrime('ASSAULT', nil, false, victim)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- CRIME DETECTION THREADS
-- (aus dem alten System portiert + ESX entfernt + ox_core/ox_inventory)
-- ════════════════════════════════════════════════════════════════════════════════

local function StartCrimeDetectionThread()
    if crimeThreadStarted then
        Debug('Crime-Thread läuft bereits')
        return
    end
    crimeThreadStarted = true

    -- ── Area & Police Proximity Checks ──────────────────────────────────────
    CreateThread(function()
        while true do
            Wait(2000)
            if not crimeState.systemInitialized then goto nextAreaCheck end

            local now = GetGameTimer()
            if now - crimeState.lastAreaCheck > 5000 then
                crimeState.currentArea, crimeState.areaMultiplier = GetCurrentArea()
                crimeState.lastAreaCheck = now
            end
            if now - crimeState.lastPoliceCheck > 3000 then
                crimeState.isPoliceNearby = CheckPoliceProximity()
                crimeState.lastPoliceCheck = now
            end

            ::nextAreaCheck::
        end
    end)

    -- ── SHOOTING — Schuss abgefeuert ─────────────────────────────────────────
    -- ✅ FIX #34 (1.0.2-alpha): Nur triggern wenn TATSÄCHLICH ein Ziel im Spiel ist.
    -- Vorher: jeder Schuss in die Luft → SHOOTING → 0.9 witnessChance → Wanted Level.
    -- Jetzt: muss aimen auf Entity ODER es muss ein Treffer passiert sein.
    CreateThread(function()
        while true do
            Wait(100)
            if not crimeState.systemInitialized then goto nextShoot end

            if IsPedShooting(cache.ped) and not IsCrimeOnCooldown('SHOOTING') then
                local requiresTarget = Config.CrimeRealism and Config.CrimeRealism.shootingRequiresTarget
                local hasTarget = false

                if requiresTarget then
                    -- (a) Free-aim auf eine Entity?
                    local aiming, aimEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if aiming and aimEntity and aimEntity ~= 0 and DoesEntityExist(aimEntity) then
                        hasTarget = true
                    end
                    -- (b) Auto-Lock-Ziel? (Konsolen-Style)
                    if not hasTarget then
                        local lockTarget = GetPlayerTargetEntity(PlayerId())
                        if lockTarget and lockTarget ~= 0 then hasTarget = true end
                    end
                    -- (c) Treffer in den letzten paar Frames?
                    if not hasTarget and HasEntityBeenDamagedByEntity then
                        -- gameEventTriggered handelt damage events bereits separat —
                        -- aber wenn eine Entity in 30m getroffen wurde nehmen wir das mit
                        if IsBulletInArea(cache.coords.x, cache.coords.y, cache.coords.z, 25.0, true) then
                            -- Prüfen ob ein NPC in der Nähe getroffen wurde
                            local peds = GetGamePool('CPed')
                            for _, p in ipairs(peds) do
                                if p ~= cache.ped and HasEntityBeenDamagedByEntity(p, cache.ped, 1) then
                                    hasTarget = true
                                    ClearEntityLastDamageEntity(p)
                                    break
                                end
                            end
                        end
                    end
                else
                    hasTarget = true  -- Old behavior wenn Config aus
                end

                if hasTarget then
                    crimeState.lastShotFired = GetGameTimer()  -- v2.0: Combat Suppression
                    LogCrime('SHOOTING')
                else
                    -- Cooldown trotzdem setzen damit wir nicht jeden Frame neu prüfen
                    crimeState.cooldowns['SHOOTING'] = GetGameTimer() - (Config.CrimeTypes.SHOOTING.cooldown - 2000)
                    Debug('SHOOTING ignoriert: kein Ziel (Schuss in die Luft)')
                end
            end

            ::nextShoot::
        end
    end)

    -- ── BRANDISHING — Waffe gezogen ──────────────────────────────────────────
    -- ✅ FIX #36 (1.0.2-alpha): Nur triggern wenn ein NPC/Cop dich tatsächlich sieht.
    -- Vorher: rein zufällig — auch wenn niemand in der Nähe.
    CreateThread(function()
        while true do
            Wait(1000)
            if not crimeState.systemInitialized or cache.inVehicle then goto nextBrand end

            if IsPedArmed(cache.ped, 4) and not IsCrimeOnCooldown('BRANDISHING') then
                local weapon = GetSelectedPedWeapon(cache.ped)
                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                    local realism = Config.CrimeRealism or {}
                    local requireLOS = realism.brandishingRequiresLOS

                    -- LOS-Check: gibt es einen NPC der mich gerade mit Waffe sieht?
                    local seen = false
                    if requireLOS then
                        -- Cops in der Nähe?
                        if crimeState.isPoliceNearby and CheckCopsLineOfSight() then
                            seen = true
                        else
                            -- Mindestens 1 NPC in 20m mit Sichtlinie?
                            local witnesses = GetNearbyWitnesses(cache.coords, 20.0)
                            seen = #witnesses.npcs > 0
                        end
                    else
                        seen = true
                    end

                    if seen then
                        local chance = crimeState.isPoliceNearby and 0.04 or 0.006
                        if math.random() < chance then
                            LogCrime('BRANDISHING')
                        end
                    end
                end
            end

            ::nextBrand::
        end
    end)

    -- ── BURGLARY — Aufbruch-Animation erkannt ────────────────────────────────
    -- (aus old system, portiert auf GTA-native-Checks)
    CreateThread(function()
        while true do
            Wait(1000)
            if not crimeState.systemInitialized or cache.inVehicle then goto nextBurg end

            local ped = cache.ped
            local isLockpicking =
                IsEntityPlayingAnim(ped, 'mini@safe_cracking', 'idle_base', 3) or
                IsEntityPlayingAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 3) or
                IsEntityPlayingAnim(ped, 'veh@break_in@0h@std@ds', 'low_stance_ds', 3) or
                IsEntityPlayingAnim(ped, 'missheist_apartment2', 'loop_hacker', 3)

            if isLockpicking and not IsCrimeOnCooldown('BURGLARY') then
                LogCrime('BURGLARY')
            end

            ::nextBurg::
        end
    end)

    -- ── VANDALISM — Melee auf Objekte ────────────────────────────────────────
    CreateThread(function()
        while true do
            Wait(1000)
            if not crimeState.systemInitialized then goto nextVand end

            local ped = cache.ped
            if IsPedArmed(ped, 1) and IsPedInMeleeCombat(ped) then
                local entityHit = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if entityHit and entityHit ~= 0
                    and not IsEntityAPed(entityHit)
                    and not IsEntityAVehicle(entityHit)
                    and not IsCrimeOnCooldown('VANDALISM')
                then
                    LogCrime('VANDALISM')
                end
            end

            ::nextVand::
        end
    end)

    -- ── SPEEDING / RECKLESS DRIVING / HIT_AND_RUN ────────────────────────────
    -- ✅ FIX #35 (1.0.2-alpha): SPEEDING braucht jetzt Cop-Sichtlinie.
    -- Auch konfigurierbare Toleranz pro Area-Typ statt fixer "+20".
    CreateThread(function()
        local lastHitCheck = 0

        while true do
            Wait(500)
            if not crimeState.systemInitialized then goto nextVeh end
            if not cache.inVehicle then goto nextVeh end
            if GetPedInVehicleSeat(cache.vehicle, -1) ~= cache.ped then goto nextVeh end

            local speed   = GetEntitySpeed(cache.vehicle) * 3.6  -- km/h
            local area    = crimeState.currentArea
            local limit   = area == 'CITY_CENTER' and 60
                         or area == 'URBAN'       and 80
                         or area == 'SUBURBAN'    and 100
                         or 120

            -- ✅ FIX #35: Konfigurierbare Toleranz pro Area-Typ
            local realism = Config.CrimeRealism or {}
            local tolByArea = realism.speedingTolerance or {}
            local tolerance = tolByArea[area] or 30

            -- ✅ FIX #35: Cop-LOS Check für SPEEDING (verkehrsdelikt → muss gesehen werden)
            local copSees = false
            if realism.speedingRequiresCopLOS then
                copSees = CheckCopsLineOfSight() == true
            end

            -- SPEEDING — erst wenn deutlich über limit UND ein Cop es sieht
            if speed > (limit + tolerance) and not IsCrimeOnCooldown('SPEEDING') then
                if (not realism.speedingRequiresCopLOS) or copSees then
                    LogCrime('SPEEDING')
                end
            end

            -- RECKLESS DRIVING — sehr hohe Geschwindigkeit + Schräglage
            if speed > (limit + tolerance + 20) and not IsCrimeOnCooldown('RECKLESS_DRIVING') then
                local roll = GetEntityRoll(cache.vehicle)
                if math.abs(roll) > 20.0 then
                    if (not realism.recklessRequiresWitness) or copSees or crimeState.isPoliceNearby then
                        LogCrime('RECKLESS_DRIVING')
                    end
                end
            end

            -- HIT AND RUN — wenn ein NPC getroffen wurde
            local now = GetGameTimer()
            if now - lastHitCheck > 1500 and HasEntityCollidedWithAnything(cache.vehicle) then
                lastHitCheck = now
                local vCoords = GetEntityCoords(cache.vehicle)
                local pool    = GetGamePool('CPed')

                for _, ped in ipairs(pool) do
                    if ped ~= cache.ped and not IsPedInAnyVehicle(ped, true) then
                        local pCoords = GetEntityCoords(ped)
                        if #(pCoords - vCoords) < 4.0
                            and IsEntityTouchingEntity(cache.vehicle, ped)
                            and not IsCrimeOnCooldown('HIT_AND_RUN')
                        then
                            if IsPedAPlayer(ped) or not IsPedDeadOrDying(ped, true) then
                                -- ✅ FIX #44: Überfahrener NPC als Opfer markieren
                                LogCrime('HIT_AND_RUN', nil, false, ped)
                                break
                            end
                        end
                    end
                end
            end

            ::nextVeh::
        end
    end)

    -- ── VEHICLE THEFT — Fahrzeugjacking ──────────────────────────────────────
    -- ✅ FIX #44 (1.0.2-alpha hotfix3): Fahrer des Zielautos als Opfer übergeben
    -- damit er nicht selber als Zeuge gepickt wird (führte zum "Witness eliminated"
    -- Bug — Spieler jackt Fahrer raus, Fahrer ragdollt, "Zeuge eliminiert").
    CreateThread(function()
        while true do
            Wait(500)
            if not crimeState.systemInitialized then goto nextTheft end

            if (IsPedTryingToEnterALockedVehicle(cache.ped) or IsPedJacking(cache.ped))
                and not IsCrimeOnCooldown('VEHICLE_THEFT')
            then
                -- Opfer ermitteln: Fahrer des Fahrzeugs das gerade gejackt/aufgebrochen wird
                local targetVeh = GetVehiclePedIsTryingToEnter(cache.ped)
                if not targetVeh or targetVeh == 0 then
                    targetVeh = GetVehiclePedIsEntering(cache.ped)
                end
                local victimDriver = nil
                if targetVeh and targetVeh ~= 0 and DoesEntityExist(targetVeh) then
                    local drv = GetPedInVehicleSeat(targetVeh, -1)
                    if drv and drv ~= 0 and drv ~= cache.ped and DoesEntityExist(drv) then
                        victimDriver = drv
                    end
                end
                LogCrime('VEHICLE_THEFT', nil, false, victimDriver)
            end

            ::nextTheft::
        end
    end)

    -- ── ASSAULT — Nahkampf (nicht-fatal) ─────────────────────────────────────
    CreateThread(function()
        while true do
            Wait(500)
            if not crimeState.systemInitialized or cache.inVehicle then goto nextAssault end

            if IsPedInMeleeCombat(cache.ped) then
                local target = GetMeleeTargetForPed(cache.ped)
                if target ~= 0 and not IsPedDeadOrDying(target, true) then
                    if not IsCrimeOnCooldown('ASSAULT') then
                        -- ✅ FIX #44: Nahkampf-Opfer rauswerfen aus Witness-Liste
                        if GetPedType(target) == 6 then
                            LogCrime('ASSAULT_COP', nil, false, target)
                        else
                            LogCrime('ASSAULT', nil, false, target)
                        end
                    end
                end
            end

            ::nextAssault::
        end
    end)

    -- ── DRUG_POSSESSION — ox_inventory Check ─────────────────────────────────
    -- Intervall-Check alle 90s wenn Polizei in der Nähe ist
    if Config.CrimeTypes.DRUG_POSSESSION then
        CreateThread(function()
            while true do
                Wait(90000)
                if not crimeState.systemInitialized then goto nextDrug end
                if not crimeState.isPoliceNearby then goto nextDrug end
                if IsCrimeOnCooldown('DRUG_POSSESSION') then goto nextDrug end

                local ok, inv = pcall(function()
                    return exports.ox_inventory:GetPlayerItems()
                end)

                if ok and inv then
                    local illegalDrugs = {
                        'weed', 'cocaine', 'heroin', 'meth', 'oxy',
                        'weed_seeds', 'drug_', 'drugs_',
                    }
                    for _, item in pairs(inv) do
                        if item and item.name then
                            for _, keyword in ipairs(illegalDrugs) do
                                if string.find(item.name:lower(), keyword) then
                                    LogCrime('DRUG_POSSESSION')
                                    goto nextDrug
                                end
                            end
                        end
                    end
                end

                ::nextDrug::
            end
        end)
    end

    Debug('Crime Detection Threads gestartet')
end

-- ════════════════════════════════════════════════════════════════════════════════
-- EXTERNE CRIME-TRIGGER
-- (für andere Ressourcen wie Raub, Drogenverkauf etc.)
-- ════════════════════════════════════════════════════════════════════════════════

-- Allgemeiner Trigger von anderen Ressourcen
RegisterNetEvent('rde_aipd:triggerCrime', function(crimeType, coords)
    if not crimeState.systemInitialized then return end
    if not Config.CrimeTypes[crimeType] then
        Debug(('Unbekannter externer Crime-Typ: %s'):format(tostring(crimeType)))
        return
    end
    local c = coords and type(coords) == 'vector3' and coords or cache.coords
    LogCrime(crimeType, c, false)
end)

-- Kompatibilität mit alten ESX-Ereignissen → einfach weiterleiten
RegisterNetEvent('rde_crimes:clientCrime', function(crimeType)
    LogCrime(crimeType)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SERVER EVENTS
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('police:setWantedLevel', function(level)
    level = level or 0
    Debug(('Wanted Level via Event: %d'):format(level))
end)

RegisterNetEvent('police:systemReady', function(data)
    CreateThread(function()
        Wait(1000)
        crimeState.systemInitialized = false
        InitializeCrimeSystem()
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════════

function InitializeCrimeSystem()
    if crimeState.systemInitialized then return end
    Debug('Initialisiere Enhanced Crime System...')

    crimeState.playerLoaded = true

    local ok, isAdmin = pcall(function()
        return lib.callback.await('police:isAdmin', false)
    end)

    crimeState.isAdmin = ok and isAdmin or false

    if crimeState.isAdmin then
        Debug('Admin-Modus aktiv – Verbrechen werden geloggt, nicht eskaliert')
    end

    crimeState.lastSeenByCop = GetGameTimer()
    crimeState.currentArea, crimeState.areaMultiplier = GetCurrentArea()

    StartCrimeDetectionThread()
    StartWantedDecaySystem()

    crimeState.systemInitialized = true
    Debug('Crime System initialisiert')
end

AddEventHandler('ox:playerLoaded', function()
    CreateThread(function()
        Wait(3000)
        InitializeCrimeSystem()
    end)
end)

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() == name then
        CreateThread(function()
            Wait(5000)
            InitializeCrimeSystem()
        end)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ════════════════════════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('testcrime', function(_, args)
        local crimeType = args[1] or 'ASSAULT'
        if not Config.CrimeTypes[crimeType] then
            lib.notify({type='error', description=L('unknown_crime', crimeType)})
            return
        end
        lib.notify({type='inform', description=L('testing_crime', crimeType)})
        LogCrime(crimeType, nil, true)
    end, false)

    RegisterCommand('crimestatus', function()
        lib.notify({
            type        = 'inform',
            duration    = 8000,
            description = ('Init:%s | Admin:%s | Police:%s | Area:%s | Wanted:%d | Decay:%s'):format(
                tostring(crimeState.systemInitialized),
                tostring(crimeState.isAdmin),
                tostring(crimeState.isPoliceNearby),
                crimeState.currentArea,
                GetWantedLevel(),
                tostring(crimeState.decayActive)
            ),
        })
    end, false)

    RegisterCommand('testwitness', function(_, args)
        local crimeType = args[1] or 'ROBBERY'
        lib.notify({type='inform', description=L('testing_crime', crimeType)})
        -- Erzwingt vollen Zeuge-Flow (kein force-flag → Zeuge nötig)
        LogCrime(crimeType, cache.coords, false)
    end, false)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ════════════════════════════════════════════════════════════════════════════════

exports('LogCrime',             LogCrime)
exports('IsCrimeOnCooldown',    IsCrimeOnCooldown)
exports('GetCurrentArea',       GetCurrentArea)
exports('CheckCopsLineOfSight', CheckCopsLineOfSight)
exports('IsDecayActive',        function() return crimeState.decayActive end)
exports('GetWantedLevel',       GetWantedLevel)

-- ════════════════════════════════════════════════════════════════════════════════
print('^2[AIPD | Crime]^7 ✅ Zeuge-basiertes 911-Call-System aktiv')
print('^2[AIPD | Crime]^7 ✅ Zeuge unterbrechen = kein Wanted Level')
print('^2[AIPD | Crime]^7 ✅ Alle Crime-Typen erkannt (Schuss, Diebstahl, Unfall, Einbruch...)')
print('^2[AIPD | Crime]^7 ✅ ox_core only – kein ESX')