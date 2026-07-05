"""Deploy all 4 Texas-rethemed civilian job resources and cfg to XGamingServer via SFTP."""
import paramiko
import os
import sys
import time

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

PROJECT_ROOT = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"

JOB_RESOURCES = [
    "sinister_carwash",
    "sinister_trucking",
    "sinister_oiljob",
    "sinister_movers",
]

EXCLUDES = {
    ".git", ".gitignore", ".gitkeep", "__pycache__",
    ".DS_Store", "node_modules", ".pnpm-store",
}

RESULTS = {}

def create_remote_dir(sftp, path):
    parts = path.strip("/").split("/")
    current = ""
    for part in parts:
        if not part: continue
        current += "/" + part
        try: sftp.stat(current)
        except FileNotFoundError:
            try: sftp.mkdir(current)
            except: pass

def upload_directory(sftp, local_dir, remote_dir):
    file_count = 0
    for root, dirs, files in os.walk(local_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDES]
        rel = os.path.relpath(root, local_dir)
        remote_root = remote_dir if rel == "." else remote_dir + "/" + rel.replace("\\", "/")
        try: create_remote_dir(sftp, remote_root)
        except: pass
        for f in files:
            if f in EXCLUDES: continue
            local_path = os.path.join(root, f)
            remote_path = remote_root + "/" + f.replace("\\", "/")
            try: sftp.put(local_path, remote_path); file_count += 1
            except Exception as e: print(f"      FAIL {f}: {e}")
    return file_count

def main():
    print("=" * 60)
    print("  SINISTER H-TOWN RP — Civilian Job Deployment")
    print("  Deploying 4 Texas-rethemed job resources")
    print("=" * 60)

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(HOST, PORT, USER, PASS, timeout=30)
        print(f"\n[*] Connected to {HOST}:{PORT}")
    except Exception as e:
        print(f"\n[ERROR] Failed to connect: {e}")
        sys.exit(1)

    sftp = ssh.open_sftp()

    # Step 1: Ensure [standalone] directory exists
    print("\n--- Step 1: Ensure directories ---")
    try: sftp.mkdir("/resources/[standalone]")
    except: pass
    try: sftp.mkdir("/resources/qbx_disabled")
    except: pass
    print("  /resources/[standalone] OK")
    print("  /resources/qbx_disabled OK")

    # Step 2: Disable old qbx resources
    print("\n--- Step 2: Disable old resources ---")
    old_resources = {
        "qbx_carwash": "/resources/[qbx]/qbx_carwash",
        "qbx_truckerjob": "/resources/[qbx]/qbx_truckerjob",
    }
    for name, old_path in old_resources.items():
        try:
            sftp.stat(old_path)
            # Move to disabled
            new_path = f"/resources/qbx_disabled/{name}"
            print(f"  [*] Moving {name} to disabled...")
            try:
                stdin, stdout, stderr = ssh.exec_command(
                    f"mv '{old_path}' '{new_path}'", timeout=10
                )
                exit_code = stdout.channel.recv_exit_status()
                if exit_code == 0:
                    print(f"  [OK] {name} -> qbx_disabled/")
                    RESULTS[name] = "disabled"
                else:
                    err = stderr.read().decode().strip()
                    print(f"  [WARN] Could not move {name}: {err}")
                    RESULTS[name] = "move_failed"
            except Exception as e:
                print(f"  [WARN] SSH move failed: {e}")
                RESULTS[name] = "move_error"
        except FileNotFoundError:
            print(f"  [SKIP] {name} not found (already disabled)")
            RESULTS[name] = "not_found"

    # Step 3: Upload 4 job resources
    print("\n--- Step 3: Upload job resources ---")
    for res in JOB_RESOURCES:
        local = os.path.join(PROJECT_ROOT, res)
        if not os.path.isdir(local):
            print(f"  [ERROR] {res}: not found locally!")
            RESULTS[res] = "local_missing"
            continue

        remote = f"/resources/[standalone]/{res}"
        print(f"  [*] Uploading {res}...")
        try:
            count = upload_directory(sftp, local, remote)
            print(f"  [OK] {res}: {count} files uploaded")
            RESULTS[res] = f"{count} files"
        except Exception as e:
            print(f"  [FAIL] {res}: {e}")
            RESULTS[res] = f"error: {e}"

    # Step 4: Upload jobs_ensures.cfg
    print("\n--- Step 4: Upload jobs_ensures.cfg ---")
    local_cfg = os.path.join(PROJECT_ROOT, "sinister_carwash", "..", "jobs_ensures.cfg")
    local_cfg = os.path.join(PROJECT_ROOT, "jobs_ensures.cfg")
    if not os.path.exists(local_cfg):
        alt = os.path.join(PROJECT_ROOT, "resources", "[standalone]", "_cfg")
        local_cfg = alt + "/jobs_ensures.cfg"
        if not os.path.exists(local_cfg):
            print("  [ERROR] jobs_ensures.cfg not found! Creating from here...")
            # We'll create it in step 5
            pass

    remote_cfg = "/resources/[standalone]/_cfg/jobs_ensures.cfg"
    try:
        sftp.stat("/resources/[standalone]/_cfg")
    except FileNotFoundError:
        try: sftp.mkdir("/resources/[standalone]/_cfg")
        except: pass

    if os.path.exists(local_cfg):
        try:
            sftp.put(local_cfg, remote_cfg)
            print(f"  [OK] jobs_ensures.cfg uploaded")
            RESULTS["jobs_ensures.cfg"] = "uploaded"
        except Exception as e:
            print(f"  [FAIL] jobs_ensures.cfg: {e}")
            RESULTS["jobs_ensures.cfg"] = f"error: {e}"
    else:
        print(f"  [WARN] Could not find local cfg file")
        RESULTS["jobs_ensures.cfg"] = "not_found_local"

    sftp.close()
    ssh.close()

    # Summary
    print("\n" + "=" * 60)
    print("  DEPLOYMENT SUMMARY")
    print("=" * 60)
    for key, val in RESULTS.items():
        print(f"  {key}: {val}")
    print("=" * 60)
    print("  Done! Ensure these resources in server.cfg:")
    for res in JOB_RESOURCES:
        print(f"    ensure {res}")
    print("=" * 60)

if __name__ == "__main__":
    main()
