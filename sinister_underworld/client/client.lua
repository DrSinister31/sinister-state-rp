local isNuiOpen = false
local pendingCallbacks = {}

local zones = {
    { name = "Houston",    county = "Harris County",   center = vec3(0, 0, 50),      radius = 3000 },
    { name = "Fort Worth", county = "Tarrant County",  center = vec3(-440, 6000, 31), radius = 2000 },
    { name = "Killeen",    county = "Bell County",     center = vec3(1700, 3580, 35), radius = 2000 },
}
local currentDistrict = "Wilderness"

local districts = { "Eastside", "South Central", "West End", "Northside", "Downtown", "Harbor", "Little Seoul", "Mirror Park" }

local function detectZone()
    local coords = GetEntityCoords(PlayerPedId())
    local nearest, nearestDist = nil, 9999
    for _, z in ipairs(zones) do
        local dist = #(coords - z.center)
        if dist < z.radius and dist < nearestDist then
            nearestDist = dist
            nearest = z
        end
    end
    currentDistrict = nearest and nearest.name or "Wilderness"
    return currentDistrict
end

Citizen.CreateThread(function()
    while true do
        detectZone()
        Wait(isNuiOpen and 1000 or 5000)
    end
end)

RegisterNUICallback("setNuiFocus", function(data, cb)
    isNuiOpen = not not (data.hasFocus)
    SetNuiFocus(data.hasFocus, data.cursor)
    cb("ok")
end)

RegisterNUICallback("closeNui", function(_, cb)
    isNuiOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("uw:getZone", function(_, cb)
    cb({ district = currentDistrict, districts = districts })
end)

RegisterNetEvent("sinister_underworld:proxyResponse", function(requestId, result)
    local cb = pendingCallbacks[requestId]
    if cb then pendingCallbacks[requestId] = nil; cb(result) end
end)

RegisterNUICallback("uw_proxy", function(data, cb)
    local requestId = data.id
    pendingCallbacks[requestId] = cb
    TriggerServerEvent("sinister_underworld:proxyRequest", requestId, data.payload or {})
    Citizen.SetTimeout(15000, function()
        if pendingCallbacks[requestId] then pendingCallbacks[requestId] = nil; cb({ _error = "Timed out" }) end
    end)
end)

RegisterNUICallback("checkAuth", function(_, cb)
    local player = exports.qbx_core:GetPlayer(cache.playerId)
    if not player then cb({ authorized = false }); return end
    local job = player.PlayerData.job
    local gang = player.PlayerData.gang
    cb({
        authorized = true,
        job = job.name,
        gang = gang and gang.name or nil,
        citizenid = player.PlayerData.citizenid,
    })
end)

print("^5[sinister_underworld] ^7Client ready")
