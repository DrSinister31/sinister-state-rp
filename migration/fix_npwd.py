import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

tmp = os.path.join(tempfile.gettempdir(), '_npwd_fix.json')
sftp.get('/resources/[npwd]/npwd/config.json', tmp)

with open(tmp, 'r') as f:
    content = f.read()

old = 'sinister_cad", "sinister_syntok", "sinister_underworld"'
new = 'sinister_cad", "sinister_syntok", "sinister_underworld", "sinister_weather"'
content = content.replace(old, new)

with open(tmp, 'w') as f:
    f.write(content)

sftp.put(tmp, '/resources/[npwd]/npwd/config.json')
print('NPWD config: sinister_weather ADDED')
os.unlink(tmp)
sftp.close()
ssh.close()
