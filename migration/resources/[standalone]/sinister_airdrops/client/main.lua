local currentCrate = nil
local crateBlip = nil
local planeBlip = nil
local planeEntity = nil
local crateEntity = nil
local crateObject = nil
local isOpening = false
local activeZone = nil
local lastDropTime = {}
local flareObject = nil

local function notify(msg, type)
	lib.notify({ title = "Airdrop", description = msg, type = type or "inform" })
end

local function removeBlips()
	if crateBlip then RemoveBlip(crateBlip) crateBlip = nil end
	if planeBlip then RemoveBlip(planeBlip) planeBlip = nil end
end

local function removeEntities()
	if DoesEntityExist(crateObject) then DeleteEntity(crateObject) end
	if DoesEntityExist(planeEntity) then DeleteEntity(planeEntity) end
	if DoesEntityExist(flareObject) then DeleteObject(flareObject) end
	crateObject = nil
	planeEntity = nil
	flareObject = nil
end

local function cleanupCrate()
	removeBlips()
	removeEntities()
	currentCrate = nil
	isOpening = false
	activeZone = nil
	lib.hideTextUI()
end

--- Throw flare at player position
local function throwFlare()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local heading = GetEntityHeading(ped)
	local forward = vec3(-math.sin(math.rad(heading)), 0.0, math.cos(math.rad(heading)))

	RequestAnimDict("weapons@projectile@")
	while not HasAnimDictLoaded("weapons@projectile@") do Wait(0) end
	TaskPlayAnim(ped, "weapons@projectile@", "throw_m", 8.0, -8.0, -1, 0, 0, false, false, false)
	Wait(800)
	ClearPedTasks(ped)

	local target = coords + forward * 25.0
	target = vec3(target.x, target.y, GetGroundZFor_3dCoord(target.x, target.y, target.z, false) or target.z)

	flareObject = CreateObject("prop_flare_01b", target.x, target.y, target.z - 1.0, true, true, false)
	SetEntityAsMissionEntity(flareObject, true, true)
	PlaceObjectOnGroundProperly(flareObject)

	TriggerServerEvent("sinister_airdrops:requestDrop", target)
	notify("Flare deployed! Aircraft inbound to " .. (activeZone and activeZone.label or "drop zone"), "success")
end

RegisterCommand("callairdrop", function()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local closestZone = nil
	local closestDist = 99999.0

	for _, zone in ipairs(Config.Zones) do
		local dist = #(coords - zone.coords)
		if dist < 300.0 and dist < closestDist then
			closestDist = dist
			closestZone = zone
		end
	end

	if not closestZone then
		notify("You're too far from any drop zone. Head to Killeen, Galveston, Ft. Worth, Third Ward, Montrose, or the Bayou.", "error")
		return
	end

	local now = os.time()
	if lastDropTime[closestZone.id] and (now - lastDropTime[closestZone.id]) < (Config.CooldownPerZone * 60) then
		local remaining = math.ceil((Config.CooldownPerZone * 60) - (now - lastDropTime[closestZone.id]))
		notify("Zone too hot. Cooldown: " .. remaining .. "s remaining for " .. closestZone.label, "error")
		return
	end

	activeZone = closestZone
	throwFlare()
end, false)

--- Plane flyover animation
RegisterNetEvent("sinister_airdrops:planeFlyover")
AddEventHandler("sinister_airdrops:planeFlyover", function(data)
	local zone = data.zone
	local cratePos = data.cratePos
	local planeStart = data.planeStart
	local planeEnd = data.planeEnd

	RequestModel(Config.PlaneModel)
	while not HasModelLoaded(Config.PlaneModel) do Wait(10) end

	planeEntity = CreateVehicle(Config.PlaneModel, planeStart.x, planeStart.y, planeStart.z + 200.0, 0.0, true, true)
	SetEntityAsMissionEntity(planeEntity, true, true)
	SetVehicleEngineOn(planeEntity, true, true, false)
	SetVehicleForwardSpeed(planeEntity, 80.0)

	local pilot = CreatePedInsideVehicle(planeEntity, 26, GetHashKey("s_m_m_pilot_02"), -1, true, true)
	SetEntityAsMissionEntity(pilot, true, true)
	SetBlockingOfNonTemporaryEvents(pilot, true)
	TaskPlaneMission(pilot, planeEntity, planeStart.x, planeStart.y, planeStart.z + 200.0, planeEnd.x, planeEnd.y, planeEnd.z + 200.0, 4, 80.0, 0.0, 0.0, 0.0, 0.0)

	planeBlip = AddBlipForEntity(planeEntity)
	SetBlipSprite(planeBlip, Config.PlaneBlipSprite)
	SetBlipColour(planeBlip, Config.PlaneBlipColor)
	SetBlipScale(planeBlip, 1.2)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(Config.PlaneBlipLabel)
	EndTextCommandSetBlipName(planeBlip)

	SetTimeout(15000, function()
		if DoesEntityExist(planeEntity) then DeleteEntity(planeEntity) end
		if planeBlip then RemoveBlip(planeBlip) planeBlip = nil end
	end)
end)

