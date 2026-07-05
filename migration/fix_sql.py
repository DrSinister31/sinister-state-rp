import pymysql

conn = pymysql.connect(
    host='91.99.71.34', port=3307,
    user='u10208_WO0ajxNA1S',
    password='y6fpxyrazMV!!J.F0sdQvGbZ',
    database='s10208_Sinister', charset='utf8mb4',
    connect_timeout=30
)
cursor = conn.cursor()

tables_sql = [
    """CREATE TABLE IF NOT EXISTS mdt_patrols (
        id int(11) NOT NULL AUTO_INCREMENT,
        label varchar(50) NOT NULL,
        job_type varchar(50) NOT NULL DEFAULT 'all',
        sort_order int(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (id),
        KEY idx_mdt_patrols_job_sort (job_type, sort_order)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""",
    
    """CREATE TABLE IF NOT EXISTS mdt_officer_status (
        id int(11) NOT NULL AUTO_INCREMENT,
        citizenid varchar(50) NOT NULL,
        status varchar(50) NOT NULL DEFAULT '10-8',
        note text DEFAULT NULL,
        job_type varchar(50) NOT NULL DEFAULT 'police',
        updated_at timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
        PRIMARY KEY (id),
        KEY idx_mdt_officer_status_job (job_type, status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""",
    
    """CREATE TABLE IF NOT EXISTS playerskins (
        id int(11) NOT NULL AUTO_INCREMENT,
        citizenid varchar(50) NOT NULL,
        model varchar(100) NOT NULL,
        skin longtext NOT NULL,
        PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""",
    
    """CREATE TABLE IF NOT EXISTS player_outfits (
        id int(11) NOT NULL AUTO_INCREMENT,
        citizenid varchar(50) NOT NULL,
        outfitname varchar(50) NOT NULL,
        outfit longtext NOT NULL,
        PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""",
]

for sql in tables_sql:
    try:
        cursor.execute(sql)
        print(f"  OK: {sql.split()[2].split('(')[0].strip()}")
    except Exception as e:
        print(f"  FAIL: {e}")

conn.commit()
cursor.execute("SHOW TABLES")
count = len(cursor.fetchall())
print(f"\nTotal tables: {count}")
cursor.close()
conn.close()
