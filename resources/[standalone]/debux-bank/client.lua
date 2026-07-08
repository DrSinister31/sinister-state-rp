CreateThread(function()
    for i = 1, #Config.Bank do
        local blip = AddBlipForCoord(Config.Bank[i])
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(tostring(Config.Blip.name))
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
	while true do
		local sleep = 500
		local playercoord = GetEntityCoords(PlayerPedId())
		for k,v in pairs(Config.Bank) do
            local dst = #(playercoord - vector3(v.x,v.y,v.z))
                if dst < Config.Distance then
                    sleep = 1
                    DrawText3D(playercoord.x, playercoord.y, playercoord.z, Config.Langs.OpenBank)
                    DrawMarker(29, v.x,v.y,v.z ,0,0,0,0,0,1.0,1.0,1.0,1.0,255, 255, 255,200,0,0,0,1)
                    if IsControlJustPressed(0, 38) then 
                        TriggerServerEvent("BakiTelli_bankv2:getInfos")
                    end
                end
            end
            for _, v in pairs(Config.Atms) do
                local hash = joaat(v)
                local atm = IsObjectNearPoint(hash, playercoord.x, playercoord.y, playercoord.z, 1.5)
                if atm then
                    sleep = 1
                    DrawText3D(playercoord.x, playercoord.y, playercoord.z, Config.Langs.OpenAtm)
                    if IsControlJustPressed(0, 38) then 
                        TriggerServerEvent("BakiTelli_bankv2:getInfos")
                    end
                end
            end
		Citizen.Wait(sleep)
	end
end)

function OpenMenu(typ)
    SetNuiFocus(1, 1)
    SendNUIMessage({
        action = "openmenu",
        typ = typ,
    })
end

function UpdateDetail(typ, info)
    SendNUIMessage({
        action = "Update",
        typ = typ,
        info = info,
    })
end

RegisterNUICallback("close", function ()
    SetNuiFocus(0, 0)
end)

RegisterNetEvent("BakiTelli_bankv2:cl:getInfos", function (Infos, o)
    if o then else 
    OpenMenu("mainPage")
    end
    UpdateDetail("mainPage", Infos)
end)

RegisterNUICallback("First", function (data)
    typ = data.typ
    count = data.count
    TriggerServerEvent("BakiTelli_bankv2:Process", typ, count)
    Citizen.Wait(300)
    TriggerServerEvent("BakiTelli_bankv2:getInfos", true)
end)

RegisterNUICallback("Process", function (data)
    typ = data.typ
    count = data.count
    id = data.id
    TriggerServerEvent("BakiTelli_bankv2:Process", typ, count, id)
    Citizen.Wait(300)
    TriggerServerEvent("BakiTelli_bankv2:getInfos", true)
end)