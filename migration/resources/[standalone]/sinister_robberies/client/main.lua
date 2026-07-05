local robberyPoints = {}
local isRobbing = false
local currentRobbery = nil
local texasHeat = {}

local function notify(msg, type)
	lib.notify({ title = "Robbery", description = msg, type = type or "inform" })
end

local function cleanupRobbery()
	isRobbing = false
	currentRobbery = nil
	lib.hideTextUI()
end

local function loadRobberies()
	for _, point in ipairs(robberyPoints) do
		point:remove()
	end
	robberyPoints = {}

	for _, robberyType in ipairs(Config.RobberyTypes) do
		for _, loc in ipairs(robberyType.locations) do
			local point = lib.points.new({
				coords = loc.coords,
				distance = 3.0,
			})

			function point:onEnter()
				if not isRobbing then
					lib.showTextUI("[E] " .. robberyType.label .. " — " .. loc.name)
				end
			end

			function point:onExit()
				if not isRobbing then
					lib.hideTextUI()
				end
			end

			function point:nearby()
				if IsControlJustPressed(0, 38) and not isRobbing then
					local ped = PlayerPedId()
					if IsPedDeadOrDying(ped) then return end
					if IsPedInAnyVehicle(ped, false) then
						notify("Exit vehicle to start the robbery.", "error")
						return
					end
					TriggerServerEvent("sinister_robberies:startRobbery", robberyType.type, loc)
				end
			end

			robberyPoints[#robberyPoints + 1] = point
		end
	end
end

RegisterNetEvent("sinister_robberies:robberyStarted")
AddEventHandler("sinister_robberies:robberyStarted", function(data)
	isRobbing = true
	currentRobbery = data

	lib.progressBar({
		duration = Config.RobTime,
		label = data.label .. " in progress...",
		useWhileDead = false,
		canCancel = false,
		disable = { move = true, car = true, combat = true },
		anim = { dict = "mini@repair", clip = "fixing_a_ped" },
	})

	Wait(Config.RobTime)

	local ped = PlayerPedId()
	local dist = #(GetEntityCoords(ped) - data.coords)
	if dist > 5.0 then
		notify("Robbery failed — you moved too far!", "error")
		TriggerServerEvent("sinister_robberies:robberyFailed", data.type, data.name)
		cleanupRobbery()
		return
	end

	TriggerServerEvent("sinister_robberies:robberyComplete", data.type, data.name)
end)

RegisterNetEvent("sinister_robberies:robberyReward")
AddEventHandler("sinister_robberies:robberyReward", function(data)
	local msg = "Robbery complete! "
	if data.money and data.money > 0 then
		msg = msg .. "+$" .. data.money .. " "
	end
	if data.items and #data.items > 0 then
		local itemNames = {}
		for _, item in ipairs(data.items) do
			itemNames[#itemNames + 1] = item.count .. "x " .. item.item
		end
		msg = msg .. table.concat(itemNames, ", ")
	end
	notify(msg, "success")
	texasHeat[currentRobbery.type] = os.time()
	cleanupRobbery()
end)

RegisterNetEvent("sinister_robberies:robberyFailed")
AddEventHandler("sinister_robberies:robberyFailed", function(reason)
	notify("Robbery failed! " .. reason, "error")
	cleanupRobbery()
end)

RegisterNetEvent("sinister_robberies:policeAlert")
AddEventHandler("sinister_robberies:policeAlert", function(msg)
	lib.notify({ title = "🚔 Police Alert", description = msg, type = "error", duration = 8000 })
end)

RegisterNetEvent("sinister_robberies:heatWarning")
AddEventHandler("sinister_robberies:heatWarning", function(data)
	local remaining = data.remaining
	notify("Texas Heat active! " .. remaining .. "s cooldown for " .. data.label, "error")
end)

AddEventHandler("onResourceStart", function(resource)
	if resource == GetCurrentResourceName() then
		loadRobberies()
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		for _, point in ipairs(robberyPoints) do
			point:remove()
		end
		robberyPoints = {}
	end
end)

print("^5[sinister_robberies] ^7Client ready — " .. #robberyPoints .. " robbery locations loaded")
