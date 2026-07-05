local inZone = false
local curLoc = nil
local curTier = nil
local washing = false
local washCam = nil
local washVeh = nil
local points = {}

CreateThread(function()
    for _, loc in ipairs(Config.Locations) do
        local p = lib.points.new({ coords = loc.coords, distance = 20.0 })

        function p:onEnter()
            inZone = true; curLoc = loc.id
            if IsPedInAnyVehicle(cache.ped, false) then
                lib.showTextUI("[E] Texas Suds Car Wash\nBasic Rinse | Texas Two-Step | Lone Star Supreme")
            end
        end

        function p:onExit()
            inZone = false; curLoc = nil; lib.hideTextUI()
            if washCam then DestroyCam(washCam, true); washCam = nil; RenderScriptCams(false, true, 1000, true, true) end
        end

        function p:nearby()
            if not inZone or curLoc ~= loc.id then return end
            if IsControlJustPressed(0, 38) then
                local veh = GetVehiclePedIsIn(cache.ped, false)
                if veh == 0 then
                    lib.notify({ title = "Texas Suds", description = "You need to be in a vehicle.", type = "error" })
                    return
                end
                if GetPedInVehicleSeat(veh, -1) ~= cache.ped then
                    lib.notify({ title = "Texas Suds", description = "You must be the driver.", type = "error" })
                    return
                end
                if washing then return end
                local d = GetVehicleDirtLevel(veh)
                if d < 0.05 then
                    lib.notify({ title = "Texas Suds", description = "This vehicle is already spotless!", type = "inform" })
                    return
                end
                OpenTierMenu()
            end
        end
        points[#points + 1] = p

        if loc.blip then
            local b = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(b, 100); SetBlipDisplay(b, 4); SetBlipScale(b, 0.7)
            SetBlipColour(b, 47); SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.BusinessName)
            EndTextCommandSetBlipName(b)
        end
    end
end)

function OpenTierMenu()
    local opts = {}
    for i, t in ipairs(Config.Tiers) do
        local desc = t.repair and (math.floor(t.percentage * 100) .. "% clean + repair") or
                     (math.floor(t.percentage * 100) .. "% clean")
        opts[#opts + 1] = { title = t.name, description = desc .. " — $" .. t.price,
            onSelect = function() StartWash(i) end }
    end
    opts[#opts + 1] = { title = "Texas Suds Management", description = "Boss panel",
        onSelect = function() TriggerServerEvent("sinister_carwash:requestBossData", curLoc) end }
    lib.registerContext({ id = "texas_suds_main", title = Config.BusinessName, options = opts })
    lib.showContext("texas_suds_main")
end

function StartWash(tierIndex)
    local tier = Config.Tiers[tierIndex]
    if not tier then return end
    curTier = tierIndex; washing = true; lib.hideTextUI()
    local veh = GetVehiclePedIsIn(cache.ped, false); washVeh = veh
    lib.progressBar({ duration = 2000, label = "Processing payment...", anim = { dict = "mp_common", clip = "givetake1_a" },
        canCancel = true })
    TriggerServerEvent("sinister_carwash:payForService", curLoc, tierIndex, tier.price, false)
end

RegisterNetEvent("sinister_carwash:paymentFailed", function()
    washing = false; curTier = nil; washVeh = nil
    lib.notify({ title = "Texas Suds", description = "Payment or supplies issue.", type = "error" })
end)

RegisterNetEvent("sinister_carwash:serviceConfirmed", function(tierIndex, playerPay)
    local tier = Config.Tiers[tierIndex]
    if not tier then washing = false; return end
    local veh = washVeh
    if veh == 0 or not DoesEntityExist(veh) then washing = false; return end

    FreezeEntityPosition(veh, true)
    ClearPedTasksImmediately(cache.ped)

    local vCoords = GetEntityCoords(veh).xy
    local z = GetEntityCoords(veh).z

    -- Cinematic camera sequence
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, vCoords.x + 6, vCoords.y - 6, z + 3)
    PointCamAtCoord(cam, vCoords.x, vCoords.y, z + 1.2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1500, true, true)
    washCam = cam
    Citizen.Wait(1500)

    local dirt = GetVehicleDirtLevel(veh)
    local target = dirt * (1.0 - tier.percentage)
    local steps = 25; local stepDelay = 120
    local dec = (dirt - target) / steps

    for zIdx = 1, #Config.PressureWasher.zones do
        local zone = Config.PressureWasher.zones[zIdx]
        -- Orbit camera around vehicle
        local angle = (zIdx - 1) * (360 / #Config.PressureWasher.zones)
        local rad = math.rad(angle)
        local camX = vCoords.x + math.cos(rad) * 6
        local camY = vCoords.y + math.sin(rad) * 6
        SetCamCoord(cam, camX, camY, z + 2.5)
        PointCamAtCoord(cam, vCoords.x + zone.offset.x, vCoords.y + zone.offset.y, z + zone.offset.z)
        Citizen.Wait(800)

        if lib.progressBar({
            duration = Config.PressureWasher.durationPerZone,
            label = "Washing " .. zone.name .. "...",
            canCancel = true,
            disable = { move = true, sprint = true, car = true, combat = true },
        }) then
            for s = 1, steps do
                Citizen.Wait(stepDelay)
                if veh == 0 or not DoesEntityExist(veh) then break end
                SetVehicleDirtLevel(veh, math.max(target, GetVehicleDirtLevel(veh) - dec))
            end
        else
            break
        end
    end

    SetVehicleDirtLevel(veh, target)
    if tier.repair then
        SetVehicleEngineHealth(veh, 1000.0); SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
    end
    FreezeEntityPosition(veh, false)

    -- Fade out camera
    if washCam then
        DestroyCam(washCam, true); washCam = nil
        RenderScriptCams(false, true, 800, true, true)
    end

    if playerPay > 0 then
        TriggerServerEvent("sinister_carwash:playerPayment", curLoc, playerPay)
    end

    washing = false; washVeh = nil; curTier = nil
    lib.notify({ title = "Texas Suds", description = tier.name .. " complete! Paid $" .. playerPay .. ". Come again, partner!", type = "success" })
end)

