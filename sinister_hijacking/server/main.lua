-- Sinister Hijacking — Server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local activeHijacks = {}
local PREMIUM_TRAILERS = {
    "trailers2", "trailers3", "trailers4", "tanker", "armytanker", "tvtrailer",
    "raketrailer", "boattrailer", "baletrailer",
}

local HIJACK_PAYOUTS = {
    luxury_cars = { min = 15000, max = 40000 },
    weapons = { min = 20000, max = 60000 },
    ron_oil = { min = 10000, max = 30000 },
    default = { min = 5000, max = 15000 },
}

local function supabasePost(table, body)
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. table, function() end, "POST",
        json.encode(body), {
            ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
            ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=minimal",
        })
end

local function getCargoType(trailerModel)
    local model = string.lower(trailerModel or "")
    if model:find("tv") or model:find("car") or model:find("boat") or model:find("bale") then
        return "luxury_cars"
    elseif model:find("tank") or model:find("army") or model:find("rake") then
        return "weapons"
    elseif model:find("fuel") or model:find("oil") then
        return "ron_oil"
    end
    return "default"
end

RegisterNetEvent("sinister_hijacking:started", function(trailerModel, coords)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    local cargoType = getCargoType(trailerModel)
    local payout = HIJACK_PAYOUTS[cargoType] or HIJACK_PAYOUTS["default"]

    activeHijacks[cid] = {
        cargo = cargoType,
        coords = coords,
        started = os.time(),
        payout = math.random(payout.min, payout.max),
    }

    supabasePost("hijack_incidents", {
        perpetrator_citizenid = cid,
        cargo_tier = cargoType,
        cargo_value = activeHijacks[cid].payout,
        alert_level = "Priority 5",
        fib_notified = true,
        location_coords = coords,
        outcome = "in_progress",
    })

    local alertData = {
        title = "PRIORITY 5 — TRAILER HIJACK",
        coords = vector3(coords.x, coords.y, coords.z),
        description = ("Semi-truck trailer hijacked. Cargo: %s. Value: $%s. Suspect: %s %s."):format(
            cargoType, activeHijacks[cid].payout,
            player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname
        ),
    }

    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        if p then
            local pData = exports.qbx_core:GetPlayer(p)
            if pData and pData.PlayerData.job and pData.PlayerData.job.type == "leo" then
                TriggerClientEvent("sinister_hijacking:alert", p, alertData)
            end
        end
    end

    TriggerClientEvent("ox_lib:notify", src, {
        title = "HIJACK IN PROGRESS",
        description = ("Cargo: %s | Value: ~$%s | Police alerted."):format(cargoType, activeHijacks[cid].payout),
        type = "inform", duration = 10000,
    })
end)

RegisterNetEvent("sinister_hijacking:completed", function(success)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local hijack = activeHijacks[cid]
    if not hijack then return end

    local payout = success and hijack.payout or math.floor(hijack.payout * 0.2)
    local outcome = success and "succeeded" or "failed"

    if success then
        exports.qbx_core.Functions.AddMoney(src, "dirty_money", payout)
    end

    supabasePost("hijack_incidents", {
        perpetrator_citizenid = cid,
        cargo_tier = hijack.cargo,
        cargo_value = payout,
        alert_level = "Priority 5",
        fib_notified = true,
        police_responded = true,
        outcome = outcome,
        resolved_at = os.date("!%Y-%m-%dT%H:%M:%S"),
    })

    local score = success and 22 or 14
    supabasePost("chronicle_entries", {
        score = score,
        title = success and "Trailer Hijack Successful" or "Trailer Hijack Failed",
        description = ("Cargo: %s. Payout: $%s. Outcome: %s."):format(hijack.cargo, payout, outcome),
        involved_citizenids = { cid },
        involved_discord_ids = {},
        volume_index = 0,
    })

    activeHijacks[cid] = nil
end)

print("^1[sinister_hijacking] ^7Server ready")
