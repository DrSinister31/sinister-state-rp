local QBCore = exports['qb-core']:GetCoreObject()

local ped = nil
local radialOption = nil

local Cooldown = {
    Enabled = false,
    Time = 0
}

local vehData = {
    vehicle = nil,
    vehSpawned = false,
    vehCapacity = nil,
    vehPlate = nil,
    Spawn = nil,
    SpawnBlip = nil
}

local jobData = {
    Active = false,
    Vehicle = nil,
    PickupZone = nil,
    DropoffZones = {},
    Dropoffs = {},
    Blips = {},
    Pallet = nil,
    Package = nil,
    Box = nil,
    HasBox = false,
    Pickup = false,
    Dropoff = false,
    Pay = nil,
    Bonus = true,
    Drops = 0,
    Deliveries = 0
}

-- Core functions

local function resetData()
    jobData = {
        Active = false,
        Vehicle = nil,
        PickupZone = nil,
        DropoffZones = {},
        Dropoffs = {},
        Blips = {},
        Pallet = nil,
        Package = nil,
        Box = nil,
        HasBox = false,
        Pickup = false,
        Dropoff = false,
        Pay = nil,
        Bonus = true,
        Drops = 0,
        Deliveries = 0
    }
end

-- Debug blips
if Config.Debug then
    CreateThread(function()
        local blipColor = 6
        for _, Job in pairs(Config.Jobs) do
            if Job.Debug then
                for key, pickup in pairs(Job.pickups) do
                    makeBlip({ coords = pickup.xyz, sprite = 750, colour = blipColor, label = Job.title .. " Pickup #" ..key, scale = 0.7, display = 4 })
                end
                for key, dropoff in pairs(Job.dropoffs) do
                    makeBlip({ coords = dropoff.xyz, sprite = 478, colour = blipColor, label = Job.title .. " Dropoff #" ..key, scale = 0.7, display = 4 })
                end            
                blipColor += 1
            end
        end
    end)
end

-- Listen for crashes
local function listenForVehicleDamage()
    CreateThread(function()
        local lastVehicleHealth = nil
        while true do
            if not jobData.Active or not DoesEntityExist(jobData.Vehicle) then lastVehicleHealth = nil return end
            if jobData.Delivery then
                if IsVehicleDriveable(jobData.Vehicle, true) == false then
                    --TriggerEvent('fn-courier:client:cancelJob')
                    return triggerNotify(nil, "truck","Your job vehicle has been destroyed", "error")
                end
                if Config.Job.Damage.Enabled then
                    local currentHealth = GetEntityHealth(jobData.Vehicle)
                    if lastVehicleHealth and currentHealth < lastVehicleHealth and (lastVehicleHealth-currentHealth) > Config.Damage.Amount then
                        local damageChance = math.random(1, 100)
                        if damageChance <= Config.Job.Damage.Chance then
                            if jobData.Bonus then jobData.Bonus = false end
                            if (jobData.Deliveries - jobData.Drops) == 1 then
                                --TriggerEvent('fn-courier:client:cancelJob')
                                return triggerNotify(nil, "truck",'You have damaged your last package, you have no more to deliver', "error")
                            end
                            -- Delete a random dropoff
                            local randomDrop = math.random(1, jobData.Deliveries)
                            jobData.DropoffZones[randomDrop]:destroy()
                            RemoveBlip(jobData.Blips[randomDrop])
                            jobData.Deliveries -= 1
                            triggerNotify(nil, "truck", string.format('You damaged one of your packages, you only have %d left', jobData.Deliveries - jobData.Drops), "error")
                        end
                    end
                    lastVehicleHealth = currentHealth
                end
            else
                if IsVehicleDriveable(jobData.Vehicle, true) == false then
                    --TriggerEvent('fn-courier:client:cancelJob')
                    return triggerNotify(nil, "truck","Your job vehicle has been destroyed", "error")
                end
            end
            Wait(200)
        end
    end)
end

