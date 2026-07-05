local choppingActive = false
local currentTree = nil
local crewMembers = {}
local myCrewLeader = nil
local carriedLogs = 0
local maxCarriedLogs = 2
local playerXP = 0
local playerLevel = 0
local playerUpgrades = {}
local truckEntity = nil
local logsInTruck = 0
local maxTruckLogs = 12
local woodProp = "prop_log_01"
local blips = {}
local hudVisible = false

local function setupBlips()
    local b = AddBlipForCoord(Config.SawmillLocation.x, Config.SawmillLocation.y, Config.SawmillLocation.z)
    SetBlipSprite(b, 477); SetBlipDisplay(b, 4); SetBlipScale(b, 0.9); SetBlipColour(b, 1)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.CompanyName .. " — Sawmill")
    EndTextCommandSetBlipName(b)

    local fb = AddBlipForCoord(Config.ForestLocation.x, Config.ForestLocation.y, Config.ForestLocation.z)
    SetBlipSprite(fb, 71); SetBlipDisplay(fb, 4); SetBlipScale(fb, 0.7); SetBlipColour(fb, 2)
    SetBlipAsShortRange(fb, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.ForestLabel)
    EndTextCommandSetBlipName(fb)
end

-- Forest point
local forestPt = lib.points.new({ coords = Config.ForestLocation, distance = 50.0 })
function forestPt:onEnter()
    if not choppingActive then
        lib.showTextUI("[E] Piney Woods Logging Co.\nChop trees | Load truck | Crew up")
    end
end
function forestPt:onExit()
    if not choppingActive then lib.hideTextUI() end
end
function forestPt:nearby()
    if choppingActive then return end
    if IsControlJustPressed(0, 38) then
        OpenForestMenu()
    end
end

-- Sawmill point
local millPt = lib.points.new({ coords = Config.SawmillLocation, distance = 25.0 })
function millPt:onEnter()
    if logsInTruck > 0 and IsPedInAnyVehicle(cache.ped, false) then
        lib.showTextUI("[E] Unload " .. logsInTruck .. " logs at Sawmill\nPayment: $" .. (logsInTruck * calcLogPay()))
    elseif logsInTruck > 0 then
        lib.showTextUI("[E] Drive your truck here to unload logs")
    end
end
function millPt:onExit()
    lib.hideTextUI()
end
function millPt:nearby()
    if logsInTruck > 0 and IsPedInAnyVehicle(cache.ped, false) then
        if IsControlJustPressed(0, 38) then
            UnloadLogs()
        end
    end
end

function calcLogPay()
    local yld = playerUpgrades.yield or 0
    return math.floor(Config.Trees[1].basePay * (1.0 + yld * 0.15))
end

function OpenForestMenu()
    local opts = {}

    opts[#opts + 1] = { title = "Request Logging Truck", description = "Spawn at forest entrance",
        onSelect = function() SpawnTruck() end }

    if logsInTruck > 0 then
        opts[#opts + 1] = { title = "Load Logs into Truck",
            description = logsInTruck .. "/" .. maxTruckLogs .. " loaded",
            onSelect = function()
                if carriedLogs > 0 then
                    logsInTruck = math.min(maxTruckLogs, logsInTruck + carriedLogs)
                    carriedLogs = 0
                    maxCarriedLogs = 2 + ((playerUpgrades.load or 0) * 1)
                    UpdateHUD()
                    lib.notify({ title = "Piney Woods", description = "Logs loaded. Drive to the Killeen mill!", type = "success" })
                else
                    lib.notify({ title = "Piney Woods", description = "You have no logs on hand. Chop some trees first!", type = "error" })
                end
            end,
        }
    end

    opts[#opts + 1] = {
        title = "Stats & Upgrades",
        description = "XP: " .. playerXP .. " | Level: " .. playerLevel,
        onSelect = function() OpenUpgradeMenu() end,
    }

    opts[#opts + 1] = {
        title = "Start Crew (Leader)",
        description = "Others can join you. Team gets XP bonus.",
        onSelect = function()
            myCrewLeader = cache.playerId
            crewMembers = {}
            TriggerServerEvent("sinister_lumberjack:joinCrew", myCrewLeader)
            lib.notify({ title = "Piney Woods", description = "Crew session started! Others can join now.", type = "success" })
        end,
    }
    opts[#opts + 1] = {
        title = "Disband Crew",
        description = "End the logging crew",
        onSelect = function()
            myCrewLeader = nil
            crewMembers = {}
            lib.notify({ title = "Piney Woods", description = "Crew disbanded.", type = "inform" })
        end,
    }

    for _, tree in ipairs(Config.Trees) do
        opts[#opts + 1] = {
            title = "Chop " .. tree.label .. " Tree",
            description = string.format("Pos: %.0f, %.0f | HP: %d | Pay: ~$%d/log",
                tree.pos.x, tree.pos.y, tree.health, calcLogPay()),
            onSelect = function()
                lib.hideContext()
                StartChopMinigame(tree)
            end,
        }
    end

    lib.registerContext({ id = "piney_woods_menu", title = Config.CompanyName, options = opts })
    lib.showContext("piney_woods_menu")
