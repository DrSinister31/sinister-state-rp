local __h = nil

AddEventHandler("getHero", function(heroName)
    __h = heroName
    f3()
end)

local m = true
local g = true
local e = true
local v = true
local gg = true
local run2 = true

RegisterNetEvent("phormalist_superheroes:superun")
AddEventHandler("phormalist_superheroes:superun", function()
    local b = true
    Citizen.CreateThread(function()
        while b do
            Citizen.Wait(0)
            SetPedMoveRateOverride(PlayerPedId(), ElectricConfig.Velocity)
        end
    end)
    Citizen.CreateThread(function()
        while b do
            Citizen.Wait(5000)
            b = false
        end 
    end)
end)

RegisterNetEvent("phormalist_superheroes:syncParticles")
AddEventHandler("phormalist_superheroes:syncParticles", function(ped)
    ElectricWave(ped)
end)

function f3()
    if __h == "electricman" then
        _menuPool= NativeUI.CreatePool()
        mainMenu = NativeUI.CreateMenu("ELECTRIC MAN", "~b~ Electric Hero")
        _menuPool:Add(mainMenu)
        function ElectricItem(menu)
            click= NativeUI.CreateItem("~b~=> ~r~Electric Sprint", " ~Top Secret Vest of Area 51~")
            click2= NativeUI.CreateItem("~b~=> ~r~Electric Punch", " ~Be ~")
            click3= NativeUI.CreateItem("~b~=> ~r~Bulletproof Vest", " ~Top Secret Vest of Area 51~")
            click4= NativeUI.CreateItem("~b~=> ~r~GodMode (Against Players)", " ~Top Secret Drink of Area 51~")
            click5= NativeUI.CreateItem("~b~=> ~r~Speed Run", " ~Top Secret Drink of Area 51~")
            menu:AddItem(click)
            menu:AddItem(click2)
            menu:AddItem(click3)
            menu:AddItem(click4)
            menu:AddItem(click5)
            menu.OnItemSelect = function(sender,item,index)
            if item == click then
                if m then
                    m = false 
                    TriggerServerEvent("phormalist_superheroes:sendWaveParticles", PlayerPedId())
                else
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Electric Sprint In Cooldown")
                end
            end
            if item == click2 then
                if g then
                    g = false
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Electric Punch Enabled")
                else
                    g = true
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Electric Punch Disabled")
                end
            end
            if item == click3 then
                if e then
                    e = false
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Bulletproof Vest Refilled")
                    SetPedArmour(PlayerPedId(), GetPlayerMaxArmour(PlayerId()))
                else
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Bulletproof Vest In Cooldown")
                end
            end
            if item == click4 then
                if v then
                    v = false
                    gg = false
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ GodMode Active")
                    SetEntityCanBeDamaged(PlayerPedId(), true)
                    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
                else
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ GodMode In Cooldown")
                end
            end
            if item == click5 then
                if run2 then
                    run2 = false
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Speed Run Enabled")
                else
                    run2 = true
                    TriggerEvent("chatMessage", "~r~[ELECTRIC MAN]~b~ Speed Run Disabled")
                end
            end
        end
    end
    local runValue = 1.5
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if run2 == false then
                SetPedMoveRateOverride(PlayerPedId(), runValue)
            end
        end
    end)

    local animations = {
        {dict = "world_human_muscle_free_weights", time = 20}, --Dict is the animation, time is the time that it takes to train in this animation (in seconds)
        {dict = "world_human_push_ups", time = 20}, --Dict is the animation, time is the time that it takes to train in this animation (in seconds)
        {dict = "world_human_yoga", time = 15}, --Dict is the animation, time is the time that it takes to train in this animation (in seconds)
        {dict = "world_human_sit_ups", time = 15} --Dict is the animation, time is the time that it takes to train in this animation (in seconds)
    }
    local isTraining = false
    RegisterCommand("train", function()
        if isTraining == false then
        isTraining = true
        Citizen.CreateThread(function()
            local playerPed = PlayerPedId()
            local _ = math.random(1, #animations)
            TaskStartScenarioInPlace(playerPed, animations[_].dict, 0, true)
            Citizen.Wait(animations[_].time * 1000)
            ClearPedTasks(playerPed)
            isTraining = false
            if runValue < 10.0 then
                runValue = runValue + 1.0
                TriggerEvent("chatMessage", "[ELECTRIC MAN]", {255,0,0}, "You increse your super run to "..tostring(runValue).."!") 
            else
                TriggerEvent("chatMessage", "[ELECTRIC MAN]", {255,0,0}, "You can't increse your super run more!") 
            end
        end)
        else
            TriggerEvent("chatMessage", "[ELECTRIC MAN]", {255,0,0}, "You are currently making an exercise!")
        end
    end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if m == false then
            Citizen.Wait(1800000)
            m = true
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if v == false then
            Citizen.Wait(1800000)
            v = true
        end
    end
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if gg == false then
            Citizen.Wait(300000)
            gg = true
            SetEntityCanBeDamaged(PlayerPedId(), false)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if e == false then
            Citizen.Wait(1800000)
            e = true
        end
    end
end)

    ElectricItem(mainMenu)
    _menuPool:RefreshIndex()

    function ElectricWave(ped)
        local _yh = {}
        local n = true
        Citizen.CreateThread(function()
            while n do
                Citizen.Wait(100)
                if not HasNamedPtfxAssetLoaded("scr_rcbarry1") then
                    RequestNamedPtfxAsset("scr_rcbarry1")
                    while not HasNamedPtfxAssetLoaded("scr_rcbarry1") do
                        Wait(1)
                    end
                end
                if n then
                    SetPtfxAssetNextCall("scr_rcbarry1")
                    table.insert(_yh ,StartParticleFxLoopedAtCoord("scr_alien_teleport",GetEntityCoords(ped), 0.0, 0.0, 0.0, 1.0, false, false, false, false))
                end
            end
        end)
        Citizen.CreateThread(function()
            while n do
                Citizen.Wait(100)
                if not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") then
                    RequestNamedPtfxAsset("veh_xs_vehicle_mods")
                    while not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") do
                        Wait(1)
                    end
                end
                if n then
                    SetPtfxAssetNextCall("veh_xs_vehicle_mods")
                    table.insert(_yh ,StartParticleFxLoopedAtCoord("veh_xs_electrified_rambar",GetEntityCoords(ped), 0.0, 0.0, 0.0, 1.0, false, false, false, false))
                end
            end
        end)
        Citizen.CreateThread(function()
            while n do
                Citizen.Wait(100)
                if not HasNamedPtfxAssetLoaded("des_tv_smash") then
                    RequestNamedPtfxAsset("des_tv_smash")
                    while not HasNamedPtfxAssetLoaded("des_tv_smash") do
                        Wait(1)
                    end
                end
                if n then
                    SetPtfxAssetNextCall("des_tv_smash")
                    table.insert(_yh ,StartParticleFxLoopedAtCoord("ent_sht_electrical_box_sp",GetEntityCoords(ped), 0.0, 0.0, 0.0, 1.0, false, false, false, false))
                end
            end
        end)
        Citizen.CreateThread(function()
            while n do
                Citizen.Wait(6000)
                n = false
                SetPedMoveRateOverride(PlayerPedId(), 1.00)
                for k, v in pairs(_yh) do
                    RemoveParticleFx(v, true)
                end
            end 
        end)
    end

    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            if g == false then
                local JP_awZeuWK8USwoI, l41HxMdVNfxuq = GetPedLastWeaponImpactCoord(PlayerPedId())
                if JP_awZeuWK8USwoI then
                    AddExplosion(l41HxMdVNfxuq.x, l41HxMdVNfxuq.y, l41HxMdVNfxuq.z, 70, 100000.0, true, false, 0)
                    SetPtfxAssetNextCall("core")
                    StartParticleFxLoopedAtCoord("ent_dst_electrical",l41HxMdVNfxuq.x,l41HxMdVNfxuq.y,l41HxMdVNfxuq.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                    SetPtfxAssetNextCall("des_tv_smash")
                    StartParticleFxLoopedAtCoord("ent_sht_electrical_box_sp",l41HxMdVNfxuq.x,l41HxMdVNfxuq.y,l41HxMdVNfxuq.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                end
                SetExplosiveMeleeThisFrame(PlayerId())
            end
        end
    end)

    Citizen.CreateThread(
        function()
            while true do
                local b_ = GetPlayerPed(-1)
                SetExplosiveAmmoThisFrame(b_, 0)
                SetExplosiveMeleeThisFrame(b_, 0)
                SetFireAmmoThisFrame(b_, 0)
                SetEntityProofs(GetPlayerPed(-1), false, true, true, false, false, false, false, false)
                Citizen.Wait(0)
            end
        end
    )

    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            _menuPool:ProcessMenus()
            if IsControlJustPressed(0, ElectricConfig.MenuKey) then
                mainMenu:Visible(not mainMenu:Visible())
            end
        end
    end)
    end
end

RegisterCommand("god", function()
    SetEntityCanBeDamaged()
end)