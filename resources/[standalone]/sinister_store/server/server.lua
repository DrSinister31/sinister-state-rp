local db = require 'server.database'
local packageHandler = require 'server.package_handler'

local purchaseQueue = {}
local isProcessing = false

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        db.ensureTables()
        print("^2[sinister_store] ^7Resource started. Database tables ensured.")
    end
end)

local function findPackageByName(name)
    for _, pkg in ipairs(Config.Packages) do
        if pkg.name == name then
            return pkg
        end
    end
    return nil
end

local function verifyTebexTransaction(transactionId)
    if not Config.TebexSecret or Config.TebexSecret == "" then
        return true, { transaction_id = transactionId, username = "Player", package_name = "Unknown" }
    end
    local endpoint = Config.TebexStoreUrl .. "/payments/" .. transactionId
    local success, response = pcall(function()
        return PerformHttpRequest(endpoint, function(errCode, data, headers)
            return { code = errCode, data = data, headers = headers }
        end, 'GET', '', { ["X-Tebex-Secret"] = Config.TebexSecret })
    end)
    if not success then
        print("[sinister_store] Tebex API unreachable, accepting transaction anyway: " .. transactionId)
        return true, { transaction_id = transactionId, username = "Player", package_name = "Unknown" }
    end
    if response and response.code == 200 and response.data then
        local decoded = json.decode(response.data)
        if decoded and decoded.id then
            return true, decoded
        end
    end
    print("[sinister_store] Tebex verification failed for transaction: " .. transactionId)
    return false, nil
end

local function processPurchase(transactionId, playerIdentifier, playerName, packageName, rewardType, rewardData)
    local playerId = nil
    local players = GetPlayers()
    for _, id in ipairs(players) do
        local player = exports['qbx_core']:GetPlayer(tonumber(id))
        if player and player.PlayerData.citizenid == playerIdentifier then
            playerId = tonumber(id)
            break
        end
    end
    local success, err = false, "Player not online"
    if playerId then
        local parsedReward = rewardData
        if type(parsedReward) == "string" then
            parsedReward = json.decode(parsedReward)
        end
        local pkg = findPackageByName(packageName)
        if pkg and pkg.reward then
            success, err = packageHandler.dispatchReward(playerId, pkg.reward)
        elseif parsedReward and parsedReward.type then
            success, err = packageHandler.dispatchReward(playerId, parsedReward)
        else
            err = "No reward data found for package: " .. packageName
        end
    end
    if success then
        db.markRedeemed(transactionId)
        db.logAction(transactionId, playerIdentifier, packageName, "redeemed", "success")
        if playerId then
            local pkg = findPackageByName(packageName)
            local msg = string.format(Config.Notifications.purchaseRedeemed, packageName)
            TriggerClientEvent('ox_lib:notify', playerId, { title = Config.StoreName, description = msg, type = 'success' })
        end
        print(string.format("[sinister_store] Redeemed: %s for %s", packageName, playerIdentifier))
    else
        db.markFailed(transactionId, err)
        db.logAction(transactionId, playerIdentifier, packageName, "failed", "failure", tostring(err))
        if playerId then
            local msg = string.format(Config.Notifications.purchaseFailed, packageName)
            TriggerClientEvent('ox_lib:notify', playerId, { title = Config.StoreName, description = msg, type = 'error' })
        end
        print(string.format("[sinister_store] FAILED: %s for %s - %s", packageName, playerIdentifier, tostring(err)))
    end
    return success
end

local function enqueuePurchase(transactionId, playerIdentifier, playerName, packageName, category, price, rewardType, rewardData)
    if db.purchaseExists(transactionId) then
        print("[sinister_store] Duplicate transaction ignored: " .. transactionId)
        return
    end
    db.insertPurchase(transactionId, playerIdentifier, playerName, packageName, category, price, rewardType, rewardData)
    purchaseQueue[#purchaseQueue + 1] = {
        transactionId = transactionId,
        playerIdentifier = playerIdentifier,
        playerName = playerName,
        packageName = packageName,
        category = category,
        rewardType = rewardType,
        rewardData = rewardData,
    }
