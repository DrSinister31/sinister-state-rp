-- =============================================================================
-- sinister_store Database Installation Script
-- =============================================================================
-- Server: MariaDB at 91.99.71.34:3307
-- Database: s10208_Sinister
-- Resource: sinister_store (Tebex In-Game Store for Sinister H-Town RP)
-- Run this SQL against the s10208_Sinister database before starting the resource.
-- =============================================================================
-- Usage:
--   mysql -h 91.99.71.34 -P 3307 -u u10208_WO0ajxNA1S -p s10208_Sinister < install.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS `sinister_purchases` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` VARCHAR(128) NOT NULL UNIQUE,
    `player_identifier` VARCHAR(64) NOT NULL,
    `player_name` VARCHAR(128) DEFAULT NULL,
    `package_name` VARCHAR(255) NOT NULL,
    `package_category` VARCHAR(64) DEFAULT NULL,
    `price` DECIMAL(10,2) DEFAULT 0.00,
    `reward_type` VARCHAR(64) DEFAULT NULL,
    `reward_data` TEXT DEFAULT NULL,
    `status` ENUM('pending','redeemed','failed','refunded') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `redeemed_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_transaction` (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(64) NOT NULL,
    `vehicle` VARCHAR(128) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `garage` VARCHAR(64) DEFAULT 'pillboxgarage',
    `state` INT DEFAULT 1,
    `mods` LONGTEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sinister_vip` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(64) NOT NULL UNIQUE,
    `tier` VARCHAR(32) DEFAULT 'silver',
    `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sinister_purchase_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` VARCHAR(128) DEFAULT NULL,
    `player_identifier` VARCHAR(64) NOT NULL,
    `package_name` VARCHAR(255) NOT NULL,
    `action` VARCHAR(64) NOT NULL,
    `result` VARCHAR(32) DEFAULT 'success',
    `details` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_transaction` (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
