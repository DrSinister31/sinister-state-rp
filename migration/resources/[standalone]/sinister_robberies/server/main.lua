local texasHeat = {}
local activeRobberies = {}

local function notifyAll(msg, type)
	TriggerClientEvent("ox_lib:notify", -1, {
		title = "🚔 Dispatch",
		description = msg,
		type = type or "error",
		duration = 8000,
	})
end

local function notifyPlayer(src, msg, type)
	TriggerClientEvent("ox_lib:notify", src, {
		title = "Robbery",
		description = msg,
		type = type or "inform",
	})
end

local function getRobberyType(typeId)
	for _, rt in ipairs(Config.RobberyTypes) do
		if rt.type == typeId then return rt end
	end
	return nil
end

local function getPoliceCount()
	local count = 0
	for _, pid in ipairs(GetPlayers()) do
		local player = exports.qbx_core:GetPlayer(pid)
		if player then
			local job = player.PlayerData.job.name
			if job == "police" or job == "bcso" or job == "sasp" or job == "fib" then
				count = count + 1
			end
		end
	end
	return count
end

-- ============================================================================
-- Start robbery
-- ============================================================================

RegisterNetEvent("sinister_robberies:startRobbery", function(robType, location)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end
	local cid = player.PlayerData.citizenid

	local robberyType = getRobberyType(robType)
	if not robberyType then
		notifyPlayer(src, "Invalid robbery type.", "error")
		return
	end

	if Config.RequiredPolice > 0 then
		if getPoliceCount() < Config.RequiredPolice then
			notifyPlayer(src, "Not enough police online. Minimum: " .. Config.RequiredPolice, "error")
			return
		end
	end

	local now = os.time()
	if texasHeat[cid] and (now - texasHeat[cid]) < (Config.TexasHeatCooldown * 60) then
		local remaining = math.ceil((Config.TexasHeatCooldown * 60) - (now - texasHeat[cid]))
		TriggerClientEvent("sinister_robberies:heatWarning", src, {
			remaining = remaining,
			label = robberyType.label,
		})
		return
	end

	activeRobberies[src] = { type = robType, name = location.name, startedAt = now }

	local alertMsg = string.format(Config.PoliceAlertFormat, robberyType.label, location.name)
	notifyAll(alertMsg, "error")
	TriggerClientEvent("sinister_robberies:policeAlert", -1, alertMsg)

	TriggerClientEvent("sinister_robberies:robberyStarted", src, {
		type = robType,
		label = robberyType.label,
		name = location.name,
		coords = location.coords,
	})
end)

-- ============================================================================
-- Robbery complete
-- ============================================================================

RegisterNetEvent("sinister_robberies:robberyComplete", function(robType, locationName)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end
	local cid = player.PlayerData.citizenid

	local robberyType = getRobberyType(robType)
	if not robberyType then return end

	texasHeat[cid] = os.time()

	local totalMoney = 0
	local givenItems = {}

	if robberyType.rewards.dirtyMoney then
		totalMoney = math.random(robberyType.rewards.dirtyMoney.min, robberyType.rewards.dirtyMoney.max)
		if totalMoney > 0 then
			player.Functions.AddMoney("dirty_money", totalMoney)
		end
	end

	for _, entry in ipairs(robberyType.rewards.items) do
		if math.random(1, 100) <= (entry.chance or 50) then
			local count = math.random(entry.min, entry.max)
			exports.ox_inventory:AddItem(src, entry.item, count)
			givenItems[#givenItems + 1] = { item = entry.item, count = count }
		end
	end

	TriggerClientEvent("sinister_robberies:robberyReward", src, {
		money = totalMoney,
		items = givenItems,
	})

	activeRobberies[src] = nil

	TriggerClientEvent("sinister_robberies:policeAlert", -1,
		string.format("✅ 211 CLEAR — Robbery at %s completed. Suspect may have fled.", locationName))
end)

-- ============================================================================
-- Robbery failed
-- ============================================================================

RegisterNetEvent("sinister_robberies:robberyFailed", function(robType, locationName)
	local src = source
	activeRobberies[src] = nil
	TriggerClientEvent("sinister_robberies:policeAlert", -1,
		string.format("❌ 211 ABORTED — Robbery at %s failed.", locationName))
end)

-- ============================================================================
-- Admin: reset player heat
-- ============================================================================

RegisterCommand("resetcrimeheat", function(source, args)
	local src = source
	if src > 0 then
		local player = exports.qbx_core:GetPlayer(src)
		if not player then return end
		local hasPerm = false
		if IsPlayerAceAllowed(src, "command.resetheat") then hasPerm = true end
		if player.PlayerData.job.name == "admin" then hasPerm = true end
		if not hasPerm then return end
	end

	local targetId = tonumber(args[1])
	if targetId then
		local targetPlayer = exports.qbx_core:GetPlayer(targetId)
		if targetPlayer then
			texasHeat[targetPlayer.PlayerData.citizenid] = nil
			notifyPlayer(src, "Reset heat for player ID " .. targetId, "success")
		else
			notifyPlayer(src, "Player not found.", "error")
		end
	else
		notifyPlayer(src, "Usage: /resetcrimeheat [playerId]", "error")
	end
end, true)

print("^5[sinister_robberies] ^7Server ready — " .. #Config.RobberyTypes .. " robbery types loaded")
