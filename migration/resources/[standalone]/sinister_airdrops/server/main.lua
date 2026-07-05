local activeDrops = {}
local zoneCooldowns = {}
local nextDropId = 0

local function notifyAll(msg, type)
	TriggerClientEvent("ox_lib:notify", -1, {
		title = "Sinister Airdrops",
		description = msg,
		type = type or "inform",
		duration = 8000,
	})
end

local function notifyPlayer(src, msg, type)
	TriggerClientEvent("ox_lib:notify", src, {
		title = "Airdrop",
		description = msg,
		type = type or "inform",
	})
end

local function sendDiscordAlert(zone)
	if Config.DiscordWebhook == "" then return end
	local msg = Config.DiscordAlertFormat:gsub("{zone}", zone.label)
	PerformHttpRequest(Config.DiscordWebhook, function() end, "POST",
		json.encode({ content = msg }),
		{ ["Content-Type"] = "application/json" })
end

local function getPlanePath(zoneCoords)
	local angle = math.random() * math.pi * 2
	local dist = 800.0
	local start = vec3(
		zoneCoords.x + math.cos(angle) * dist,
		zoneCoords.y + math.sin(angle) * dist,
		zoneCoords.z
	)
	local finish = vec3(
		zoneCoords.x - math.cos(angle) * dist,
		zoneCoords.y - math.sin(angle) * dist,
		zoneCoords.z
	)
	return start, finish
end

