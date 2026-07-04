-- syntok server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local function httpGet(endpoint)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "GET", "", {["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY})
    return Citizen.Await(p)
end

RegisterNetEvent("sinister_syntok:proxyRequest", function(requestId, payload)
    local result = {}
    if payload.action == "loadChronicles" then
        local limit = payload.limit or 15
        local r = httpGet("chronicle_entries?select=title,description,score,created_at&order=created_at.desc&limit=" .. limit)
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    elseif payload.action == "loadTrending" then
        local r = httpGet("chronicle_entries?select=title,description,score,created_at&score=gte.15&order=created_at.desc&limit=15")
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    end
    TriggerClientEvent("sinister_syntok:proxyResponse", source, requestId, result)
end)

print("^2[sinister_syntok] ^7Server ready")
