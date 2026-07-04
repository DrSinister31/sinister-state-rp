-- Sinister Licenses — Client (City Hall purchase points)

local LICENSE_POINTS = {
    { coords = vec3(-552.0, -192.0, 38.0), type = "all", label = "City Hall — License Desk" },
}

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, point in ipairs(LICENSE_POINTS) do
        lib.points.new({
            coords = point.coords,
            distance = 2.5,
        })

        exports.qbx_core:CreateUseableItem("drivers_license", function(source, item)
            TriggerEvent("ox_lib:notify", source, { title = "License", description = "Driver's License verified.", type = "success" })
        end)
    end
end)

-- Target interaction for license desk
exports["qb-target"]:AddBoxZone("license_desk", vec3(-552.0, -192.0, 38.0), 1.5, 1.5, {
    name = "license_desk",
    heading = 340,
    debugPoly = false,
    minZ = 36.0,
    maxZ = 40.0,
}, {
    options = {
        { event = "sinister_licenses:openMenu", icon = "fas fa-id-card", label = "Purchase License" },
    },
    distance = 2.5,
})

RegisterNetEvent("sinister_licenses:openMenu", function()
    local options = {
        { title = "Driver's License", description = "$500 — Required to operate vehicles", event = "sinister_licenses:purchaseMenu", args = { type = "drivers" } },
        { title = "Weapon License", description = "$2,000 — Required to carry firearms", event = "sinister_licenses:purchaseMenu", args = { type = "weapon" } },
        { title = "Business License", description = "$5,000 — Required to own businesses", event = "sinister_licenses:purchaseMenu", args = { type = "business" } },
        { title = "Hunting License", description = "$1,000 — Legal hunting permit", event = "sinister_licenses:purchaseMenu", args = { type = "hunting" } },
        { title = "Fishing License", description = "$500 — Legal fishing permit", event = "sinister_licenses:purchaseMenu", args = { type = "fishing" } },
        { title = "Pilot License", description = "$10,000 — Required to fly aircraft", event = "sinister_licenses:purchaseMenu", args = { type = "pilot" } },
    }
    lib.showContext("sinister_licenses_menu")
    lib.registerContext({
        id = "sinister_licenses_menu",
        title = "City Hall — License Desk",
        options = options,
    })
end)

RegisterNetEvent("sinister_licenses:purchaseMenu", function(data)
    local alert = lib.alertDialog({
        header = "Purchase License",
        content = "Buy " .. data.type .. " license?",
        centered = true,
        cancel = true,
    })
    if alert == "confirm" then
        TriggerServerEvent("sinister_licenses:purchase", data.type)
    end
end)

print("^2[sinister_licenses] ^7Client ready")
