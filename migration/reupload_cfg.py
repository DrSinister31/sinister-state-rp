import paramiko
import os

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

local = os.path.join(os.path.dirname(__file__), "server.cfg")

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()
sftp.put(local, "/server.cfg")
stat = sftp.stat("/server.cfg")
print(f"server.cfg uploaded ({stat.st_size} bytes)")
sftp.close()
ssh.close()
