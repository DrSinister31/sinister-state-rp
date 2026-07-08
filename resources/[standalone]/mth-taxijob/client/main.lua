local working = false
local taxiVeh = nil
local taxiPed = nil
local pickupBlip = nil
local dropoffBlip = nil
local taxiNpc = nil

local function createBlip(coords, text)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 280)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function loadModel(model)
    model = joaat(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function spawnCustomer(coords, model)
    loadModel(model)

    taxiPed = CreatePed(
        0,
        joaat(model),
        coords.x,
        coords.y,
        coords.z,
        coords.w or 0.0,
        false,
        true
    )

    SetEntityAsMissionEntity(taxiPed, true, true)
    SetBlockingOfNonTemporaryEvents(taxiPed, true)
    SetEntityInvincible(taxiPed, true)
    FreezeEntityPosition(taxiPed, true)
end

local function startPickup()
    local coords = Config.PickupLocations[math.random(#Config.PickupLocations)]
    local model = Config.CustomerModels[math.random(#Config.CustomerModels)]

    if pickupBlip then
        RemoveBlip(pickupBlip)
    end

    pickupBlip = createBlip(coords, Locales.customer)
    spawnCustomer(coords, model)

    lib.notify({
        title = Locales.taxi_job,
        description = Locales.go_to_customer,
        type = 'inform'
    })

    CreateThread(function()
        while working and taxiPed do
            Wait(500)

            local playerPed = PlayerPedId()
            local pCoords = GetEntityCoords(playerPed)

            if #(pCoords - vec3(coords.x, coords.y, coords.z)) < 8.0 and IsPedInVehicle(playerPed, taxiVeh, false) then

                if GetEntitySpeed(taxiVeh) > 1.0 then
                    goto continue
                end

                FreezeEntityPosition(taxiPed, false)
                ClearPedTasksImmediately(taxiPed)

                local seat = 2

                TaskEnterVehicle(taxiPed, taxiVeh, -1, seat, 1.0, 1, 0)

                local timeout = GetGameTimer() + 15000

                while not IsPedInVehicle(taxiPed, taxiVeh, false) do
                    Wait(300)

                    if not working or not DoesEntityExist(taxiPed) then
                        return
                    end

                    if GetGameTimer() > timeout then
                        TaskEnterVehicle(taxiPed, taxiVeh, -1, seat, 1.0, 1, 0)
                        timeout = GetGameTimer() + 15000
                    end
                end

                if pickupBlip then
                    RemoveBlip(pickupBlip)
                    pickupBlip = nil
                end

                startDropoff()
                break
            end

            ::continue::
        end
    end)
end

function startDropoff()
    local dest = Config.DropoffLocations[math.random(#Config.DropoffLocations)]

    dropoffBlip = createBlip(dest, Locales.dropoff_destination)

    lib.notify({
        title = Locales.taxi_job,
        description = Locales.go_to_destination,
        type = 'inform'
    })

    CreateThread(function()
        while working and taxiPed do
            Wait(500)

            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)

            if #(coords - dest) < 8.0 and IsPedInVehicle(playerPed, taxiVeh, false) then

                TaskLeaveVehicle(taxiPed, taxiVeh, 0)

                local timeout = GetGameTimer() + 8000
                while IsPedInVehicle(taxiPed, taxiVeh, false) and GetGameTimer() < timeout do
                    Wait(200)
                end
                
                Wait(500)

                for i = 0, 5 do
                    SetVehicleDoorShut(taxiVeh, i, false)
                end

                Wait(700)

                if DoesEntityExist(taxiPed) then
                    local pedCoords = GetEntityCoords(taxiPed)
                    local forward = GetEntityForwardVector(taxiVeh)

                    local walkTo = vec3(
                        pedCoords.x + forward.x * 6.0,
                        pedCoords.y + forward.y * 6.0,
                        pedCoords.z
                    )

                    TaskGoStraightToCoord(
                        taxiPed,
                        walkTo.x,
                        walkTo.y,
                        walkTo.z,
                        1.0,
                        -1,
                        0.0,
                        0.0
                    )
                end

                TriggerServerEvent('mth9f2m7d4k8s1x6r5c0h3j:w4n7b2p9d5m6kA8Q')

                if dropoffBlip then
                    RemoveBlip(dropoffBlip)
                    dropoffBlip = nil
                end

                Wait(2000)

                if DoesEntityExist(taxiPed) then
                    DeleteEntity(taxiPed)
                end

                taxiPed = nil

                if working then
                    startPickup()
                end

                break
            end
        end
    end)
end

local function spawnTaxiVehicle()
    loadModel(Config.VehicleModel)

    local c = Config.VehicleSpawn

    taxiVeh = CreateVehicle(
        joaat(Config.VehicleModel),
        c.x, c.y, c.z,
        c.w,
        true,
        false
    )

    SetVehicleOnGroundProperly(taxiVeh)
    SetEntityAsMissionEntity(taxiVeh, true, true)
end

local function startJob()
    if working then return end

    working = true
    spawnTaxiVehicle()

    lib.notify({
        title = Locales.taxi_job,
        description = Locales.get_in_taxi,
        type = 'inform'
    })

    CreateThread(function()
        while working do
            Wait(500)

            local ped = PlayerPedId()

            if IsPedInVehicle(ped, taxiVeh, false) then
                startPickup()
                break
            end
        end
    end)
end

local function stopJob()
    working = false

    if pickupBlip then RemoveBlip(pickupBlip) pickupBlip = nil end
    if dropoffBlip then RemoveBlip(dropoffBlip) dropoffBlip = nil end

    if taxiPed then
        DeleteEntity(taxiPed)
        taxiPed = nil
    end

    if taxiVeh and DoesEntityExist(taxiVeh) then
        DeleteEntity(taxiVeh)
        taxiVeh = nil
    end

    lib.notify({
        title = Locales.taxi_job,
        description = Locales.stopped_working,
        type = 'error'
    })
end

CreateThread(function()
    loadModel(Config.TaxiNPCModel)

    local c = Config.TaxiNPC

    taxiNpc = CreatePed(
        0,
        joaat(Config.TaxiNPCModel),
        c.x, c.y, c.z - 1.0,
        c.w,
        false,
        true
    )

    FreezeEntityPosition(taxiNpc, true)
    SetEntityInvincible(taxiNpc, true)
    SetBlockingOfNonTemporaryEvents(taxiNpc, true)

    exports.ox_target:addLocalEntity(taxiNpc, {
        {
            label = Locales.taxi_job,
            icon = 'fa-solid fa-taxi',
            onSelect = function()
                local options = {}

                if not working then
                    options[#options+1] = {
                        title = Locales.start_work,
                        onSelect = function()
                            startJob()
                        end
                    }
                else
                    options[#options+1] = {
                        title = Locales.stop_work,
                        onSelect = function()
                            stopJob()
                        end
                    }
                end

                lib.registerContext({
                    id = 'mth_taxi_menu',
                    title = Locales.taxi_job,
                    options = options
                })

                lib.showContext('mth_taxi_menu')
            end
        }
    })
end)