local function CreatePickup(coords)
    jobData.PickupZone = BoxZone:Create(
        coords, 100, 100, {
        minZ = coords.z - 5.0,
        maxZ = coords.z + 5.0,
        name = "pickup",
        debugPoly = Config.Debug,
        heading = coords.w,
    })
    jobData.PickupZone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            triggerNotify(nil, nil, "Now load the packages", "success")
            loadModel('prop_boxpile_02c')
            jobData.Pallet = CreateObject(
                'prop_boxpile_02c',
                coords.xyz,
            true)
            jobData.Pickup = true
            SetEntityDrawOutlineColor(255, 191, 0, 222)
            SetEntityDrawOutlineShader(1)
            SetEntityDrawOutline(jobData.Pallet, true) 
            PlaceObjectOnGroundProperly(jobData.Pallet)
            FreezeEntityPosition(jobData.Pallet, true)
            SetEntityHeading(jobData.Pallet, coords.w)
            exports.ox_target:addBoxZone({
                name = 'pickup_package',
                coords = coords,
                size = vec3(2.0, 2.0, 2.0),
                rotation = coords.w,
                debug = Config.Debug,
                options = {
                    {
                        icon = 'fas fa-box',
                        type = 'client',
                        event = 'fn-courier:client:pickupPackage',
                        label = 'Pickup Package',
                        canInteract = function(entity, distance, coords, name, bone)
                            if distance > 1.5 or jobData.HasBox then return false end
                            return true
                        end
                    },
                },
            })
        else
            exports.ox_target:removeZone('pickup_package')
            DeleteObject(jobData.Pallet)
            SetEntityDrawOutline(jobData.Pallet, false) 
            jobData.Pallet = nil
            jobData.Pickup = false
            if jobData.Drops ~= jobData.Deliveries then
                triggerNotify(nil, "truck-pickup","You left some packages behind!", "error")
            else
                triggerNotify(nil, "truck-pickup","You left the pickup location!", "error")
            end
        end
    end)
end

local function CreateDropoff(coords, key)
    jobData.DropoffZones[key] = BoxZone:Create(
        coords, 50, 50, {
        minZ = coords.z - 5.0,
        maxZ = coords.z + 5.0,
        name = "Delivery "..key,
        debugPoly = Config.Debug,
        heading = coords.w,
    })
    jobData.DropoffZones[key]:onPlayerInOut(function(isPointInside)
        if isPointInside then
            triggerNotify(nil, nil, "Now remove the package from your vehicle", "success")
            jobData.Dropoff = true
            exports.ox_target:addGlobalVehicle({
                name = 'remove_package',
                event = 'fn-courier:client:removePackage',
                args = {coords = coords, key = key},
                icon = 'fa-solid fa-box',
                bones = {'bumper_r', 'door_pside_r', 'door_dside_r'},
                label = 'Remove Package',
                canInteract = function(entity, distance, coords, name, bone)
                    if entity ~= jobData.Vehicle or distance > 1.5 then return false end
                    return true
                end
            })
        else
            DeleteObject(jobData.Box)
            exports.ox_target:removeGlobalVehicle('remove_package')
            triggerNotify(nil, "truck-pickup","You left the dropoff location!", "error")
            jobData.Dropoff = false
        end
    end)
end

