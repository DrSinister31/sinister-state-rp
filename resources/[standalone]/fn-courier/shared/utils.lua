function loadModel(model) 
    local time = 1000
    if not HasModelLoaded(model) then
		while not HasModelLoaded(model) do
			if time > 0 then 
                time = time - 1 
                RequestModel(model)
			else 
                time = 1000 
                break
			end
			Wait(10)
		end
	end
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(3)
	end
end

function makeBlip(data)
    local blip = AddBlipForCoord(data.coords)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.colour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, data.scale)
	SetBlipDisplay(blip, data.display or 4)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(data.label)
	EndTextCommandSetBlipName(blip)
end

function makePed(model, coords, freeze, collision, scenario, anim)
	loadModel(model)
	local ped = CreatePed(0, model, coords.x, coords.y, coords.z-1.03, coords.w, false, false)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, freeze or true)
    if collision then SetEntityNoCollisionEntity(ped, PlayerPedId(), false) end
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    if anim then
        loadAnimDict(anim[1])
        TaskPlayAnim(ped, anim[1], anim[2], 1.0, 1.0, -1, 1, 0.2, 0, 0, 0)
    end
    return ped
end

function triggerNotify(title, icon, message, type, src)
	if Config.Notify == "okok" then
		if not src then	exports['okokNotify']:Alert(title, message, 6000, type)
		else TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type) end
	elseif Config.Notify == "qb" then
		if not src then	TriggerEvent("QBCore:Notify", message, type)
		else TriggerClientEvent("QBCore:Notify", src, message, type) end
	elseif Config.Notify == "t" then
		if not src then exports['t-notify']:Custom({title = title, style = type, message = message, sound = true})
		else TriggerClientEvent('t-notify:client:Custom', src, { style = type, duration = 6000, title = title, message = message, sound = true, custom = true}) end
	elseif Config.Notify == "infinity" then
		if not src then TriggerEvent('infinity-notify:sendNotify', message, type)
		else TriggerClientEvent('infinity-notify:sendNotify', src, message, type) end
	elseif Config.Notify == "rr" then
		if not src then exports.rr_uilib:Notify({msg = message, type = type, style = "dark", duration = 6000, position = "top-right", })
		else TriggerClientEvent("rr_uilib:Notify", src, {msg = message, type = type, style = "dark", duration = 6000, position = "top-right", }) end
	elseif Config.Notify == "ox" then
		if not src then	exports.ox_lib:notify({title = title, description = message, type = type or "success"})
		else TriggerClientEvent('ox_lib:notify', src, { type = type or "success", title = title, description = message }) end
    end
end

function DistanceToBone(vehicle, bone, distance)
    if distance then
        local offset = distance
    else
        offset = 1.5
    end
    local BonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, bone))
    local PlayerPos = GetEntityCoords(PlayerPedId())
    if #(BonePos - PlayerPos) > offset then
        return true
    else
        return false
    end
end

function playAnim(time)
    lib.playAnim(cache.ped, 'amb@prop_human_bum_bin@base', 'base', 3.0, 3.0, -1, 16, 0, false, false, false)
    local play = true
    CreateThread(function()
        while play do
            lib.playAnim(cache.ped, 'amb@prop_human_bum_bin@base', 'base', 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(1000)
            time = time - 1
            if time <= 0 then
                play = false
                StopAnimTask(cache.ped, 'amb@prop_human_bum_bin@base', 'base', 1.0)
            end
        end
    end)
end