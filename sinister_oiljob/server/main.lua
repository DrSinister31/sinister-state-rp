local playerCycles = {}
local playerGrades = {}
local rigWorkers = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getCid(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid
end

local function getPlayerGrade(cid)
    return playerGrades[cid] or 0
end

local function getPayForGrade(grade)
    return Config.PayPerCycle[grade + 1] or Config.PayPerCycle[1]
end

RegisterNetEvent("sinister_oiljob:clockIn", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if rigWorkers[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Crude Co.", description = "You're already on shift.", type = "error"
        })
        return
    end
    local player = getPlayer(src)
    local name = player and (player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname) or "Worker"
    rigWorkers[cid] = { name = name, src = src, startTime = os.time() }
    if not playerCycles[cid] then playerCycles[cid] = 0 end
    if not playerGrades[cid] then playerGrades[cid] = 0 end
    local grade = Config.Grades[getPlayerGrade(cid) + 1]
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Crude Co.", description = "Clocked in as " .. grade.name .. ". Get to work!", type = "success", duration = 5000
    })
    TriggerClientEvent("sinister_oiljob:clockedIn", src)
    TriggerClientEvent("sinister_oiljob:updateWorkers", -1, rigWorkers)
end)

RegisterNetEvent("sinister_oiljob:clockOut", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if not rigWorkers[cid] then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Crude Co.", description = "You're not clocked in.", type = "error"
        })
        return
    end

    local totalCycles = playerCycles[cid] or 0
    local grade = getPlayerGrade(cid)
    local bonus = totalCycles > 0 and (totalCycles * 50) or 0
    local gradeData = Config.Grades[grade + 1]
    local pay = totalCycles * (getPayForGrade(grade)) + bonus

    exports.qbx_core.Functions.AddMoney(src, "bank", pay)

    rigWorkers[cid] = nil

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Crude Co.",
        description = "Shift over! " .. totalCycles .. " cycles completed. Paid $" .. pay .. " | " .. gradeData.name,
        type = "success",
        duration = 7000,
    })
    TriggerClientEvent("sinister_oiljob:updateWorkers", -1, rigWorkers)
end)

RegisterNetEvent("sinister_oiljob:completeCycle", function(zoneLabel)
    local src = source
    local cid = getCid(src)
    if not cid then return end
    if not rigWorkers[cid] then return end

    playerCycles[cid] = (playerCycles[cid] or 0) + 1
    local grade = getPlayerGrade(cid)
    local pay = getPayForGrade(grade)

    exports.qbx_core.Functions.AddMoney(src, "bank", pay)

    local totalCycles = playerCycles[cid]
    local newGrade = grade
    for i = #Config.Grades, 1, -1 do
        if totalCycles >= Config.Grades[i].cyclesToPromote then
            newGrade = i - 1
            break
        end
    end
    playerGrades[cid] = math.max(playerGrades[cid], newGrade)
    local gradeData = Config.Grades[newGrade + 1]

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Crude Co.",
        description = zoneLabel .. " cycle complete! +$" .. pay .. " | " .. totalCycles .. " total cycles | " .. gradeData.name,
        type = "success",
        duration = 4000,
    })
end)

RegisterNetEvent("sinister_oiljob:requestBossData", function()
    local src = source
    local cid = getCid(src)
    if not cid then return end
    local grade = getPlayerGrade(cid)
    local gradeData = Config.Grades[grade + 1]

    local workerList = {}
    for wcid, data in pairs(rigWorkers) do
        workerList[#workerList + 1] = {
            cid = wcid,
            name = data.name,
            cycles = playerCycles[wcid] or 0,
            grade = Config.Grades[getPlayerGrade(wcid) + 1].name,
        }
    end

    TriggerClientEvent("sinister_oiljob:receiveBossData", src, {
        myGrade = gradeData.name,
        myCycles = playerCycles[cid] or 0,
        myPay = getPayForGrade(grade),
        nextGrade = grade < #Config.Grades and Config.Grades[grade + 2] or nil,
        nextPromoCycles = grade < #Config.Grades and Config.Grades[grade + 2].cyclesToPromote or nil,
        activeWorkers = workerList,
        isManager = grade >= 2,
        companyName = Config.CompanyName,
    })
end)

RegisterNetEvent("sinister_oiljob:requestWorkers", function()
    local src = source
    TriggerClientEvent("sinister_oiljob:updateWorkers", src, rigWorkers)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_oiljob] ^7Texas Crude Co. ready — " .. #Config.FieldZones .. " zones, " .. #Config.Grades .. " grades")
    end
end)

AddEventHandler("QBCore:Server:PlayerUnloaded", function(player)
    local cid = player.PlayerData.citizenid
    if rigWorkers[cid] then
        rigWorkers[cid] = nil
        TriggerClientEvent("sinister_oiljob:updateWorkers", -1, rigWorkers)
    end
end)
