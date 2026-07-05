"""Try old server FTP with corrected credentials.
Password includes single quotes at both ends.
Also try port 2022 (SFTP) in addition to port 21.
"""
import ftplib
import socket
import paramiko

HOST = "79.127.172.121"
USER = "FEN8gHlIbozd1X"
# Password WITH single quotes
PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA'"

# Try FTP on port 21
print("=== Attempt FTP port 21 ===")
try:
    sock = socket.create_connection((HOST, 21), timeout=10)
    sock.close()
    print(f"Port 21 reachable")
    
    ftp = ftplib.FTP()
    ftp.connect(HOST, 21, timeout=15)
    print(f"Server: {ftp.getwelcome()}")
    ftp.login(USER, PASS)
    print("SUCCESS! FTP port 21 connected!")
    
    # List root directory
    ftp.cwd("/")
    items = []
    ftp.dir(items.append)
    for item in items:
        print(f"  {item}")
    ftp.quit()
except Exception as e:
    print(f"FTP port 21 FAILED: {e}")

# Try FTP_TLS on port 21
print("\n=== Attempt FTP_TLS port 21 ===")
try:
    from ftplib import FTP_TLS
    ftp = FTP_TLS()
    ftp.connect(HOST, 21, timeout=15)
    ftp.login(USER, PASS)
    ftp.prot_p()
    print("SUCCESS! FTP_TLS port 21 connected!")
    ftp.quit()
except Exception as e:
    print(f"FTP_TLS FAILED: {e}")

# Try SFTP on port 2022
print("\n=== Attempt SFTP port 2022 ===")
try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, 2022, USER, PASS, timeout=15)
    print("SUCCESS! SFTP port 2022 connected!")
    sftp = ssh.open_sftp()
    items = sftp.listdir_attr("/")
    for item in sorted(items, key=lambda x: x.filename):
        t = "<DIR>" if item.st_mode & 0o40000 else f"{item.st_size}B"
        print(f"  {item.filename:40s} {t}")
    sftp.close()
    ssh.close()
except Exception as e:
    print(f"SFTP port 2022 FAILED: {e}")