-- Create job location
CreateThread(function()
    if Config.Location.blip.show then
        makeBlip({ coords = Config.Location.blip.coords, sprite = Config.Location.blip.sprite or 356, colour = Config.Location.blip.color or 29, label = Config.Location.blip.label or "Courier Headquarters", scale = Config.Location.blip.scale or 0.7, display = Config.Location.blip.display or 6})
    end
    ped = makePed(Config.Location.model, Config.Location.coords, true, false, Config.Location.scenario or nil)
    -- exports.ox_target:addBoxZone({
    --     name = 'ped',
    --     coords = vector3(Config.Location.coords.xyz),
    --     size = vec3(0.75, 0.75, 2.0),
    --     rotation = Config.Location.coords.w,
    --     debug = Config.Debug,
    --     options = {
    --         {
    --             icon = 'fas fa-truck-front',
    --             label = 'Open Job Menu',
    --             event = 'fn-courier:client:jobMenu',
    --             distance = 1.5,
    --         }
    --     }
    -- })
    local point = lib.points.new({
        coords = GetEntityCoords(ped),
        distance = 2.0,
        onEnter = function()
            lib.showTextUI('[E] Talk to Shop Owner')
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(self)
            if IsControlJustReleased(0, 38) then -- 'E' key
                exports['era-dialog']:ShowDialog({
                    title = "Foreman",
                    message = "Welcome! How can I help you today?",
                    targetPed = ped,
                    rot = vector3(0.95, 1.0, 0.75),
                    buttons = {
                        {text = "Open Job Menu", action = "menu"},
                        {text = "Nevermind", action = "close"}
                    }
                }, function(buttonId, buttonData)
                    if buttonData.action == "menu" then
                        TriggerEvent('fn-courier:client:jobMenu')
                    end
                end)
            end
        end
    })
    -- Create vehicle return location
    local garage = BoxZone:Create(
        Config.Return.coords, Config.Return.y, Config.Return.x, {
        minZ = Config.Return.coords.z - 5.0,
        maxZ = Config.Return.coords.z + 5.0,
        name = "return",
        debugPoly = Config.Debug,
        heading = Config.Return.coords.w,
    })
    garage:onPlayerInOut(function(isPointInside)
        if isPointInside then
            -- Create radial option
            if radialOption ~= nil then
                exports["qb-radialmenu"]:RemoveOption(radialOption)
                radialOption = nil
            end
            lib.showTextUI("Return Vehicle [Hold F1]")
            radialOption = exports["qb-radialmenu"]:AddOption(
                {
                    id = "radial_option",
                    title = "Return Vehicle",
                    icon = "warehouse",
                    type = "client",
                    event = "fn-courier:client:returnVehicle",
                    shouldClose = true
                }
            )
        else
            -- Remove radial option
            if radialOption ~= nil then
                exports["qb-radialmenu"]:RemoveOption(radialOption)
                radialOption = nil
            end
            lib.hideTextUI()
        end
    end)
end)

-- Core events

-- Client event to rent vehicles
RegisterNetEvent('fn-courier:client:rentVehicle', function(data)
    if vehData.vehSpawned then
        triggerNotify(nil, "truck","Return your previous vehicle first!", "error") return
    end
    local closestVehicle
    local spawn = false
    for _, coords in pairs(data.spawns) do
        closestVehicle, _ = lib.getClosestVehicle(coords.xyz, 3)
        if not closestVehicle then
            if Config.Deposit then
                TriggerServerEvent('fn-courier:server:payDeposit', true, data.deposit, data.vehicle, coords)
            else
                TriggerEvent("fn-courier:client:retrieveVehicle", data.vehicle, coords)
            end
            vehData.vehCapacity = data.capacity
            spawn = true
            break
        end
    end
    if not spawn then 
        triggerNotify(nil, "truck","There are no parking spaces available", "error")
    end
end)

-- Garage retrieve vehicle event
RegisterNetEvent('fn-courier:client:retrieveVehicle', function(vehicle, coords)
    -- Create vehicle return blip
    if vehData.SpawnBlip ~= nil then RemoveBlip(vehData.SpawnBlip) end
    vehData.SpawnBlip = AddBlipForCoord(coords.xyz)
    SetBlipSprite(vehData.SpawnBlip, 357)
    SetBlipColour(vehData.SpawnBlip, 5)
    SetBlipScale(vehData.SpawnBlip, 0.7)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Vehicle Return")
    EndTextCommandSetBlipName(vehData.SpawnBlip)
    loadModel(vehicle)
    vehData.vehicle = CreateVehicle(
        vehicle, 
        coords.x, 
        coords.y, 
        coords.z, 
        coords.w, 
        true, 
        true
    )
    SetVehicleLivery(vehData.vehicle, 0)
    SetEntityRotation(vehData.vehicle, 0.0, 0.0, GetEntityHeading(vehData.vehicle), 2, true)
    exports[Config.Fuel]:SetFuel(vehData.vehicle, 100.0)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehData.vehicle, -1)
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(vehData.vehicle))
    vehData.vehSpawned = true
    vehData.Spawn = coords
    vehData.vehPlate = QBCore.Functions.GetPlate(vehData.vehicle)
    jobData.Vehicle = vehData.vehicle
end)

