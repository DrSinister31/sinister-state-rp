local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local function httpGet(endpoint)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "GET", "", {
        ["Content-Type"] = "application/json",
        ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
    })
    return Citizen.Await(p)
end

RegisterNetEvent("sinister_cad:proxyRequest", function(requestId, payload)
    local src = source
    local result = {}

    if payload.action == "plateLookup" then
        local plate = payload.plate
        local reg = httpGet("vehicle_registry?select=*&plate=eq." .. plate)
        local regData = (reg.code == 200 and reg.data and json.decode(reg.data) or {})
        local owner = regData[1] or {}
        local cid = owner.owner_citizenid
        local warrants, records = {}, {}
        if cid then
            local wr = httpGet("warrants?select=*&citizenid=eq." .. cid .. "&active=eq.true")
            warrants = (wr.code == 200 and wr.data and json.decode(wr.data) or {})
            local cr = httpGet("criminal_records?select=*&citizenid=eq." .. cid .. "&order=created_at.desc&limit=10")
            records = (cr.code == 200 and cr.data and json.decode(cr.data) or {})
        end
        result = { plate = plate, registry = owner, warrants = warrants, records = records }
    elseif payload.action == "loadMDT" then
        local resp = httpGet("mdt_reports?select=*&order=created_at.desc&limit=20")
        if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data } end
    elseif payload.action == "createReport" then
        local body = json.encode(payload.report)
        local p = promise.new()
        PerformHttpRequest(SUPABASE_URL .. "/rest/v1/mdt_reports", function(code, data)
            p:resolve({ code = code, data = data })
        end, "POST", body, {
            ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
            ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=representation",
        })
        local resp = Citizen.Await(p)
        if resp.code == 201 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data } end
    elseif payload.action == "speedLog" then
        local body = json.encode({
            plate = payload.plate, speed = payload.speed, limit_speed = payload.limit_speed or 60,
            location = payload.location, officer_citizenid = payload.officer_citizenid,
            flagged = (payload.speed > (payload.limit_speed or 60) + 20),
        })
        local p = promise.new()
        PerformHttpRequest(SUPABASE_URL .. "/rest/v1/speed_logs", function(code, data)
            p:resolve({ ok = true })
        end, "POST", body, {
            ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
            ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=representation",
        })
        Citizen.Await(p)
        result = { ok = true }
    else
        result = { _error = "Unknown action" }
    end

    TriggerClientEvent("sinister_cad:proxyResponse", src, requestId, result)
end)

print("^2[sinister_cad] ^7Server ready")
