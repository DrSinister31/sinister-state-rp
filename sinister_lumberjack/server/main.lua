local playerData = {}
local activeCrews = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end
local function getCid(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid
end

local function getOrCreateData(cid)
    if not playerData[cid] then
        playerData[cid] = {
            xp = 0, level = 0,
            upgrades = { speed = 0, aim = 0, yield = 0, load = 0 },
            totalLogs = 0, totalTrees = 0, totalDeliveries = 0, banked = 0,
        }
    end
    return playerData[cid]
end

local function getLevel(exp)
    local lvl = 0
    for i, l in ipairs(Config.Experience.levels) do
        if exp >= l.min then lvl = i - 1 end
    end
    return lvl
end

local function calcPay(basePay, upgradeLevel)
    return math.floor(basePay * (1.0 + upgradeLevel * 0.15))
end

RegisterNetEvent("sinister_lumberjack:requestData", function()
    local src = source; local cid = getCid(src)
    if not cid then return end
    local d = getOrCreateData(cid)
    local lvl = getLevel(d.xp)
    local lvlData = Config.Experience.levels[lvl + 1]
    d.level = lvl
    TriggerClientEvent("sinister_lumberjack:receiveData", src, {
        xp = d.xp, level = lvl, levelName = lvlData.name,
        upgrades = d.upgrades, totalLogs = d.totalLogs,
        totalTrees = d.totalTrees, totalDeliveries = d.totalDeliveries,
        banked = d.banked, nextLevel = lvl < #Config.Experience.levels and Config.Experience.levels[lvl + 2] or nil,
    })
end)

RegisterNetEvent("sinister_lumberjack:upgrade", function(upgradeType)
    local src = source; local cid = getCid(src)
    if not cid then return end
    local d = getOrCreateData(cid)
    if not Config.Upgrades[upgradeType] then return end
    local u = Config.Upgrades[upgradeType]
    local cur = d.upgrades[upgradeType] or 0
    if cur >= u.maxLevel then
        TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = u.name .. " is max level!", type = "error" })
        return
    end
    local cost = u.costs[cur + 1]
    if not cost then return end
    local lvl = getLevel(d.xp)
    local lvlData = Config.Experience.levels[lvl + 1]
    if cur >= lvlData.unlockUpgrades then
        TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "You need a higher logging level to unlock more " .. u.name .. " upgrades.", type = "error" })
        return
    end

    local removed = exports.qbx_core.Functions.RemoveMoney(src, "bank", cost, "lumberjack-upgrade")
    if not removed then
        TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "You need $" .. cost .. " in your bank.", type = "error" })
        return
    end
    d.upgrades[upgradeType] = cur + 1
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Piney Woods — " .. u.name,
        description = "Upgraded to level " .. (cur + 1) .. "!",
        type = "success",
    })
    TriggerEvent("sinister_lumberjack:requestData")
end)

RegisterNetEvent("sinister_lumberjack:chopComplete", function(treeId, logsEarned)
    local src = source; local cid = getCid(src)
    if not cid then return end
    local d = getOrCreateData(cid)
    d.xp = d.xp + Config.Experience.perTree
    d.totalTrees = (d.totalTrees or 0) + 1
    TriggerClientEvent("sinister_lumberjack:updateXP", src, d.xp)
end)

RegisterNetEvent("sinister_lumberjack:deliverLogs", function(logCount)
    local src = source; local cid = getCid(src)
    if not cid then return end
    local d = getOrCreateData(cid)
    local upgradeLevel = d.upgrades.yield or 0
    local basePay = Config.Trees[1].basePay
    local payPerLog = calcPay(basePay, upgradeLevel)
    local totalPay = payPerLog * logCount

    exports.qbx_core.Functions.AddMoney(src, "bank", totalPay)

    local xpGain = Config.Experience.perLog * logCount + Config.Experience.perDelivery
    d.xp = d.xp + xpGain
    d.totalLogs = (d.totalLogs or 0) + logCount
    d.totalDeliveries = (d.totalDeliveries or 0) + 1
    d.banked = (d.banked or 0) + totalPay
    local newLvl = getLevel(d.xp)
    d.level = newLvl
    local lvlData = Config.Experience.levels[newLvl + 1]

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Piney Woods Logging",
        description = "Delivered " .. logCount .. " logs! Paid $" .. totalPay .. " | +" .. xpGain .. " XP | " .. lvlData.name,
        type = "success", duration = 7000,
    })
    TriggerClientEvent("sinister_lumberjack:updateXP", src, d.xp)
    TriggerClientEvent("sinister_lumberjack:deliveryComplete", src, totalPay, xpGain, lvlData.name)
end)

RegisterNetEvent("sinister_lumberjack:joinCrew", function(leaderId)
    local src = source; local cid = getCid(src)
    if not cid then return end
    local leaderSrc = nil
    for _, p in ipairs(GetPlayers()) do
        if tonumber(p) == leaderId then leaderSrc = tonumber(p); break end
    end
    if not leaderSrc then
        TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "Crew leader not found.", type = "error" })
        return
    end
    if not activeCrews[leaderSrc] then activeCrews[leaderSrc] = {} end
    if #activeCrews[leaderSrc] >= 3 then
        TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "Crew is full (max 3 members).", type = "error" })
        return
    end
    for _, mid in ipairs(activeCrews[leaderSrc]) do
        if mid == src then
            TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "You are already in this crew.", type = "error" })
            return
        end
    end
    activeCrews[leaderSrc][#activeCrews[leaderSrc] + 1] = src
    TriggerClientEvent("sinister_lumberjack:crewUpdated", leaderSrc, activeCrews[leaderSrc])
    TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "Joined the logging crew! Team XP bonus active.", type = "success" })
end)

RegisterNetEvent("sinister_lumberjack:leaveCrew", function(leaderId)
    local src = source
    if not activeCrews[leaderId] then return end
    for i, mid in ipairs(activeCrews[leaderId]) do
        if mid == src then
            table.remove(activeCrews[leaderId], i)
            if #activeCrews[leaderId] == 0 then activeCrews[leaderId] = nil end
            TriggerClientEvent("sinister_lumberjack:crewUpdated", leaderId, activeCrews[leaderId] or {})
            TriggerClientEvent("ox_lib:notify", src, { title = "Piney Woods", description = "Left the crew.", type = "inform" })
            return
        end
    end
end)

RegisterNetEvent("sinister_lumberjack:shareXPSync", function(leaderId, xpAmount)
    local src = source
    if not activeCrews[leaderId] then return end
    for _, mid in ipairs(activeCrews[leaderId]) do
        if mid ~= src then
            local memberCid = getCid(mid)
            if memberCid then
                local d = getOrCreateData(memberCid)
                local bonus = math.floor(xpAmount * Config.Experience.teamMultiplier)
                d.xp = d.xp + bonus
                TriggerClientEvent("sinister_lumberjack:updateXP", mid, d.xp)
                TriggerClientEvent("ox_lib:notify", mid, {
                    title = "Piney Woods — Team Bonus",
                    description = "+" .. bonus .. " XP from crew activity!",
                    type = "inform",
                })
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    for leader, crew in pairs(activeCrews) do
        for i, mid in ipairs(crew) do
            if mid == src then table.remove(crew, i); break end
        end
        if #crew == 0 then activeCrews[leader] = nil
        else TriggerClientEvent("sinister_lumberjack:crewUpdated", leader, crew) end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        print("^2[sinister_lumberjack] ^7Piney Woods Logging Co. ready — " ..
              #Config.Trees .. " trees | multi-crew | axe upgrades | XP system")
    end
end)
