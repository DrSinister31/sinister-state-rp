local businessData = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end
local function getCid(src)
    local player = getPlayer(src)
    return player and player.PlayerData.citizenid
end
local function getJob(src)
    local player = getPlayer(src)
    return player and player.PlayerData.job
end

local function loadBiz(locId)
    if not businessData[locId] then
        businessData[locId] = {
            balance = 0,
            salesHistory = {},
            supplies = 50,
            employees = {},
            activityLog = {},
            ownerCid = nil,
            npcWashQueue = {},
            totalWashes = 0,
        }
    end
    return businessData[locId]
end

local function logAct(locId, msg)
    local b = loadBiz(locId)
    b.activityLog[#b.activityLog + 1] = { msg = msg, time = os.date("%H:%M:%S") }
    if #b.activityLog > 100 then table.remove(b.activityLog, 1) end
end

local function addSale(locId, tierName, amount)
    local b = loadBiz(locId)
    b.salesHistory[#b.salesHistory + 1] = {
        tier = tierName, amount = amount, time = os.date("%Y-%m-%d %H:%M:%S")
    }
    if #b.salesHistory > 200 then table.remove(b.salesHistory, 1) end
end

local function getEmp(biz, cid)
    for _, e in ipairs(biz.employees) do
        if e.cid == cid then return e end
    end
    return nil
end

local function hasPerm(src, locId, minLevel)
    local cid = getCid(src)
    if not cid then return false end
    local biz = loadBiz(locId)
    if biz.ownerCid == cid then return true end
    local emp = getEmp(biz, cid)
    if emp and (not minLevel or (emp.level or 0) >= minLevel) then return true end
    return false
end

local function consumeSupplies(biz, amount)
    if biz.supplies <= 0 then return false end
    biz.supplies = math.max(0, biz.supplies - amount)
    for _, e in ipairs(biz.employees) do
        if biz.supplies <= 10 then
            e.happiness = math.max(0, (e.happiness or 75) - 5)
        else
            e.happiness = math.min(100, (e.happiness or 75) + 2)
        end
    end
    return true
end

local function getBossPayload(src, locId)
    local cid = getCid(src)
    local biz = loadBiz(locId)
    local empList = {}
    for _, e in ipairs(biz.employees) do
        empList[#empList + 1] = {
            cid = e.cid, name = e.name, level = e.level or 1,
            salary = e.salary or Config.NPCSalary, happiness = e.happiness or 75,
            hired = e.hired or "unknown", isNPC = e.isNPC, gender = e.gender,
        }
    end
    local recentSales = {}
    local count = 0
    for i = #biz.salesHistory, 1, -1 do
        if count >= 20 then break end
        recentSales[#recentSales + 1] = biz.salesHistory[i]
        count = count + 1
    end
    local recentLog = {}
    count = 0
    for i = #biz.activityLog, 1, -1 do
        if count >= 15 then break end
        recentLog[#recentLog + 1] = biz.activityLog[i]
        count = count + 1
    end
    return {
        locationId = locId, balance = biz.balance,
        totalWashes = biz.totalWashes, supplies = biz.supplies,
        employees = empList, salesHistory = recentSales,
        activityLog = recentLog, isOwner = biz.ownerCid == cid,
        maxNPCS = Config.MaxNPCS, supplyPackPrice = Config.SupplyPack.price,
        supplyPackUnits = Config.SupplyPack.units, npcSalary = Config.NPCSalary,
    }
end

RegisterNetEvent("sinister_carwash:requestBossData", function(locId)
    local src = source
    if not hasPerm(src, locId) then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Suds", description = "You don't manage this location.", type = "error"
        })
        return
    end
    TriggerClientEvent("sinister_carwash:receiveBossData", src, getBossPayload(src, locId))
end)

RegisterNetEvent("sinister_carwash:setOwner", function(locId)
    local src = source; local cid = getCid(src)
    if not cid then return end
    local biz = loadBiz(locId)
    if biz.ownerCid then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Suds", description = "This location already has an owner.", type = "error"
        })
        return
    end
    biz.ownerCid = cid
    logAct(locId, "Ownership claimed by " .. GetPlayerName(src))
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Suds", description = "You now own this location!", type = "success"
    })
