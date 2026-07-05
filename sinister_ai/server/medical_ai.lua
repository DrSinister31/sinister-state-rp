-- =====================================================================
-- MEDICAL AI — AI Doctors, ER Check-Ins, Treatment Timers, Invoicing
-- Per spec 1.2: Low-population fallback for medical roleplay
-- =====================================================================

HOSPITAL_LOCATIONS = {
    { label = "Houston Medical Center", coords = vec4(305.0, -1430.0, 30.0, 140.0) },
    { label = "Ft. Worth Clinic", coords = vec4(-245.0, 6330.0, 33.0, 45.0) },
    { label = "Sandy Shores Medical", coords = vec4(1830.0, 3675.0, 34.5, 210.0) },
}

MEDICAL_MODELS = {
    doctor = { "s_m_m_doctor_01", "s_f_y_scrubs_01" },
    nurse = { "s_f_y_scrubs_01", "a_f_y_business_02" },
    emt = { "s_m_m_paramedic_01", "s_f_y_scrubs_01" },
}

TREATMENT_TIME_SEC = 30
TREATMENT_BASE_COST = 500
REVIVE_RANGE = 2.5

local activeDoctors = {}
local activePatients = {}

function SpawnMedicalAI(hospital)
    if not AI_ENABLED then return end
    local count = GetDensityCapped(3)
    if count < 1 then return end

    local loc = hospital.coords
    for i = 1, count do
        local modelName = MEDICAL_MODELS.doctor[(i % #MEDICAL_MODELS.doctor) + 1]
        local hash = GetHashKey(modelName)

        local offsetX = math.random(-5, 5)
        local offsetY = math.random(-5, 5)
        local ped = CreatePed(0, hash, loc.x + offsetX, loc.y + offsetY, loc.z, loc.w, true, true)
        TagAI(ped, "medical", "doctor", hospital.label, 0.0)

        activeDoctors[#activeDoctors + 1] = { ped = ped, hospital = hospital }
    end
end

local function GetNearestDownedPlayer(coords, maxRange)
    local nearest = nil
    local nearestDist = maxRange
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        if IsPedDeadOrDying(ped, true) then
            local dist = #(GetEntityCoords(ped) - coords)
            if dist < nearestDist then
                nearestDist = dist
                nearest = { ped = ped, playerId = playerId, dist = dist }
            end
        end
    end
    return nearest
end

local function InvoicePatient(playerId, cost, hospital)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local body = {
        patient_citizenid = cid,
        treatment_type = "ER Visit",
        injury_cause = "Unknown",
        doctor_citizenid = "AI",
        is_ai_doctor = true,
        treatment_duration_sec = TREATMENT_TIME_SEC,
        invoice_amount = cost,
        invoice_paid = false,
        outcome = "treated",
        hospital_location = hospital.label,
    }
    PerformHttpRequest(
        GetConvar("sinister_apps:supabase_url", "") .. "/rest/v1/medical_treatments",
        function() end, "POST", json.encode(body),
        {
            ["Content-Type"] = "application/json",
            ["apikey"] = GetConvar("sinister_apps:supabase_key", ""),
            ["Authorization"] = "Bearer " .. GetConvar("sinister_apps:supabase_key", ""),
            ["Prefer"] = "return=minimal",
        }
    )

    local billing = {
        patient_citizenid = cid,
        treatment_id = nil,
        base_cost = cost,
        distance_charge = 0,
        severity_multiplier = 1.0,
        total_amount = cost,
        paid = false,
    }
    PerformHttpRequest(
        GetConvar("sinister_apps:supabase_url", "") .. "/rest/v1/ambulance_billing",
        function() end, "POST", json.encode(billing),
        {
            ["Content-Type"] = "application/json",
            ["apikey"] = GetConvar("sinister_apps:supabase_key", ""),
            ["Authorization"] = "Bearer " .. GetConvar("sinister_apps:supabase_key", ""),
            ["Prefer"] = "return=minimal",
        }
    )

    TriggerClientEvent("ox_lib:notify", playerId, {
        title = hospital.label,
        description = "Treatment complete. Invoice: $" .. cost,
        type = "inform",
        duration = 8000,
    })
end

Citizen.CreateThread(function()
    while true do
        Wait(5000)

        if not AI_ENABLED then
            Wait(10000)
            goto continue
        end

        local emsOnline = 0
        for _, pid in ipairs(GetPlayers()) do
            local p = exports.qbx_core:GetPlayer(pid)
            if p and p.PlayerData.job and p.PlayerData.job.type == "ems" and p.PlayerData.job.onduty then
                emsOnline = emsOnline + 1
            end
        end

        if emsOnline > 0 and AI_DENSITY < 0.3 then
            for _, doc in ipairs(activeDoctors) do
                if DoesEntityExist(doc.ped) then DeleteEntity(doc.ped) end
            end
            activeDoctors = {}
            Wait(30000)
            goto continue
        end

        if #activeDoctors == 0 or #activeDoctors < GetDensityCapped(3) then
            for _, h in ipairs(HOSPITAL_LOCATIONS) do
                if #activeDoctors < GetDensityCapped(3) then
                    pcall(SpawnMedicalAI, h)
                end
            end
        end

        for _, doc in ipairs(activeDoctors) do
            if not DoesEntityExist(doc.ped) then goto continue_doctor end

            local docCoords = GetEntityCoords(doc.ped)
            local nearestPlayer = nil
            local nearestDist = 50.0
            local allPlayers = GetActivePlayers()

            for _, pid in ipairs(allPlayers) do
                local ped = GetPlayerPed(pid)
                local coords = GetEntityCoords(ped)
                local dist = #(coords - docCoords)

                if dist < 30.0 and not activePatients[pid] then
                    if IsPedDeadOrDying(ped, true) then
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestPlayer = { ped = ped, id = pid }
                        end
                    end
                end
            end

            if nearestPlayer then
                activePatients[nearestPlayer.id] = {
                    doctorPed = doc.ped,
                    startTime = GetGameTimer(),
                    hospital = doc.hospital,
                }

                ClearPedTasks(doc.ped)
                TaskGoToEntity(doc.ped, nearestPlayer.ped, -1, 1.5, 1.0, 0, 0)

                Citizen.SetTimeout(TREATMENT_TIME_SEC * 1000, function(pid)
                    pid = pid
                    local patientData = activePatients[pid]
                    if not patientData then return end

                    local pPed = GetPlayerPed(pid)
                    if not DoesEntityExist(pPed) then return end

                    local docCoords = GetEntityCoords(patientData.doctorPed)
                    local patCoords = GetEntityCoords(pPed)
                    if #(docCoords - patCoords) > REVIVE_RANGE then return end

                    if IsPedDeadOrDying(pPed, true) then
                        local cost = TREATMENT_BASE_COST + math.random(0, 500)
                        InvoicePatient(pid, cost, patientData.hospital)

                        TriggerClientEvent("hospital:client:Revive", pid)
                    end

                    activePatients[pid] = nil

                    TaskWanderStandard(patientData.doctorPed, 10.0, 10)
                end, nearestPlayer.id)
            end

            ::continue_doctor::
        end

        ::continue::
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_ai] ^7Medical AI ready — density-aware")
    end
end)
