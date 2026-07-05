local clockedIn = false
local currentZone = nil
local workingCycle = false
local rigWorkers = {}
local activeZones = {}

CreateThread(function()
    local blip = AddBlipForCoord(Config.RigLocation.x, Config.RigLocation.y, Config.RigLocation.z)
    SetBlipSprite(blip, 89)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.CompanyName)
    EndTextCommandSetBlipName(blip)

    for _, zone in ipairs(Config.FieldZones) do
        local point = lib.points.new({
            coords = zone.coords,
            distance = 25.0,
        })
        function point:onEnter()
            currentZone = zone
            if clockedIn then
                lib.showTextUI("[E] Work: " .. zone.label .. "\nAction: " .. zone.action)
            end
        end
        function point:onExit()
            currentZone = nil
            lib.hideTextUI()
        end
        function point:nearby()
            if not clockedIn or not currentZone or currentZone ~= zone then return end
            if workingCycle then return end
            if IsControlJustPressed(0, 38) then
                StartWorkCycle(zone)
            end
        end
        activeZones[#activeZones + 1] = point

        local b = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(b, 89)
        SetBlipDisplay(b, 4)
        SetBlipScale(b, 0.5)
        SetBlipColour(b, 47)
        SetBlipAsShortRange(b, true)
    end
end)

local rigPoint = lib.points.new({
    coords = Config.RigLocation,
    distance = 40.0,
})

function rigPoint:onEnter()
    if not clockedIn then
        lib.showTextUI("[E] Texas Crude Co.\nClock In for shift")
    else
        lib.showTextUI("[H] Clock Out | [E] Boss Panel\n" .. Config.CompanyName)
    end
end

function rigPoint:onExit()
    lib.hideTextUI()
end

function rigPoint:nearby()
    if IsControlJustPressed(0, 38) then
        if not clockedIn then
            TriggerServerEvent("sinister_oiljob:clockIn")
        else
            TriggerServerEvent("sinister_oiljob:requestBossData")
        end
    elseif IsControlJustPressed(0, 74) and clockedIn then
        TriggerServerEvent("sinister_oiljob:clockOut")
        clockedIn = false
    end
end

function StartWorkCycle(zone)
    workingCycle = true
    lib.hideTextUI()

    local animDict = zone.action == "refine" and Config.WrenchAnim.dict or Config.WorkerAnim.dict
    local animClip = zone.action == "refine" and Config.WrenchAnim.clip or Config.WorkerAnim.clip

    lib.requestAnimDict(animDict, 5000)

    if lib.progressBar({
        duration = Config.CycleDuration,
        label = "Working: " .. zone.label,
        useWhileDead = false,
        canCancel = true,
        anim = { dict = animDict, clip = animClip, flag = 1 },
        prop = zone.action == "wrench" and { model = Config.Equipment.wrench, pos = vec3(0.15, 0.0, 0.0), rot = vec3(0.0, 90.0, 0.0) } or nil,
    }) then
        TriggerServerEvent("sinister_oiljob:completeCycle", zone.label)
    else
        lib.notify({ title = "Texas Crude Co.", description = "Work interrupted.", type = "inform" })
    end
    StopAnimTask(cache.ped, animDict, animClip, 1.0)
    workingCycle = false
end

RegisterNetEvent("sinister_oiljob:clockedIn", function()
    clockedIn = true
    lib.notify({ title = "Texas Crude Co.", description = "Head to the field zones to start working.", type = "success", duration = 5000 })
end)

RegisterNetEvent("sinister_oiljob:updateWorkers", function(workers)
    rigWorkers = workers or {}
end)

RegisterNetEvent("sinister_oiljob:receiveBossData", function(data)
    local workerText = ""
    for _, w in ipairs(data.activeWorkers) do
        workerText = workerText .. w.name .. " — " .. w.grade .. " (" .. w.cycles .. " cycles)\n"
    end

    local options = {
        { title = "Your Stats", description = data.myGrade .. " | " .. data.myCycles .. " cycles | $" .. data.myPay .. "/cycle" },
    }

    if data.nextGrade then
        options[#options + 1] = {
            title = "Next Promotion: " .. data.nextGrade.name,
            description = "Need " .. data.nextPromoCycles .. " total cycles (currently " .. data.myCycles .. ")",
        }
    end

    options[#options + 1] = {
        title = "Active Workers (" .. #data.activeWorkers .. ")",
        description = workerText ~= "" and workerText:sub(1, 400) or "No other workers on shift",
    }

    if data.isManager then
        options[#options + 1] = {
            title = data.companyName .. " Manager",
            description = "You have field supervisor access",
        }
    end

    options[#options + 1] = {
        title = "Pay Rate: $" .. data.myPay .. "/cycle",
        description = "Payment goes directly to your bank account",
    }

    lib.registerContext({
        id = "texas_crude_boss",
        title = Config.BossMenuTitle,
        menu = "texas_crude_boss",
        options = options,
    })
    lib.showContext("texas_crude_boss")
end)

CreateThread(function()
    local playerCount = 0
    while true do
        Citizen.Wait(60000)
        local currentCount = 0
        for _ in pairs(rigWorkers) do
            currentCount = currentCount + 1
        end
        if currentCount ~= playerCount then
            playerCount = currentCount
            if playerCount >= 2 then
                lib.notify({ title = "Texas Crude Co.", description = "Multiplayer bonus active: " .. playerCount .. " workers on the field!", type = "inform" })
            end
        end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_oiljob] ^7Texas Crude Co. client ready")
    end
end)
