import os
from ftplib import FTP
FTP_HOST = "79.127.172.121"; FTP_USER = "FEN8gHlIbozd1X"; FTP_PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"
ftp = FTP(); ftp.connect(FTP_HOST, 21, timeout=20)
try: ftp.login(FTP_USER, "warmup")
except: pass
try: ftp.quit()
except: pass
ftp = FTP(); ftp.connect(FTP_HOST, 21, timeout=20); ftp.login(FTP_USER, FTP_PASS)
base = "/servers/QboxProject_4826CC.base/resources/fix_black"
for f in ["fxmanifest.lua", "client.lua"]:
    lp = os.path.join(r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master\fix_black", f)
    ftp.cwd("/"); cur = ""
    for d in [x for x in base.strip("/").split("/") if x]:
        cur += "/" + d
        try: ftp.cwd(cur)
        except: ftp.mkd(cur); ftp.cwd(cur)
    with open(lp, "rb") as fh: ftp.storbinary(f"STOR {os.path.basename(f)}", fh)
ftp.quit()
print("Uploaded.")

import sys; sys.path.insert(0, "Kronus")
from shared.config import Config; from shared.supabase_client import get_supabase
cfg = Config.from_env(); s = get_supabase(cfg)
s.table("rcon_commands").insert({"command": "ensure fix_black", "source": "emergency", "status": "pending"}).execute()
print("fix_black ensured.")
