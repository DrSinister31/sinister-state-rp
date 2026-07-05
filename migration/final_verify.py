import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()
checks = []

# 1. easyadmin moved to disabled
try:
    sftp.stat('/resources/qbx_disabled/easyadmin/fxmanifest.lua')
    checks.append(('easyadmin in qbx_disabled', True))
except:
    checks.append(('easyadmin in qbx_disabled', False))

try:
    sftp.stat('/resources/[standalone]/easyadmin/fxmanifest.lua')
    checks.append(('easyadmin GONE from standalone', False))
except:
    checks.append(('easyadmin GONE from standalone', True))

# 2. Ensure disabled
p = os.path.join(tmp, '_1.lua')
sftp.get('/resources/[standalone]/_cfg/qol_ensures.cfg', p)
with open(p) as f: c = f.read()
checks.append(('easyadmin ensure DISABLED', '-- ensure easyadmin' in c))
os.unlink(p)

# 3. Chess heading
p = os.path.join(tmp, '_2.lua')
sftp.get('/resources/[standalone]/sinister_chess/server/presets.lua', p)
with open(p) as f: c = f.read()
checks.append(('chess column heading', 'heading FLOAT' in c))
os.unlink(p)

# 4. Server.cfg
p = os.path.join(tmp, '_3.cfg')
sftp.get('/server.cfg', p)
with open(p) as f: c = f.read()
checks.append(('sv_maxclients commented', '# sv_maxclients' in c))
checks.append(('exec permissions.cfg', 'exec permissions.cfg' in c))
checks.append(('tebex secret set', 'sv_tebexSecret' in c))
os.unlink(p)

# 5. Crafting clean
p = os.path.join(tmp, '_4.lua')
sftp.get('/resources/[standalone]/sinister_crafting/server/main.lua', p)
with open(p) as f: c = f.read()
checks.append(('crafting clean rewrite', 'sinister_crafting' in c and 'Server ready' in c))
os.unlink(p)

# 6. htown copas gone
p = os.path.join(tmp, '_5.lua')
sftp.get('/resources/[standalone]/htown_customs/fxmanifest.lua', p)
with open(p) as f: c = f.read()
checks.append(('copas/ removed', "'copas/" not in c))
os.unlink(p)

# 7. Permissions
p = os.path.join(tmp, '_6.cfg')
sftp.get('/permissions.cfg', p)
with open(p) as f: c = f.read()
checks.append(('command.set allow', 'command.set allow' in c))
checks.append(('discord owner set', 'identifier.discord:1370770707507708047' in c))
os.unlink(p)

# 8. Ravn logs stub
p = os.path.join(tmp, '_7.lua')
sftp.get('/resources/[standalone]/ravn_logs/server/server.lua', p)
with open(p) as f: lines = f.readlines()
checks.append(('ravn webhook stubbed', 'webhook' in lines[0] if lines else False))
os.unlink(p)

# 9. Store MySQL
p = os.path.join(tmp, '_9.lua')
sftp.get('/resources/[standalone]/sinister_store/server/database.lua', p)
with open(p) as f: c = f.read()
checks.append(('store MySQL patterns clean', 'MySQL.insert.await' in c or 'MySQL.query.await' in c))
checks.append(('store no broken exports', 'exports.oxmysql:query.await' not in c))
os.unlink(p)

# 10. NPWD weather registered
p = os.path.join(tmp, '_10.json')
sftp.get('/resources/[npwd]/npwd/config.json', p)
with open(p) as f: c = f.read()
checks.append(('NPWD has sinister_weather', 'sinister_weather' in c))
os.unlink(p)

# 11. mbt_emote_menu exists
try:
    sftp.stat('/resources/[standalone]/mbt_emote_menu/fxmanifest.lua')
    checks.append(('mbt_emote_menu deployed', True))
except:
    checks.append(('mbt_emote_menu deployed', False))

sftp.close()
ssh.close()

ok = 0
for label, result in checks:
    st = 'OK' if result else 'MISS'
    print('  [%s] %s' % (st, label))
    if result: ok += 1

print('\n%s/%s confirmed on server' % (ok, len(checks)))
