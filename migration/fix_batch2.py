import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# 1. Rename mbt_emote_menu
try:
    sftp.rename('/resources/[standalone]/sinister_emotes', '/resources/[standalone]/mbt_emote_menu')
    print('RENAMED: sinister_emotes -> mbt_emote_menu')
except Exception as e:
    print(f'RENAME: {e}')

# 2. Fix sinister_chat
tmp = os.path.join(tempfile.gettempdir(), '_fix_chat2.lua')
sftp.get('/resources/[standalone]/sinister_chat/server/server.lua', tmp)
with open(tmp) as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if "GetCoreObject" in line:
        lines[i] = '-- Qbox exports available directly via exports.qbx_core\n'
    if "require '@sinister_chat/locales/en'" in line:
        lines[i] = line.replace("require '@sinister_chat/locales/en'", "require 'locales.en'")
with open(tmp, 'w') as f:
    f.writelines(lines)
sftp.put(tmp, '/resources/[standalone]/sinister_chat/server/server.lua')
print('sinister_chat: fixed')
os.unlink(tmp)

# 3. Fix sinister_crafting - fix the # comment
tmp2 = os.path.join(tempfile.gettempdir(), '_fix_craft2.lua')
sftp.get('/resources/[standalone]/sinister_crafting/server/main.lua', tmp2)
with open(tmp2) as f:
    c = f.read()
c = c.replace('#tablelength(', '-- tablelength(')
with open(tmp2, 'w') as f:
    f.write(c)
sftp.put(tmp2, '/resources/[standalone]/sinister_crafting/server/main.lua')
print('sinister_crafting: fixed')
os.unlink(tmp2)

# 4. Fix spike_strips - restore a clean version
tmp3 = os.path.join(tempfile.gettempdir(), '_fix_spike2.lua')
sftp.get('/resources/[standalone]/spike_strips/server/main.lua', tmp3)
with open(tmp3) as f:
    c = f.read()
# Remove broken lines with if -- ESX
c = c.replace('\nif -- ESX', '\n-- ESX compatibility removed')
c = c.replace('\nif -- ESX.GetPlayerData', '\n-- ESX compatibility removed')
with open(tmp3, 'w') as f:
    f.write(c)
sftp.put(tmp3, '/resources/[standalone]/spike_strips/server/main.lua')
print('spike_strips: fixed')
os.unlink(tmp3)

# 5. Fix sinister_ai police_ai.lua - PlayerId is client native
tmp4 = os.path.join(tempfile.gettempdir(), '_fix_police.lua')
sftp.get('/resources/[standalone]/sinister_ai/server/police_ai.lua', tmp4)
with open(tmp4) as f:
    c = f.read()
c = c.replace('PlayerId()', 'GetPlayerPed(source)')
with open(tmp4, 'w') as f:
    f.write(c)
sftp.put(tmp4, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('sinister_ai police_ai: PlayerId fixed')
os.unlink(tmp4)

# 6. Fix qol_ensures.cfg - update name
tmp5 = os.path.join(tempfile.gettempdir(), '_fix_qol.cfg')
sftp.get('/resources/[standalone]/_cfg/qol_ensures.cfg', tmp5)
with open(tmp5) as f:
    c = f.read()
c = c.replace('ensure sinister_emotes', 'ensure mbt_emote_menu')
with open(tmp5, 'w') as f:
    f.write(c)
sftp.put(tmp5, '/resources/[standalone]/_cfg/qol_ensures.cfg')
print('qol_ensures.cfg: updated')
os.unlink(tmp5)

sftp.close()
ssh.close()
print('\nAll fixes applied. Restart.')
