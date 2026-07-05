local db = {}

function db.ensureTables()
    local createPurchases = [[
        CREATE TABLE IF NOT EXISTS sinister_purchases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            transaction_id VARCHAR(128) NOT NULL UNIQUE,
            player_identifier VARCHAR(64) NOT NULL,
            player_name VARCHAR(128) DEFAULT NULL,
            package_name VARCHAR(255) NOT NULL,
            package_category VARCHAR(64) DEFAULT NULL,
            price DECIMAL(10,2) DEFAULT 0.00,
            reward_type VARCHAR(64) DEFAULT NULL,
            reward_data TEXT DEFAULT NULL,
            status ENUM('pending','redeemed','failed','refunded') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            redeemed_at TIMESTAMP NULL DEFAULT NULL,
            INDEX idx_player_identifier (player_identifier),
            INDEX idx_status (status),
            INDEX idx_transaction (transaction_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]

    local createVehicles = [[
        CREATE TABLE IF NOT EXISTS player_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL,
            vehicle VARCHAR(128) NOT NULL,
            plate VARCHAR(16) NOT NULL,
            garage VARCHAR(64) DEFAULT 'pillboxgarage',
            state INT DEFAULT 1,
            mods LONGTEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid),
            INDEX idx_plate (plate)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]

    local createVip = [[
        CREATE TABLE IF NOT EXISTS sinister_vip (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL UNIQUE,
            tier VARCHAR(32) DEFAULT 'silver',
            purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL DEFAULT NULL,
            INDEX idx_citizenid (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]

    local createPurchaseLog = [[
        CREATE TABLE IF NOT EXISTS sinister_purchase_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            transaction_id VARCHAR(128) DEFAULT NULL,
            player_identifier VARCHAR(64) NOT NULL,
            package_name VARCHAR(255) NOT NULL,
            action VARCHAR(64) NOT NULL,
            result VARCHAR(32) DEFAULT 'success',
            details TEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_player (player_identifier),
            INDEX idx_transaction (transaction_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]

    MySQL.query.await(createPurchases)
    MySQL.query.await(createVehicles)
    MySQL.query.await(createVip)
    MySQL.query.await(createPurchaseLog)
    print("[sinister_store] Database tables ensured.")
end

function db.insertPurchase(transactionId, playerIdentifier, playerName, packageName, packageCategory, price, rewardType, rewardData)
    return MySQL.insert.await('INSERT INTO sinister_purchases (transaction_id, player_identifier, player_name, package_name, package_category, price, reward_type, reward_data, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        transactionId,
        playerIdentifier,
        playerName,
        packageName,
        packageCategory,
        price,
        rewardType,
        json.encode(rewardData or {}),
        'pending'
    })
end

function db.getPendingPurchases(playerIdentifier)
    return MySQL.query.await('SELECT * FROM sinister_purchases WHERE player_identifier = ? AND status = ?', { playerIdentifier, 'pending' })
end

function db.getAllPendingPurchases()
    return MySQL.query.await('SELECT * FROM sinister_purchases WHERE status = ?', { 'pending' })
end

function db.markRedeemed(transactionId)
    return MySQL.update.await('UPDATE sinister_purchases SET status = ?, redeemed_at = NOW() WHERE transaction_id = ?', { 'redeemed', transactionId })
end

function db.markFailed(transactionId, reason)
    return MySQL.update.await('UPDATE sinister_purchases SET status = ? WHERE transaction_id = ?', { 'failed', transactionId })
    if reason then
        MySQL.insert.await('INSERT INTO sinister_purchase_log (transaction_id, player_identifier, package_name, action, result, details) VALUES (?, ?, ?, ?, ?, ?)', {
            transactionId, '', '', 'failed', 'failure', tostring(reason)
        })
    end
end

function db.markRefunded(transactionId)
    return MySQL.update.await('UPDATE sinister_purchases SET status = ? WHERE transaction_id = ?', { 'refunded', transactionId })
end

function db.purchaseExists(transactionId)
    local result = MySQL.single.await('SELECT id FROM sinister_purchases WHERE transaction_id = ?', { transactionId })
    return result ~= nil
end

function db.getPurchaseCount(playerIdentifier)
    local result = MySQL.single.await('SELECT COUNT(*) as count FROM sinister_purchases WHERE player_identifier = ? AND status = ?', { playerIdentifier, 'pending' })
    return result and result.count or 0
end

function db.logAction(transactionId, playerIdentifier, packageName, action, result, details)
    return MySQL.insert.await('INSERT INTO sinister_purchase_log (transaction_id, player_identifier, package_name, action, result, details) VALUES (?, ?, ?, ?, ?, ?)', {
        transactionId, playerIdentifier, packageName, action, result or 'success', details or ''
    })
end

return db