end)

RegisterNetEvent("sinister_carwash:buySupplies", function(locId)
    local src = source; local biz = loadBiz(locId)
    if not hasPerm(src, locId) then return end
    local cost = Config.SupplyPack.price
    local removed = exports.qbx_core.Functions.RemoveMoney(src, "bank", cost, "carwash-supplies")
    if not removed then
        removed = exports.qbx_core.Functions.RemoveMoney(src, "cash", cost, "carwash-supplies")
    end
    if not removed then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Suds", description = "You can't afford supplies ($" .. cost .. ").", type = "error"
        })
        return
    end
    biz.supplies = biz.supplies + Config.SupplyPack.units
    logAct(locId, "Bought supply pack for $" .. cost)
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Suds", description = "Supplies restocked! +" .. Config.SupplyPack.units .. " units.", type = "success"
    })
    TriggerClientEvent("sinister_carwash:receiveBossData", src, getBossPayload(src, locId))
end)

RegisterNetEvent("sinister_carwash:hireNPC", function(locId, npcName, npcGender)
    local src = source; local biz = loadBiz(locId)
    if not hasPerm(src, locId) then return end
    if #biz.employees >= Config.MaxNPCS then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Suds", description = "Max " .. Config.MaxNPCS .. " employees per location.", type = "error"
        })
        return
    end
    biz.employees[#biz.employees + 1] = {
        cid = "npc_" .. npcName:lower() .. "_" .. math.random(1000, 9999),
        name = npcName, isNPC = true, gender = npcGender,
        level = 1, salary = Config.NPCSalary, happiness = 75,
        hired = os.date("%Y-%m-%d"),
    }
    logAct(locId, "Hired " .. npcName)
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Suds", description = npcName .. " has been hired!", type = "success"
    })
    TriggerClientEvent("sinister_carwash:receiveBossData", src, getBossPayload(src, locId))
end)

RegisterNetEvent("sinister_carwash:fireEmployee", function(locId, empCid)
    local src = source; local biz = loadBiz(locId)
    if not hasPerm(src, locId) then return end
    for i, emp in ipairs(biz.employees) do
        if emp.cid == empCid then
            local name = emp.name
            table.remove(biz.employees, i)
            logAct(locId, "Fired " .. name)
            TriggerClientEvent("ox_lib:notify", src, {
                title = "Texas Suds", description = name .. " has been fired.", type = "inform"
            })
            TriggerClientEvent("sinister_carwash:receiveBossData", src, getBossPayload(src, locId))
            return
        end
    end
end)

RegisterNetEvent("sinister_carwash:withdrawBalance", function(locId, amount)
    local src = source; local biz = loadBiz(locId)
    if not hasPerm(src, locId) then return end
    if amount <= 0 then return end
    if biz.balance < amount then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Texas Suds", description = "Insufficient business balance.", type = "error"
        })
        return
    end
    biz.balance = biz.balance - amount
    exports.qbx_core.Functions.AddMoney(src, "bank", amount)
    logAct(locId, "Withdrew $" .. amount)
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Texas Suds", description = "Withdrew $" .. amount .. " to your bank.", type = "success"
    })
    TriggerClientEvent("sinister_carwash:receiveBossData", src, getBossPayload(src, locId))
end)