end

local function processQueue()
    if isProcessing then return end
    if #purchaseQueue == 0 then return end
    isProcessing = true
    local batch = {}
    local count = math.min(#purchaseQueue, 5)
    for i = 1, count do
        batch[#batch + 1] = table.remove(purchaseQueue, 1)
    end
    for _, item in ipairs(batch) do
        processPurchase(item.transactionId, item.playerIdentifier, item.playerName, item.packageName, item.rewardType, item.rewardData)
    end
    isProcessing = false
end

CreateThread(function()
    while true do
        Wait(Config.QueueProcessingInterval)
        processQueue()
    end
end)

RegisterNetEvent('sinister_store:server:openStore', function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pendingCount = db.getPurchaseCount(player.PlayerData.citizenid)
    local playerInfo = {
        name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid,
        money = { bank = player.PlayerData.money.bank or 0, cash = player.PlayerData.money.cash or 0 },
        pendingCount = pendingCount,
    }
    TriggerClientEvent('sinister_store:client:openStore', src, Config.Packages, Config.Categories, playerInfo)
end)

RegisterNetEvent('sinister_store:server:requestPurchase', function(packageName, data)
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pkg = findPackageByName(packageName)
    if not pkg then
        TriggerClientEvent('ox_lib:notify', src, { title = Config.StoreName, description = "Package not found.", type = 'error' })
        return
    end
    local transactionId = "SIN-" .. os.time() .. "-" .. math.random(1000, 9999)
    local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    enqueuePurchase(transactionId, player.PlayerData.citizenid, playerName, packageName, pkg.category, pkg.price, pkg.reward.type, json.encode(pkg.reward))
    TriggerClientEvent('sinister_store:client:purchaseQueued', src, { packageName = packageName, transactionId = transactionId })
    TriggerClientEvent('ox_lib:notify', src, { title = Config.StoreName, description = Config.Notifications.checkoutComplete, type = 'success' })
end)

RegisterNetEvent('sinister_store:server:redeemPurchases', function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local identifier = player.PlayerData.citizenid
    local pending = db.getPendingPurchases(identifier)
    if not pending or #pending == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = Config.StoreName, description = Config.Notifications.noPending, type = 'inform' })
        TriggerClientEvent('sinister_store:client:redeemResult', src, { success = false, message = Config.Notifications.noPending })
        return
    end
    local redeemed = 0
    local failed = 0
    for _, purchase in ipairs(pending) do
        local rewardData = purchase.reward_data
        if type(rewardData) == "string" then
            rewardData = json.decode(rewardData)
        end
        local success, err = packageHandler.dispatchReward(src, rewardData or {})
        if success then
            db.markRedeemed(purchase.transaction_id)
            db.logAction(purchase.transaction_id, identifier, purchase.package_name, "redeemed", "success")
            redeemed = redeemed + 1
        else
            db.markFailed(purchase.transaction_id, tostring(err))
            db.logAction(purchase.transaction_id, identifier, purchase.package_name, "failed", "failure", tostring(err))
            failed = failed + 1
        end
    end
    local resultMsg = string.format("Redeemed %d purchase(s).", redeemed)
    if failed > 0 then
        resultMsg = resultMsg .. string.format(" %d failed. Contact support.", failed)
    end
    TriggerClientEvent('ox_lib:notify', src, { title = Config.StoreName, description = resultMsg, type = redeemed > 0 and 'success' or 'error' })
    TriggerClientEvent('sinister_store:client:redeemResult', src, {
        success = redeemed > 0,
        message = resultMsg,
        redeemed = redeemed,
        failed = failed,
    })
end)

RegisterNetEvent('sinister_store:server:checkPending', function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pendingCount = db.getPurchaseCount(player.PlayerData.citizenid)
    TriggerClientEvent('sinister_store:client:pendingCount', src, pendingCount)
end)

RegisterNetEvent('sinister_store:server:getPlayerInfo', function()
    local src = source
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pendingCount = db.getPurchaseCount(player.PlayerData.citizenid)
    TriggerClientEvent('sinister_store:client:playerInfo', src, {
        name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid,
        money = { bank = player.PlayerData.money.bank or 0, cash = player.PlayerData.money.cash or 0 },
        pendingCount = pendingCount,
    })
end)

AddEventHandler('playerJoining', function()
    local src = source
    Wait(5000)
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pendingCount = db.getPurchaseCount(player.PlayerData.citizenid)
    if pendingCount > 0 then
        local msg = string.format(Config.Notifications.pendingPurchase, pendingCount)
        TriggerClientEvent('ox_lib:notify', src, { title = Config.StoreName, description = msg, type = 'warning', duration = 10000 })
        TriggerClientEvent('sinister_store:client:pendingCount', src, pendingCount)
    end
end)

RegisterCommand(Config.Commands.openStore, function(source, args, raw)
    local src = source
    if src <= 0 then return end
    TriggerEvent('sinister_store:server:openStore', src)
end)

RegisterCommand(Config.Commands.redeem, function(source, args, raw)
    local src = source
    if src <= 0 then return end
    TriggerEvent('sinister_store:server:redeemPurchases', src)
end)

RegisterCommand(Config.Commands.adminCheck, function(source, args, raw)
    local src = source
    if src <= 0 then
        local pending = db.getAllPendingPurchases()
        if pending and #pending > 0 then
            print(string.format("[sinister_store] === PENDING PURCHASES (%d) ===", #pending))
            for _, p in ipairs(pending) do
                print(string.format("  ID: %s | Player: %s | Package: %s | Status: %s | Created: %s",
                    p.transaction_id, p.player_identifier, p.package_name, p.status, p.created_at))
            end
        else
            print("[sinister_store] No pending purchases.")
        end
        return
    end
    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end
    local pending = db.getAllPendingPurchases()
    TriggerClientEvent('sinister_store:client:adminPending', src, pending or {})
end, true)

RegisterNetEvent('sinister_store:webhook', function(data)
    if not data or not data.transaction_id then
        print("[sinister_store] Invalid webhook data received")
        return
    end
    local verified, paymentData = verifyTebexTransaction(data.transaction_id)
    if not verified then
        print("[sinister_store] Webhook verification failed for: " .. data.transaction_id)
        return
    end
    local playerIdentifier = data.player_identifier or (data.player and data.player.uuid) or "unknown"
    local packageName = data.package_name or "Unknown Package"
    local playerName = data.player_name or (data.player and data.player.username) or "Unknown"
    enqueuePurchase(data.transaction_id, playerIdentifier, playerName, packageName, "webhook", data.price or 0, data.reward_type or "unknown", json.encode(data.reward or {}))
    print(string.format("[sinister_store] Webhook purchase queued: %s for %s", packageName, playerIdentifier))
end)

SetHttpHandler(function(req, res)
    if req.path == "/webhook" and req.method == "POST" then
        local body = req.body
        local data = json.decode(body)
        if data then
            TriggerEvent('sinister_store:webhook', data)
            res.writeHead(200, { ["Content-Type"] = "application/json" })
            res.send(json.encode({ success = true }))
        else
            res.writeHead(400, { ["Content-Type"] = "application/json" })
            res.send(json.encode({ success = false, error = "Invalid payload" }))
        end
        return
    end
    res.writeHead(404, { ["Content-Type"] = "application/json" })
    res.send(json.encode({ error = "Not found" }))
end)

print("^2[sinister_store] ^7Server loaded. Tebex webhook at /webhook.")
