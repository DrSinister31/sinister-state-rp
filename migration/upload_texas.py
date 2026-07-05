"""Upload downloaded old-server files to new server."""
import paramiko
import os

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

TEXAS_DIR = os.path.join(os.path.dirname(__file__), "texas_files")

EXCLUDES = {".DS_Store", "__MACOSX"}

def upload_dir(sftp, local_dir, remote_dir, label):
    count = 0
    for root, dirs, files in os.walk(local_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDES]
        rel = os.path.relpath(root, local_dir)
        if rel == ".":
            remote_root = remote_dir
        else:
            remote_root = f"{remote_dir}/{rel.replace(os.sep, '/')}"
        try: sftp.stat(remote_root)
        except:
            d = "/"
            for part in remote_root.strip("/").split("/"):
                d += part + "/"
                try: sftp.mkdir(d.rstrip("/"))
                except: pass
        for f in files:
            if f in EXCLUDES: continue
            local = os.path.join(root, f)
            remote = f"{remote_root}/{f.replace(os.sep, '/')}"
            try:
                sftp.put(local, remote)
                count += 1
            except Exception as e:
                print(f"      FAIL {f}: {e}")
    return count

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, PORT, USER, PASS, timeout=30)
    sftp = ssh.open_sftp()
    total = 0

    # Upload Texas-modified jobs.lua → overwrite clean Qbox one
    print("=== Overwriting qbx_core/shared/jobs.lua ===")
    src = os.path.join(TEXAS_DIR, "qbx_core/shared/jobs.lua")
    dst = "/resources/[qbx]/qbx_core/shared/jobs.lua"
    if os.path.exists(src):
        sftp.put(src, dst)
        print(f"  Uploaded ({os.path.getsize(src):,} bytes)")
        total += 1

    # Upload ambulance shared.lua
    print("\n=== Overwriting qbx_ambulancejob/config/shared.lua ===")
    src = os.path.join(TEXAS_DIR, "qbx_ambulancejob/config/shared.lua")
    dst = "/resources/[qbx]/qbx_ambulancejob/config/shared.lua"
    if os.path.exists(src):
        sftp.put(src, dst)
        print(f"  Uploaded ({os.path.getsize(src):,} bytes)")
        total += 1

    # Upload MLOs to standalone
    mlos_dir = os.path.join(TEXAS_DIR, "mlos")
    if os.path.isdir(mlos_dir):
        print("\n=== Uploading MLOs ===")
        for mlo in sorted(os.listdir(mlos_dir)):
            local = os.path.join(mlos_dir, mlo)
            if os.path.isdir(local):
                remote = f"/resources/[standalone]/{mlo}"
                print(f"  {mlo}...")
                c = upload_dir(sftp, local, remote, mlo)
                print(f"    {c} files")
                total += c

    # Upload popcornrp_zancudoalert
    extra_dir = os.path.join(TEXAS_DIR, "extra")
    if os.path.isdir(extra_dir):
        print("\n=== Uploading companion resources ===")
        for extra in sorted(os.listdir(extra_dir)):
            local = os.path.join(extra_dir, extra)
            if os.path.isdir(local):
                remote = f"/resources/[standalone]/{extra}"
                print(f"  {extra}...")
                c = upload_dir(sftp, local, remote, extra)
                print(f"    {c} files")
                total += c

    sftp.close()
    ssh.close()
    print(f"\nTotal files uploaded: {total}")

if __name__ == "__main__":
    main()
