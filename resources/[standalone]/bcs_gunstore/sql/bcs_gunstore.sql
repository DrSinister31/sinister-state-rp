-- ============================================================
--  bcs_gunstore - database schema
--  Import this file into your server database (e.g. via HeidiSQL,
--  phpMyAdmin or `mysql < bcs_gunstore.sql`) before starting the resource.
-- ============================================================

CREATE TABLE IF NOT EXISTS `bcs_gunstore_stores` (
    `id`          INT(11)        NOT NULL AUTO_INCREMENT,
    `name`        VARCHAR(64)    NOT NULL DEFAULT 'Gun Store',
    `owner`       VARCHAR(64)    DEFAULT NULL,            -- player identifier / citizenid (NULL = unowned)
    `owner_name`  VARCHAR(64)    DEFAULT NULL,            -- cached character name for display
    `price`       INT(11)        NOT NULL DEFAULT 50000,  -- purchase price of the store itself
    `for_sale`    TINYINT(1)     NOT NULL DEFAULT 1,      -- 1 = can be purchased while unowned
    `balance`     INT(11)        NOT NULL DEFAULT 0,      -- accumulated earnings, withdrawn by owner
    `coords`      LONGTEXT       NOT NULL,                -- json: {"x":..,"y":..,"z":..,"w":heading}
    `blip_sprite` INT(11)        NOT NULL DEFAULT 110,
    `blip_color`  INT(11)        NOT NULL DEFAULT 2,
    `blip_scale`  FLOAT          NOT NULL DEFAULT 0.8,
    `ped_model`   VARCHAR(64)    DEFAULT NULL,            -- optional ped model spawned at the store
    `created_at`  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bcs_gunstore_items` (
    `id`        INT(11)     NOT NULL AUTO_INCREMENT,
    `store_id`  INT(11)     NOT NULL,
    `item`      VARCHAR(64) NOT NULL,                     -- ox_inventory item / weapon name
    `price`     INT(11)     NOT NULL DEFAULT 0,           -- price per unit
    `stock`     INT(11)     NOT NULL DEFAULT 0,           -- units currently in stock
    `metadata`  LONGTEXT    DEFAULT NULL,                 -- optional json metadata for the item
    PRIMARY KEY (`id`),
    UNIQUE KEY `store_item` (`store_id`, `item`),
    CONSTRAINT `fk_bcs_gunstore_items_store`
        FOREIGN KEY (`store_id`) REFERENCES `bcs_gunstore_stores` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Wholesale stock prices (admin-set, shared by every store). When an owner
-- restocks from the system they pay this per unit. Items without a row here fall
-- back to Config.defaultStockPrice.
CREATE TABLE IF NOT EXISTS `bcs_gunstore_stock_prices` (
    `item`  VARCHAR(64) NOT NULL,                         -- ox_inventory item / weapon name
    `price` INT(11)     NOT NULL DEFAULT 0,               -- wholesale cost per unit
    PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
--  Optional sample store (uncomment to insert a ready-to-use store).
--  Stores are normally created in-game with the admin editor
--  (default command: /gunstore), so this is only for testing.
-- ------------------------------------------------------------
-- INSERT INTO `bcs_gunstore_stores` (`name`, `price`, `coords`, `blip_sprite`, `blip_color`, `blip_scale`)
-- VALUES ('Ammu-Nation', 50000, '{"x":21.7,"y":-1106.7,"z":29.8,"w":160.0}', 110, 2, 0.8);
