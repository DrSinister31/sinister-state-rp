"""Check existing directory structure on new XGamingServer via SFTP."""
import paramiko
import sys

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(HOST, PORT, USER, PASS, timeout=30)
        sftp = ssh.open_sftp()
        
        print("=== SFTP Root Directory ===")
        items = sftp.listdir_attr("/")
        for item in sorted(items, key=lambda x: x.filename):
            t = "<DIR>" if item.st_mode & 0o40000 else f"{item.st_size}B"
            print(f"  {item.filename:40s} {t}")
        
        print("\n=== /resources/ Directory ===")
        try:
            res_items = sftp.listdir_attr("/resources/")
            for item in sorted(res_items, key=lambda x: x.filename):
                t = "<DIR>" if item.st_mode & 0o40000 else f"{item.st_size}B"
                print(f"  {item.filename:40s} {t}")
                if item.st_mode & 0o40000:
                    # List subdirectory contents
                    try:
                        sub = sftp.listdir_attr(f"/resources/{item.filename}/")
                        count = sum(1 for s in sub if s.st_mode & 0o40000)
                        print(f"    → {count} subdirectories")
                    except:
                        pass
        except Exception as e:
            print(f"  Error: {e}")
        
        # Check for existing server.cfg
        print("\n=== Server Config Files ===")
        for f in ["server.cfg", "permissions.cfg", "ox.cfg", "voice.cfg", "misc.cfg"]:
            try:
                sftp.stat(f"/{f}")
                print(f"  /{f} EXISTS")
            except:
                print(f"  /{f} NOT FOUND")
        
        sftp.close()
        ssh.close()
        print("\nDone.")
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
