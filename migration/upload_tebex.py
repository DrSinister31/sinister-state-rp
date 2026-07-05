"""Upload Tebex FiveM plugin and ensures config to game server."""
import paramiko
import os

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCAL_TEBEX = os.path.join(ROOT, "resources", "[standalone]", "tebex")
LOCAL_CFG = os.path.join(ROOT, "resources", "[standalone]", "_cfg", "tebex_ensures.cfg")
REMOTE_TEBEX = "/resources/[standalone]/tebex"
REMOTE_CFG = "/resources/[standalone]/_cfg/tebex_ensures.cfg"

EXCLUDES = {".DS_Store", "__MACOSX", ".git", ".gitattributes", ".gitignore"}

def mkdir_p(sftp, remote_path):
    parts = remote_path.strip("/").split("/")
    current = ""
    for part in parts:
        current += "/" + part
        try:
            sftp.stat(current)
        except FileNotFoundError:
            try:
                sftp.mkdir(current)
                print(f"  MKDIR {current}")
            except Exception as e:
                print(f"  MKDIR FAIL {current}: {e}")

def upload_dir(sftp, local_dir, remote_dir):
    total = 0
    for root, dirs, files in os.walk(local_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDES]
        rel = os.path.relpath(root, local_dir)
        remote_root = remote_dir if rel == "." else f"{remote_dir}/{rel.replace(os.sep, '/')}"
        mkdir_p(sftp, remote_root)
        for f in files:
            if f in EXCLUDES:
                continue
            local = os.path.join(root, f)
            remote = f"{remote_root}/{f.replace(os.sep, '/')}"
            try:
                sftp.put(local, remote)
                total += 1
                print(f"  OK {f} ({os.path.getsize(local):,} bytes)")
            except Exception as e:
                print(f"  FAIL {f}: {e}")
    return total

def main():
    print("Connecting to SFTP...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, PORT, USER, PASS, timeout=30)
    sftp = ssh.open_sftp()

    print(f"\n=== Uploading Tebex plugin to {REMOTE_TEBEX} ===")
    n = upload_dir(sftp, LOCAL_TEBEX, REMOTE_TEBEX)
    print(f"  Uploaded {n} files")

    print(f"\n=== Uploading ensures config ===")
    sftp.put(LOCAL_CFG, REMOTE_CFG)
    print(f"  OK tebex_ensures.cfg ({os.path.getsize(LOCAL_CFG):,} bytes)")

    sftp.close()
    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
