-- Sinister Hijacking — Client
local hijackActive = false
local hijackBlip = nil

RegisterNetEvent("sinister_hijacking:alert", function(data)
    if not data or not data.coords then return end

    exports.qbx_core:Notify({
        title = data.title or "PRIORITY 5",
        description = data.description or "Trailer hijack in progress.",
        type = "error",
        duration = 15000,
    })

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, 477)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Priority 5 — Trailer Hijack")
    EndTextCommandSetBlipName(blip)

    SetTimeout(300000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)

    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", false, 0, true)
end)

Citizen.CreateThread(function()
    while true do
        Wait(5000)

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 then
            hijackActive = false
            if hijackBlip and DoesBlipExist(hijackBlip) then
                RemoveBlip(hijackBlip)
                hijackBlip = nil
            end
            goto continue
        end

        local trailer = GetVehicleTrailerVehicle(vehicle)
        if trailer == 0 then goto continue end

        local trailerModel = GetDisplayNameFromVehicleModel(GetEntityModel(trailer))

        if not hijackActive then
            hijackActive = true
            local coords = GetEntityCoords(trailer)
            TriggerServerEvent("sinister_hijacking:started", trailerModel, coords)

            lib.showTextUI("[G] Complete Hijack | [X] Abort\nTrailer: " .. trailerModel)

            hijackBlip = AddBlipForEntity(trailer)
            SetBlipSprite(hijackBlip, 479)
            SetBlipColour(hijackBlip, 1)
        end

        DisableControlAction(0, 47, true)
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent("sinister_hijacking:completed", true)
            lib.hideTextUI()
            hijackActive = false
            if hijackBlip and DoesBlipExist(hijackBlip) then RemoveBlip(hijackBlip) end
        end

        DisableControlAction(0, 73, true)
        if IsControlJustPressed(0, 73) then
            TriggerServerEvent("sinister_hijacking:completed", false)
            lib.hideTextUI()
            hijackActive = false
            if hijackBlip and DoesBlipExist(hijackBlip) then RemoveBlip(hijackBlip) end
        end

        ::continue::
    end
end)

print("^1[sinister_hijacking] ^7Client ready")