-- Garage return vehicle event
RegisterNetEvent('fn-courier:client:returnVehicle', function(data)
    if not IsPedInAnyVehicle(PlayerPedId()) then -- Make sure player is in a vehicle
        triggerNotify(nil, nil, "You have no vehicle to return", "error") 
        return 
    end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    local plate = GetVehicleNumberPlateText(vehicle)
    if vehData.vehPlate == plate then -- Checks to ensure the vehicle they're returning matches the one they rented
        DeleteVehicle(vehicle)
        if Config.Deposit then
            TriggerServerEvent('fn-courier:server:payDeposit', false)
        else
            triggerNotify(nil, "helmet-safety", "Vehicle Returned!", "success")
        end
        if vehData.SpawnBlip ~= nil then 
            RemoveBlip(vehData.SpawnBlip) 
        end
        vehData.vehSpawned = false
    else
        triggerNotify(nil, "helmet-safety", "This is not the vehicle you received", "error")
    end
end)

-- Open job dispatch menu
RegisterNetEvent('fn-courier:client:jobMenu', function()
    QBCore.Functions.TriggerCallback('fn-courier:list', function(list)
        local mainOptions = {}
        mainOptions = {
            {
                title = 'Check Jobs', -- Header/title text
                description = 'Check available jobs', -- Description
                menu = 'job_menu', -- Menu that opens when the button is pressed
                icon = 'truck-front', -- Icon displayed on menu (https://fontawesome.com/search)
                arrow = true,
              },
              {
                title = 'Open Garage',
                description = 'Check available vehicles',
                menu = 'vehicle_menu',
                icon = 'warehouse',
                arrow = true,
              },
        }
        if jobData.Active then
            local isCancel = jobData.Pickup or (jobData.Delivery and jobData.Drops == 0)
            mainOptions[#mainOptions+1] = {
                title = isCancel and 'Cancel Job' or 'Finish Job',
                description = isCancel and 'Cancel your current job' or 'Finish your current job',
                icon = isCancel and 'ban' or 'check',
                event = 'fn-courier:client:finish'
            }
        end
        -- Main menu
        lib.registerContext({
            id = 'main_menu',
            title = 'Job Menu',
            options = mainOptions
        })
        -- Job menu
        local jobOptions = {}
        if #list > 0 then
            for k, v in ipairs(list) do
                local playerDist = string.format("%.2f", (GetDistanceBetweenCoords(v.pickup.xyz, GetEntityCoords(PlayerPedId())) / 1609.34))
                local dropCount = v.dropoffs and #v.dropoffs or 0
                local totalPay = v.pay and dropCount * v.pay or 0
                local distance = playerDist or "N/A"
                jobOptions[#jobOptions+1] = {
                    title = v.title,
                    description = string.format("%i Deliveries, $%i, %s Mi away%s", dropCount, totalPay, distance, 
                    (vehData.vehSpawned and vehData.vehCapacity < #v.dropoffs) and "\nYour vehicle does not have enough capacity." or ""),
                    icon = 'trailer',
                    event = 'fn-courier:client:startPickup',
                    args = {
                        key = k,
                        id = v.id,
                        title = v.title,
                        pickup = v.pickup,
                        dropoffs = v.dropoffs,
                        livery = v.livery,
                        pay = v.pay
                    }
                }
            end
        else
            jobOptions[1] = {
                title = "No jobs currently available.",
                description = "Please wait till later...",
                icon = 'trailer',
                event = '',
            }
        end
        lib.registerContext({
            id = 'job_menu',
            title = 'Available Jobs',
            menu = 'main_menu',
            options = jobOptions
        })
        -- Garage menu
        local vehicleOptions = {}
        for k, v in pairs(Config.Vehicles) do
            title = v.title
            if Config.Deposit then
                title = v.title .. " [$"..v.deposit.."]"
            else
                title = v.title
            end
            vehicleOptions[#vehicleOptions+1] = {
                title = title,
                description = string.format("%s\nCapacity: %d", v.desc, v.capacity),
                icon = 'truck-front',
                event = 'fn-courier:client:rentVehicle',
                args = {
                    spawns = v.spawns,
                    vehicle = v.model,
                    deposit = v.deposit,
                    capacity = v.capacity
                }
            }
        end
        lib.registerContext({
            id = 'vehicle_menu',
            title = 'Job Vehicles',
            menu = 'main_menu',
            options = vehicleOptions
        })

        lib.showContext('main_menu') -- Open menu
    end)
end)

-- Client event to start jobs
RegisterNetEvent('fn-courier:client:startPickup', function(data)
    if not vehData.vehSpawned then
        triggerNotify(nil, "truck","You must have a vehicle out to start the job", "error") return
    end
    if not jobData.Active then
        if Cooldown.Enabled then triggerNotify(nil, "truck","You must wait "..Cooldown.Time.." minutes before starting another job...", "error") return end
        QBCore.Functions.TriggerCallback('fn-courier:checklist', function(result) -- Check to make sure the job still exists
            if not result then
                triggerNotify(nil, "truck","This job is no longer available!", "error")
                return
            end
        end, data.id)
        TriggerServerEvent('fn-courier:server:removeList', data.key)
        -- Set vehicle livery
        SetVehicleLivery(vehData.vehicle, data.livery)
        -- Update variables
        jobData.Active = true
        jobData.Pay = data.pay
        jobData.Pickup = true
        jobData.Dropoffs = data.dropoffs
        jobData.Deliveries = #jobData.Dropoffs
        -- Check vehicle capacity
        if vehData.vehCapacity < #jobData.Dropoffs then
            for i = #jobData.Dropoffs, vehData.vehCapacity + 1, -1 do
                table.remove(jobData.Dropoffs, i)
            end
            jobData.Deliveries = vehData.vehCapacity
            triggerNotify(nil, "truck","Your vehicle does not have the capacity for all the packages, head to the pickup location", "success")
        else
            triggerNotify(nil, "truck", "Head to the pickup location")
        end
        -- Create pickup blip
        jobData.Blips[0] = AddBlipForCoord(data.pickup.xyz)
        SetBlipSprite(jobData.Blips[0], 750)
        SetBlipColour(jobData.Blips[0], 5)
        SetBlipScale(jobData.Blips[0], 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Pickup Location")
        EndTextCommandSetBlipName(jobData.Blips[0])
        CreatePickup(data.pickup)
    else
        triggerNotify(nil, "truck","Finish your current job!", "error")
    end
end)

RegisterNetEvent('fn-courier:client:pickupPackage', function()
    playAnim(Config.Anim.Pickup)
    if lib.progressBar({
        duration = Config.Anim.Pickup * 1000,
        label = "Picking up package",
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
    }) then
        jobData.HasBox = true
        if jobData.Drops == jobData.Deliveries-1 then
            exports.ox_target:removeZone('pickup_package')
            DeleteObject(jobData.Pallet)
            jobData.Pallet = nil
        end
        loadModel('hei_prop_heist_box')
        loadAnimDict("anim@heists@box_carry@")
        ClearPedTasks(PlayerPedId())
        -- Create prop
        jobData.Package = CreateObject('hei_prop_heist_box', 0, 0, 0, true, true, true)
        AttachEntityToEntity(jobData.Package, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, false, 2, true)
        TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 4.0, -1.0, -1, 49, 0, false, false, false)
        CreateThread(function()
            while jobData.HasBox do -- Carry part till player scraps it
                if not IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) then
                    TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -1.0, -1, 49, 0, false, false, false)
                end
                DisableControlAction(0, 23, true)
                Wait(1)
            end
        end)
        exports.ox_target:addGlobalVehicle({
            name = 'load_package',
            event = 'fn-courier:client:loadPackage',
            icon = 'fa-solid fa-box',
            bones = {'bumper_r', 'door_pside_r', 'door_dside_r'},
            label = 'Load Package',
            canInteract = function(entity, distance, coords, name, bone)
                if entity ~= jobData.Vehicle or distance > 1.5 or not jobData.HasBox then return false end
                return true
            end
        })
    else
        triggerNotify(nil, "truck-pickup","Task Cancelled", "error")
    end
end)

RegisterNetEvent('fn-courier:client:loadPackage', function()
    exports.ox_target:removeGlobalVehicle('load_package')
    SetVehicleDoorOpen(jobData.Vehicle, 2, false, true)
    SetVehicleDoorOpen(jobData.Vehicle, 3, false, true)
    playAnim(Config.Anim.Loading)
    if lib.progressBar({
        duration = Config.Anim.Loading * 1000,
        label = "Loading package",
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = false
        },
    }) then
        SetVehicleDoorShut(jobData.Vehicle, 2, true)
        SetVehicleDoorShut(jobData.Vehicle, 3, true)
        jobData.HasBox = false
        ClearPedTasks(PlayerPedId())
        DeleteObject(jobData.Package)
        jobData.Drops += 1
        lib.showTextUI("Packages: "..jobData.Drops.." / "..jobData.Deliveries)
        if jobData.Drops == jobData.Deliveries then
            TriggerEvent('fn-courier:client:startDeliveries')
            jobData.Drops = 0
        else
            triggerNotify(nil, "truck-pickup", "Package loaded", "success")
        end
        SetTimeout(5000, function()
            lib.hideTextUI()
        end)
    else
        SetVehicleDoorShut(jobData.Vehicle, 2, true)
        SetVehicleDoorShut(jobData.Vehicle, 3, true)
        triggerNotify(nil, "truck-pickup","Task Cancelled", "error")
    end
end)

