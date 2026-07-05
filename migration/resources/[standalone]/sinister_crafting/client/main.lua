local stationPoints = {}
local isCrafting = false

local function notify(msg, type)
	lib.notify({ title = "Crafting", description = msg, type = type or "inform", icon = Config.NotifyIcon, iconColor = Config.UIColor })
end

local function loadStations()
	for _, pt in ipairs(stationPoints) do
		pt:remove()
	end
	stationPoints = {}

	for _, station in ipairs(Config.Stations) do
		local point = lib.points.new({
			coords = station.coords,
			distance = 3.0,
		})

		function point:onEnter()
			if not isCrafting then
				lib.showTextUI("[E] Use " .. station.name .. "\n" .. station.category)
			end
		end

		function point:onExit()
			if not isCrafting then
				lib.hideTextUI()
			end
		end

		function point:nearby()
			if IsControlJustPressed(0, 38) and not isCrafting then
				local ped = PlayerPedId()
				if IsPedDeadOrDying(ped) then return end
				if IsPedInAnyVehicle(ped, false) then
					notify("Exit vehicle to use crafting station.", "error")
					return
				end
				openCraftingMenu(station)
			end
		end

		stationPoints[#stationPoints + 1] = point
	end
end

function openCraftingMenu(station)
	local recipes = {}
	for _, recipe in ipairs(station.recipes) do
		local ingredientsStr = {}
		for _, ing in ipairs(recipe.ingredients) do
			ingredientsStr[#ingredientsStr + 1] = ing.count .. "x " .. ing.item
		end
		local desc = "Requires: " .. table.concat(ingredientsStr, ", ") .. " | Time: " .. (recipe.time / 1000) .. "s"

		recipes[#recipes + 1] = {
			title = recipe.name,
			description = desc,
			icon = station.categoryIcon or "fa-solid fa-gear",
			metadata = {
				{ label = "Ingredients", value = table.concat(ingredientsStr, ", ") },
				{ label = "Result", value = recipe.result.count .. "x " .. recipe.result.item },
				{ label = "Craft Time", value = (recipe.time / 1000) .. " seconds" },
			},
			arrow = true,
			onSelect = function()
				startCrafting(station, recipe)
			end,
		}
	end

	lib.registerContext({
		id = "sinister_crafting_menu",
		title = station.name,
		description = station.category,
		options = recipes,
	})
	lib.showContext("sinister_crafting_menu")
end

function startCrafting(station, recipe)
	local success = lib.callback.await("sinister_crafting:validateIngredients", false, recipe.id)

	if not success then
		notify("Missing ingredients for " .. recipe.name .. "!", "error")
		return
	end

	isCrafting = true

	local cancelled = lib.progressBar({
		duration = recipe.time,
		label = "Crafting: " .. recipe.name,
		useWhileDead = false,
		canCancel = true,
		disable = { move = true, car = true, combat = true },
		anim = { dict = "anim@ambient@business@coc@coc_uncleaned_clean@coke_powder_tray_a", clip = "coke_powder_tray_a" },
	})

	if cancelled then
		isCrafting = false
		notify("Crafting cancelled.", "inform")
		return
	end

	local ped = PlayerPedId()
	local dist = #(GetEntityCoords(ped) - station.coords)
	if dist > 5.0 then
		isCrafting = false
		notify("Too far from station. Crafting failed.", "error")
		return
	end

	TriggerServerEvent("sinister_crafting:craft", recipe.id)
	isCrafting = false
end

RegisterNetEvent("sinister_crafting:craftSuccess")
AddEventHandler("sinister_crafting:craftSuccess", function(recipe)
	notify("Crafted: " .. recipe.name .. " — " .. recipe.result.count .. "x " .. recipe.result.item, "success")
end)

RegisterNetEvent("sinister_crafting:craftFail")
AddEventHandler("sinister_crafting:craftFail", function(msg)
	notify(msg or "Crafting failed.", "error")
end)

AddEventHandler("onResourceStart", function(resource)
	if resource == GetCurrentResourceName() then
		loadStations()
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		for _, pt in ipairs(stationPoints) do
			pt:remove()
		end
		stationPoints = {}
	end
end)

print("^5[sinister_crafting] ^7Client ready — " .. #Config.Stations .. " crafting stations loaded")
