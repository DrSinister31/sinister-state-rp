local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local defaultTerritories = {
    Eastside = "Ballas",
    ["South Central"] = "Vagos",
    ["West End"] = "Cartel",
    Northside = "Uncontrolled",
    Downtown = "Uncontrolled",
    Harbor = "Uncontrolled",
    ["Little Seoul"] = "Uncontrolled",
    ["Mirror Park"] = "Uncontrolled",
}

GlobalState["underworld:territories"] = GlobalState["underworld:territories"] or defaultTerritories

local function httpGet(endpoint)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "GET", "", {
        ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
    })
    return Citizen.Await(p)
end

RegisterNetEvent("sinister_underworld:proxyRequest", function(requestId, payload)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local cid = player and player.PlayerData.citizenid or ""
    local result = {}

    if payload.action == "loadRep" then
        local r = httpGet("street_reputation?select=*&citizenid=eq." .. cid)
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    elseif payload.action == "loadContracts" then
        local r = httpGet("darknet_contracts?select=*&status=eq.open&order=created_at.desc&limit=10")
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    elseif payload.action == "loadDrugXP" then
        local r = httpGet("player_drug_xp?select=*&citizenid=eq." .. cid)
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    elseif payload.action == "loadHeists" then
        local r = httpGet("robbery_incidents?select=*&order=occurred_at.desc&limit=10")
        result = (r.code == 200 and r.data and json.decode(r.data) or {})
    elseif payload.action == "getTerritories" then
        local territories = GlobalState["underworld:territories"] or defaultTerritories
        result = { territories = territories }
    else
        result = { _error = "Unknown action" }
    end

    TriggerClientEvent("sinister_underworld:proxyResponse", src, requestId, result)
end)

print("^5[sinister_underworld] ^7Server ready")
