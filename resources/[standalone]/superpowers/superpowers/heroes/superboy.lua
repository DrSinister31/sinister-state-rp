local __11h = nil

AddEventHandler("getHero", function(heroName)
    __11h = heroName
    f5()
end)

function f5()
    if __11h == "superboy" then
        local strength = true
        local swim = true
        local jump = true
        local bulletproof = true
        local heal = true
        local gg = true
        local v = true
        local run22 = true
        _menuPool= NativeUI.CreatePool()
        mainMenu = NativeUI.CreateMenu("SUPERBOY", "~b~ Super Hero")
        _menuPool:Add(mainMenu)
        local isSkyfall = false

        function SkyFall()
            if not isSkyfall then
                isSkyfall = true
                SetPlayerInvincible(playerPed, true)
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    local playerPos = GetEntityCoords(playerPed)
        
                    GiveWeaponToPed(playerPed, GetHashKey('gadget_parachute'), 1, true, true)
        
                    DoScreenFadeOut(3000)
        
                    SetEntityInvincible(GetPlayerPed(-1), true)
                    SetPlayerInvincible(PlayerId(), true)
                    SetPedCanRagdoll(GetPlayerPed(-1), false)
                    ClearPedBloodDamage(GetPlayerPed(-1))
                    ResetPedVisibleDamage(GetPlayerPed(-1))
                    ClearPedLastWeaponDamage(GetPlayerPed(-1))
                    SetEntityProofs(GetPlayerPed(-1), true, true, true, true, true, true, true, true)
                    SetEntityOnlyDamagedByPlayer(GetPlayerPed(-1), false)
                    SetEntityCanBeDamaged(GetPlayerPed(-1), false)

                    while not IsScreenFadedOut() do
                        Wait(0)
                    end
        
                    SetEntityCoords(playerPed, playerPos.x, playerPos.y, playerPos.z + 500.0)
        
                    DoScreenFadeIn(2000)
        
                    Wait(2000)
        
                    SetPlayerInvincible(playerPed, true)
                    SetEntityProofs(playerPed, true, true, true, true, true, false, 0, false)
        
                    while true do
                        if isSkyfall then			
                            if IsPedInParachuteFreeFall(playerPed) and not HasEntityCollidedWithAnything(playerPed) then
                                ApplyForceToEntity(playerPed, true, 0.0, 200.0, 2.5, 0.0, 0.0, 0.0, false, true, false, false, false, true)
                            else
                                isSkyfall = false
                            end
                        else
        
                            break
                        end
        
                        Wait(0)
                    end
        
                    RemoveWeaponFromPed(playerPed, GetHashKey('gadget_parachute'))
        
                    Wait(3000)
        
                    Wait(2000)
                    print("false")
                    SetEntityInvincible(GetPlayerPed(-1), false)
                    SetPlayerInvincible(PlayerId(), false)
                    SetPedCanRagdoll(GetPlayerPed(-1), true)
                    ClearPedBloodDamage(GetPlayerPed(-1))
                    ResetPedVisibleDamage(GetPlayerPed(-1))
                    ClearPedLastWeaponDamage(GetPlayerPed(-1))
                    SetEntityProofs(GetPlayerPed(-1), false, false, false, false, false, false, false, false)
                    SetEntityOnlyDamagedByPlayer(GetPlayerPed(-1), false)
                    SetEntityCanBeDamaged(GetPlayerPed(-1), true)
                end)
            end
    end
    local skyfall = false
        function SuperBoyItem(menu)
            click= NativeUI.CreateItem("~b~=> ~r~Super Strength", " ~Top Secret Vest of Area 51~")
            click2= NativeUI.CreateItem("~b~=> ~r~Super Jump", " ~Be ~")
            click3= NativeUI.CreateItem("~b~=> ~r~Super Swim", " ~Be ~")
            click4= NativeUI.CreateItem("~b~=> ~r~Bulletproof Vest", " ~Top Secret Vest of Area 51~")
            click5= NativeUI.CreateItem("~b~=> ~r~GodMode (Against Players)", " ~Top Secret Drink of Area 51~")
            click6= NativeUI.CreateItem("~b~=> ~r~Super Run", " ~Top Secret Drink of Area 51~")
            click7= NativeUI.CreateItem("~b~=> ~r~Flight Mode", " ~Top Secret Drink of Area 51~")
            menu:AddItem(click)
            menu:AddItem(click2)
            menu:AddItem(click3)
            menu:AddItem(click4)
            menu:AddItem(click5)
            menu:AddItem(click6)
            menu:AddItem(click7)
            menu.OnItemSelect = function(sender,item,index)
            if item == click then
                if strength then
                    strength = false
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Strength Enabled!")
                else
                    strength = true
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Strength Disabled!")
                end
            end
            if item == click2 then
                if jump then
                    jump = false
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Jump Enabled!")
                else
                    jump = true
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Jump Disabled!")
                end
            end
            if item == click3 then
                if swim then
                    swim = false
                    SetSwimMultiplierForPlayer(PlayerId(), 1.49)
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Swim Enabled!")
                else
                    swim = true
                    SetSwimMultiplierForPlayer(PlayerId(), 1.00)
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Super Swim Disabled!")
                end
            end
            if item == click4 then
                if bulletproof then
                    bulletproof = false
                    SetPedArmour(PlayerPedId(), 100)
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Bulletproof refilled!")
                else
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "Bulletproof In Cooldown!")
                end
            end
            if item == click5 then
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
            if item == click6 then
                if run22 then
                    run22 = false
                    TriggerEvent("chatMessage", "~r~[SUPERBOY]~b~ Super Run Enabled")
                else
                    run22 = true
                    TriggerEvent("chatMessage", "~r~[SUPERBOY]~b~ Super Run Disabled")
                end
            end
            if item == click7 then
                if skyfall == false then
                    skyfall = true
                    SkyFall()
                else
                    TriggerEvent("chatMessage", "~r~[SUPERBOY]~b~ FlyMode In Cooldown")
                end
            end
        end
    end
    SuperBoyItem(mainMenu)
    _menuPool:RefreshIndex()
    local runVlue = 2.0
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if run22 == false then
                SetPedMoveRateOverride(PlayerPedId(), runVlue)
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
    local strengthValue = 15.0
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
            if strengthValue < 150.0 or runVlue < 5.0 then
                if runVlue < 5.0 then
                    runVlue = runVlue + 1.0
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "You increse your super run to "..tostring(runVlue).."!")
                end
                if strengthValue < 150.0 then
                    strengthValue = strengthValue + 1.0
                    TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "You increse your super strengt to "..tostring(strengthValue).."!") 
                end
            else
                TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "You can't increse your stats more!") 
            end
        end)
        else
            TriggerEvent("chatMessage", "[SUPERBOY]", {255,0,0}, "You are currently making an exercise!")
        end
    end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if strength == false then
            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), strengthValue) 
        end
        if jump == false then
            SetSuperJumpThisFrame(PlayerId())
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
        if skyfall then
            Citizen.Wait(60000)
            skyfall = false
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
            if bulletproof == false then
                Citizen.Wait(1800000)
                bulletproof = true
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if heal == false then
                Citizen.Wait(1800000)
                heal = true
            end
        end
    end)
    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            _menuPool:ProcessMenus()
            if IsControlJustPressed(0, SuperboyConfig.MenuKey) then
                mainMenu:Visible(not mainMenu:Visible())
            end
        end
    end)
    end
end