RegisterNetEvent('fn-courier:client:startDeliveries', function(data)
    -- Destroy pickup zones/targets
    exports.ox_target:removeGlobalVehicle('load_package')
    jobData.PickupZone:destroy()
    jobData.Pickup = false
    jobData.Delivery = true
    RemoveBlip(jobData.Blips[0])
    table.remove(jobData.Blips, 0)
    -- Create blips and zones for each dropoff.
    for k, coords in pairs(jobData.Dropoffs) do
        jobData.Blips[k] = AddBlipForCoord(coords.xyz)
        SetBlipSprite(jobData.Blips[k], 478)
        SetBlipColour(jobData.Blips[k], 5)
        SetBlipScale(jobData.Blips[k], 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Delivery")
        EndTextCommandSetBlipName(jobData.Blips[k])
        CreateDropoff(coords, k)
    end
    triggerNotify(nil, "truck-pickup", "Start dropping off packages", "success")
    listenForVehicleDamage()
end)

RegisterNetEvent('fn-courier:client:removePackage', function(data)
    if data and data.args then data = data.args end
    exports.ox_target:removeGlobalVehicle('remove_package')
    playAnim(Config.Anim.Pickup)
    SetVehicleDoorOpen(jobData.Vehicle, 2, false, true)
    SetVehicleDoorOpen(jobData.Vehicle, 3, false, true)
    if lib.progressBar({
        duration = Config.Anim.Pickup * 1000,
        label = "Removing package",
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = false
        },
    }) then
        SetVehicleDoorShut(jobData.Vehicle, 2, true)
        SetVehicleDoorShut(jobData.Vehicle, 3, true)
        jobData.DropoffZones[data.key]:destroy()
        loadModel('hei_prop_heist_box')
        loadAnimDict("anim@heists@box_carry@")
        ClearPedTasks(PlayerPedId())
        -- Create package
        jobData.HasBox = true
        jobData.Package = CreateObject('hei_prop_heist_box', 0, 0, 0, true, true, true)
        AttachEntityToEntity(jobData.Package, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, false, 2, true)
        TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 4.0, -1.0, -1, 49, 0, false, false, false)
        CreateThread(function()
            while jobData.HasBox do -- Carry part till player scraps it
                if not IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) then
                    TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -1.0, -1, 49, 0, false, false, false)
                end
                DisableControlAction(0, 23, true)
                Wait(1)
            end
        end)
        -- Create reference
        jobData.Box = CreateObject(
            'hei_prop_heist_box',
            data.coords.xyz,
        false)
        SetEntityDrawOutlineColor(255, 191, 0, 222)
        SetEntityDrawOutlineShader(1)
        SetEntityDrawOutline(jobData.Box, true) 
        SetEntityAlpha(jobData.Box, 120)
        PlaceObjectOnGroundProperly(jobData.Box)
        FreezeEntityPosition(jobData.Box, true)
        SetEntityHeading(jobData.Box, data.coords.w)
        local position = GetEntityCoords(jobData.Box)
        exports.ox_target:addBoxZone({
            name = 'dropoff_zone'..data.key,
            coords = position,
            size = vec3(0.5, 0.5, 0.5),
            rotation = data.coords.w,
            debug = Config.Debug,
            options = {
                {
                    icon = 'fas fa-box',
                    type = 'client',
                    event = 'fn-courier:client:deliverPackage',
                    args = { key = data.key, coords = data.coords },
                    label = 'Deliver Package',
                    distance = 2.0
                },
            },
        })
    else
        SetVehicleDoorShut(jobData.Vehicle, 2, true)
        SetVehicleDoorShut(jobData.Vehicle, 3, true)
        triggerNotify(nil, "truck-pickup","Task Cancelled", "error")
    end
