import pymysql

conn = pymysql.connect(
    host='91.99.71.34', port=3307,
    user='u10208_WO0ajxNA1S', password='y6fpxyrazMV!!J.F0sdQvGbZ',
    database='s10208_Sinister', charset='utf8mb4', connect_timeout=30
)
cursor = conn.cursor()

# Fix mdt_patrols: add missing column
try:
    cursor.execute("ALTER TABLE mdt_patrols ADD COLUMN member_ids longtext DEFAULT NULL")
    print("Added member_ids to mdt_patrols")
except Exception as e:
    if "Duplicate" in str(e) or "already exists" in str(e):
        print("member_ids column already exists")
    else:
        # Table might not have all needed columns, recreate properly
        cursor.execute("DROP TABLE IF EXISTS mdt_patrols")
        cursor.execute("""CREATE TABLE mdt_patrols (
            id int(11) NOT NULL AUTO_INCREMENT,
            label varchar(100) NOT NULL,
            job_type varchar(50) NOT NULL DEFAULT 'all',
            member_ids longtext DEFAULT NULL,
            sort_order int(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (id),
            KEY idx_mdt_patrols_job_sort (job_type, sort_order)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""")
        print("Recreated mdt_patrols with member_ids")

# Create player_mails
cursor.execute("""CREATE TABLE IF NOT EXISTS player_mails (
    id int(11) NOT NULL AUTO_INCREMENT,
    citizenid varchar(50) NOT NULL,
    sender varchar(50) NOT NULL,
    subject varchar(100) NOT NULL,
    message text NOT NULL,
    `read` tinyint(1) DEFAULT 0,
    `date` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci""")
print("Created player_mails")

conn.commit()
cursor.close()
conn.close()
print("\nDone. Restart.")
