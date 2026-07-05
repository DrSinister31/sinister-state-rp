"""Verify database tables were created properly."""
import pymysql

DB_HOST = "91.99.71.34"
DB_PORT = 3307
DB_USER = "u10208_dSneZNQyLN"
DB_PASS = "c.=ib4KPvLDR@Z4yLPH8oSkX"
DB_NAME = "s10208_MySQL"

# Expected tables from Qbox + NPWD + PS-MDT
EXPECTED_TABLES = [
    # Qbox core
    "players", "player_vehicles", "player_houses",
    # Qbox vehicles
    "player_vehicles",
    # NPWD
    "npwd_phone_contacts", "npwd_phone_messages", "npwd_twitter_tweets",
    "npwd_match_profiles", "npwd_marketplace_listings",
    # PS-MDT
    "mdt_settings", "mdt_bulletins", "mdt_profiles", "mdt_reports",
    "mdt_warrants", "mdt_bolos", "mdt_messages", "mdt_bodycams",
    "mdt_evidence", "mdt_incidents",
]

conn = pymysql.connect(
    host=DB_HOST, port=DB_PORT,
    user=DB_USER, password=DB_PASS,
    database=DB_NAME, charset='utf8mb4',
    connect_timeout=30,
)
cursor = conn.cursor()

print("=== Database Table Verification ===\n")

# Get all tables
cursor.execute("SHOW TABLES")
tables = [row[0] for row in cursor.fetchall()]
print(f"Total tables: {len(tables)}\n")

# Check expected tables
found = 0
missing = 0
for table in EXPECTED_TABLES:
    if table.lower() in [t.lower() for t in tables]:
        found += 1
    else:
        print(f"  MISSING: {table}")
        missing += 1

print(f"\nExpected tables: {found}/{len(EXPECTED_TABLES)} found")
if missing == 0:
    print("All critical tables present!")
else:
    print(f"{missing} tables missing")

print(f"\nAll tables in database ({len(tables)}):")
for t in tables:
    print(f"  {t}")

cursor.close()
conn.close()
