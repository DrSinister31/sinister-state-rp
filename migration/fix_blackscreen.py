import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

# 1. CRITICAL — Remove manual_shutdown from loading screen
p = os.path.join(tmp, '_ld_fx.lua')
sftp.get('/resources/[standalone]/sinister_loadingv2/fxmanifest.lua', p)
with open(p) as f: c = f.read()
c = c.replace("loadscreen_manual_shutdown 'yes'", '-- loadscreen_manual_shutdown removed (auto-dismiss)')
with open(p, 'w') as f: f.write(c)
sftp.put(p, '/resources/[standalone]/sinister_loadingv2/fxmanifest.lua')
print('1. loadingv2: manual shutdown REMOVED')
os.unlink(p)

# 2. sinister_motels — fix infinite wait for GlobalState.Motels
try:
    p = os.path.join(tmp, '_motel_cl.lua')
    sftp.get('/resources/[standalone]/sinister_motels/client/main.lua', p)
    with open(p) as f: c = f.read()
    c = c.replace('while GlobalState.Motels == nil do Wait(1) end',
        'local waitCount = 0\n    while GlobalState.Motels == nil do Wait(100); waitCount = waitCount + 1; if waitCount > 100 then print("^1[sinister_motels] GlobalState.Motels never loaded"); return end end')
    with open(p, 'w') as f: f.write(c)
    sftp.put(p, '/resources/[standalone]/sinister_motels/client/main.lua')
    print('2. sinister_motels: infinite wait capped at 10s')
    os.unlink(p)
except Exception as e:
    print('2. sinister_motels: SKIP (%s)' % str(e)[:50])

# 3. sinister_motels bridge — safety check before fade on spawn
bridge_paths = [
    '/resources/[standalone]/sinister_motels/bridge/framework/client/qbcore.lua',
    '/resources/[standalone]/sinister_motels/bridge/framework/client/esx.lua',
]
for bp in bridge_paths:
    try:
        p = os.path.join(tmp, '_motel_br.lua')
        sftp.get(bp, p)
        with open(p) as f: c = f.read()
        c = c.replace('DoScreenFadeOut(0)\n        EnterShell(data,true)',
            'if data and data.coords then\n            DoScreenFadeOut(0)\n            EnterShell(data,true)\n        end')
        c = c.replace('DoScreenFadeOut(0)\n    EnterShell(data,true)',
            'if data and data.coords then\n        DoScreenFadeOut(0)\n        EnterShell(data,true)\n    end')
        with open(p, 'w') as f: f.write(c)
        sftp.put(p, bp)
        print('3. motel bridge safety: %s' % bp.split('/')[-1])
        os.unlink(p)
    except:
        pass

# 4. ps_lib — NUI focus release
pslib_files = {
    '/resources/[standalone]/ps_lib/modules/psui/client/crafter.lua': 'SetNuiFocus(true, true)',
    '/resources/[standalone]/ps_lib/modules/psui/client/showImage.lua': 'SetNuiFocus(true, true)',
}
for ppath, pat in pslib_files.items():
    try:
        p = os.path.join(tmp, '_pslib.lua')
        sftp.get(ppath, p)
        with open(p) as f: c = f.read()
        needle = '\n' + pat
        repl = '\n-- ' + pat + '\n    SetNuiFocus(false, false) -- cleanup\n    ' + pat
        if needle in c:
            c = c.replace(needle, repl)
        else:
            c = c.replace(pat, '-- ' + pat + '\n    SetNuiFocus(false, false)\n    ' + pat)
        with open(p, 'w') as f: f.write(c)
        sftp.put(p, ppath)
        print('4. ps_lib NUI release: %s' % ppath.split('/')[-1])
        os.unlink(p)
    except Exception as e:
        print('4. SKIP %s: %s' % (ppath.split('/')[-1], str(e)[:40]))

sftp.close()
ssh.close()
print('\nAll 4 fixes applied. Restart.')
