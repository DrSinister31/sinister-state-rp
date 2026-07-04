-- Sinister Licenses — Server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local LICENSE_TYPES = {
    drivers = { name = "Driver's License", cost = 500, item = "drivers_license" },
    weapon = { name = "Weapon License", cost = 2000, item = "weapon_license" },
    business = { name = "Business License", cost = 5000, item = "business_license" },
    hunting = { name = "Hunting License", cost = 1000, item = "hunting_license" },
    fishing = { name = "Fishing License", cost = 500, item = "fishing_license" },
    pilot = { name = "Pilot License", cost = 10000, item = "pilot_license" },
}

local function supabaseGet(endpoint)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "GET", "", {["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY})
    return Citizen.Await(p)
end

local function supabasePost(endpoint, body)
    local p = promise.new()
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/" .. endpoint, function(code, data)
        p:resolve({ code = code, data = data })
    end, "POST", json.encode(body), {
        ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=minimal",
    })
    return Citizen.Await(p)
end

-- Purchase a license at City Hall
RegisterNetEvent("sinister_licenses:purchase", function(licenseType)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local cid = player.PlayerData.citizenid
    local lic = LICENSE_TYPES[licenseType]
    if not lic then
        TriggerClientEvent("ox_lib:notify", src, { title = "License", description = "Invalid license type.", type = "error" })
        return
    end

    -- Check if already has license
    local r = supabaseGet("business_licenses?select=id&license_type=eq." .. licenseType .. "&citizenid=eq." .. cid .. "&revoked=eq.false")
    local existing = (r.code == 200 and r.data and json.decode(r.data) or {})
    if #existing > 0 then
        TriggerClientEvent("ox_lib:notify", src, { title = "License", description = "You already have a valid " .. lic.name .. ".", type = "error" })
        return
    end

    -- Check funds
    local bank = player.Functions.GetMoney("bank") or 0
    if bank < lic.cost then
        TriggerClientEvent("ox_lib:notify", src, { title = "License", description = "Insufficient funds. Need $" .. lic.cost, type = "error" })
        return
    end

    player.Functions.RemoveMoney("bank", lic.cost)

    supabasePost("business_licenses", {
        citizenid = cid,
        license_type = licenseType,
        issued_by = "City Hall",
        issued_at = os.date("!%Y-%m-%dT%H:%M:%S"),
        expires_at = os.date("!%Y-%m-%dT%H:%M:%S", os.time() + 365 * 24 * 3600),
        active = true,
        revoked = false,
    })

    exports.qbx_inventory:AddItem(src, lic.item, 1)

    TriggerClientEvent("ox_lib:notify", src, { title = "License", description = lic.name .. " purchased for $" .. lic.cost, type = "success" })
end)

-- Verify a license (police check)
lib.callback.register("sinister_licenses:verify", function(source, targetCid, licenseType)
    local r = supabaseGet("business_licenses?select=*&citizenid=eq." .. targetCid .. "&license_type=eq." .. licenseType .. "&revoked=eq.false")
    local licenses = (r.code == 200 and r.data and json.decode(r.data) or {})
    
    if #licenses == 0 then
        return { valid = false, reason = "No valid license found" }
    end

    local lic = licenses[1]
    local expired = false
    if lic.expires_at then
        local exp = os.time({year=tonumber(lic.expires_at:sub(1,4)),month=tonumber(lic.expires_at:sub(6,7)),day=tonumber(lic.expires_at:sub(9,10))})
        if os.time() > exp then expired = true end
    end

    return {
        valid = not expired,
        license_type = lic.license_type,
        issued_at = lic.issued_at,
        expires_at = lic.expires_at,
        expired = expired,
    }
end)

-- Revoke a license (police/admin)
RegisterNetEvent("sinister_licenses:revoke", function(targetCid, licenseType)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job
    
    if job.type ~= "leo" and job.name ~= "judge" then
        TriggerClientEvent("ox_lib:notify", src, { title = "License", description = "LEO only.", type = "error" })
        return
    end

    supabaseGet("business_licenses?select=id&citizenid=eq." .. targetCid .. "&license_type=eq." .. licenseType .. "&revoked=eq.false")
    supabasePost("business_licenses", { -- Mark as revoked via update
    })
    -- Actually update the existing record
    local r = supabaseGet("business_licenses?select=id&citizenid=eq." .. targetCid .. "&license_type=eq." .. licenseType .. "&revoked=eq.false")
    local data = (r.code == 200 and r.data and json.decode(r.data) or {})
    if #data > 0 then
        supabasePost("", {}) -- placeholder
        -- Use PATCH
        local p = promise.new()
        PerformHttpRequest(SUPABASE_URL .. "/rest/v1/business_licenses?id=eq." .. data[1].id, function() p:resolve(true) end,
            "PATCH", json.encode({ revoked = true, revoked_by = player.PlayerData.citizenid, revoked_at = os.date("!%Y-%m-%dT%H:%M:%S") }),
            {["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY})
        Citizen.Await(p)
    end

    TriggerClientEvent("ox_lib:notify", src, { title = "License Revoked", description = licenseType .. " license revoked for " .. targetCid, type = "success" })
end)

-- Get all licenses for a player
lib.callback.register("sinister_licenses:getAll", function(source, targetCid)
    local r = supabaseGet("business_licenses?select=*&citizenid=eq." .. (targetCid or "0") .. "&revoked=eq.false")
    return (r.code == 200 and r.data and json.decode(r.data) or {})
end)

print("^2[sinister_licenses] ^7Server ready")