end)

RegisterNetEvent('fn-courier:client:deliverPackage', function(data)
    if data and data.args then data = data.args end
    playAnim(Config.Anim.Dropoff)
    if lib.progressBar({
        duration = Config.Anim.Dropoff * 1000,
        label = "Delivering package",
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = false
        },
    }) then
        -- Spawn box
        if DoesEntityExist(jobData.Box) then DeleteObject(jobData.Box) end
        loadModel('hei_prop_heist_box')
        jobData.Box = CreateObject(
            'hei_prop_heist_box',
            data.coords.xyz,
        true)
        PlaceObjectOnGroundProperly(jobData.Box)
        FreezeEntityPosition(jobData.Box, true)
        SetEntityHeading(jobData.Box, data.coords.w)
        ClearPedTasks(PlayerPedId())
        DeleteObject(jobData.Package)
        -- Update variables
        jobData.HasBox = false
        jobData.DropoffZones[data.key]:destroy()
        jobData.Drops += 1
        jobData.Dropoff = false
        exports.ox_target:removeZone('dropoff_zone'..data.key)
        --exports.scully_emotemenu:cancelEmote()
        lib.showTextUI("Deliveries: "..jobData.Drops.." / "..jobData.Deliveries)
        RemoveBlip(jobData.Blips[data.key])
        jobData.DropoffZones[data.key]:destroy()
        if jobData.Drops == jobData.Deliveries then
            triggerNotify(nil, "truck-pickup","All dropoffs completed, return to the depot for your paycheck", "success")
        else
            triggerNotify(nil, "truck-pickup","Package dropped off", "success")
        end
        SetTimeout(5000, function()
            lib.hideTextUI()
            DeleteObject(jobData.Box)
        end)
    else
        triggerNotify(nil, "truck-pickup","Task Cancelled", "error")
    end
