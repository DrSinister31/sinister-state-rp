-- Sinister Clock-In — Server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local activeShifts = {}

local function supabase(method, endpoint, body)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, method, body and json.encode(body) or "", {
        ["Content-Type"] = "application/json",
        ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY,
        ["Prefer"] = "return=representation",
    })
    return Citizen.Await(p)
end

RegisterNetEvent("sinister_clockin:requestNodes", function()
    local src = source
    local nodes = {}
    local resp = supabase("GET", "clock_in_nodes?select=*&active=eq.true", nil)
    if resp.code == 200 and resp.data then
        nodes = json.decode(resp.data)
    end
    TriggerClientEvent("sinister_clockin:receiveNodes", src, nodes)
end)

RegisterNetEvent("sinister_clockin:clockIn", function(nodeId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    if activeShifts[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Clock-In", description = "You are already clocked in.", type = "error", duration = 5000
        })
        return
    end

    local nodeResp = supabase("GET", "clock_in_nodes?select=*&id=eq." .. nodeId, nil)
    local node = (nodeResp.code == 200 and nodeResp.data and json.decode(nodeResp.data)[1]) or {}

    local body = {
        employee_citizenid = cid,
        business_id = node.business_id,
        clock_in_node_id = nodeId,
        session_active = true,
    }
    local resp = supabase("POST", "employee_shifts", body)
    if resp.code == 201 and resp.data then
        activeShifts[cid] = json.decode(resp.data)[1] or { id = "pending" }
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Clocked In", description = "Shift started at " .. (node.label or "facility"), type = "success", duration = 5000
        })
    else
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Clock-In Failed", description = "Could not record shift.", type = "error", duration = 5000
        })
    end
end)

RegisterNetEvent("sinister_clockin:clockOut", function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    if not activeShifts[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Clock-Out", description = "You are not clocked in.", type = "error", duration = 5000
        })
        return
    end

    local shiftId = activeShifts[cid].id or activeShifts[cid].clock_in_id
    local clockInTime = os.date("!%Y-%m-%dT%H:%M:%S")
    supabase("PATCH", "employee_shifts?id=eq." .. shiftId, {
        clock_out_time = clockInTime,
        session_active = false,
    })

    activeShifts[cid] = nil
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Clocked Out", description = "Shift ended.", type = "inform", duration = 5000
    })
end)

AddEventHandler("playerDropped", function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    if activeShifts[cid] then
        local shiftId = activeShifts[cid].id or activeShifts[cid].clock_in_id
        supabase("PATCH", "employee_shifts?id=eq." .. shiftId, {
            clock_out_time = os.date("!%Y-%m-%dT%H:%M:%S"),
            session_active = false,
        })
        activeShifts[cid] = nil
    end
end)

print("^2[sinister_clockin] ^7Server ready")
