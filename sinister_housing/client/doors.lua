-- ============================================================================
-- SINISTER HOUSING — Client Door Teleport System
-- ============================================================================

local currentApartment = nil

-- ============================================================================
-- DOOR SPAWNING & TARGETS
-- ============================================================================

CreateThread(function()
    for _, apt in ipairs(Config.Apartments) do
        if Config.BlipEnabled then
            local blip = AddBlipForCoord(apt.coords.x, apt.coords.y, apt.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipScale(blip, 0.7)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(apt.label)
            EndTextCommandSetBlipName(blip)
        end

        exports.ox_target:addSphereZone({
            coords = vec3(apt.coords.x, apt.coords.y, apt.coords.z),
            radius = Config.DoorRange,
            debug = false,
            options = {
                {
                    name = 'apt_enter_' .. apt.id,
                    label = 'Enter ' .. apt.label,
                    icon = 'fa-solid fa-door-open',
                    onSelect = function()
                        TriggerServerEvent('sinister_housing:enter', apt.id)
                    end,
                },
            },
        })
    end
end)

-- ============================================================================
-- INTERIOR ENTRY / EXIT
-- ============================================================================

RegisterNetEvent('sinister_housing:teleportIn', function(aptId)
    for _, apt in ipairs(Config.Apartments) do
        if apt.id == aptId then
            currentApartment = apt
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(PlayerPedId(), apt.inside.x, apt.inside.y, apt.inside.z)
            SetEntityHeading(PlayerPedId(), apt.inside.w)
            Wait(200)
            DoScreenFadeIn(500)

            -- Create exit target inside
            local exitCoords = vec3(apt.inside.x, apt.inside.y, apt.inside.z)
            exports.ox_target:addSphereZone({
                coords = exitCoords,
                radius = 1.5,
                debug = false,
                options = {
                    {
                        name = 'apt_exit_' .. apt.id,
                        label = 'Exit Apartment',
                        icon = 'fa-solid fa-door-closed',
                        onSelect = function()
                            leaveApartment()
                        end,
                    },
                },
            })
            break
        end
    end
end)

function leaveApartment()
    if not currentApartment then return end
    local apt = currentApartment
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), apt.coords.x, apt.coords.y, apt.coords.z)
    SetEntityHeading(PlayerPedId(), apt.coords.w)
    Wait(200)
    DoScreenFadeIn(500)
    currentApartment = nil
    TriggerEvent('sinister_housing:removeInteriorZones', apt.id)
end

RegisterNetEvent('sinister_housing:removeInteriorZones', function(aptId)
    exports.ox_target:removeZone('apt_exit_' .. aptId)
end)

-- Command for /leavehouse
RegisterCommand('leavehouse', function()
    leaveApartment()
end, false)

RegisterCommand('leavemansion', function()
    leaveApartment()
end, false)
