-- ============================================================================
-- SINISTER HOUSING — Server Ownership System
-- ============================================================================

local ownedApartments = {}

-- Create table on startup
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS sinister_apartments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            apt_id VARCHAR(50) NOT NULL UNIQUE,
            citizenid VARCHAR(50) NOT NULL,
            purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            rent_due_at TIMESTAMP NULL,
            rent_paid TINYINT DEFAULT 1,
            INDEX idx_citizenid (citizenid),
            INDEX idx_apt_id (apt_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    print('^2[sinister_housing] ^7Database ready')
end)

-- ============================================================================
-- ENTER APARTMENT
-- ============================================================================

RegisterNetEvent('sinister_housing:enter', function(aptId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local apt = nil
    for _, a in ipairs(Config.Apartments) do
        if a.id == aptId then apt = a; break end
    end
    if not apt then return end

    -- Check ownership
    local result = MySQL.query.await('SELECT citizenid FROM sinister_apartments WHERE apt_id = ?', { aptId })
    local owner = result and result[1] and result[1].citizenid

    if not owner then
        -- Unlocked — offer purchase
        TriggerClientEvent('ox_lib:notify', src, {
            title = apt.label,
            description = string.format('For Sale: $%d | Rent: $%d/week\nUse /buyhouse to purchase', apt.price, apt.rent),
            type = 'inform',
            duration = 8000,
        })
        -- Still let them tour
        TriggerClientEvent('sinister_housing:teleportIn', src, aptId)
        return
    end

    if owner == cid then
        -- Owner — free entry
        TriggerClientEvent('sinister_housing:teleportIn', src, aptId)
        return
    end

    -- Someone else owns it — check if they allow visitors (for now, locked)
    TriggerClientEvent('ox_lib:notify', src, {
        title = apt.label,
        description = 'This property is owned by another resident.',
        type = 'error',
    })
end)

-- ============================================================================
-- PURCHASE APARTMENT
-- ============================================================================

RegisterCommand('buyhouse', function(source)
    local src = source
    if src <= 0 then return end
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    -- Find nearest apartment
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)

    local nearest = nil
    local nearestDist = Config.DoorRange
    for _, apt in ipairs(Config.Apartments) do
        local dist = #(pCoords - vec3(apt.coords.x, apt.coords.y, apt.coords.z))
        if dist < nearestDist then
            nearestDist = dist
            nearest = apt
        end
    end

    if not nearest then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Real Estate',
            description = 'Stand near a property door to purchase.',
            type = 'error',
        })
        return
    end

    -- Check if already owned
    local existing = MySQL.query.await('SELECT citizenid FROM sinister_apartments WHERE apt_id = ?', { nearest.id })
    if existing and existing[1] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Real Estate',
            description = 'This property is already owned.',
            type = 'error',
        })
        return
    end

    -- Check bank balance
    local bank = player.Functions.GetMoney('bank')
    if bank < nearest.price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Real Estate',
            description = string.format('You need $%d in your bank. You have $%d.', nearest.price, bank),
            type = 'error',
        })
        return
    end

    -- Purchase
    player.Functions.RemoveMoney('bank', nearest.price, 'property-purchase')
    MySQL.insert.await('INSERT INTO sinister_apartments (apt_id, citizenid, rent_due_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY))',
        { nearest.id, cid })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Real Estate',
        description = string.format('Congratulations! You now own:\n%s', nearest.label),
        type = 'success',
        duration = 10000,
    })

    TriggerClientEvent('sinister_housing:teleportIn', src, nearest.id)
end, false)

-- ============================================================================
-- SELL APARTMENT
-- ============================================================================

RegisterCommand('sellhouse', function(source)
    local src = source
    if src <= 0 then return end
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT apt_id FROM sinister_apartments WHERE citizenid = ? LIMIT 1', { cid })
    if not result or not result[1] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Real Estate',
            description = 'You do not own any property.',
            type = 'error',
        })
        return
    end

    local aptId = result[1].apt_id
    local apt = nil
    for _, a in ipairs(Config.Apartments) do
        if a.id == aptId then apt = a; break end
    end

    local sellPrice = apt and math.floor(apt.price * 0.65) or 50000
    MySQL.query.await('DELETE FROM sinister_apartments WHERE apt_id = ?', { aptId })
    player.Functions.AddMoney('bank', sellPrice, 'property-sale')

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Real Estate',
        description = string.format('Property sold for $%d. Keys surrendered.', sellPrice),
        type = 'success',
    })
end, false)

-- ============================================================================
-- COMMAND: MY PROPERTIES
-- ============================================================================

RegisterCommand('myhouses', function(source)
    local src = source
    if src <= 0 then return end
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT apt_id FROM sinister_apartments WHERE citizenid = ?', { cid })
    if not result or #result == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'My Properties',
            description = 'You do not own any property.',
            type = 'inform',
        })
        return
    end

    local labels = {}
    for _, row in ipairs(result) do
        for _, apt in ipairs(Config.Apartments) do
            if apt.id == row.apt_id then
                labels[#labels + 1] = apt.label
                break
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = string.format('My Properties (%d)', #labels),
        description = table.concat(labels, '\n'),
        type = 'inform',
        duration = 10000,
    })
end, false)

-- ============================================================================
-- PAY RENT (weekly)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        local overdue = MySQL.query.await(
            'SELECT citizenid, apt_id FROM sinister_apartments WHERE rent_due_at < NOW() AND rent_paid = 0')
        if overdue then
            for _, row in ipairs(overdue) do
                -- Flag for Kronus to process eviction
                -- For now just reset rent_due
                MySQL.query.await('UPDATE sinister_apartments SET rent_due_at = DATE_ADD(NOW(), INTERVAL 7 DAY), rent_paid = 1 WHERE apt_id = ?', { row.apt_id })
            end
        end
    end
end)

print('^2[sinister_housing] ^7Server ready — ' .. #Config.Apartments .. ' Texas apartments')
