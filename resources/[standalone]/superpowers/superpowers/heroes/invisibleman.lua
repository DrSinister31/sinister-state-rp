local _h = nil

AddEventHandler("getHero", function(heroName)
    _h = heroName
    f()
end)

function f()
if _h == "invisibleman" then
_menuPool= NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu("INVISIBLE MAN", "~b~ Invisible Hero")
_menuPool:Add(mainMenu)

local isInvisible = false
local strength = false
local heal = false
local gg = true
local v = true
local invisibleList = {}
RegisterNetEvent("phormalist_superheroes:getEntityInvisible")
AddEventHandler("phormalist_superheroes:getEntityInvisible" ,function(playerPedId)
    table.insert(invisibleList, playerPedId)
end)

RegisterNetEvent("phormalist_superheroes:quitEntityInvisibleC")
AddEventHandler("phormalist_superheroes:quitEntityInvisibleC" ,function(playerPedId)
    for k, v in pairs(invisibleList) do
        if invisibleList[k] == playerPedId then
            table.remove(invisibleList, k)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k, v in pairs(invisibleList) do
            if k ~= nil then
                if invisibleList[k] ~= nil then
                    SetEntityLocallyInvisible(invisibleList[k], true)
                end
            end
        end
    end
end)

function SetPlayerInvisible(playerPedId)
    f = true
    Citizen.CreateThread(function()
        while f do
            Citizen.Wait(0)
            SetEntityLocallyInvisible(playerPedId, true)
        end
    end)
    Citizen.CreateThread(function()
        Citizen.Wait(150000)
        f = false
    end)
end

function InvisibleItem(menu)
        click= NativeUI.CreateItem("~b~=> ~r~Invisible Vest", " ~Top Secret Vest of Area 51~")
        click2= NativeUI.CreateItem("~b~=> ~r~Super Strength", " ~Be ~")
        click3= NativeUI.CreateItem("~b~=> ~r~GodMode (Against Players)", " ~Top Secret Drink of Area 51~")
        click4= NativeUI.CreateItem("~b~=> ~r~Quit Invisible Vest", " ~Top Secret Drink of Area 51~")
        menu:AddItem(click)
        menu:AddItem(click2)
        menu:AddItem(click3)
        menu:AddItem(click4)
        menu.OnItemSelect = function(sender,item,index)
        if item == click then
            if isInvisible == false then
                isInvisible = true
                TriggerEvent("chatMessage", "~r~[INVISIBLE MAN]~b~ Invisible Mode Enabled")
                TriggerServerEvent("phormalist_superheroes:setEntityInvisible", PlayerPedId())
            else
                TriggerEvent("chatMessage", "~r~[INVISIBLE MAN]~b~ Invisible Mode In Cooldown")
            end
        end
        if item == click2 then
            if strength == false then
                strength = true
                TriggerEvent("chatMessage", "~r~[INVISIBLE MAN]~b~ Super Strength Enabled")
            else
                strength = false
                TriggerEvent("chatMessage", "~r~[INVISIBLE MAN]~b~ Super Strength Disabled")
            end
        end
        if item == click3 then
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
        if item == click4 then
            TriggerServerEvent("phormalist_superheroes:quitEntityInvisible", PlayerPedId())
        end
    end
end

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
        if isInvisible then
            if finish == true then
                Citizen.Wait(120000)
                isInvisible = false
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInvisible then
            TriggerServerEvent("phormalist_superheroes:setEntityInvisible", PlayerId())
            Citizen.Wait(150000)
            TriggerServerEvent("phormalist_superheroes:setEntityInvisible", PlayerId())
            finish = true
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if strength then
            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), InvisiblemanConfig.Strength)
        end
    end
end)

InvisibleItem(mainMenu)
_menuPool:RefreshIndex()

Citizen.CreateThread(function()
    while true do  
        Citizen.Wait(0)
        _menuPool:ProcessMenus()
        if IsControlJustPressed(0, InvisiblemanConfig.MenuKey) then
            mainMenu:Visible(not mainMenu:Visible())
        end
    end
end)
end
end