end)

-- Cancel job event
RegisterNetEvent('fn-courier:client:finish', function()
    for k, _ in pairs(jobData.Blips) do RemoveBlip(jobData.Blips[k]) end -- Remove blips
    if jobData.Pickup then -- Remove pickup zones
        if jobData.PickupZone ~= nil then jobData.PickupZone:destroy() end
        if jobData.Box ~= nil then DeleteObject(jobData.Box) end
        exports.ox_target:removeZone('pickup_package')
    end
    if jobData.Dropoff then -- Remove dropoff zones
        for k, v in pairs(jobData.Dropoffs) do
            exports.ox_target:removeZone('dropoff_zone'..k)
            jobData.DropoffZones[k]:destroy()
        end
    end
    if jobData.Delivery and jobData.Drops == jobData.Deliveries then
        TriggerServerEvent('fn-courier:server:finish', jobData.Pay * jobData.Drops, true)
    elseif jobData.Delivery and jobData.Drops > 0 then
        TriggerServerEvent('fn-courier:server:finish', jobData.Pay * jobData.Drops, false)
    else
        triggerNotify(nil, "truck-pickup","Job cancelled", "error")
    end
    resetData()
    --StartCooldown()
end)

AddEventHandler('onResourceStop', function(r) if r ~= GetCurrentResourceName() then return end
    for k, _ in pairs(jobData.Blips) do RemoveBlip(jobData.Blips[k]) end -- Remove blips
    if jobData.Pickup then -- Remove pickup zones
        if jobData.PickupZone ~= nil then jobData.PickupZone:destroy() end
        if jobData.Package ~= nil then DeleteObject(jobData.Package) end
        if jobData.Pallet ~= nil then DeleteObject(jobData.Pallet) end
        if jobData.Box ~= nil then DeleteObject(jobData.Box) end
        exports.ox_target:removeZone('pickup_package')
    end
    if jobData.Dropoff then -- Remove dropoff zones
        for k, _ in pairs(jobData.Dropoffs) do
            exports.ox_target:removeZone('dropoff_zone'..key)
            jobData.DropoffZones[key]:destroy()
        end
    end
end)