RegisterNetEvent("sinister_carwash:payForService", function(locId, tierIndex, amount, isNPC)
    local src = source
    local tier = Config.Tiers[tierIndex]
    if not tier then return end

    local biz = loadBiz(locId)

    if not isNPC then
        local cid = getCid(src)
        if not cid then return end
        local removed = exports.qbx_core.Functions.RemoveMoney(src, "bank", amount, "carwash-service")
        if not removed then
            removed = exports.qbx_core.Functions.RemoveMoney(src, "cash", amount, "carwash-service")
        end
        if not removed then
            return false, TriggerClientEvent("sinister_carwash:paymentFailed", src, tierIndex)
        end
    end

    if not consumeSupplies(biz, tier.supplyCost) then
        if not isNPC then
            TriggerClientEvent("ox_lib:notify", src, {
                title = "Texas Suds", description = "Out of supplies! Owner needs to restock.", type = "error"
            })
        end
        return false, TriggerClientEvent("sinister_carwash:paymentFailed", src, tierIndex)
    end

    biz.balance = biz.balance + amount
    biz.totalWashes = biz.totalWashes + 1
    addSale(locId, tier.name, amount)
    logAct(locId, "Wash: " .. tier.name .. " ($" .. amount .. ")")

    local playerPayment = math.floor(amount * 0.4)

    if not isNPC then
        return tier.percentage, tier.repair, playerPayment,
            TriggerClientEvent("sinister_carwash:serviceConfirmed", src, tierIndex, playerPayment)
    else
        return tier.percentage, tier.repair, playerPayment
    end
end)

RegisterNetEvent("sinister_carwash:playerPayment", function(locId, amount)
    local src = source
    exports.qbx_core.Functions.AddMoney(src, "bank", amount)
    local biz = loadBiz(locId)
    biz.balance = biz.balance - amount
end)

-- NPC auto-work: periodically process wash queue
CreateThread(function()
    while true do
        Citizen.Wait(30000)
        for _, loc in ipairs(Config.Locations) do
            local biz = businessData[loc.id]
            if biz then
                local npcs = {}
                for _, emp in ipairs(biz.employees) do
                    if emp.isNPC then
                        npcs[#npcs + 1] = emp
                    end
                end
                for _, npc in ipairs(npcs) do
                    npc.happiness = math.max(0, (npc.happiness or 75) - 2)
                    if biz.supplies <= 0 then
                        npc.happiness = math.max(0, npc.happiness - 5)
                    end
                    if npc.happiness < 20 and math.random(100) <= 5 then
                        logAct(loc.id, npc.name .. " is unhappy and slacking off!")
                    end
                end
                -- Simulate NPC wash sales
                if biz.supplies > 0 and #npcs > 0 and math.random(100) <= 40 then
                    local avgHappiness = 0
                    for _, npc in ipairs(npcs) do
                        avgHappiness = avgHappiness + npc.happiness
                    end
                    avgHappiness = avgHappiness / #npcs
                    if avgHappiness >= 25 then
                        local tier = Config.Tiers[math.random(1, #Config.Tiers)]
                        if biz.supplies >= tier.supplyCost then
                            biz.supplies = biz.supplies - tier.supplyCost
                            biz.balance = biz.balance + tier.price
                            biz.totalWashes = biz.totalWashes + 1
                            addSale(loc.id, tier.name .. " (NPC)", tier.price)
                            logAct(loc.id, "NPC auto-wash: " .. tier.name .. " ($" .. tier.price .. ")")
                            for _, npc in ipairs(npcs) do
                                npc.happiness = math.min(100, npc.happiness + 1)
                            end
                        end
                    end
                end
                -- Level up NPCs
                if biz.totalWashes % 20 == 0 and biz.totalWashes > 0 then
                    for _, npc in ipairs(npcs) do
                        npc.level = math.min(5, (npc.level or 1) + 1)
                        npc.salary = (npc.salary or Config.NPCSalary) + 10
                    end
                end
                -- Pay NPC salaries
                for _, npc in ipairs(npcs) do
                    biz.balance = biz.balance - (npc.salary or Config.NPCSalary)
                end
            end
        end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        for _, loc in ipairs(Config.Locations) do
            loadBiz(loc.id)
        end
        print("^2[sinister_carwash] ^7Texas Suds Car Wash ready — " .. #Config.Locations ..
              " locations | NPC auto-wash active | Supply system | Cinematic cameras")
    end
end)
