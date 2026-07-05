-- Made by ChapterDonut - https://www.chapterdonut.com/ → https://discord.gg/YE77ZCMJHj

local lastState = nil

CreateThread(function()
    DecorRegister("engineState", 2)
end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({
        type = "images",
        on = Config.Images.On,
        off = Config.Images.Off
    })
end)

function GetEngineState(veh)
    if DecorExistOn(veh, "engineState") then
        return DecorGetInt(veh, "engineState") == 1
    else
        local running = GetIsVehicleEngineRunning(veh)
        DecorSetInt(veh, "engineState", running and 1 or 0)
        return running
    end
end

function SetEngineState(veh, state)
    DecorSetInt(veh, "engineState", state and 1 or 0)
    SetVehicleEngineOn(veh, state, true, true)
    SetVehicleUndriveable(veh, not state)
end

RegisterCommand("engine_toggle", function()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then return end

    local veh = GetVehiclePedIsIn(ped, false)

    if GetPedInVehicleSeat(veh, -1) ~= ped then return end

    local class = GetVehicleClass(veh)

    if not Config.Categories[class] then return end

    local speed = GetEntitySpeed(veh)

    if speed > 0.1 then return end

    local engineOn = GetEngineState(veh)

    SendNUIMessage({
        type = "click",
        volume = Config.SoundVolume
    })

    if engineOn then
        SetEngineState(veh, false)
    else
        local chance = math.random(1, 100)

        if chance > Config.FailChance then
            SetEngineState(veh, true)
        else
            SetEngineState(veh, false)
        end
    end
end, false)

RegisterKeyMapping('engine_toggle', 'Toggle Vehicle Engine', 'keyboard', 'Z')

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)

            if GetPedInVehicleSeat(veh, -1) == ped then

                local class = GetVehicleClass(veh)

                if Config.Categories[class] then

                    local engineOn = GetEngineState(veh)

                    if GetIsVehicleEngineRunning(veh) ~= engineOn then
                        SetVehicleEngineOn(veh, engineOn, true, true)
                    end

                    SetVehicleUndriveable(veh, not engineOn)

                    if engineOn ~= lastState then
                        if engineOn then
                            SendNUIMessage({
                                type = "on",
                                time = Config.DisplayTime
                            })
                        else
                            SendNUIMessage({type = "off"})
                        end
                        lastState = engineOn
                    end

                else
                    lastState = nil
                    SendNUIMessage({type = "hide"})
                end
            end
        else
            lastState = nil
            SendNUIMessage({type = "hide"})
        end
    end
end)