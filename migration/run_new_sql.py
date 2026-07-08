import pymysql

conn = pymysql.connect(
    host='91.99.71.34', port=3307,
    user='u10208_WO0ajxNA1S', password='y6fpxyrazMV!!J.F0sdQvGbZ',
    database='s10208_Sinister'
)

with conn.cursor() as cur:
    cur.execute("""CREATE TABLE IF NOT EXISTS `fireac_admin` (
        `id` int(11) NOT NULL AUTO_INCREMENT, `identifier` longtext NOT NULL, PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin""")
    cur.execute("""CREATE TABLE IF NOT EXISTS `fireac_banlist` (
        `id` int(11) NOT NULL AUTO_INCREMENT, `STEAM` longtext NOT NULL, `DISCORD` longtext NOT NULL,
        `LICENSE` longtext NOT NULL, `LIVE` longtext NOT NULL, `XBL` longtext NOT NULL,
        `IP` longtext NOT NULL, `TOKENS` longtext NOT NULL, `BANID` longtext NOT NULL,
        `REASON` longtext NOT NULL, PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin""")
    cur.execute("""CREATE TABLE IF NOT EXISTS `fireac_unban` (
        `id` int(11) NOT NULL AUTO_INCREMENT, `identifier` longtext NOT NULL, PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin""")
    cur.execute("""CREATE TABLE IF NOT EXISTS `fireac_whitelist` (
        `id` int(11) NOT NULL AUTO_INCREMENT, `identifier` longtext NOT NULL, PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin""")

conn.commit()
conn.close()
print('FIREAC tables created')