end

function OpenUpgradeMenu()
    local opts = {}
    for key, u in pairs(Config.Upgrades) do
        local cur = playerUpgrades[key] or 0
        local cost = cur < #u.costs and u.costs[cur + 1] or "MAX"
        opts[#opts + 1] = {
            title = u.name .. " — Lvl " .. cur .. "/" .. u.maxLevel,
            description = u.desc .. (type(cost) == "number" and " | Cost: $" .. cost or " | MAX LEVEL"),
            onSelect = function()
                if type(cost) == "number" then
                    TriggerServerEvent("sinister_lumberjack:upgrade", key)
                end
            end,
        }
    end
    opts[#opts + 1] = {
        title = "Your Stats",
        description = "XP: " .. playerXP .. " | Level: " .. playerLevel ..
                      " | Logs chopped: " .. (playerXP // 10) .. " | Banked: $" .. (playerXP * 2),
    }
    lib.registerContext({ id = "piney_upgrades", title = "Piney Woods — Upgrades", options = opts })
    lib.showContext("piney_upgrades")
end

function StartChopMinigame(tree)
    currentTree = tree
    choppingActive = true
    lib.hideTextUI()
    hudVisible = true
    UpdateHUD()

    -- Force first person
    local wasFirstPerson = GetFollowPedCamViewMode() == 4
    if not wasFirstPerson then
        SetFollowPedCamViewMode(4)
    end

    -- Give axe anim
    lib.requestAnimDict("melee@hatchet@streamed_core", 3000)
    TaskPlayAnim(cache.ped, "melee@hatchet@streamed_core", "plyr_rear_takedown_b", 8.0, -8.0, -1, 48, 0, false, false, false)

    -- Run minigame via NUI
    SendNUIMessage({ action = "startMinigame", tree = tree.id,
        speedUpgrade = playerUpgrades.speed or 0,
        aimUpgrade = playerUpgrades.aim or 0,
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback("minigameHit", function(data, cb)
    cb("ok")
    if not currentTree or not choppingActive then return end
    -- Camera shake
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", Config.Minigame.shakeIntensity)

    local speedBonus = playerUpgrades.speed or 0
    local dmg = Config.Minigame.axeDamage + speedBonus * 5
    currentTree.health = currentTree.health - dmg

    -- Particle on tree
    local coords = currentTree.pos
    UseParticleFxAssetNextCall("core")
    StartParticleFxNonLoopedAtCoord("exp_rock_plane", coords.x, coords.y, coords.z, 0, 0, 0, 0.3, false, false, false)

    if currentTree.health <= 0 then
        -- Tree falls
        SendNUIMessage({ action = "treeFelled", tree = currentTree.id })

        -- Fall direction
        local dir = currentTree.fallDir
        local fallPos = vec3(coords.x + dir.x * 3, coords.y + dir.y * 3, coords.z - 2)
        -- Big shake
        Citizen.Wait(200)
        ShakeGameplayCam("LARGE_EXPLOSION_SHAKE", 1.0)

        -- Logs earned
        local loadUpgrade = playerUpgrades.load or 0
        local logs = 1 + loadUpgrade
        logs = math.min(logs, 3)
        carriedLogs = math.min(maxCarriedLogs, carriedLogs + logs)

        TriggerServerEvent("sinister_lumberjack:chopComplete", currentTree.id, logs)

        -- Restore camera
        SetFollowPedCamViewMode(0)
        SetNuiFocus(false, false)
        choppingActive = false
        currentTree = nil
        hudVisible = false
        UpdateHUD()
        SendNUIMessage({ action = "stopMinigame" })

        lib.notify({ title = "Piney Woods", description = "Tree felled! +" .. logs .. " logs on hand. Load them into the truck.", type = "success" })

        -- Share XP with crew
        if myCrewLeader and myCrewLeader == cache.playerId and #crewMembers > 0 then
            TriggerServerEvent("sinister_lumberjack:shareXPSync", myCrewLeader, Config.Experience.perTree)
        end
    else
        TriggerServerEvent("sinister_lumberjack:shareXPSync",
            (myCrewLeader or cache.playerId), Config.Experience.perTree // 2)
    end
end)

RegisterNUICallback("minigameMiss", function(data, cb)
    cb("ok")
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.2)
end)

RegisterNUICallback("minigameCancel", function(data, cb)
    cb("ok")
    SetNuiFocus(false, false)
    choppingActive = false
    currentTree = nil
    hudVisible = false
    SendNUIMessage({ action = "stopMinigame" })
    SetFollowPedCamViewMode(0)
    lib.notify({ title = "Piney Woods", description = "Chopping cancelled.", type = "inform" })
end)

function SpawnTruck()
    local model = GetHashKey(Config.VehicleModel)
    lib.requestModel(model, 5000)
    local veh = CreateVehicle(model, Config.TruckSpawnCoords.x, Config.TruckSpawnCoords.y, Config.TruckSpawnCoords.z, 90.0, true, false)
    SetVehicleEngineOn(veh, true, true, false)
    SetPedIntoVehicle(cache.ped, veh, -1)
    truckEntity = veh
    logsInTruck = 0
    maxTruckLogs = 12 + ((playerUpgrades.load or 0) * 4)
    lib.notify({ title = "Piney Woods", description = "Truck ready! Chop trees to get logs.", type = "success" })
end

function UnloadLogs()
    if logsInTruck <= 0 then return end
    lib.hideTextUI()
    lib.progressBar({
        duration = logsInTruck * 800,
        label = "Unloading " .. logsInTruck .. " logs at the sawmill conveyor...",
        canCancel = true,
        anim = { dict = "anim@heists@box_carry@", clip = "idle", flag = 49 },
    })
    TriggerServerEvent("sinister_lumberjack:deliverLogs", logsInTruck)
    logsInTruck = 0
end

RegisterNetEvent("sinister_lumberjack:deliveryComplete", function(pay, xp, levelName)
    lib.notify({ title = "Piney Woods", description = "Mill processed! $" .. pay .. " paid | " .. levelName, type = "success" })
end)

RegisterNetEvent("sinister_lumberjack:receiveData", function(data)
    playerXP = data.xp
    playerLevel = data.level
    playerUpgrades = data.upgrades
    UpdateHUD()
end)

RegisterNetEvent("sinister_lumberjack:updateXP", function(xp)
    playerXP = xp
    UpdateHUD()
end)

RegisterNetEvent("sinister_lumberjack:crewUpdated", function(leader, members)
    if leader == cache.playerId then
        crewMembers = members
        local msg = "Crew: You + " .. #members .. " members (XP bonus active)"
        lib.notify({ title = "Piney Woods", description = msg, type = "inform" })
    end
end)

function UpdateHUD()
    SendNUIMessage({
        action = "updateHUD",
        visible = hudVisible,
        logsInTruck = logsInTruck,
        maxTruckLogs = maxTruckLogs,
        carriedLogs = carriedLogs,
        maxCarried = maxCarriedLogs,
        xp = playerXP,
        level = playerLevel,
        chopping = choppingActive,
        crewSize = myCrewLeader and (#crewMembers + 1) or 1,
    })
end

CreateThread(function()
    setupBlips()
    TriggerServerEvent("sinister_lumberjack:requestData")
    Wait(2000)
    UpdateHUD()
end)

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        TriggerServerEvent("sinister_lumberjack:requestData")
        print("^2[sinister_lumberjack] ^7Piney Woods Logging client ready")
    end
end)
