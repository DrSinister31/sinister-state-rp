math.randomseed(os.time())
local QBCore = exports['qb-core']:GetCoreObject()
local jobList, cooldownList, depositList = {}, {}, {}

-- functions

CreateThread(function()
    while true do
        Wait(60000)
        for k, v in pairs(cooldownList) do
            if v.timer > 0 then
                v.timer -= 1
            else
                table.remove(cooldownList, k)
                TriggerEvent('fn-courier:server:addList')
            end
        end
    end
end)

function NearDrop(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, job in pairs(Config.Jobs) do
        for _, dropoff in ipairs(job.dropoffs) do
            local dist = #(coords - vector3(dropoff.x, dropoff.y, dropoff.z))
            if dist < 20 then
                return true
            end
        end
    end
end

-- events

RegisterNetEvent('fn-courier:server:generateList', function()
    -- Normal jobs
    math.randomseed(os.time())
    for key = 1, Config.Length do
        local jobCategory = math.random(1, #Config.Jobs)
        local randomPickup = math.random(1, #Config.Jobs[jobCategory].pickups)
        local numDrops = math.random(Config.Job.Drops.min, Config.Job.Drops.max)
        local shuffledDrops = Config.Jobs[jobCategory].dropoffs
        for i = #shuffledDrops, 2, -1 do
            local j = math.random(1, i)
            shuffledDrops[i], shuffledDrops[j] = shuffledDrops[j], shuffledDrops[i]
        end
        local dropList = {}
        for loc = 1, math.min(numDrops, #shuffledDrops) do
            dropList[loc] = shuffledDrops[loc]
        end
        local job = {
            id = os.time() + key,
            title = Config.Jobs[jobCategory].title,
            pickup = Config.Jobs[jobCategory].pickups[randomPickup],
            dropoffs = dropList,
            livery = Config.Jobs[jobCategory].livery,
            pay = math.random(Config.Job.Pay.min, Config.Job.Pay.max)
        }
        jobList[key] = job
    end
end)

-- Generate list
TriggerEvent("fn-courier:server:generateList")

-- Server event to add a job to the jobList
RegisterNetEvent('fn-courier:server:addList', function()
    local jobCategory = math.random(1, #Config.Jobs)
    local numDrops = math.random(Config.Job.Drops.min, Config.Job.Drops.max)
    local pickup = math.random(1, #Config.Jobs[jobCategory].pickups)
    local shuffledDrops = Config.Jobs[jobCategory].dropoffs
    for i = #shuffledDrops, 2, -1 do
        local j = math.random(1, i)
        shuffledDrops[i], shuffledDrops[j] = shuffledDrops[j], shuffledDrops[i]
    end
    local dropList = {}
    for loc = 1, math.min(numDrops, #shuffledDrops) do
        dropList[loc] = shuffledDrops[loc]
    end
    local job = {
        id = os.time() + #jobList+1,
        title = Config.Jobs[jobCategory].title,
        pickup = Config.Jobs[jobCategory].pickups[pickup],
        dropoffs = dropList,
        pay = math.random(Config.Job.Pay.min, Config.Job.Pay.max)
    }
    table.insert(jobList, job)
end)

-- Rental events

-- Rental deposit event
RegisterNetEvent('fn-courier:server:payDeposit', function(bool, amount, model, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if bool then 
        if Player.Functions.RemoveMoney('bank', amount, "insurance-deposit-paid") then
            triggerNotify(nil, 'dollar-sign', 'You have paid a $'..amount..' insurance deposit.', 'success', src)
            depositList[Player.PlayerData.citizenid] = { amount = amount}
            TriggerClientEvent('fn-courier:client:retrieveVehicle', src, model, coords)
        else
            triggerNotify(nil, 'exclamation', 'Insufficient funds to pay the deposit.', 'error', src)
        end
    else
        local deposit = depositList[Player.PlayerData.citizenid]
        if deposit then
            Player.Functions.AddMoney('bank', deposit.amount, "insurance-deposit-refund")
            triggerNotify(nil, 'dollar-sign', 'You have been refunded $'..deposit.amount..' from your insurance deposit.', 'success', src)
            depositList[Player.PlayerData.citizenid] = nil
        end
    end
end)

QBCore.Functions.CreateCallback('fn-courier:list', function(source, cb)
    cb(jobList)
end)

QBCore.Functions.CreateCallback('fn-courier:checklist', function(source, cb, id)
    local result = false
    for _, v in pairs(jobList) do
        if v.id == id then
            result = true
        end
    end
    cb(result)
end)

-- Server event to remove a job from the jobList
RegisterNetEvent('fn-courier:server:removeList', function(key)
    table.remove(jobList, key)
    if Config.Job.Cooldown.enabled then
        local job = { timer = math.random(Config.Job.Cooldown.min, Config.Job.Cooldown.min)}
        table.insert(cooldownList, job)
    else
        TriggerEvent('fn-courier:server:addList')
    end
end)

RegisterNetEvent('fn-courier:server:finish', function(payAmount, bonus)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local bonusAmount = 0
    if Config.Job.Damage.enabled and Config.Job.Bonus.enabled then
        if bonus then
            bonusAmount = math.floor(payAmount * Config.Job.Bonus.percentage / 100)
            payAmount = payAmount + bonusAmount
            Player.Functions.AddMoney('cash', payAmount, 'courier-Salary')
            triggerNotify(nil, 'dollar-sign', string.format("You have received $%d + $%d for not damaging any packages", payAmount - bonusAmount, bonusAmount), 'success', src)
        else
            Player.Functions.AddMoney('cash', payAmount, 'courier-Salary')
            triggerNotify(nil, 'dollar-sign', string.format("You have received $%d, you forfeit your bonus", payAmount), 'success', src)
        end
    else
        Player.Functions.AddMoney('cash', payAmount, 'courier-Salary')
        triggerNotify(nil, 'dollar-sign', string.format("You have been paid $%d", payAmount), 'success', src)
    end
end)