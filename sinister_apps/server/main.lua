local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local function supabaseRequest(method, endpoint, body)
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

RegisterNetEvent("sinister_apps:open", function(appName)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if appName == "banking" then
        TriggerClientEvent("sinister_apps:openNui", src, "banking", {
            citizenid = player.PlayerData.citizenid
        })
    elseif appName == "browser" then
        TriggerClientEvent("sinister_apps:openNui", src, "browser", {})
    elseif appName == "syntok" then
        TriggerClientEvent("sinister_apps:openNui", src, "syntok", {})
    end
end)

RegisterNetEvent("sinister_apps:proxyRequest", function(requestId, app, payload)
    local src = source
    local result = {}

    if app == "banking" then
        if payload.action == "loadBusinesses" then
            local resp = supabaseRequest("GET", "businesses?select=*&owner_citizenid=eq." .. payload.citizenid .. "&active=eq.true", nil)
            if resp.code == 200 then
                result = resp.data and json.decode(resp.data) or {}
            else
                result = { _error = resp.data or "Failed to load businesses" }
            end
        elseif payload.action == "loadTransactions" then
            local bizId = payload.business_id
            local resp = supabaseRequest("GET", "transactions?select=*&business_id=eq." .. bizId .. "&order=created_at.desc&limit=20", nil)
            if resp.code == 200 then
                result = resp.data and json.decode(resp.data) or {}
            else
                result = { _error = resp.data or "Failed to load transactions" }
            end
        elseif payload.action == "loadPnl" then
            local bizId = payload.business_id
            local resp = supabaseRequest("GET", "business_pnl?select=*&business_id=eq." .. bizId .. "&order=created_at.desc&limit=12", nil)
            if resp.code == 200 then
                result = resp.data and json.decode(resp.data) or {}
            else
                result = { _error = resp.data or "Failed to load P&L" }
            end
        elseif payload.action == "loadEmployees" then
            local bizId = payload.business_id
            local resp = supabaseRequest("GET", "business_employees?select=*&business_id=eq." .. bizId, nil)
            if resp.code == 200 then
                result = resp.data and json.decode(resp.data) or {}
            else
                result = { _error = resp.data or "Failed to load employees" }
            end
        else
            result = { _error = "Unknown banking action: " .. (payload.action or "nil") }
        end
    elseif app == "syntok" then
        if payload.action == "loadChronicles" then
            local resp = supabaseRequest("GET", "chronicle_entries?select=title,description,score,created_at&order=created_at.desc&limit=10", nil)
            if resp.code == 200 then
                result = resp.data and json.decode(resp.data) or {}
            else
                result = { _error = resp.data or "Failed to load chronicles" }
            end
        else
            result = { _error = "Unknown syntok action: " .. (payload.action or "nil") }
        end
    else
        result = { _error = "Unknown app: " .. (app or "nil") }
    end

    TriggerClientEvent("sinister_apps:proxyResponse", src, requestId, result)
end)

print("^2[sinister_apps] ^7Server ready — proxy mode (no client-side keys)")

