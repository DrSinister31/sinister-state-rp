local packageHandler = {}
local QBCore = exports['qbx_core']

local function getPlayer(src)
    return QBCore:GetPlayer(src)
end

local function generatePlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. chars:sub(rand, rand)
    end
    return plate
end

local function logSuccess(playerId, packageName, rewardType)
    local player = getPlayer(playerId)
    local name = player and player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname or "Unknown"
    local identifier = player and player.PlayerData.citizenid or "Unknown"
    local msg = string.format("[SUCCESS] %s | Player: %s (%s) | CitizenID: %s | Package: %s | Reward: %s",
        os.date("%Y-%m-%d %H:%M:%S"), name, playerId, identifier, packageName, rewardType)
    local file = io.open(Config.LogFile, "a")
    if file then
        file:write(msg .. "\n")
        file:close()
    end
    print(msg)
end

local function logFailure(playerId, packageName, rewardType, err)
    local player = getPlayer(playerId)
    local name = player and player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname or "Unknown"
    local identifier = player and player.PlayerData.citizenid or "Unknown"
    local msg = string.format("[FAILURE] %s | Player: %s (%s) | CitizenID: %s | Package: %s | Reward: %s | Error: %s",
        os.date("%Y-%m-%d %H:%M:%S"), name, playerId, identifier, packageName, rewardType, tostring(err))
    local file = io.open(Config.LogFile, "a")
    if file then
        file:write(msg .. "\n")
        file:close()
    end
    print(msg)
end

function packageHandler.handleMoney(playerId, amount)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success = pcall(function()
        exports['qbx_core']:Functions.AddMoney(playerId, "bank", amount, "store-purchase")
    end)
    if not success then
        logFailure(playerId, "$" .. amount .. " Cash", "money", "AddMoney failed")
        return false, "Failed to add money"
    end
    logSuccess(playerId, "$" .. amount .. " Cash", "money")
    return true
end

function packageHandler.handleItem(playerId, items)
    if type(items) ~= "table" then
        return false, "Invalid items table"
    end
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local allSuccess = true
    local failedItems = {}
    for _, item in ipairs(items) do
        local success, result = pcall(function()
            return exports.ox_inventory:AddItem(playerId, item.name, item.amount or 1)
        end)
        if not success then
            allSuccess = false
            failedItems[#failedItems + 1] = item.name
            logFailure(playerId, "Item: " .. item.name, "item", result)
        end
    end
    if not allSuccess then
        for _, itemName in ipairs(items) do
            if not table.contains(failedItems, itemName.name) then
                local succeededToRemove = pcall(function()
                    exports.ox_inventory:RemoveItem(playerId, itemName.name, itemName.amount or 1)
                end)
                if not succeededToRemove then
                    print("[WARN] Could not rollback item: " .. (itemName.name or "unknown"))
                end
            end
        end
        return false, "Failed to add items: " .. table.concat(failedItems, ", ")
    end
    logSuccess(playerId, "Item Pack", "item")
    return true
end

function packageHandler.handleVehicle(playerId, model, plate)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    if plate == nil or plate == "" then
        plate = generatePlate()
    end
    local citizenid = player.PlayerData.citizenid
    local success, result = pcall(MySQL.insert.await, 'INSERT INTO player_vehicles (citizenid, vehicle, plate, garage, state) VALUES (?, ?, ?, ?, ?)', {
        citizenid,
        model,
        plate,
        "pillboxgarage",
        1
    })
    if not success then
        logFailure(playerId, model, "vehicle", result)
        return false, "Failed to insert vehicle into database"
    end
    logSuccess(playerId, model, "vehicle")
    return true
end

function packageHandler.handleJob(playerId, jobName, grade)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success, err = pcall(function()
        player.Functions.SetJob(jobName, grade)
    end)
    if not success then
        logFailure(playerId, jobName, "job", err)
        return false, "Failed to set job"
    end
    logSuccess(playerId, jobName, "job")
    return true
end

function packageHandler.handleGang(playerId, gangName, grade)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success, err = pcall(function()
        player.Functions.SetGang(gangName, grade)
    end)
    if not success then
        logFailure(playerId, gangName, "gang", err)
        return false, "Failed to set gang"
    end
    logSuccess(playerId, gangName, "gang")
    return true
end

function packageHandler.handleVip(playerId, tier)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success, err = pcall(function()
        local identifier = player.PlayerData.citizenid
        MySQL.insert.await('INSERT INTO sinister_vip (citizenid, tier, purchased_at, expires_at) VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)) ON DUPLICATE KEY UPDATE tier = ?, purchased_at = NOW(), expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY)', {
            identifier, tier, tier
        })
    end)
    if not success then
        logFailure(playerId, "VIP " .. tier, "vip", err)
        return false, "Failed to set VIP status"
    end
    logSuccess(playerId, "VIP " .. tier, "vip")
    return true
end

function packageHandler.handleNameChange(playerId)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success, result = pcall(function()
        return exports.ox_inventory:AddItem(playerId, "name_change_token", 1)
    end)
    if not success then
        logFailure(playerId, "Name Change Token", "namechange", result)
        return false, "Failed to add name change token"
    end
    logSuccess(playerId, "Name Change Token", "namechange")
    return true
end

function packageHandler.handlePlateChange(playerId)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local success, result = pcall(function()
        return exports.ox_inventory:AddItem(playerId, "custom_plate_token", 1)
    end)
    if not success then
        logFailure(playerId, "Custom Plate Token", "platechange", result)
        return false, "Failed to add custom plate token"
    end
    logSuccess(playerId, "Custom Plate Token", "platechange")
    return true
end

function packageHandler.handleAppearanceReset(playerId)
    local player = getPlayer(playerId)
    if not player then
        return false, "Player not found"
    end
    local citizenid = player.PlayerData.citizenid
    local success, err = pcall(MySQL.update.await, 'UPDATE players SET appearance_reset = 1 WHERE citizenid = ?', { citizenid })
    if not success then
        logFailure(playerId, "Appearance Reset", "appearance", err)
        return false, "Failed to set appearance reset flag"
    end
    TriggerClientEvent('qb-clothing:client:openClothing', playerId)
    logSuccess(playerId, "Appearance Reset", "appearance")
    return true
end

function packageHandler.dispatchReward(playerId, reward)
    if not reward or not reward.type then
        return false, "Invalid reward data"
    end
    local rewardType = reward.type
    if rewardType == "money" then
        return packageHandler.handleMoney(playerId, reward.amount)
    elseif rewardType == "item" then
        return packageHandler.handleItem(playerId, reward.items)
    elseif rewardType == "vehicle" then
        return packageHandler.handleVehicle(playerId, reward.class or "adder", nil)
    elseif rewardType == "job" then
        return packageHandler.handleJob(playerId, reward.job, reward.grade or 1)
    elseif rewardType == "gang" then
        return packageHandler.handleGang(playerId, reward.gang, reward.grade or 1)
    elseif rewardType == "vip" then
        return packageHandler.handleVip(playerId, reward.tier)
    elseif rewardType == "namechange" then
        return packageHandler.handleNameChange(playerId)
    elseif rewardType == "platechange" then
        return packageHandler.handlePlateChange(playerId)
    elseif rewardType == "appearance" then
        return packageHandler.handleAppearanceReset(playerId)
    else
        return false, "Unknown reward type: " .. rewardType
    end
end

return packageHandler
