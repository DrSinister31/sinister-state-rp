import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# Fix sinister_chat server.lua - change QBCore to qbx_core and fix require path
tmp = os.path.join(tempfile.gettempdir(), '_fix_chat.lua')
sftp.get('/resources/[standalone]/sinister_chat/server/server.lua', tmp)
with open(tmp) as f:
    lines = f.readlines()

# Fix the two issues
for i, line in enumerate(lines):
    if "exports['qb-core']" in line:
        lines[i] = line.replace("exports['qb-core']", "exports['qbx_core']")
    if "require 'locales.en'" in line:
        lines[i] = line.replace("require 'locales.en'", "require '@sinister_chat/locales/en'")

with open(tmp, 'w') as f:
    f.writelines(lines)

sftp.put(tmp, '/resources/[standalone]/sinister_chat/server/server.lua')
print('sinister_chat: QBCore -> qbx_core, require path fixed')
os.unlink(tmp)

# Fix package_handler.lua in sinister_store - check for similar issues
tmp2 = os.path.join(tempfile.gettempdir(), '_fix_pkg.lua')
try:
    sftp.get('/resources/[standalone]/sinister_store/server/package_handler.lua', tmp2)
    with open(tmp2) as f:
        lines = f.readlines()
    # Fix line 52 area
    for i in range(max(0,48), min(len(lines), 58)):
        print(f'  pkg_handler line {i+1}: {lines[i].rstrip()}')
    os.unlink(tmp2)
except Exception as e:
    print(f'  package_handler: {e}')

sftp.close()
ssh.close()
