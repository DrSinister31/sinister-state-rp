-- Client: receives teleport event from server
RegisterNetEvent("fix_black:teleport", function()
    local ped = PlayerPedId()
    -- Pink Cage Motel parking lot
    SetEntityCoords(ped, 325.0, -210.0, 54.0, false, false, false, true)
    SetEntityHeading(ped, 160.0)
    SetNuiFocus(false, false)
    FreezeEntityPosition(ped, true)
    Citizen.SetTimeout(500, function()
        if DoesEntityExist(ped) then FreezeEntityPosition(ped, false) end
    end)
    print("[fix_black] Teleported to Pink Cage Motel")
end)
