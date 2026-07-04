-- Sinister Realtor — Client (Real Estate Office markers)

local REAL_ESTATE_MARKERS = {
    { coords = vec3(-790.0, -720.0, 28.2), label = "Lone Star Realty & Trust" }, -- Main office
    { coords = vec3(-540.58, -212.02, 37.65), label = "City Hall — Property Desk" }, -- City Hall
}

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, spot in ipairs(REAL_ESTATE_MARKERS) do
        exports["qb-target"]:AddBoxZone("realtor_" .. spot.label, spot.coords, 1.5, 1.5, {
            name = "realtor_" .. spot.label,
            heading = 0,
            debugPoly = false,
            minZ = spot.coords.z - 2,
            maxZ = spot.coords.z + 2,
        }, {
            options = {
                {
                    event = "sinister_realtor:openMenu",
                    icon = "fas fa-home",
                    label = "Browse Properties — " .. spot.label,
                },
            },
            distance = 2.5,
        })

        -- Blip
        local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(blip, 350)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 46)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(spot.label)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent("sinister_realtor:openMenu", function()
    local listings = lib.callback.await("sinister_realtor:getListings", false)

    -- Group by neighborhood
    local hoods = {}
    for _, p in ipairs(listings) do
        if not hoods[p.hood] then hoods[p.hood] = {} end
        table.insert(hoods[p.hood], p)
    end

    local options = {}
    for hood, props in pairs(hoods) do
        table.insert(options, { title = "--- " .. hood .. " ---", disabled = true })
        for _, p in ipairs(props) do
            local status = p.owned and "🔒 OWNED" or ("💰 $" .. string.format("%d", p.price))
            local garage = p.garage > 0 and (" | 🚗 " .. p.garage .. " car") or ""
            table.insert(options, {
                title = p.name,
                description = status .. " | " .. p.hood .. garage,
                disabled = p.owned,
                icon = p.owned and "fa-solid fa-lock" or "fa-solid fa-house",
                event = "sinister_realtor:buyProperty",
                args = { name = p.name, price = p.price },
            })
        end
    end

    lib.registerContext({
        id = "sinister_realtor_menu",
        title = "Sinister Real Estate",
        menu = "sinister_realtor_menu",
        options = options,
    })
    lib.showContext("sinister_realtor_menu")
end)

RegisterNetEvent("sinister_realtor:buyProperty", function(data)
    local alert = lib.alertDialog({
        header = "Purchase Property",
        content = "Buy " .. data.name .. " for $" .. string.format("%d", data.price) .. "?",
        centered = true,
        cancel = true,
        confirm = "Purchase",
    })
    if alert ~= "confirm" then return end

    local result = lib.callback.await("sinister_realtor:purchase", false, data.name)
    if result.success then
        lib.notify({ title = "Real Estate", description = result.message, type = "success" })
    else
        lib.notify({ title = "Real Estate", description = result.message, type = "error" })
    end
end)

print("^2[sinister_realtor] ^7Client ready")
