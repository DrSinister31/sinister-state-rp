local __112h = nil

AddEventHandler("getHero", function(heroName)
    __112h = heroName
    f6()
end)

function f6()
    if __112h == "vigilante" then
        local strength = true
        local strengthValue = 5.0
        _menuPool= NativeUI.CreatePool()
        mainMenu = NativeUI.CreateMenu("VIGILANTE", "~b~ Super Hero")
        _menuPool:Add(mainMenu)

        function VigilanteItem(menu)
            click= NativeUI.CreateItem("~b~=> ~r~Super Strength", " ~Top Secret Vest of Area 51~")
            menu:AddItem(click)
            menu.OnItemSelect = function(sender,item,index)
            if item == click then
                if strength then
                    strength = false
                    TriggerEvent("chatMessage", "[VIGILANTE]", {255,0,0}, "Super Strength Enabled!")
                else
                    strength = true
                    TriggerEvent("chatMessage", "[VIGILANTE]", {255,0,0}, "Super Strength Disabled!")
                end
            end
        end
    end

    VigilanteItem(mainMenu)
    _menuPool:RefreshIndex()

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
            if strengthValue < 15.0 then
                strengthValue = strengthValue + 1.0
                TriggerEvent("chatMessage", "[VIGILANTE]", {255,0,0}, "You increse your super strengt to "..tostring(strengthValue).."!") 
            else
                TriggerEvent("chatMessage", "[VIGILANTE]", {255,0,0}, "You can't increse your super strengt more!") 
            end
        end)
        else
            TriggerEvent("chatMessage", "[VIGILANTE]", {255,0,0}, "You are currently making an exercise!")
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if strength == false then
                N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), strengthValue) 
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            _menuPool:ProcessMenus()
            if IsControlJustPressed(0, 38) then
                mainMenu:Visible(not mainMenu:Visible())
            end
        end
    end)

    end
end