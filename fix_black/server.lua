-- Server-side emergency teleport to safe outdoor location
-- Uses SetEntityCoords via client event to fix black screen

RegisterCommand("fixme", function(source, args, raw)
    local src = source
    if src > 0 then
        TriggerClientEvent("fix_black:teleport", src)
        print("[fix_black] Teleported player " .. tostring(src))
    end
end, false) -- false = anyone can use it

RegisterNetEvent("fix_black:teleportSelf")
AddEventHandler("fix_black:teleportSelf", function()
    local src = source
    if src > 0 then
        TriggerClientEvent("fix_black:teleport", src)
    end
end)
