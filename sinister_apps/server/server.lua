local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local function httpRequest(method, endpoint, body)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data, headers)
        p:resolve({ code = code, data = data })
    end, method, body and json.encode(body) or "", {
        ["Content-Type"] = "application/json",
        ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
        ["Prefer"] = "return=representation"
    })
    return Citizen.Await(p)
end

RegisterNetEvent("sinister_apps:proxyRequest", function(requestId, app, payload)
    local src = source
    local result = {}

    if app == "banking" then
        if payload.action == "loadBusinesses" then
            local resp = httpRequest("GET", "businesses?select=*&owner_citizenid=eq." .. (payload.citizenid or "") .. "&active=eq.true", nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        elseif payload.action == "loadTransactions" then
            local resp = httpRequest("GET", "transactions?select=*&business_id=eq." .. payload.business_id .. "&order=created_at.desc&limit=20", nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        elseif payload.action == "loadPnl" then
            local resp = httpRequest("GET", "business_pnl?select=*&business_id=eq." .. payload.business_id .. "&order=created_at.desc&limit=12", nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        elseif payload.action == "loadEmployees" then
            local resp = httpRequest("GET", "business_employees?select=*&business_id=eq." .. payload.business_id, nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        else
            result = { _error = "Unknown banking action" }
        end
    elseif app == "syntok" then
        if payload.action == "loadChronicles" then
            local resp = httpRequest("GET", "chronicle_entries?select=title,description,score,created_at&order=created_at.desc&limit=10", nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        else
            result = { _error = "Unknown syntok action" }
        end
    elseif app == "cad" then
        if payload.action == "plateLookup" then
            local plate = payload.plate
            local reg = httpRequest("GET", "vehicle_registry?select=*&plate=eq." .. plate, nil)
            local regData = (reg.code == 200 and reg.data and json.decode(reg.data) or {})
            local owner = regData[1] or {}
            local cid = owner.owner_citizenid

            local warrants = {}
            local records = {}
            if cid then
                local wr = httpRequest("GET", "warrants?select=*&citizenid=eq." .. cid .. "&active=eq.true", nil)
                warrants = (wr.code == 200 and wr.data and json.decode(wr.data) or {})
                local cr = httpRequest("GET", "criminal_records?select=*&citizenid=eq." .. cid .. "&order=created_at.desc&limit=10", nil)
                records = (cr.code == 200 and cr.data and json.decode(cr.data) or {})
            end

            result = {
                plate = plate,
                registry = owner,
                warrants = warrants,
                records = records,
                lookup_at = os.date("!%Y-%m-%dT%H:%M:%S")
            }
        elseif payload.action == "speedLog" then
            local resp = httpRequest("POST", "speed_logs", {
                plate = payload.plate,
                speed = payload.speed,
                limit_speed = payload.limit_speed or 60,
                location = payload.location or "unknown",
                officer_citizenid = payload.officer_citizenid,
                flagged = (payload.speed > (payload.limit_speed or 60) + 20)
            })
            result = { ok = true, id = resp.data and json.decode(resp.data) }
        elseif payload.action == "loadMDT" then
            local resp = httpRequest("GET", "mdt_reports?select=*&order=created_at.desc&limit=20", nil)
            if resp.code == 200 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        elseif payload.action == "createReport" then
            local resp = httpRequest("POST", "mdt_reports", payload.report)
            if resp.code == 201 then result = resp.data and json.decode(resp.data) or {} else result = { _error = resp.data or "Failed" } end
        else
            result = { _error = "Unknown CAD action" }
        end
    else
        result = { _error = "Unknown app" }
    end

    TriggerClientEvent("sinister_apps:proxyResponse", src, requestId, result)
end)

print("^2[sinister_apps] ^7Server proxy ready (banking + syntok + cad)")
