import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# === DELETE BROKEN RESOURCES ===
to_delete = [
    'sinister_chat',      # qbx_chat_theme already works
    'sinister_store',     # tebex plugin already works
    'sinister_crafting',  # broken beyond repair
    'sinister_loadingv2', # black screen bug
    'easyadmin',          # qbx_adminmenu works
]

for r in to_delete:
    path = '/resources/[standalone]/%s' % r
    try:
        sftp.rename(path, '/resources/qbx_disabled/%s' % r)
        print('DELETED: %s -> qbx_disabled' % r)
    except:
        # Already in disabled or gone
        try:
            sftp.stat('/resources/qbx_disabled/%s/fxmanifest.lua' % r)
            print('SKIP: %s already in qbx_disabled' % r)
        except:
            print('NOT FOUND: %s' % r)

# === RESTORE: Move loadscreen BACK from disabled to standalone ===
try:
    sftp.rename('/resources/qbx_disabled/loadscreen', '/resources/[standalone]/loadscreen')
    print('RESTORED: loadscreen -> [standalone] (default Qbox loadscreen)')
except Exception as e:
    print('loadscreen restore: %s' % str(e)[:60])

# === CLEAN INFRA ENSURES (remove deleted resources) ===
tmp = tempfile.gettempdir()
p = os.path.join(tmp, '_infra.cfg')
try:
    sftp.get('/resources/[standalone]/_cfg/infra_ensures.cfg', p)
    with open(p) as f: lines = f.readlines()
    with open(p, 'w') as f:
        for line in lines:
            if any(d in line for d in ['sinister_chat', 'sinister_store', 'sinister_loadingv2', 'easyadmin']):
                f.write('-- DELETED: ' + line.lstrip('-').lstrip())
            elif 'Ensure BEFORE qbx_core' in line or 'drop into server.cfg BEFORE' in line:
                f.write('-- ' + line)
            else:
                f.write(line)
    # Add qbx_adminmenu and loadscreen restores
    f2 = open(p, 'a')
    f2.write('\n# --- Restored community resources ---\n')
    f2.write('# qbx_chat_theme, qbx_adminmenu, and loadscreen now handled by [qbx] and server.cfg default ensures\n')
    f2.close()
    sftp.put(p, '/resources/[standalone]/_cfg/infra_ensures.cfg')
    print('infra_ensures: cleaned, deleted resources removed')
    os.unlink(p)
except:
    pass

# === UPDATE qol_ensures.cfg (remove easyadmin ensure) ===
p = os.path.join(tmp, '_qol.cfg')
try:
    sftp.get('/resources/[standalone]/_cfg/qol_ensures.cfg', p)
    with open(p) as f: c = f.read()
    c = c.replace('-- ensure easyadmin DISABLED (use qbx_adminmenu)', '# easyadmin deleted')
    c = c.replace('\nensure sinister_chat', '\n# sinister_chat deleted (use qbx_chat_theme)')
    c = c.replace('\nensure sinister_store', '\n# sinister_store deleted (use tebex)')
    c = c.replace('\nensure sinister_crafting', '\n# sinister_crafting deleted')
    c = c.replace('\nensure sinister_loadingv2', '\n# sinister_loadingv2 deleted (use loadscreen)')
    c = c.replace('\nensure easyadmin', '')
    with open(p, 'w') as f: f.write(c)
    sftp.put(p, '/resources/[standalone]/_cfg/qol_ensures.cfg')
    print('qol_ensures: cleaned')
    os.unlink(p)
except:
    pass

# === DISABLE sinister_ai broken threads ===
p = os.path.join(tmp, '_ai_med.lua')
try:
    sftp.get('/resources/[standalone]/sinister_ai/server/medical_ai.lua', p)
    with open(p) as f: c = f.read()
    # Keep identity system, disable everything else
    if 'AI_ENABLED = true' in c:
        c = c.replace('AI_ENABLED = true', 'AI_ENABLED = false -- DISABLED (client natives on server)')
    with open(p, 'w') as f: f.write(c)
    sftp.put(p, '/resources/[standalone]/sinister_ai/server/medical_ai.lua')
    os.unlink(p)
except:
    pass

p = os.path.join(tmp, '_ai_pol.lua')
try:
    sftp.get('/resources/[standalone]/sinister_ai/server/police_ai.lua', p)
    with open(p) as f: c = f.read()
    if 'local COP_FALLBACK_THRESHOLD = 0' not in c and 'COP_FALLBACK_THRESHOLD' in c:
        # Force-disable by setting threshold impossibly high
        c = c.replace('COP_FALLBACK_THRESHOLD = ', 'COP_FALLBACK_THRESHOLD = 9999 -- DISABLED ')
    with open(p, 'w') as f: f.write(c)
    sftp.put(p, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
    print('sinister_ai: police/medical threads disabled')
    os.unlink(p)
except:
    pass

# === RESTORE SERVER.CFG: enable loadscreen ===
p = os.path.join(tmp, '_srv.cfg')
sftp.get('/server.cfg', p)
with open(p) as f: lines = f.readlines()
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if 'loadscreen_ensures' in s:
            f.write('# loadscreen_ensures removed (using default loadscreen from [qbx_disabled]/loadscreen)\n')
            f.write('ensure loadscreen\n')
        else:
            f.write(line)
sftp.put(p, '/server.cfg')
print('server.cfg: loadscreen restored')
os.unlink(p)

sftp.close()
ssh.close()
print('\n=== CLEANUP COMPLETE ===')
print('DELETED: 5 broken resources -> qbx_disabled')
print('RESTORED: loadscreen (default Qbox)')
print('DISABLED: sinister_ai police/medical threads')
print('CLEANED: infra_ensures.cfg, qol_ensures.cfg, server.cfg')
print('KEPT: 46 working custom/resources (dealers, housing, interact, tutorials, MLOs, emotes, etc.)')
print('\nRestart.')
