import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

manifests = [
    '/resources/[standalone]/htown_customs/fxmanifest.lua',
    '/resources/[standalone]/sinister_crafting/fxmanifest.lua',
    '/resources/[standalone]/sinister_chess/fxmanifest.lua',
    '/resources/[standalone]/ravn_logs/fxmanifest.lua',
    '/resources/[standalone]/sinister_ai/fxmanifest.lua',
    '/resources/[standalone]/sinister_chat/fxmanifest.lua',
    '/resources/[standalone]/sinister_store/fxmanifest.lua',
    '/resources/[standalone]/easyadmin/fxmanifest.lua',
    '/resources/[standalone]/mbt_emote_menu/fxmanifest.lua',
    '/resources/[standalone]/sinister_dealers/fxmanifest.lua',
    '/resources/[standalone]/sinister_housing/fxmanifest.lua',
    '/resources/[standalone]/sinister_interact/fxmanifest.lua',
]
issues = []
for m in manifests:
    try:
        name = m.split('/')[-2]
        p = os.path.join(tmp, 'mf_' + name + '.lua')
        sftp.get(m, p)
        with open(p) as f: content = f.read()
        lines = content.strip().split('\n')
        # Count single and double quotes
        sq = content.count("'")
        dq = content.count('"')
        if sq % 2 != 0:
            issues.append(name + ': ODD single quotes (' + str(sq) + ')')
        if dq % 2 != 0:
            issues.append(name + ': ODD double quotes (' + str(dq) + ')')
        if 'fx_version' not in content:
            issues.append(name + ': missing fx_version')
        if 'game' not in content:
            issues.append(name + ': missing game entry')
        print('  OK: ' + name + ' (' + str(len(lines)) + ' lines, sq=' + str(sq) + ' dq=' + str(dq) + ')')
        os.unlink(p)
    except Exception as e:
        issues.append('MISSING: ' + m.split('/')[-2] + ' - ' + str(e))
        print('  MISSING: ' + m.split('/')[-2])

sftp.close()
ssh.close()

if issues:
    print('\nISSUES:')
    for i in issues: print('  ' + i)
else:
    print('\nAll manifests pass')
