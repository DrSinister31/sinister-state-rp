local pawnPed = {}

local function openPawnMenu()
    local items = lib.callback.await('attano_pawnshop:getItems', 100)

    if not items or #items == 0 then
        lib.notify({ description = 'You have nothing to sell.' })
        return
    end

    SendNUIMessage({
        action = 'openFishingSell', -- reuse same NUI action
        fish = items
    })

    SetNuiFocus(true, true)
end

CreateThread(function()
    for i = 1, #Config.PawnShop do
        local shop = Config.PawnShop[i]

        if Config.Blip and Config.Blip.enabled then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)

            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.Blip.scale or 0.8)
            SetBlipColour(blip, Config.Blip.colour or 2)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Blip.label or 'Pawn Shop')
            EndTextCommandSetBlipName(blip)
        end

        local model = joaat(shop.ped)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        local ped = CreatePed(0, model, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.heading, false, false)

        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        Entity(ped).state.pawnshopNpc = true

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'pawnshop_sell',
                icon = 'fa-solid fa-hand-holding-dollar',
                label = 'Open Pawnshop',
                onSelect = function()
                    openPawnMenu()
                end
            }
        })

        pawnPed[#pawnPed+1] = ped
    end
end)

RegisterNUICallback('closeFishingSell', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeFishingSell' })
    cb('ok')
end)

RegisterNUICallback('sellFishType', function(data, cb)
    local success, msg = lib.callback.await('attano_pawnshop:sellItem', 100, data.item)

    if success then
        local updated = lib.callback.await('attano_pawnshop:getItems', 100)
        SendNUIMessage({
            action = 'refreshFishingSell',
            fish = updated
        })
    else
        lib.notify({ description = msg })
    end

    cb({ success = success })
end)
