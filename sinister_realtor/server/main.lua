-- Sinister Realtor — Server
local SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "")
local SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "")

local PROPERTY_TEMPLATES = {
    -- Loma Vista (Harmony) — drug hot spot, low-end
    ["Loma Vista Trailer A"] = { coords = vec3(1170, 2640, 38), price = 15000, interior = "furnitured_midapart", garage = 0, hood = "Loma Vista" },
    ["Loma Vista Trailer B"] = { coords = vec3(1180, 2645, 38), price = 20000, interior = "furnitured_midapart", garage = 1, hood = "Loma Vista" },
    ["Loma Vista Rancher"]  = { coords = vec3(1175, 2630, 38), price = 45000, interior = "furnitured_midapart", garage = 2, hood = "Loma Vista" },

    -- Third Ward (Strawberry) — low-end urban
    ["Third Ward Apt A"]    = { coords = vec3(100, -1430, 29), price = 25000, interior = "4IntegrityWayApt28", garage = 0, hood = "Third Ward" },
    ["Third Ward Apt B"]    = { coords = vec3(90, -1425, 29),  price = 35000, interior = "4IntegrityWayApt30", garage = 1, hood = "Third Ward" },
    ["Third Ward Small House"] = { coords = vec3(80, -1440, 29), price = 60000, interior = "furnitured_midapart", garage = 1, hood = "Third Ward" },

    -- Sunnyside (Davis) — mid-range
    ["Sunnyside Family Home"] = { coords = vec3(160, -1300, 29), price = 80000, interior = "furnitured_midapart", garage = 2, hood = "Sunnyside" },
    ["Sunnyside Duplex"]      = { coords = vec3(140, -1310, 29), price = 55000, interior = "furnitured_midapart", garage = 1, hood = "Sunnyside" },

    -- The Heights (Mirror Park) — trendy mid-range
    ["Heights Bungalow A"]  = { coords = vec3(1095, -705, 57), price = 180000, interior = "RichardMajesticApt2", garage = 2, hood = "The Heights" },
    ["Heights Bungalow B"]  = { coords = vec3(1105, -695, 57), price = 220000, interior = "TinselTowersApt42", garage = 2, hood = "The Heights" },

    -- Montrose (Vinewood) — artsy mid-high
    ["Montrose Studio Loft"] = { coords = vec3(375, -25, 100),   price = 250000, interior = "TinselTowersApt42", garage = 1, hood = "Montrose" },
    ["Montrose Hills Home"]  = { coords = vec3(365, -35, 100),   price = 450000, interior = "RichardMajesticApt2", garage = 2, hood = "Montrose" },

    -- River Oaks (Rockford Hills) — luxury
    ["River Oaks Estate A"] = { coords = vec3(-895, 305, 70), price = 800000, interior = "TinselTowersApt42", garage = 3, hood = "River Oaks" },
    ["River Oaks Estate B"] = { coords = vec3(-905, 295, 70), price = 1200000, interior = "TinselTowersApt42", garage = 4, hood = "River Oaks" },
    ["River Oaks Mansion"]  = { coords = vec3(-885, 315, 70), price = 2500000, interior = "TinselTowersApt42", garage = 6, hood = "River Oaks" },

    -- Galveston Beach (Vespucci) — coastal
    ["Galveston Beach House"] = { coords = vec3(-1305, -1410, 4), price = 350000, interior = "DellPerroHeightsApt4", garage = 2, hood = "Galveston" },
    ["Galveston Pier Condo"]  = { coords = vec3(-1295, -1400, 4), price = 500000, interior = "DellPerroHeightsApt7", garage = 2, hood = "Galveston" },
}

-- On resource start, seed properties into MySQL
AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for name, data in pairs(PROPERTY_TEMPLATES) do
        local existing = MySQL.query.await("SELECT id FROM properties WHERE property_name = ?", { name })
        if not existing or #existing == 0 then
            MySQL.insert.await("INSERT INTO properties (property_name, coords, price, interior, rent_interval) VALUES (?, ?, ?, ?, ?)", {
                name,
                json.encode({ x = data.coords.x, y = data.coords.y, z = data.coords.z }),
                data.price,
                data.interior,
                168, -- 7 day rent interval
            })
            print("[sinister_realtor] Created: " .. name)
        end
    end
    print("[sinister_realtor] " .. #PROPERTY_TEMPLATES .. " properties seeded into MySQL")
end)

-- Purchase handling
lib.callback.register("sinister_realtor:purchase", function(source, propertyName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { success = false, message = "Not logged in" } end

    local cid = player.PlayerData.citizenid
    local template = PROPERTY_TEMPLATES[propertyName]
    if not template then return { success = false, message = "Property not found" } end

    -- Check if already owned
    local owned = MySQL.query.await("SELECT id FROM properties WHERE property_name = ? AND owner IS NOT NULL", { propertyName })
    if owned and #owned > 0 then return { success = false, message = "Property already owned" } end

    -- Check funds
    local bank = player.Functions.GetMoney("bank") or 0
    if bank < template.price then return { success = false, message = "Insufficient funds. Need $" .. template.price } end

    -- Remove money
    player.Functions.RemoveMoney("bank", template.price)

    -- Assign ownership
    MySQL.update.await("UPDATE properties SET owner = ? WHERE property_name = ?", { cid, propertyName })

    -- Log to Supabase
    local body = json.encode({
        property_id = propertyName,
        property_type = "residential",
        address = template.hood .. " — " .. propertyName,
        price = template.price,
        owner_citizenid = cid,
        listing_status = "sold",
    })
    PerformHttpRequest(SUPABASE_URL .. "/rest/v1/property_listings", function() end, "POST", body, {
        ["Content-Type"] = "application/json", ["apikey"] = SUPABASE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Prefer"] = "return=minimal",
    })

    return { success = true, message = "Purchased " .. propertyName .. " for $" .. template.price }
end)

-- Get available properties grouped by neighborhood
lib.callback.register("sinister_realtor:getListings", function()
    local available = {}
    for name, data in pairs(PROPERTY_TEMPLATES) do
        local record = MySQL.query.await("SELECT owner, id FROM properties WHERE property_name = ?", { name })
        local owned = false
        if record and #record > 0 then
            owned = record[1].owner ~= nil
        end
        table.insert(available, {
            name = name,
            price = data.price,
            hood = data.hood,
            garage = data.garage,
            interior = data.interior,
            owned = owned,
            coords = { x = data.coords.x, y = data.coords.y, z = data.coords.z },
        })
    end
    return available
end)

print("^2[sinister_realtor] ^7Server ready")
