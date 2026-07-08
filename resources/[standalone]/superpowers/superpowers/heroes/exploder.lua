local _h2 = nil

AddEventHandler("getHero", function(heroName)
    _h2 = heroName
    f2()
end)


function f2()
    if _h2 == "exploder" then
_menuPool= NativeUI.CreatePool()
    mainMenu = NativeUI.CreateMenu("EXPLODER", "~b~Explosive Hero")
    _menuPool:Add(mainMenu)
    local explosive = false
    local bulletproof = false
    local jump = false
    local heal = false
    local gg = true
        local v = true
    function ExploderItem(menu)
        click= NativeUI.CreateItem("~b~=> ~r~Explosive Punch", " ~Punch like a misile!~")
        click2= NativeUI.CreateItem("~b~=> ~r~Bulletproof Vest", " ~Top Secret Vest of Area 51~")
        click3= NativeUI.CreateItem("~b~=> ~r~Super Jump", " ~Top Secret Shoes of Area 51~")
        click4= NativeUI.CreateItem("~b~=> ~r~GodMode (Against Players)", " ~Top Secret Drink of Area 51~")
        menu:AddItem(click)
        menu:AddItem(click3)
        menu:AddItem(click4)
        menu:AddItem(click2)
        menu.OnItemSelect = function(sender,item,index)
            if item == click then
                if explosive == false then
                    explosive = true
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Explosive Punch Enabled")
                else
                    explosive = false
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Explosive Punch Disabled")
                end
            end
            if item == click2 then
                if bulletproof == false then
                    bulletproof = true
                    SetPedArmour(PlayerPedId(), 100)
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Bulletproof Vest Refilled")
                else
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Bulletproof Vest In Cooldown")
                end
            end
            if item == click3 then
                if jump == false then
                    jump = true
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Super Jump Shoes Enabled")
                else
                    jump = false
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ Super Jump Shoes Disabled")
                end
            end
            if item == click4 then
                if v then
                    v = false
                    gg = false
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ GodMode Active")
                    SetEntityCanBeDamaged(PlayerPedId(), true)
                    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
                else
                    TriggerEvent("chatMessage", "~r~[EXPLODER]~b~ GodMode In Cooldown")
                end
            end
        end
    end

    ExploderItem(mainMenu)
    _menuPool:RefreshIndex()

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
            if explosive then
                local JP_awZeuWK8USwoI, l41HxMdVNfxuq = GetPedLastWeaponImpactCoord(PlayerPedId())
                if JP_awZeuWK8USwoI then
                    AddExplosion(l41HxMdVNfxuq.x, l41HxMdVNfxuq.y, l41HxMdVNfxuq.z, 2, 100000.0, true, false, 0)
                end
                SetExplosiveMeleeThisFrame(PlayerId())
            end
            if jump then
                SetSuperJumpThisFrame(PlayerId())
            end
        end
    end)
    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            if bulletproof then
                Citizen.Wait(1800000)
                bulletproof = false
            end
        end
    end)
    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            if heal then
                Citizen.Wait(1800000)
                heal = false
            end
        end
    end)
    Citizen.CreateThread(function()
        while true do  
            Citizen.Wait(0)
            _menuPool:ProcessMenus()
            if IsControlJustPressed(0, ExploderConfig.MenuKey) then
                mainMenu:Visible(not mainMenu:Visible())
            end
        end
    end)
end
end