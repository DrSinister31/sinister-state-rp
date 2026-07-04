-- === IDENTITY MARKER SYSTEM ===
-- Every AI ped gets state bags so Kronus and other systems can identify them.
-- Format: Entity(state).ai_type = "police" | "criminal" | "civilian" | "worker"
--          Entity(state).ai_behavior = "patrol" | "deal" | "boost" | "respond" | "walk"

AI_POOLS = {
    police_patrol = {},
    police_ems = {},
    criminal_dealer = {},
    criminal_booster = {},
    civilian_walker = {},
}

-- API: Tag an AI ped with identity markers
function TagAI(entity, ai_type, ai_behavior, zone, aggression)
    Entity(entity).state:set("ai_type", ai_type, true)
    Entity(entity).state:set("ai_behavior", ai_behavior, true)
    Entity(entity).state:set("ai_zone", zone or "general", true)
    Entity(entity).state:set("ai_aggression", aggression or 0.2, true)
    Entity(entity).state:set("ai_active", true, true)
end

function UntagAI(entity)
    Entity(entity).state:set("ai_active", false, true)
end

-- Called by Kronus via bridge to spawn an AI ped
RegisterNetEvent("sinister_ai:spawnPed", function(ai_type, ai_behavior, coords, model)
    local src = source
    if not IsPlayerAceAllowed(src, "command") then return end
    
    local pedModel = model or "a_m_m_business_01"
    local hash = GetHashKey(pedModel)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    TagAI(ped, ai_type, ai_behavior, "auto")
    FreezeEntityPosition(ped, false)
    
    local netId = NetworkGetNetworkIdFromEntity(ped)
    TriggerClientEvent("sinister_ai:pedSpawned", -1, netId, ai_type, ai_behavior)
end)

RegisterNetEvent("sinister_ai:despawnPed", function(netId)
    local ped = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(ped) then
        UntagAI(ped)
        DeleteEntity(ped)
    end
end)

RegisterNetEvent("sinister_ai:despawnAll", function(ai_type)
    if ai_type == "all" or ai_type == "police" then
        for _, ped in pairs(AI_POOLS.police_patrol) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        AI_POOLS.police_patrol = {}
    end
    if ai_type == "all" or ai_type == "criminal" then
        for _, ped in pairs(AI_POOLS.criminal_dealer) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        AI_POOLS.criminal_dealer = {}
        for _, ped in pairs(AI_POOLS.criminal_booster) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        AI_POOLS.criminal_booster = {}
    end
    if ai_type == "all" or ai_type == "civilian" then
        for _, ped in pairs(AI_POOLS.civilian_walker) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        AI_POOLS.civilian_walker = {}
    end
end)

-- === DENSITY CONTROLLER ===
-- Reads convars set by Kronus via RCON bridge
AI_ENABLED = true
AI_DENSITY = 1.0

Citizen.CreateThread(function()
    while true do
        local toggle = GetConvar("sinister_ai:ai_toggle", "true")
        AI_ENABLED = (toggle == "true")
        local density = GetConvar("sinister_ai:global_density", "1.0")
        AI_DENSITY = tonumber(density) or 1.0
        Wait(10000)
    end
end)

function GetDensityCapped(count)
    if not AI_ENABLED then return 0 end
    local capped = math.floor(count * AI_DENSITY)
    return math.max(0, capped)
end

print("^2[sinister_ai] ^7Identity system loaded — awaiting Kronus density commands")
