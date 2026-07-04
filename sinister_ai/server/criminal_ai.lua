-- === CRIMINAL AI — Dealers, Boosters, Smugglers ===

DEALER_SPOTS = {
    vec3(150.0, -1300.0, 29.0),   -- Davis
    vec3(900.0, -2300.0, 30.0),   -- Cypress
    vec3(500.0, -1500.0, 29.0),  -- Industrial
    vec3(1100.0, -700.0, 57.0),  -- Mirror Park
}

BOOST_SPOTS = {
    vec3(540.0, -200.0, 54.0),   -- Near Mosley's
    vec3(-300.0, -1300.0, 31.0), -- PostOP area
    vec3(1300.0, -3100.0, 5.0),  -- Docks
}

function SpawnStreetDealer()
    local spot = DEALER_SPOTS[(math.random(#DEALER_SPOTS))]
    local hash = GetHashKey("g_m_y_mexgoon_03")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local ped = CreatePed(0, hash, spot.x, spot.y, spot.z, 0.0, true, true)
    TagAI(ped, "criminal", "deal", "general", 0.1)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SMOKING", 0, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_snspistol"), 0, true, true)
    
    -- Look around suspiciously every 30 seconds
    Citizen.CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(30000)
            if DoesEntityExist(ped) then
                TaskLookAtCoord(ped, spot.x + math.random(-50,50), spot.y + math.random(-50,50), spot.z, 5000, 0, 2)
            end
        end
    end)
    
    AI_POOLS.criminal_dealer[#AI_POOLS.criminal_dealer + 1] = ped
end

function SpawnBooster()
    local spot = BOOST_SPOTS[(math.random(#BOOST_SPOTS))]
    local hash = GetHashKey("g_m_y_lost_02")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local ped = CreatePed(0, hash, spot.x, spot.y, spot.z, 0.0, true, true)
    TagAI(ped, "criminal", "boost", "general", 0.3)
    GiveWeaponToPed(ped, GetHashKey("weapon_knife"), 0, true, true)
    TaskWanderStandard(ped, 10.0, 10)
    
    AI_POOLS.criminal_booster[#AI_POOLS.criminal_booster + 1] = ped
end

print("^2[sinister_ai] ^7Criminal AI ready")
