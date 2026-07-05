"""Upload server.cfg to new server and run SQL migrations on MariaDB."""
import paramiko
import pymysql
import os
import sys

# ============================================================================
# PART 1: Upload server.cfg
# ============================================================================
SFTP_HOST = "nyc15.xgamingserver.com"
SFTP_PORT = 2022
SFTP_USER = "nhxija4f.69162937"
SFTP_PASS = "Familia1!"

# ============================================================================
# PART 2: Run SQL on MariaDB
# ============================================================================
DB_HOST = "91.99.71.34"
DB_PORT = 3307
DB_USER = "u10208_dSneZNQyLN"
DB_PASS = "c.=ib4KPvLDR@Z4yLPH8oSkX"
DB_NAME = "s10208_MySQL"

MIGRATION_DIR = os.path.dirname(__file__)
PROJECT_ROOT = os.path.dirname(MIGRATION_DIR)
QBOX_DOWNLOAD = os.path.join(MIGRATION_DIR, "qbox_download")

# SQL files to execute (in order)
SQL_FILES = [
    # Qbox base SQL
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_core", "qbx_core.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehicles", "vehicles.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehiclesales", "qbx_vehiclesales.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_vehicleshop", "vehshop.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_weed", "sql", "qbx_weed.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_lapraces", "qbx_lapraces.sql"),
    os.path.join(QBOX_DOWNLOAD, "[qbx]", "qbx_drugs", "qbx_drugs.sql"),
    # NPWD SQL
    os.path.join(QBOX_DOWNLOAD, "[npwd]", "npwd", "import.sql"),
    # PS-MDT SQL
    os.path.join(PROJECT_ROOT, "ps-mdt", "sql", "qbx.sql"),
]

def upload_server_cfg():
    print("=== Uploading server.cfg ===")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SFTP_HOST, SFTP_PORT, SFTP_USER, SFTP_PASS, timeout=30)
    sftp = ssh.open_sftp()
    
    local = os.path.join(MIGRATION_DIR, "server.cfg")
    sftp.put(local, "/server.cfg")
    print("  Uploaded server.cfg → /server.cfg")
    
    # Verify
    stat = sftp.stat("/server.cfg")
    print(f"  Size: {stat.st_size} bytes")
    
    sftp.close()
    ssh.close()
    print("  Done.\n")

def run_sql_file(cursor, filepath):
    """Execute a SQL file, splitting on semicolons."""
    if not os.path.exists(filepath):
        print(f"  SKIP (not found): {filepath}")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    statements = content.split(';')
    executed = 0
    errors = 0
    
    for stmt in statements:
        stmt = stmt.strip()
        if not stmt or stmt.startswith('--') or stmt.startswith('#'):
            continue
        try:
            cursor.execute(stmt)
            executed += 1
        except Exception as e:
            error_msg = str(e)[:120]
            if "already exists" in error_msg.lower() or "duplicate" in error_msg.lower():
                # Tables/data already exist — not a real error
                pass
            else:
                errors += 1
                if errors <= 3:
                    print(f"    Warning: {error_msg}")
    
    return True

def run_migrations():
    print("=== Running SQL Migrations ===")
    
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            charset='utf8mb4',
            connect_timeout=30,
        )
        cursor = conn.cursor()
        print(f"  Connected to MariaDB: {DB_HOST}:{DB_PORT}/{DB_NAME}")
        
        for filepath in SQL_FILES:
            filename = os.path.basename(filepath)
            parent = os.path.basename(os.path.dirname(filepath))
            print(f"  [{parent}/{filename}]...")
            run_sql_file(cursor, filepath)
        
        conn.commit()
        cursor.close()
        conn.close()
        print("  All SQL migrations complete.\n")
        return True
    except Exception as e:
        print(f"  SQL ERROR: {e}")
        return False

def main():
    # Upload server.cfg
    upload_server_cfg()
    
    # Run SQL migrations
    run_migrations()

if __name__ == "__main__":
    main()