--- Kamikaze dive
RegisterNetEvent("sinister_airdrops:kamikazeDive")
AddEventHandler("sinister_airdrops:kamikazeDive", function(data)
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)

	notify("⚠️ " .. Config.KamikazeName .. " IS GOING ROGUE — RUN!", "error")

	local kamikazePlane = data.planeEntity
	if DoesEntityExist(kamikazePlane) then
		SetEntityCoords(kamikazePlane, coords.x, coords.y, coords.z + 200.0)
		SetVehicleForwardSpeed(kamikazePlane, 120.0)
		SetVehicleEngineOn(kamikazePlane, true, true, false)
	end

	SetTimeout(8000, function()
		AddExplosion(coords.x + math.random(-10, 10), coords.y + math.random(-10, 10), coords.z, 4, 10.0, true, false, 2.0)
		if DoesEntityExist(kamikazePlane) then DeleteEntity(kamikazePlane) end
		notify("💥 CROP DUSTER CRASHED — area is hot!", "error")
	end)
end)

--- Spawn crate at drop point
RegisterNetEvent("sinister_airdrops:spawnCrate")
AddEventHandler("sinister_airdrops:spawnCrate", function(data)
	local pos = data.coords
	activeZone = data.zone

	RequestModel(Config.CrateModel)
	while not HasModelLoaded(Config.CrateModel) do Wait(10) end

	crateObject = CreateObject(Config.CrateModel, pos.x, pos.y, pos.z, true, true, true)
	SetEntityAsMissionEntity(crateObject, true, true)
	PlaceObjectOnGroundProperly(crateObject)
	FreezeEntityPosition(crateObject, true)

	crateBlip = AddBlipForEntity(crateObject)
	SetBlipSprite(crateBlip, 478)
	SetBlipColour(crateBlip, 1)
	SetBlipScale(crateBlip, 1.0)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Supply Crate — " .. data.zone.label)
	EndTextCommandSetBlipName(crateBlip)

	currentCrate = {
		id = data.id,
		zone = data.zone,
		coords = pos,
	}

	notify("📦 Crate dropped at " .. data.zone.label .. "! Stand near it to open.", "success")

	Citizen.CreateThread(function()
		Wait(Config.CrateStayTime)
		if currentCrate and currentCrate.id == data.id then
			cleanupCrate()
			notify("Crate at " .. data.zone.label .. " has despawned.", "inform")
		end
	end)
end)

--- Crate interaction loop
Citizen.CreateThread(function()
	while true do
		Wait(500)
		if currentCrate and crateObject and DoesEntityExist(crateObject) then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			local dist = #(coords - currentCrate.coords)
			if dist < 2.5 and not isOpening then
				lib.showTextUI("[E] Open Crate — " .. currentCrate.zone.label .. "\nStand your ground for " .. (Config.CrateOpenTime / 1000) .. "s")
				if IsControlJustPressed(0, 38) then
					TriggerServerEvent("sinister_airdrops:openCrate", currentCrate.id)
				end
			elseif dist > 3.0 and isOpening then
				isOpening = false
				TriggerServerEvent("sinister_airdrops:cancelOpen", currentCrate.id)
				lib.hideTextUI()
				notify("Opening cancelled — you moved away!", "error")
			end
		else
			if currentCrate and (not crateObject or not DoesEntityExist(crateObject)) then
				cleanupCrate()
			end
		end
	end
end)

RegisterNetEvent("sinister_airdrops:startOpening")
AddEventHandler("sinister_airdrops:startOpening", function()
	isOpening = true
	lib.progressBar({
		duration = Config.CrateOpenTime,
		label = "Opening supply crate...",
		useWhileDead = false,
		canCancel = true,
		disable = { move = true, car = true, combat = true },
		anim = { dict = "mini@repair", clip = "fixing_a_ped" },
	})
end)

RegisterNetEvent("sinister_airdrops:stopOpening")
AddEventHandler("sinister_airdrops:stopOpening", function()
	isOpening = false
	lib.cancelProgressBar()
	lib.hideTextUI()
end)

RegisterNetEvent("sinister_airdrops:lootReceived")
AddEventHandler("sinister_airdrops:lootReceived", function(loot)
	local msg = "Crate opened! Loot: "
	local items = {}
	for _, item in ipairs(loot) do
		items[#items + 1] = item.count .. "x " .. item.label
	end
	msg = msg .. table.concat(items, ", ")
	notify(msg, "success")
	cleanupCrate()
end)

RegisterNetEvent("sinister_airdrops:lootEmpty")
AddEventHandler("sinister_airdrops:lootEmpty", function()
	notify("The crate was empty... better luck next time.", "inform")
	cleanupCrate()
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		cleanupCrate()
	end
end)

print("^5[sinister_airdrops] ^7Client ready — /callairdrop to deploy flare")
