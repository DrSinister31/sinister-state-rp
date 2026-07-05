-- Sinister Interact — Server side (placeholders for future expansion)

-- Carry system
RegisterNetEvent('sinister_interact:carryPlayer', function(targetId)
    local src = source
    TriggerClientEvent('sinister_interact:carryTarget', targetId, src)
end)

-- GPS share
RegisterNetEvent('sinister_interact:shareGPS', function(coords, label)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'GPS Shared',
        description = 'Waypoint sent: ' .. (label or 'Location'),
        type = 'inform',
    })
end)

print('^2[sinister_interact] ^7Server ready')
