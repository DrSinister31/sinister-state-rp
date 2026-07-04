-- Sinister Airspace — Server
-- Logs intercept events to Supabase

local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local function logToSupabase(table, body)
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. table, function() end, "POST",
        json.encode(body), {
            ["Content-Type"] = "application/json",
            ["apikey"] = SUPABASE_KEY,
            ["Authorization"] = "Bearer " .. SUPABASE_KEY,
            ["Prefer"] = "return=minimal",
        })
end

RegisterNetEvent("sinister_airspace:interceptStarted", function(aircraft, altitude)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local cid = player and player.PlayerData.citizenid or "unknown"

    logToSupabase("intercept_logs", {
        pilot_citizenid = cid,
        aircraft_model = aircraft,
        stage_1_triggered = true,
        stage_1_at = os.date("!%Y-%m-%dT%H:%M:%S"),
        outcome = "in_progress",
    })

    TriggerClientEvent("ox_lib:notify", src, {
        title = "AIRSPACE VIOLATION",
        description = "SQUAWK 7500. Descend below 150m immediately.",
        type = "error",
        duration = 10000,
    })
end)

RegisterNetEvent("sinister_airspace:interceptStage", function(stage)
    local src = source
    logToSupabase("kronus_logs", {
        service = "sinister-airspace",
        action = "intercept_escalated",
        context_json = { stage = stage, source = src },
        result = "stage_" .. stage,
    })
end)

print("^2[sinister_airspace] ^7Server ready")
