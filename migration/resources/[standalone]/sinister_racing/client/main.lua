local isRacing = false
local currentRoute = nil
local currentCheckpoint = 1
local checkpointBlip = nil
local raceBlips = {}
local raceStarted = false
local organizerPoint = nil

local function notify(msg, type)
	lib.notify({ title = "H-Town Midnight Runs", description = msg, type = type or "inform" })
end

local function cleanupRace()
	isRacing = false
	currentRoute = nil
	currentCheckpoint = 1
	raceStarted = false
	if checkpointBlip then RemoveBlip(checkpointBlip) checkpointBlip = nil end
	for _, blip in ipairs(raceBlips) do RemoveBlip(blip) end
	raceBlips = {}
	lib.hideTextUI()
end

local function setCheckpointBlip(pos, isFinish)
	if checkpointBlip then RemoveBlip(checkpointBlip) end
	checkpointBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
	SetBlipSprite(checkpointBlip, isFinish and 38 or 162)
	SetBlipColour(checkpointBlip, isFinish and 2 or 5)
	SetBlipScale(checkpointBlip, 1.0)
	SetBlipRoute(checkpointBlip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(isFinish and "FINISH" or ("CP " .. currentCheckpoint))
	EndTextCommandSetBlipName(checkpointBlip)
end

local function openRaceMenu()
	local playerRep = lib.callback.await("sinister_racing:getReputation", false)

	local routes = {
		{
			title = "H-Town Midnight Runs",
			description = "Reputation: " .. playerRep .. " | Muscle cars only | /leaverace to quit",
			icon = "fa-solid fa-flag-checkered",
		},
	}

	for _, route in ipairs(Config.RaceRoutes) do
		local locked = playerRep < route.minRep
		routes[#routes + 1] = {
			title = (locked and "🔒 " or "") .. route.name,
			description = route.label .. " | " .. #route.checkpoints .. " CPs" .. (locked and " | Req: " .. route.minRep .. " rep" or ""),
			icon = "fa-solid fa-road",
			disabled = locked,
			onSelect = function()
				if not locked then createLobby(route) end
			end,
		}
	end

	lib.registerContext({
		id = "sinister_racing_menu",
		title = "H-Town Midnight Runs",
		description = "Underground Street Racing",
		options = routes,
	})
	lib.showContext("sinister_racing_menu")
end

function createLobby(route)
	local presets = {}
	for _, amt in ipairs(Config.EntryFee.presets) do
		presets[#presets + 1] = {
			title = "$" .. amt .. " Entry Fee",
			description = "Winner takes all",
			icon = "fa-solid fa-dollar-sign",
			onSelect = function()
				TriggerServerEvent("sinister_racing:createLobby", route.id, amt)
			end,
		}
	end

	lib.registerContext({
		id = "sinister_racing_wager",
		title = "Create Race: " .. route.name,
		description = "Select entry fee",
		options = presets,
	})
	lib.showContext("sinister_racing_wager")
end

RegisterNetEvent("sinister_racing:lobbyCreated")
AddEventHandler("sinister_racing:lobbyCreated", function(data)
	notify("Lobby created! Waiting for racers... Race: " .. data.routeName .. " | Entry: $" .. data.entryFee .. " | ID: " .. data.lobbyId, "success")
	TriggerServerEvent("sinister_racing:lobbyAnnounce", data.lobbyId)
end)

RegisterNetEvent("sinister_racing:lobbyAnnouncement")
AddEventHandler("sinister_racing:lobbyAnnouncement", function(data)
	lib.notify({
		title = "🏁 H-Town Race Lobby",
		description = data.routeName .. " | $" .. data.entryFee .. " entry | " .. data.playerCount .. "/" .. Config.MaxRacers .. " racers | /joinrace " .. data.lobbyId,
		type = "inform",
		duration = 10000,
	})
end)

RegisterNetEvent("sinister_racing:raceStart")
AddEventHandler("sinister_racing:raceStart", function(data)
	currentRoute = data.route
	currentCheckpoint = 1
	isRacing = true
	raceStarted = true

	for i, cp in ipairs(data.route.checkpoints) do
		local blip = AddBlipForCoord(cp.x, cp.y, cp.z)
		SetBlipSprite(blip, i == #data.route.checkpoints and 38 or 162)
		SetBlipColour(blip, i == #data.route.checkpoints and 2 or 5)
		SetBlipScale(blip, 0.6)
		SetBlipAlpha(blip, 180)
		raceBlips[#raceBlips + 1] = blip
	end

	setCheckpointBlip(data.route.checkpoints[1], false)

	lib.progressBar({
		duration = 5000,
		label = "🏁 " .. data.route.name .. " — GO!",
		useWhileDead = false,
		canCancel = false,
		disable = { combat = true },
	})

	notify("GO! " .. #data.route.checkpoints .. " checkpoints. Time limit: " .. Config.RaceTimeout .. " min", "success")
end)

Citizen.CreateThread(function()
	while true do
		Wait(500)
		if isRacing and raceStarted and currentRoute then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			local cp = currentRoute.checkpoints[currentCheckpoint]
			if cp then
				local dist = #(coords - cp)
				local isFinish = currentCheckpoint == #currentRoute.checkpoints
				if dist < (isFinish and Config.FinishRadius or Config.CheckpointRadius) then
					if isFinish then
						TriggerServerEvent("sinister_racing:playerFinished", currentRoute.id)
						notify("FINISHED! Waiting for results...", "success")
						cleanupRace()
					else
						currentCheckpoint = currentCheckpoint + 1
						setCheckpointBlip(currentRoute.checkpoints[currentCheckpoint], currentCheckpoint == #currentRoute.checkpoints)
						notify("Checkpoint " .. (currentCheckpoint - 1) .. "/" .. #currentRoute.checkpoints .. " passed!", "success")
					end
				end
			end
		end
	end
end)

RegisterCommand("joinrace", function(_, args)
	local lobbyId = tonumber(args[1])
	if not lobbyId then
		notify("Usage: /joinrace [lobbyId]", "error")
		return
	end
	TriggerServerEvent("sinister_racing:joinLobby", lobbyId)
end, false)

RegisterCommand("leaverace", function()
	if not isRacing and not raceStarted then
		TriggerServerEvent("sinister_racing:leaveLobby")
		return
	end
	TriggerServerEvent("sinister_racing:playerQuit")
	cleanupRace()
	notify("You left the race.", "inform")
end, false)

RegisterNetEvent("sinister_racing:joinedLobby")
AddEventHandler("sinister_racing:joinedLobby", function()
	notify("You joined the race lobby! Wait for the host to start.", "success")
end)

RegisterNetEvent("sinister_racing:raceResult")
AddEventHandler("sinister_racing:raceResult", function(data)
	local placement = data.placement or "?"
	lib.notify({
		title = "🏁 Race Results",
		description = "You placed #" .. placement .. "! " .. (data.winnings and "+$" .. data.winnings or ""),
		type = placement == 1 and "success" or "inform",
		duration = 8000,
	})
end)

RegisterNetEvent("sinister_racing:policeAlert")
AddEventHandler("sinister_racing:policeAlert", function(msg)
	lib.notify({ title = "🚔 Police Alert", description = msg, type = "error", duration = 8000 })
end)

AddEventHandler("onResourceStart", function(resource)
	if resource == GetCurrentResourceName() then
		local org = Config.RaceOrganizer
		RequestModel(org.model)
		while not HasModelLoaded(org.model) do Wait(10) end
		local ped = CreatePed(0, org.model, org.coords.x, org.coords.y, org.coords.z - 1.0, org.coords.w, false, true)
		SetEntityAsMissionEntity(ped, true, true)
		FreezeEntityPosition(ped, true)
		SetBlockingOfNonTemporaryEvents(ped, true)

		organizerPoint = lib.points.new({
			coords = vec3(org.coords.x, org.coords.y, org.coords.z),
			distance = 3.0,
		})

		function organizerPoint:onEnter()
			if not isRacing then
				lib.showTextUI("[E] H-Town Midnight Runs — Underground Racing")
			end
		end

		function organizerPoint:onExit()
			if not isRacing then
				lib.hideTextUI()
			end
		end

		function organizerPoint:nearby()
			if IsControlJustPressed(0, 38) and not isRacing then
				local p = PlayerPedId()
				if IsPedDeadOrDying(p) then return end
				local veh = GetVehiclePedIsIn(p, false)
				if veh == 0 then
					notify("You need a muscle car to race. Bring one!", "error")
					return
				end
				openRaceMenu()
			end
		end
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		if organizerPoint then organizerPoint:remove() end
		cleanupRace()
	end
end)

print("^5[sinister_racing] ^7Client ready — H-Town Midnight Runs | /leaverace, /joinrace")
