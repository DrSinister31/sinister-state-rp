"""Deploy recently modified resources to XGamingServer via SFTP."""
import paramiko, os, sys

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"
PROJECT_ROOT = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"

FILES = [
    ("resources/[standalone]/sinister_chat/client/client.lua",               "/resources/[standalone]/sinister_chat/client/client.lua"),
    ("resources/[standalone]/sinister_chat/server/server.lua",               "/resources/[standalone]/sinister_chat/server/server.lua"),
    ("resources/[standalone]/sinister_chess/server/main.lua",                "/resources/[standalone]/sinister_chess/server/main.lua"),
    ("sinister_clockin/client/main.lua",                                     "/resources/[standalone]/sinister_clockin/client/main.lua"),
    ("sinister_clockin/server/main.lua",                                     "/resources/[standalone]/sinister_clockin/server/main.lua"),
    ("sinister_lumberjack/server/main.lua",                                  "/resources/[standalone]/sinister_lumberjack/server/main.lua"),
    ("sinister_movers/server/main.lua",                                      "/resources/[standalone]/sinister_movers/server/main.lua"),
    ("sinister_oiljob/server/main.lua",                                      "/resources/[standalone]/sinister_oiljob/server/main.lua"),
    ("sinister_trucking/server/main.lua",                                    "/resources/[standalone]/sinister_trucking/server/main.lua"),
    ("synix_bridge/server/main.lua",                                         "/resources/[standalone]/synix_bridge/server/main.lua"),
]

def ensure_remote_dir(sftp, remote_path):
    parts = remote_path.strip("/").split("/")
    cur = ""
    for p in parts[:-1]:
        cur += "/" + p
        try: sftp.stat(cur)
        except FileNotFoundError:
            try: sftp.mkdir(cur)
            except Exception as e: print(f"  mkdir fail {cur}: {e}")

def main():
    print("=" * 50)
    print("  Deploying resource updates to XGamingServer")
    print("=" * 50)

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(HOST, PORT, USER, PASS, timeout=30)
        print(f"\n[OK] Connected to {HOST}:{PORT}")
    except Exception as e:
        print(f"\n[FAIL] Connection error: {e}")
        sys.exit(1)

    sftp = ssh.open_sftp()
    uploaded = 0
    failed = 0

    for local_rel, remote_path in FILES:
        local_path = os.path.join(PROJECT_ROOT, local_rel)
        if not os.path.isfile(local_path):
            print(f"  [SKIP] Not found: {local_rel}")
            failed += 1
            continue

        ensure_remote_dir(sftp, remote_path)
        try:
            sftp.put(local_path, remote_path)
            print(f"  [OK] {local_rel}")
            uploaded += 1
        except Exception as e:
            print(f"  [FAIL] {local_rel}: {e}")
            failed += 1

    sftp.close()
    ssh.close()

    print(f"\n{'=' * 50}")
    print(f"  Uploaded: {uploaded}  Failed: {failed}")
    print(f"  Restart the FiveM server to apply changes.")
    print(f"{'=' * 50}")

if __name__ == "__main__":
    main()
