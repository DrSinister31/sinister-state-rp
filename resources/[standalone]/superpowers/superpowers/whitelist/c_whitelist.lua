RegisterNetEvent("getHero")

RegisterCommand("addHero", function(source, args)
    TriggerServerEvent("phormalist_superheroes:addHero", tonumber(args[1]), args[2])
end)

RegisterCommand("promoteHero", function(source, args)
    TriggerServerEvent("phormalist_superheroes:promoteHero", tonumber(args[1]), args[2])
end)