"""Try connecting to old server with various auth methods."""
import ftplib
import socket

HOST = "79.127.172.121"
PORT = 21
USER = "FEN8gHlIbozd1X"
PASS_OPTIONS = [
    'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA',           # plain
    "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA'",          # with single quotes
    '"CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"',          # with double quotes
    "CPb4{ams3Lzv=t~UlViy8(PJ)pqnA",            # plain (same as first)
]

# Check if host is even reachable
print("=== Checking connectivity ===")
try:
    sock = socket.create_connection((HOST, PORT), timeout=10)
    sock.close()
    print(f"Host {HOST}:{PORT} is reachable")
except Exception as e:
    print(f"Host {HOST}:{PORT} is NOT reachable: {e}")

# Try plain FTP with each password
for i, pw in enumerate(list(dict.fromkeys(PASS_OPTIONS))):  # deduplicate
    print(f"\n=== Attempt {i+1}: Password {repr(pw[:20])}... ===")
    try:
        ftp = ftplib.FTP()
        ftp.connect(HOST, PORT, timeout=15)
        welcome = ftp.getwelcome()
        print(f"Server: {welcome}")
        ftp.login(USER, pw)
        print("SUCCESS!")
        ftp.quit()
        break
    except Exception as e:
        print(f"FAILED: {e}")
        try:
            ftp.close()
        except:
            pass

# Try FTP_TLS
print(f"\n=== Attempting FTP_TLS ===")
try:
    from ftplib import FTP_TLS
    ftp = FTP_TLS()
    ftp.connect(HOST, PORT, timeout=15)
    ftp.login(USER, PASS_OPTIONS[0])
    ftp.prot_p()
    print("FTP_TLS SUCCESS!")
    ftp.quit()
except Exception as e:
    print(f"FTP_TLS FAILED: {e}")
