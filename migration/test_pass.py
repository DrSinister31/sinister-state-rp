import ftplib
HOST = '79.127.172.121'
USER = 'FEN8gHlIbozd1X'
# Password with opening single quote, NO closing quote
PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"

print(f"Trying password ending with: ...{PASS[-5:]}")
try:
    ftp = ftplib.FTP()
    ftp.connect(HOST, 21, timeout=10)
    ftp.login(USER, PASS)
    print("SUCCESS!")
    ftp.cwd("/")
    items = []
    ftp.dir(items.append)
    for item in items[:30]:
        print(f"  {item}")
    ftp.quit()
except Exception as e:
    print(f"FAILED: {e}")
    try: ftp.close()
    except: pass
