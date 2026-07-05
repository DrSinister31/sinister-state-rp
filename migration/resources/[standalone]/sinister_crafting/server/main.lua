local allRecipes = {}

for _, station in ipairs(Config.Stations) do
	for _, recipe in ipairs(station.recipes) do
		allRecipes[recipe.id] = recipe
	end
end

local function getRecipe(recipeId)
	return allRecipes[recipeId]
end

local function hasIngredients(src, recipe)
	local inv = exports.ox_inventory:GetInventory(src)
	if not inv then return false end

	for _, ing in ipairs(recipe.ingredients) do
		local found = false
		for _, slot in ipairs(inv.items or {}) do
			if slot.name == ing.item and (slot.count or 0) >= ing.count then
				found = true
				break
			end
		end
		if not found then return false end
	end
	return true
end

local function removeIngredients(src, recipe)
	for _, ing in ipairs(recipe.ingredients) do
		exports.ox_inventory:RemoveItem(src, ing.item, ing.count)
	end
end

local function addResult(src, recipe)
	if recipe.result.item == "dirty_money" then
		local player = exports.qbx_core:GetPlayer(src)
		if player then
			player.Functions.AddMoney("dirty_money", recipe.result.count)
		end
	else
		exports.ox_inventory:AddItem(src, recipe.result.item, recipe.result.count)
	end
end

-- ============================================================================
-- Validate ingredients (callback for client)
-- ============================================================================

lib.callback.register("sinister_crafting:validateIngredients", function(source, recipeId)
	local recipe = getRecipe(recipeId)
	if not recipe then return false end
	return hasIngredients(source, recipe)
end)

-- ============================================================================
-- Execute craft
-- ============================================================================

RegisterNetEvent("sinister_crafting:craft", function(recipeId)
	local src = source
	local recipe = getRecipe(recipeId)
	if not recipe then
		TriggerClientEvent("sinister_crafting:craftFail", src, "Unknown recipe.")
		return
	end

	if not hasIngredients(src, recipe) then
		TriggerClientEvent("sinister_crafting:craftFail", src, "Missing ingredients.")
		return
	end

	removeIngredients(src, recipe)
	addResult(src, recipe)

	TriggerClientEvent("sinister_crafting:craftSuccess", src, recipe)
end)

-- ============================================================================
-- List recipes (admin/debug)
-- ============================================================================

RegisterCommand("listcrafting", function(source)
	local src = source
	local lines = {}
	for _, station in ipairs(Config.Stations) do
		lines[#lines + 1] = "Station: " .. station.name .. " (" .. station.category .. ")"
		for _, recipe in ipairs(station.recipes) do
			lines[#lines + 1] = "  - " .. recipe.name .. " => " .. recipe.result.count .. "x " .. recipe.result.item
		end
	end
	print("^2[sinister_crafting] ^7Loaded recipes:")
	for _, line in ipairs(lines) do
		print(line)
	end
	TriggerClientEvent("ox_lib:notify", src, {
		title = "Crafting Stations",
		description = #Config.Stations .. " stations loaded. Check F8 console.",
		type = "inform",
	})
end, false)

print("^5[sinister_crafting] ^7Server ready — " .. #Config.Stations .. " stations, " .. tablelength(allRecipes) .. " recipes")

function tablelength(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end
