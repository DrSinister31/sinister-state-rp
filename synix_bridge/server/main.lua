local SUPABASE_URL = GetConvar("synix:supabase_url", "")
local SUPABASE_KEY = GetConvar("synix:supabase_key", "")
local POLL_INTERVAL = 2000

local function httpRequest(method, endpoint, body)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data, headers)
        p:resolve({ code = code, data = data, headers = headers })
    end, method, body and json.encode(body) or "", {
        ["Content-Type"] = "application/json",
        ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
        ["Prefer"] = "return=representation"
    })
    return Citizen.Await(p)
end

local function pushPlayerData(citizenid)
    local player = exports["qbx_core"]:GetPlayerByCitizenId(citizenid)
    if not player then return end
    local char = player.PlayerData
    if not char then return end
    local body = {
        citizenid = citizenid,
        first_name = char.charinfo and char.charinfo.firstname or "",
        last_name = char.charinfo and char.charinfo.lastname or "",
        dob = char.charinfo and char.charinfo.birthdate or nil,
        gender = char.charinfo and char.charinfo.gender or nil,
        nationality = char.charinfo and char.charinfo.nationality or nil,
        job_name = char.job and char.job.name or nil,
        job_grade = char.job and char.job.grade and char.job.grade.level or 0,
        gang_name = char.gang and char.gang.name or nil,
        gang_grade = char.gang and char.gang.grade and char.gang.grade.level or 0,
        active = true
    }
    httpRequest("POST", "characters?on_conflict=citizenid", body)
    local econ = {
        citizenid = citizenid,
        cash = player.Functions.GetMoney("cash") or 0,
        bank = player.Functions.GetMoney("bank") or 0,
        crypto = player.Functions.GetMoney("crypto") or 0,
        updated_at = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    httpRequest("POST", "player_economy?on_conflict=citizenid", econ)
end

local function pullCommands()
    local result = httpRequest("GET", "rcon_commands?status=eq.pending&order=created_at.asc&limit=10", nil)
    if result.code ~= 200 or not result.data then return end
    local commands = json.decode(result.data)
    for _, cmd in ipairs(commands) do
        ExecuteCommand(cmd.command)
        httpRequest("PATCH", "rcon_commands?id=eq." .. cmd.id, {
            status = "executed",
            executed_at = os.date("!%Y-%m-%dT%H:%M:%S")
        })
    end
end

AddEventHandler("playerJoining", function()
    local src = source
    Wait(1000)
    local ply = exports["qbx_core"]:GetPlayer(src)
    if ply then
        pushPlayerData(ply.PlayerData.citizenid)
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local ply = exports["qbx_core"]:GetPlayer(src)
    if ply then
        httpRequest("PATCH", "characters?id=eq." .. ply.PlayerData.citizenid, { active = false })
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[synix_bridge] ^7Started. Supabase URL: " .. SUPABASE_URL)
        SetConvarReplicated("synix:bridge_active", "true")
    end
end)

Citizen.CreateThread(function()
    while true do
        pullCommands()
        Citizen.Wait(POLL_INTERVAL)
    end
end)
