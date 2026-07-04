-- Sinister Crime — Server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local activeDealers = {}
local DRUG_ITEMS = {
    weed = { label = "Weed", base = 200, alertKey = "drug_alert_chance_weed" },
    cocaine = { label = "Cocaine", base = 500, alertKey = "drug_alert_chance_cocaine" },
    meth = { label = "Meth", base = 800, alertKey = "drug_alert_chance_meth" },
    heroin = { label = "Heroin", base = 1200, alertKey = "drug_alert_chance_heroin" },
    fentanyl = { label = "Fentanyl", base = 2000, alertKey = "drug_alert_chance_fentanyl" },
}

local function supabasePost(table, body)
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. table, function() end, "POST",
        json.encode(body), {
            ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
            ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=minimal",
        })
end

local function supabaseGet(endpoint)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "GET", "", {["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY})
    return Citizen.Await(p)
end

-- Player sets up as a dealer at a drug spot
RegisterNetEvent("sinister_crime:setupDealer", function(spotId, drugType, quality)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local spotResp = supabaseGet("drug_spots?select=*&id=eq." .. spotId)
    local spot = (spotResp.code == 200 and spotResp.data and json.decode(spotResp.data) or {})[1] or {}

    activeDealers[cid] = {
        spotId = spotId,
        zone = spot.zone_name or "Unknown",
        drugType = drugType,
        quality = quality or "standard",
        startedAt = os.time(),
        sales = 0,
        earnings = 0,
    }

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Dealing Setup",
        description = "Selling " .. (DRUG_ITEMS[drugType] or {}).label or drugType .. " in " .. (spot.zone_name or "Unknown"),
        type = "inform", duration = 5000,
    })

    -- AI buyer spawn
    supabasePost("kronus_logs", {
        service = "sinister-crime",
        action = "dealer_active",
        context_json = { citizenid = cid, spot = spot.zone_name, drug = drugType, quality = quality },
        result = "active"
    })
end)

-- Drug sale at spot
RegisterNetEvent("sinister_crime:sellDrugs", function(spotId, drugType, quantity, quality)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local drug = DRUG_ITEMS[drugType]
    if not drug then return end

    local qualityMult = { dirty = 0.6, standard = 1.0, clean = 1.5, premium = 2.5 }
    local qMult = qualityMult[quality or "standard"] or 1.0
    local earnings = math.floor(drug.base * quantity * qMult * (0.8 + math.random() * 0.4))

    player.Functions.AddMoney("dirty_money", earnings)

    if not activeDealers[cid] then activeDealers[cid] = {} end
    activeDealers[cid].sales = (activeDealers[cid].sales or 0) + quantity
    activeDealers[cid].earnings = (activeDealers[cid].earnings or 0) + earnings

    -- Update drug XP via Supabase
    supabasePost("kronus_logs", {
        service = "sinister-crime",
        action = "drug_sale",
        context_json = {
            citizenid = cid, drug = drugType, quantity = quantity,
            earnings = earnings, quality = quality, spot = spotId,
        },
        result = "sold"
    })

    -- Police witness check (30% civilian + camera zones)
    local spotResp = supabaseGet("drug_spots?select=zone_name&id=eq." .. spotId)
    local zone = "unknown"
    if spotResp.code == 200 and spotResp.data then
        local spots = json.decode(spotResp.data)
        zone = (spots[1] or {}).zone_name or "unknown"
    end

    local cameraZones = { "Downtown Houston", "Montrose", "The Heights", "Port of Houston", "Stockyards" }
    local hasCamera = false
    for _, z in ipairs(cameraZones) do
        if zone == z then hasCamera = true; break end
    end
    local witnessNearby = math.random() < 0.30
    local alerted = witnessNearby or hasCamera

    supabasePost("crime_witnesses", {
        crime_type = "drug_deal",
        location = zone,
        zone_name = zone,
        perpetrator_citizenid = cid,
        witness_type = hasCamera and "camera" or (witnessNearby and "civilian" or "none"),
        reported_to_police = alerted,
        caught_on_camera = hasCamera,
        ps_mdt_alerted = alerted,
    })

    if alerted then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Witness Alert",
            description = hasCamera and "Camera captured the deal!" or "A civilian witnessed the deal!",
            type = "error", duration = 5000,
        })
    end

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Sale Complete",
        description = "Sold " .. quantity .. "x " .. drug.label .. " for $" .. earnings,
        type = "success", duration = 4000,
    })
end)

-- Stop dealing
RegisterNetEvent("sinister_crime:stopDealing", function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    if activeDealers[cid] then
        activeDealers[cid] = nil
    end
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Dealing", description = "You packed up.", type = "inform", duration = 3000,
    })
end)

print("^5[sinister_crime] ^7Server ready")
