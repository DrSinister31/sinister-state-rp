-- Sinister Airspace — Client
-- Tracks flight altitude, triggers intercept state machine

local FLIGHT_ALTITUDE_LIMIT = 150
local INTERCEPT_COOLDOWN = 300000
local lastInterceptTime = 0
local interceptActive = false
local interceptStage = 0
local jetPeds = {}

local function IsFlying()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return false end
    local model = GetEntityModel(vehicle)
    return IsThisModelAHeli(model) or IsThisModelAPlane(model)
end

local function GetAircraftInfo()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return nil end
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local altitude = GetEntityCoords(vehicle).z
    return { vehicle = vehicle, model = model, altitude = altitude }
end

local function SpawnFighterJet(coords)
    local hash = GetHashKey("lazer")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local jet = CreateVehicle(hash, coords.x, coords.y, coords.z + 500.0, 0.0, true, true)
    local pilot = CreatePedInsideVehicle(jet, 0, GetHashKey("s_m_y_blackops_01"), -1, true, true)
    SetPedAsNoLongerNeeded(pilot)
    TaskPlaneChase(pilot, GetPlayerPed(-1))
    jetPeds[#jetPeds + 1] = pilot
    return jet, pilot
end

local function FireMissile(targetVehicle)
    local missile = CreateVehicle(GetHashKey("lazer"), GetEntityCoords(targetVehicle).x,
        GetEntityCoords(targetVehicle).y, GetEntityCoords(targetVehicle).z + 200.0, 0.0, true, true)
    SetVehicleEngineOn(missile, true, true, true)
    SetEntityVelocity(missile, 0.0, 0.0, -200.0)
    Citizen.SetTimeout(2000, function()
        if DoesEntityExist(missile) then
            AddExplosion(GetEntityCoords(targetVehicle).x, GetEntityCoords(targetVehicle).y,
                GetEntityCoords(targetVehicle).z, 4, 1.0, true, false, 1.0)
            DeleteEntity(missile)
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Wait(3000)

        if not IsFlying() then
            interceptActive = false
            interceptStage = 0
            goto continue
        end

        local info = GetAircraftInfo()
        if not info then goto continue end

        if info.altitude > FLIGHT_ALTITUDE_LIMIT and not interceptActive then
            local now = GetGameTimer()
            if now - lastInterceptTime < INTERCEPT_COOLDOWN then goto continue end

            interceptActive = true
            interceptStage = 0
            lastInterceptTime = now

            local coords = GetEntityCoords(info.vehicle)
            TriggerServerEvent("sinister_airspace:interceptStarted", info.model, math.floor(info.altitude))

            -- Stage 1: 0-30s — Cockpit alarms
            interceptStage = 1
            TriggerServerEvent("sinister_airspace:interceptStage", 1)
            Citizen.SetTimeout(30000, function()
                if not interceptActive then return end
                interceptStage = 2
                TriggerServerEvent("sinister_airspace:interceptStage", 2)
                -- Stage 2: Spawn fighter jets
                SpawnFighterJet(coords)
                SpawnFighterJet(coords)
                Citizen.SetTimeout(60000, function()
                    if not interceptActive then return end
                    interceptStage = 3
                    TriggerServerEvent("sinister_airspace:interceptStage", 3)
                    -- Stage 3: 90-120s — Formation escort
                    Citizen.SetTimeout(30000, function()
                        if not interceptActive then return end
                        interceptStage = 4
                        TriggerServerEvent("sinister_airspace:interceptStage", 4)
                        -- Stage 4: Kinetic strike
                        FireMissile(info.vehicle)
                        interceptActive = false
                    end)
                end)
            end)
        end

        ::continue::
    end
end)

-- Cleanup jets when pilot lands or exits
Citizen.CreateThread(function()
    while true do
        Wait(10000)
        if not IsFlying() and #jetPeds > 0 then
            for _, p in ipairs(jetPeds) do
                if DoesEntityExist(p) then DeleteEntity(p) end
            end
            jetPeds = {}
        end
    end
end)

print("^2[sinister_airspace] ^7Client ready")
