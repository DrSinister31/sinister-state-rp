"""Migrate to new database and upload fixes."""
import pymysql, paramiko, os

# ===== PART 1: Run SQL migrations on new DB =====
DB_HOST = "91.99.71.34"
DB_PORT = 3307
DB_USER = "u10208_WO0ajxNA1S"
DB_PASS = "y6fpxyrazMV!!J.F0sdQvGbZ"
DB_NAME = "s10208_Sinister"

MIGRATION_DIR = os.path.dirname(__file__)
PROJECT_ROOT = os.path.dirname(MIGRATION_DIR)
QBOX_DOWNLOAD = os.path.join(MIGRATION_DIR, "qbox_download")

SQL_FILES = [
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_core", "qbx_core.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehicles", "vehicles.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehiclesales", "qbx_vehiclesales.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehicleshop", "vehshop.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_weed", "sql", "qbx_weed.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_lapraces", "qbx_lapraces.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_drugs", "qbx_drugs.sql"),
    os.path.join(QBOX_DOWNLOAD, "[npwd]", "npwd", "import.sql"),
    os.path.join(PROJECT_ROOT, "ps-mdt", "sql", "qbx.sql"),
]

print("=== Running SQL Migrations on s10208_Sinister ===")
conn = pymysql.connect(
    host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASS,
    database=DB_NAME, charset='utf8mb4', connect_timeout=30,
)
cursor = conn.cursor()

for fp in SQL_FILES:
    fname = os.path.basename(fp)
    if not os.path.exists(fp):
        print(f"  SKIP {fname}: not found")
        continue
    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    statements = content.split(';')
    ok = 0
    for stmt in statements:
        stmt = stmt.strip()
        if not stmt or stmt.startswith('--') or stmt.startswith('#'):
            continue
        try:
            cursor.execute(stmt)
            ok += 1
        except Exception as e:
            err = str(e)[:80]
            if "already exists" in err.lower(): pass
            elif "duplicate" in err.lower(): pass
            elif ok == 0:
                print(f"  WARN {fname}: {err}")
    print(f"  OK   {fname}")

conn.commit()
cursor.close()
conn.close()

# Verify tables
print("\n=== Verification ===")
conn = pymysql.connect(
    host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASS,
    database=DB_NAME, charset='utf8mb4', connect_timeout=30,
)
cursor = conn.cursor()
cursor.execute("SHOW TABLES")
tables = [r[0] for r in cursor.fetchall()]
print(f"{len(tables)} tables created")
cursor.close()
conn.close()

# ===== PART 2: Upload files to server =====
SFTP_HOST = "nyc15.xgamingserver.com"
SFTP_PORT = 2022
SFTP_USER = "nhxija4f.69162937"
SFTP_PASS = "Familia1!"

print("\n=== Uploading to server ===")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(SFTP_HOST, SFTP_PORT, SFTP_USER, SFTP_PASS, timeout=30)
sftp = ssh.open_sftp()

# server.cfg
cfg = os.path.join(MIGRATION_DIR, "server.cfg")
sftp.put(cfg, "/server.cfg")
print(f"  server.cfg ({os.path.getsize(cfg)}B)")

# AI fixes
ai_dir = os.path.join(PROJECT_ROOT, "sinister_ai", "server")
for fname in ["medical_ai.lua", "police_ai.lua"]:
    local = os.path.join(ai_dir, fname)
    remote = f"/resources/[standalone]/sinister_ai/server/{fname}"
    if os.path.exists(local):
        sftp.put(local, remote)
        print(f"  {fname} ({os.path.getsize(local)}B)")

sftp.close()
ssh.close()

print("\nAll done. Restart the server!")