-- Boss panel
RegisterNetEvent("sinister_carwash:receiveBossData", function(data)
    local mgmt = {}

    mgmt[#mgmt + 1] = { title = "Balance: $" .. data.balance,
        description = "Total washes: " .. data.totalWashes .. " | Supplies: " .. data.supplies .. " units" }

    if data.isOwner then
        local minWithdraw = data.balance > 0 and 1 or data.balance
        if data.balance > 0 then
            mgmt[#mgmt + 1] = { title = "Withdraw Funds",
                description = "Transfer to bank (balance: $" .. data.balance .. ")",
                onSelect = function()
                    local inp = lib.inputDialog("Withdraw", {
                        { type = "number", label = "Amount", default = data.balance, min = 1, max = data.balance }
                    })
                    if inp and inp[1] then
                        TriggerServerEvent("sinister_carwash:withdrawBalance", data.locationId, tonumber(inp[1]))
                    end
                end }
        end
        mgmt[#mgmt + 1] = { title = "Buy Supplies — $" .. data.supplyPackPrice,
            description = "+" .. data.supplyPackUnits .. " units (current: " .. data.supplies .. ")",
            onSelect = function() TriggerServerEvent("sinister_carwash:buySupplies", data.locationId) end }
    end

    -- Sales history
    local salesText = ""
    for _, s in ipairs(data.salesHistory) do
        salesText = salesText .. s.time .. " — " .. s.tier .. " ($" .. s.amount .. ")\n"
    end
    mgmt[#mgmt + 1] = { title = "Sales History (last 20)",
        description = salesText ~= "" and salesText:sub(1, 800) or "No sales yet" }

    -- Employees
    for _, e in ipairs(data.employees) do
        local mood = e.happiness >= 75 and "Happy" or (e.happiness >= 40 and "Content" or "Unhappy")
        mgmt[#mgmt + 1] = {
            title = e.name .. " (Lvl " .. e.level .. ") — " .. mood,
            description = "Happiness: " .. e.happiness .. "% | Salary: $" .. e.salary,
            onSelect = function()
                local fireOps = {{
                    title = "Fire " .. e.name,
                    description = "Remove this employee permanently.",
                    onSelect = function()
                        TriggerServerEvent("sinister_carwash:fireEmployee", data.locationId, e.cid)
                    end,
                }}
                lib.registerContext({ id = "fire_npc_" .. e.cid, title = "Manage " .. e.name, options = fireOps })
                lib.showContext("fire_npc_" .. e.cid)
            end,
        }
    end

    -- Hire
    if data.isOwner and #data.employees < data.maxNPCS then
        for _, name in ipairs(Config.NPCNames.male) do
            mgmt[#mgmt + 1] = { title = "Hire " .. name .. " (Male)",
                description = "$" .. data.npcSalary .. "/cycle",
                onSelect = function() TriggerServerEvent("sinister_carwash:hireNPC", data.locationId, name, "male") end }
        end
        for _, name in ipairs(Config.NPCNames.female) do
            mgmt[#mgmt + 1] = { title = "Hire " .. name .. " (Female)",
                description = "$" .. data.npcSalary .. "/cycle",
                onSelect = function() TriggerServerEvent("sinister_carwash:hireNPC", data.locationId, name, "female") end }
        end
    end

    if not data.isOwner then
        mgmt[#mgmt + 1] = { title = "Claim Ownership",
            description = "Become the owner of this Texas Suds location",
            onSelect = function() TriggerServerEvent("sinister_carwash:setOwner", data.locationId) end }
    end

    -- Activity log
    local logText = ""
    for _, e in ipairs(data.activityLog) do
        logText = logText .. e.time .. " " .. e.msg .. "\n"
    end
    mgmt[#mgmt + 1] = { title = "Activity Log",
        description = logText ~= "" and logText:sub(1, 600) or "No activity" }

    lib.registerContext({ id = "texas_suds_boss", title = Config.BossMenuTitle, options = mgmt })
    lib.showContext("texas_suds_boss")
end)

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        print("^2[sinister_carwash] ^7Texas Suds Car Wash client ready")
    end
end)
