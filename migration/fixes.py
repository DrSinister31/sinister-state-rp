"""Upload all fixes to the new server."""
import paramiko
import os

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"
PROJECT = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"

FILES_TO_UPLOAD = [
    (os.path.join(PROJECT, "sinister_licenses", "fxmanifest.lua"), "/resources/[standalone]/sinister_licenses/fxmanifest.lua"),
    (os.path.join(PROJECT, "sinister_ai", "server", "medical_ai.lua"), "/resources/[standalone]/sinister_ai/server/medical_ai.lua"),
    (os.path.join(PROJECT, "sinister_ai", "server", "police_ai.lua"), "/resources/[standalone]/sinister_ai/server/police_ai.lua"),
    (os.path.join(PROJECT, "migration", "server.cfg"), "/server.cfg"),
]

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()

for local, remote in FILES_TO_UPLOAD:
    if os.path.exists(local):
        sftp.put(local, remote)
        print(f"  {os.path.basename(local)} -> {remote} ({os.path.getsize(local)}B)")
    else:
        print(f"  MISSING: {local}")

print("\nAll fixes uploaded. Restart the server to apply.")
sftp.close()
ssh.close()
