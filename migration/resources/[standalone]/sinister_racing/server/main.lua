local lobbies = {}
local activeRaces = {}
local playerCooldowns = {}
local playerRep = {}
local nextLobbyId = 0
local nextRaceId = 0

local function notifyAll(msg, type)
	TriggerClientEvent("ox_lib:notify", -1, {
		title = "🏁 H-Town Midnight Runs",
		description = msg,
		type = type or "inform",
		duration = 8000,
	})
end

local function notifyPlayer(src, msg, type)
	TriggerClientEvent("ox_lib:notify", src, {
		title = "H-Town Racing",
		description = msg,
		type = type or "inform",
	})
end

local function getRaceRoute(routeId)
	for _, r in ipairs(Config.RaceRoutes) do
		if r.id == routeId then return r end
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

local function validateVehicle(src, routeId)
	local ped = GetPlayerPed(src)
	local veh = GetVehiclePedIsIn(ped, false)
	if veh == 0 then return false end
	local class = GetVehicleClass(veh)
	if class ~= 6 then
		notifyPlayer(src, "Only muscle cars allowed in H-Town Midnight Runs.", "error")
		return false
	end
	return true
end

-- ============================================================================
-- Reputation
-- ============================================================================

lib.callback.register("sinister_racing:getReputation", function(source)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return 0 end
	local cid = player.PlayerData.citizenid
	return playerRep[cid] or 0
end)

local function addRep(src, amount)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end
	local cid = player.PlayerData.citizenid
	playerRep[cid] = (playerRep[cid] or 0) + amount
end

-- ============================================================================
-- Lobby
-- ============================================================================

RegisterNetEvent("sinister_racing:createLobby", function(routeId, entryFee)
	local src = source
	local route = getRaceRoute(routeId)
	if not route then
		notifyPlayer(src, "Invalid race route.", "error")
		return
	end

	if not validateVehicle(src, routeId) then return end

	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end
	local cid = player.PlayerData.citizenid

	local rep = playerRep[cid] or 0
	if rep < route.minRep then
		notifyPlayer(src, "Need " .. route.minRep .. " rep for " .. route.name .. ". You have " .. rep .. ".", "error")
		return
	end

	local now = os.time()
	if playerCooldowns[cid] and (now - playerCooldowns[cid]) < (Config.CooldownMinutes * 60) then
		local remaining = math.ceil((Config.CooldownMinutes * 60) - (now - playerCooldowns[cid]))
		notifyPlayer(src, "Cooldown: " .. remaining .. "s remaining.", "error")
		return
	end

	nextLobbyId = nextLobbyId + 1
	lobbies[nextLobbyId] = {
		id = nextLobbyId,
		routeId = routeId,
		routeName = route.name,
		entryFee = entryFee,
		host = src,
		players = { src },
		createdAt = now,
	}

	TriggerClientEvent("sinister_racing:lobbyCreated", src, {
		lobbyId = nextLobbyId,
		routeName = route.name,
		entryFee = entryFee,
	})
end)

RegisterNetEvent("sinister_racing:lobbyAnnounce", function(lobbyId)
	local lobby = lobbies[lobbyId]
	if not lobby then return end
	TriggerClientEvent("sinister_racing:lobbyAnnouncement", -1, {
		lobbyId = lobby.id,
		routeName = lobby.routeName,
		entryFee = lobby.entryFee,
		playerCount = #lobby.players,
	})
end)

