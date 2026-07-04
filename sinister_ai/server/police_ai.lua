-- === POLICE AI — 4-Level SOP STATE MACHINE ===
-- Level 1: Traffic Stop   Level 2: Foot Pursuit
-- Level 3: Surrender/Arrest  Level 4: Lethal Release

POLICE_SPAWN_POINTS = {
    hpd = { vec4(440.0, -980.0, 30.3, 90.0), vec4(460.0, -970.0, 30.3, 270.0), vec4(420.0, -990.0, 30.3, 0.0) },
    sheriff = { vec4(-440.0, 6000.0, 31.0, 180.0), vec4(-460.0, 6020.0, 31.0, 0.0) },
    dps = { vec4(2400.0, 3100.0, 48.0, 90.0), vec4(2380.0, 3120.0, 48.0, 270.0) },
}

POLICE_MODELS = { "s_m_y_cop_01", "s_m_y_hwaycop_01", "s_f_y_cop_01" }
POLICE_VEHICLES = { "police", "police2", "police3", "sheriff", "sheriff2" }

function SpawnPolicePatrol(agency, count)
    local points = POLICE_SPAWN_POINTS[agency]
    if not points then return end
    for i = 1, count do
        local spawn = points[(i % #points) + 1]
        local model = POLICE_MODELS[(i % #POLICE_MODELS) + 1]
        local hash = GetHashKey(model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(0) end
        
        local ped = CreatePed(0, hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
        TagAI(ped, "police", "patrol", agency, 0.2)
        SetPedArmour(ped, 100)
        GiveWeaponToPed(ped, GetHashKey("weapon_combatpistol"), 100, false, true)
        GiveWeaponToPed(ped, GetHashKey("weapon_stungun"), 0, false, true)
        
        -- Spawn vehicle
        local vehModel = POLICE_VEHICLES[(i % #POLICE_VEHICLES) + 1]
        local vHash = GetHashKey(vehModel)
        RequestModel(vHash)
        while not HasModelLoaded(vHash) do Wait(0) end
        local veh = CreateVehicle(vHash, spawn.x, spawn.y + 5.0, spawn.z, spawn.w, true, true)
        TaskWarpPedIntoVehicle(ped, veh, -1)
        
        -- Start patrol behavior
        TaskVehicleDriveWander(ped, veh, 15.0, 786603)
        SetVehicleSiren(veh, false)
        
        AI_POOLS.police_patrol[#AI_POOLS.police_patrol + 1] = ped
    end
end

-- SOP LEVEL 1: Traffic Stop
function InitiateTrafficStop(policePed, targetVehicle)
    TaskVehicleChase(policePed, targetVehicle)
    SetVehicleSiren(GetVehiclePedIsIn(policePed, false), true)
    Citizen.SetTimeout(8000, function()
        if DoesEntityExist(policePed) and DoesEntityExist(targetVehicle) then
            TaskLeaveVehicle(policePed, GetVehiclePedIsIn(policePed, false), 0)
            Entity(policePed).state:set("ai_sop_level", 1, true)
        end
    end)
end

-- SOP LEVEL 2: Foot Pursuit
function InitiateFootPursuit(policePed, suspectPed)
    TaskCombatPed(policePed, suspectPed, 0, 16)
    SetPedCombatAttributes(policePed, 5, true) -- Non-lethal
    SetPedCombatAttributes(policePed, 46, true) -- Prioritize taser
    Entity(policePed).state:set("ai_sop_level", 2, true)
end

-- SOP LEVEL 3: Arrest
function InitiateArrest(policePed, suspectPed)
    ClearPedTasks(policePed)
    ClearPedTasks(suspectPed)
    TaskHandsUp(suspectPed, 5000, poliecePed, -1, true)
    Citizen.SetTimeout(5000, function()
        if DoesEntityExist(policePed) and DoesEntityExist(suspectPed) then
            TaskArrestPed(policePed, suspectPed)
            Entity(policePed).state:set("ai_sop_level", 3, true)
        end
    end)
end

-- SOP LEVEL 4: Lethal Release
function InitiateLethalForce(policePed, suspectPed)
    TaskCombatPed(policePed, suspectPed, 0, 0)
    SetPedCombatAttributes(policePed, 5, false) -- Lethal
    SetPedCombatAttributes(policePed, 46, false) -- No taser priority
    Entity(policePed).state:set("ai_sop_level", 4, true)
    Entity(policePed).state:set("ai_aggression", 1.0, true)
end

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_ai] ^7Police AI ready — awaiting Kronus density commands")
    end
end)
