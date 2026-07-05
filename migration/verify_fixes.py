import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()
ok = 0

checks = []

# 1. easyadmin config.lua
p = os.path.join(tmp, '_chk.lua')
sftp.get('/resources/[standalone]/easyadmin/config.lua', p)
with open(p) as f: c = f.read()
clean = c.count('goto ') < 2
checks.append(('easyadmin config (no goto)', clean))
os.unlink(p)

# 2. sinister_chess presets.lua
sftp.get('/resources/[standalone]/sinister_chess/server/presets.lua', p)
with open(p) as f: c = f.read()
clean = 'MySQL.query' not in c
checks.append(('sinister_chess (no MySQL)', clean))
os.unlink(p)

# 3. sinister_store database.lua
sftp.get('/resources/[standalone]/sinister_store/server/database.lua', p)
with open(p) as f: c = f.read()
clean = '.await(' not in c
checks.append(('sinister_store (no .await)', clean))
os.unlink(p)

# 4. ravn_logs server.lua
sftp.get('/resources/[standalone]/ravn_logs/server/server.lua', p)
with open(p) as f: c = f.read()
clean = 'require' not in c or 'webhook' not in c
checks.append(('ravn_logs (no webhook require)', clean))
os.unlink(p)

# 5. sinister_ai police_ai.lua
sftp.get('/resources/[standalone]/sinister_ai/server/police_ai.lua', p)
with open(p) as f: c = f.read()
clean = 'GetPlayerPed(source)' not in c and 'GetPlayerPed(pid)' in c
checks.append(('sinister_ai (GetPlayerPed(pid))', clean))
os.unlink(p)

# 6. sinister_chat server.lua
sftp.get('/resources/[standalone]/sinister_chat/server/server.lua', p)
with open(p) as f: lines = f.readlines()
clean = len(lines) <= 3
checks.append(('sinister_chat (clean rewrite)', clean))
os.unlink(p)

# 7. loadingv2 logo
try:
    sftp.stat('/resources/[standalone]/sinister_loadingv2/html/media/logo.png')
    checks.append(('loadingv2 logo.png', True))
except:
    checks.append(('loadingv2 logo.png', False))

# 8. permissions.cfg
try:
    sftp.stat('/permissions.cfg')
    checks.append(('permissions.cfg', True))
except:
    checks.append(('permissions.cfg', False))

# 9. server.cfg exec line
sftp.get('/server.cfg', p)
with open(p) as f: c = f.read()
checks.append(('server.cfg exec permissions', 'exec permissions.cfg' in c))
os.unlink(p)

sftp.close()
ssh.close()

for label, result in checks:
    status = 'OK' if result else 'MISS'
    print('  [%s] %s' % (status, label))
    if result: ok += 1

print('\n%s/9 confirmed on server' % ok)
