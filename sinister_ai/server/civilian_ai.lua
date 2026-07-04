-- === CIVILIAN AI — Ambient life ===

CIVILIAN_MODELS = {
    "a_m_m_business_01", "a_m_m_farmer_01", "a_m_y_business_02",
    "a_f_y_business_01", "a_f_y_business_02", "a_f_m_business_02",
    "a_m_y_beach_01", "a_m_y_hipster_01", "a_f_y_hipster_01",
}

function SpawnCivilian(coords)
    local model = CIVILIAN_MODELS[(math.random(#CIVILIAN_MODELS))]
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local x = coords.x + math.random(-50, 50)
    local y = coords.y + math.random(-50, 50)
    local ped = CreatePed(0, hash, x, y, coords.z, math.random(0,360), true, true)
    TagAI(ped, "civilian", "walk", "general", 0.0)
    TaskWanderStandard(ped, 10.0, 10)
    
    AI_POOLS.civilian_walker[#AI_POOLS.civilian_walker + 1] = ped
end

function SpawnCivilianCluster(center, count)
    for i = 1, count do
        SpawnCivilian(center)
    end
end

-- Cleanup old civilians to prevent entity overflow
Citizen.CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        local maxCivs = 30
        while #AI_POOLS.civilian_walker > maxCivs do
            local ped = table.remove(AI_POOLS.civilian_walker, 1)
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
end)

print("^2[sinister_ai] ^7Civilian AI ready")