local function rollLoot(rarity)
	local items = {}
	local lootTable = Config.Loot[rarity]
	if not lootTable then return items end

	for _, entry in ipairs(lootTable) do
		if math.random(1, 100) <= entry.chance then
			local count = math.random(entry.min, entry.max)
			items[#items + 1] = { item = entry.item, count = count }
		end
	end
	return items
end

local function giveLoot(src, loot)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return false end

	local given = {}
	for _, entry in ipairs(loot) do
		if entry.item == "dirty_money" then
			player.Functions.AddMoney("dirty_money", entry.count)
		else
			exports.ox_inventory:AddItem(src, entry.item, entry.count)
		end
		given[#given + 1] = { label = entry.item, count = entry.count }
	end
	return given
end

local function pickRarity()
	local roll = math.random(1, 100)
	if roll <= 15 then return "Rare" end
	if roll <= 50 then return "Uncommon" end
	return "Common"
end

-- ============================================================================
-- Request drop from flare
-- ============================================================================

RegisterNetEvent("sinister_airdrops:requestDrop", function(cratePos)
	local src = source
	local now = os.time()

	local closestZone = nil
	local closestDist = 99999.0
	for _, z in ipairs(Config.Zones) do
		local dist = #(cratePos - z.coords)
		if dist < 300.0 and dist < closestDist then
			closestDist = dist
			closestZone = z
		end
	end

	if not closestZone then
		notifyPlayer(src, "Must be within 300m of a drop zone.", "error")
		return
	end

	if zoneCooldowns[closestZone.id] and (now - zoneCooldowns[closestZone.id]) < (Config.CooldownPerZone * 60) then
		local remaining = math.ceil((Config.CooldownPerZone * 60) - (now - zoneCooldowns[closestZone.id]))
		notifyPlayer(src, "Zone on cooldown: " .. remaining .. "s remaining.", "error")
		return
	end

	zoneCooldowns[closestZone.id] = now
	nextDropId = nextDropId + 1
	local dropId = nextDropId

	-- Adjust crate to ground
	cratePos = vec3(cratePos.x, cratePos.y, GetGroundZFor_3dCoord(cratePos.x, cratePos.y, cratePos.z, false) or cratePos.z)

	local planeStart, planeEnd = getPlanePath(cratePos)

	local isKamikaze = math.random(1, 100) <= Config.KamikazeChance

	local dropData = {
		id = dropId,
		zone = closestZone,
		cratePos = cratePos,
		planeStart = planeStart,
		planeEnd = planeEnd,
		isKamikaze = isKamikaze,
	}
	activeDrops[dropId] = dropData

	TriggerClientEvent("sinister_airdrops:planeFlyover", -1, dropData)

	if isKamikaze then
		notifyAll("⚠️ " .. Config.KamikazeName .. " HAS GONE ROGUE! Seek cover at " .. closestZone.label .. "!", "error")
		TriggerClientEvent("sinister_airdrops:kamikazeDive", -1, dropData)
		sendDiscordAlert(closestZone)

		SetTimeout(10000, function()
			activeDrops[dropId] = nil
		end)
		return
	end

	notifyAll("🛩️ Unregistered aircraft detected over " .. closestZone.label .. " airspace!", "inform")
	sendDiscordAlert(closestZone)

	SetTimeout(8000, function()
		if not activeDrops[dropId] then return end
		TriggerClientEvent("sinister_airdrops:spawnCrate", -1, dropData)
		notifyAll("📦 Cargo dropped near " .. closestZone.label .. " — secure the crate!", "success")
	end)

	SetTimeout(Config.CrateStayTime + 12000, function()
		activeDrops[dropId] = nil
	end)
end)

-- ============================================================================
-- Crate opening
-- ============================================================================

RegisterNetEvent("sinister_airdrops:openCrate", function(dropId)
	local src = source
	local drop = activeDrops[dropId]
	if not drop then return end

	TriggerClientEvent("sinister_airdrops:startOpening", src)

	SetTimeout(Config.CrateOpenTime, function()
		if not activeDrops[dropId] then return end
		local player = exports.qbx_core:GetPlayer(src)
		if not player then return end

		local ped = GetPlayerPed(src)
		local coords = GetEntityCoords(ped)
		if #(coords - drop.cratePos) > 5.0 then
			TriggerClientEvent("sinister_airdrops:stopOpening", src)
			return
		end

		local rarity = pickRarity()
		local loot = rollLoot(rarity)
		local given = giveLoot(src, loot)

		if #given > 0 then
			TriggerClientEvent("sinister_airdrops:lootReceived", src, given)
		else
			TriggerClientEvent("sinister_airdrops:lootEmpty", src)
		end

		activeDrops[dropId] = nil
	end)
end)

RegisterNetEvent("sinister_airdrops:cancelOpen", function(dropId)
	local src = source
	TriggerClientEvent("sinister_airdrops:stopOpening", src)
end)

-- ============================================================================
-- Automatic scheduled drops
-- ============================================================================

Citizen.CreateThread(function()
	while true do
		Wait(Config.AutoDropInterval * 60 * 1000)
		if #GetPlayers() >= Config.MinPlayersForAuto then
			local zone = Config.Zones[math.random(1, #Config.Zones)]
			local jitterX = math.random(-50, 50)
			local jitterY = math.random(-50, 50)
			local cratePos = vec3(zone.coords.x + jitterX, zone.coords.y + jitterY, zone.coords.z)
			local planeStart, planeEnd = getPlanePath(cratePos)
			local now = os.time()

			if zoneCooldowns[zone.id] and (now - zoneCooldowns[zone.id]) < (Config.CooldownPerZone * 60) then
				goto continue
			end

			zoneCooldowns[zone.id] = now
			nextDropId = nextDropId + 1
			local dropId = nextDropId

			local dropData = {
				id = dropId,
				zone = zone,
				cratePos = cratePos,
				planeStart = planeStart,
				planeEnd = planeEnd,
				isKamikaze = false,
			}
			activeDrops[dropId] = dropData

			notifyAll("🛩️ Automated supply drop inbound to " .. zone.label .. "!", "inform")
			sendDiscordAlert(zone)
			TriggerClientEvent("sinister_airdrops:planeFlyover", -1, dropData)

			SetTimeout(8000, function()
				if not activeDrops[dropId] then return end
				TriggerClientEvent("sinister_airdrops:spawnCrate", -1, dropData)
			end)

			SetTimeout(Config.CrateStayTime + 12000, function()
				activeDrops[dropId] = nil
			end)
		end
		::continue::
	end
end)

-- ============================================================================
-- Admin spawn
-- ============================================================================

RegisterCommand("spawnairdrop", function(source, args)
	local src = source
	if src > 0 then
		local player = exports.qbx_core:GetPlayer(src)
		if not player then return end
		local hasPerm = false
		for _, grade in ipairs({ "admin", "god", "owner" }) do
			if player.PlayerData.job.name == "admin" or IsPlayerAceAllowed(src, "command.spawnairdrop") then
				hasPerm = true
				break
			end
		end
		if not hasPerm then return end
	end

	local zoneName = args[1]
	local zone = nil
	for _, z in ipairs(Config.Zones) do
		if z.id == zoneName then zone = z break end
	end
	if not zone then
		zone = Config.Zones[math.random(1, #Config.Zones)]
	end

	local cratePos = zone.coords
	nextDropId = nextDropId + 1
	local dropId = nextDropId
	local planeStart, planeEnd = getPlanePath(cratePos)

	local dropData = {
		id = dropId,
		zone = zone,
		cratePos = cratePos,
		planeStart = planeStart,
		planeEnd = planeEnd,
		isKamikaze = false,
	}
	activeDrops[dropId] = dropData

	notifyAll("🛩️ Admin-ordered drop inbound to " .. zone.label .. "!", "inform")
	TriggerClientEvent("sinister_airdrops:planeFlyover", -1, dropData)

	SetTimeout(8000, function()
		if not activeDrops[dropId] then return end
		TriggerClientEvent("sinister_airdrops:spawnCrate", -1, dropData)
	end)

	SetTimeout(Config.CrateStayTime + 12000, function()
		activeDrops[dropId] = nil
	end)
end, true)

print("^5[sinister_airdrops] ^7Server ready — " .. #Config.Zones .. " drop zones configured")
