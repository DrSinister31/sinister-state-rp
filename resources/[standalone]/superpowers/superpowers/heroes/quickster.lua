local _h4 = nil

AddEventHandler("getHero", function(heroName)
    _h4 = heroName
    f4()
end)

_menuPool= NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu("QUICKSTER", "~b~Quickster Hero")
_menuPool:Add(mainMenu)

local run = true
local swim = true
local strength = true
local health = true
local gg = true
        local v = true
function f4()
    if _h4 == "quickster" then
function ExploderItem(menu)
    click= NativeUI.CreateItem("~b~=> ~r~Super Run", " ~Run like a plane!~")
    click2= NativeUI.CreateItem("~b~=> ~r~Fast Swim", " ~Top Secret Vest of Area 51~")
    click3= NativeUI.CreateItem("~b~=> ~r~Super Strength", " ~Top Secret Gloves of Area 51~")
    click4= NativeUI.CreateItem("~b~=> ~r~GodMode (Against Players)", " ~Top Secret Drink of Area 51~")
    menu:AddItem(click)
    menu:AddItem(click2)
    menu:AddItem(click3)
    menu:AddItem(click4)
    menu.OnItemSelect = function(sender,item,index)
        if item == click then
            if run then
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Run Enabled!")
                run = false
            else
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Run Disabled!")
                run = true
            end
        end
        if item == click2 then
            if swim then
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Swim Enabled!")
                SetSwimMultiplierForPlayer(PlayerId(), 1.49)
                swim = false
            else
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Swim Disabled!")
                SetSwimMultiplierForPlayer(PlayerId(), 1.00)
                swim = true
            end
        end
        if item == click3 then
            if strength then
                strength = false
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Strength Enabled!")
            else
                strength = true
                TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "Super Strength Disabled!")
            end
        end
        if item == click4 then
            if v then
                v = false
                gg = false
                TriggerEvent("chatMessage", "~r~[QUICKSTER]~b~ GodMode Active")
                SetEntityCanBeDamaged(PlayerPedId(), true)
                SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
            else
                TriggerEvent("chatMessage", "~r~[QUICKSTER]~b~ GodMode In Cooldown")
            end
        end
    end
end

ExploderItem(mainMenu)
_menuPool:RefreshIndex()

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

local vehVal = 5.0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if run == false then
            SetPedMoveRateOverride(PlayerPedId(), vehVal)
        end
        if strength == false then
            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), QuicksterConfig.Damage) 
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
        if vehVal < 25.0 then
            vehVal = vehVal + 1.0
            TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "You increse your super run to "..tostring(vehVal).."!") 
        else
            TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "You can't increse your super run more!") 
        end
    end)
    else
        TriggerEvent("chatMessage", "[QUICKSTER]", {255,0,0}, "You are currently making an exercise!")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
            if health == false then
                Citizen.Wait(1800000)
                health = true
            end
    end
end)

Citizen.CreateThread(function()
    while true do  
        Citizen.Wait(0)
        _menuPool:ProcessMenus()
        if IsControlJustPressed(0, QuicksterConfig.MenuKey) then
            mainMenu:Visible(not mainMenu:Visible())
        end
    end
end)
end
end