RegisterNetEvent("sinister_racing:joinLobby", function(lobbyId)
	local src = source
	local lobby = lobbies[lobbyId]
	if not lobby then
		notifyPlayer(src, "Lobby not found.", "error")
		return
	end

	if #lobby.players >= Config.MaxRacers then
		notifyPlayer(src, "Lobby is full.", "error")
		return
	end

	for _, pid in ipairs(lobby.players) do
		if pid == src then
			notifyPlayer(src, "Already in this lobby.", "error")
			return
		end
	end

	if not validateVehicle(src, lobby.routeId) then return end

	lobby.players[#lobby.players + 1] = src
	TriggerClientEvent("sinister_racing:joinedLobby", src)

	for _, pid in ipairs(lobby.players) do
		notifyPlayer(pid, "Racer joined — " .. #lobby.players .. "/" .. Config.MaxRacers .. " | /leaverace to quit", "inform")
	end

	if #lobby.players >= Config.MinRacers then
		notifyPlayer(lobby.host, "Ready to start! Type /startrace to begin the race.", "success")
	end
end)

RegisterNetEvent("sinister_racing:leaveLobby", function()
	local src = source
	for id, lobby in pairs(lobbies) do
		for i, pid in ipairs(lobby.players) do
			if pid == src then
				table.remove(lobby.players, i)
				if #lobby.players == 0 then
					lobbies[id] = nil
				else
					if lobby.host == src then lobby.host = lobby.players[1] end
					for _, p in ipairs(lobby.players) do
						notifyPlayer(p, "A racer left. " .. #lobby.players .. "/" .. Config.MaxRacers, "inform")
					end
				end
				return
			end
		end
	end
end)

-- ============================================================================
-- Start Race
-- ============================================================================

RegisterCommand("startrace", function(source)
	local src = source
	local lobby = nil
	for _, l in pairs(lobbies) do
		if l.host == src then lobby = l break end
	end

	if not lobby then
		notifyPlayer(src, "You're not hosting a lobby.", "error")
		return
	end

	if #lobby.players < Config.MinRacers then
		notifyPlayer(src, "Need at least " .. Config.MinRacers .. " racers.", "error")
		return
	end

	local route = getRaceRoute(lobby.routeId)
	if not route then return end

	if Config.RequiredPolice > 0 and getPoliceCount() < Config.RequiredPolice then
		notifyPlayer(src, "Not enough police online.", "error")
		return
	end

	nextRaceId = nextRaceId + 1
	local race = {
		id = nextRaceId,
		route = route,
		players = {},
		startTime = os.time(),
		finishers = {},
		entryFee = lobby.entryFee,
	}

	for _, pid in ipairs(lobby.players) do
		race.players[#race.players + 1] = { src = pid, finished = false, place = nil }

		local player = exports.qbx_core:GetPlayer(pid)
		if player then
			player.Functions.RemoveMoney("dirty_money", lobby.entryFee)
			playerCooldowns[player.PlayerData.citizenid] = os.time()
		end
	end

	activeRaces[nextRaceId] = race
	lobbies[lobby.id] = nil

	for _, pid in ipairs(lobby.players) do
		TriggerClientEvent("sinister_racing:raceStart", pid, { route = route })
	end

	notifyAll("🏁 RACE STARTED: " .. route.name .. " | " .. #lobby.players .. " racers | $" .. lobby.entryFee .. " entry", "success")

	if math.random(1, 100) <= Config.PoliceAlertChance then
		local alertMsg = string.format(Config.PoliceAlertFormat, route.name, "H-Town")
		TriggerClientEvent("sinister_racing:policeAlert", -1, alertMsg)
		notifyAll("🚔 Police have been alerted to street racing activity!", "error")
	end

	SetTimeout(Config.RaceTimeout * 60 * 1000, function()
		if activeRaces[nextRaceId] then
			for _, entry in ipairs(activeRaces[nextRaceId].players) do
				if not entry.finished then
					TriggerClientEvent("sinister_racing:raceResult", entry.src, { placement = "DNF" })
				end
			end
			activeRaces[nextRaceId] = nil
		end
	end)
end, false)

-- ============================================================================
-- Race finish
-- ============================================================================

RegisterNetEvent("sinister_racing:playerFinished", function(routeId)
	local src = source
	local race = nil
	for _, r in pairs(activeRaces) do
		if r.route.id == routeId then race = r break end
	end
	if not race then return end

	local entry = nil
	for _, e in ipairs(race.players) do
		if e.src == src and not e.finished then entry = e break end
	end
	if not entry then return end

	entry.finished = true
	entry.place = #race.finishers + 1
	race.finishers[#race.finishers + 1] = src

	local place = entry.place

	if place == 1 then
		addRep(src, Config.ReputationGain.win)
	elseif place <= 3 then
		addRep(src, Config.ReputationGain.podium)
	else
		addRep(src, Config.ReputationGain.finish)
	end

	local allFinished = true
	local totalFinishers = #race.finishers
	for _, e in ipairs(race.players) do
		if not e.finished then allFinished = false break end
	end

	if allFinished or totalFinishers >= #race.players then
		local pot = race.entryFee * totalFinishers
		local payout = math.floor(pot * 0.7)
		local winnerSrc = race.finishers[1]
		if winnerSrc then
			local winnerPlayer = exports.qbx_core:GetPlayer(winnerSrc)
			if winnerPlayer then
				winnerPlayer.Functions.AddMoney("dirty_money", payout)
			end
			TriggerClientEvent("sinister_racing:raceResult", winnerSrc, { placement = 1, winnings = payout })
		end

		for i = 2, totalFinishers do
			local rep = i <= 3 and Config.ReputationGain.podium or Config.ReputationGain.finish
			addRep(race.finishers[i], rep)
			TriggerClientEvent("sinister_racing:raceResult", race.finishers[i], { placement = i })
		end

		notifyAll("🏁 RACE OVER: " .. race.route.name .. " | Winner takes $" .. payout, "success")
		activeRaces[race.id] = nil
	else
		TriggerClientEvent("sinister_racing:raceResult", src, { placement = place })
	end
end)

RegisterNetEvent("sinister_racing:playerQuit", function()
	local src = source
	for _, race in pairs(activeRaces) do
		for _, e in ipairs(race.players) do
			if e.src == src and not e.finished then
				e.finished = true
				e.place = "DNF"
			end
		end
	end
end)

-- ============================================================================
-- Leaderboard command
-- ============================================================================

RegisterCommand("raceleaderboard", function(source)
	local src = source
	local sorted = {}
	for cid, rep in pairs(playerRep) do
		sorted[#sorted + 1] = { cid = cid:sub(1, 6), rep = rep }
	end
	table.sort(sorted, function(a, b) return a.rep > b.rep end)

	local lines = { "🏁 H-Town Midnight Runs — Leaderboard" }
	for i = 1, math.min(10, #sorted) do
		lines[#lines + 1] = i .. ". " .. sorted[i].cid .. " — " .. sorted[i].rep .. " rep"
	end
	TriggerClientEvent("chat:addMessage", src, { args = { "RACING", table.concat(lines, "\n") } })
end, false)

print("^5[sinister_racing] ^7Server ready — " .. #Config.RaceRoutes .. " routes | H-Town Midnight Runs")
