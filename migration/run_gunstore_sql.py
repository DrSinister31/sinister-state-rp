import pymysql

conn = pymysql.connect(
    host='91.99.71.34', port=3307,
    user='u10208_WO0ajxNA1S', password='y6fpxyrazMV!!J.F0sdQvGbZ',
    database='s10208_Sinister'
)

with conn.cursor() as cur:
    cur.execute('DROP TABLE IF EXISTS `bcs_gunstore_items`')
    cur.execute('DROP TABLE IF EXISTS `bcs_gunstore_stock_prices`')
    cur.execute('DROP TABLE IF EXISTS `bcs_gunstore_stores`')

    cur.execute("""CREATE TABLE IF NOT EXISTS `bcs_gunstore_stores` (
        `id`          INT(11)        NOT NULL AUTO_INCREMENT,
        `name`        VARCHAR(64)    NOT NULL DEFAULT 'Gun Store',
        `owner`       VARCHAR(64)    DEFAULT NULL,
        `owner_name`  VARCHAR(64)    DEFAULT NULL,
        `price`       INT(11)        NOT NULL DEFAULT 50000,
        `for_sale`    TINYINT(1)     NOT NULL DEFAULT 1,
        `balance`     INT(11)        NOT NULL DEFAULT 0,
        `coords`      LONGTEXT       NOT NULL,
        `blip_sprite` INT(11)        NOT NULL DEFAULT 110,
        `blip_color`  INT(11)        NOT NULL DEFAULT 2,
        `blip_scale`  FLOAT          NOT NULL DEFAULT 0.8,
        `ped_model`   VARCHAR(64)    DEFAULT NULL,
        `created_at`  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""")

    cur.execute("""CREATE TABLE IF NOT EXISTS `bcs_gunstore_items` (
        `id`        INT(11)     NOT NULL AUTO_INCREMENT,
        `store_id`  INT(11)     NOT NULL,
        `item`      VARCHAR(64) NOT NULL,
        `price`     INT(11)     NOT NULL DEFAULT 0,
        `stock`     INT(11)     NOT NULL DEFAULT 0,
        `metadata`  LONGTEXT    DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `store_item` (`store_id`, `item`),
        CONSTRAINT `fk_bcs_gunstore_items_store`
            FOREIGN KEY (`store_id`) REFERENCES `bcs_gunstore_stores` (`id`)
            ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""")

    cur.execute("""CREATE TABLE IF NOT EXISTS `bcs_gunstore_stock_prices` (
        `item`  VARCHAR(64) NOT NULL,
        `price` INT(11)     NOT NULL DEFAULT 0,
        PRIMARY KEY (`item`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""")

conn.commit()
conn.close()
print('All 3 bcs_gunstore tables created successfully')
