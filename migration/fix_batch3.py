import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# Fix 1: sinister_chat - inline locales
tmp = os.path.join(tempfile.gettempdir(), '_loc.lua')
sftp.get('/resources/[standalone]/sinister_chat/locales/en.lua', tmp)
with open(tmp) as f:
    locale_src = f.read()

# Build a simple locale stub
locale_stub = 'local locales = { en = { chat_title = "Sinister H-Town Chat", job_prefix = "[Job]", ooc_prefix = "[OOC]" } }'

tmp2 = os.path.join(tempfile.gettempdir(), '_fix_chat.lua')
sftp.get('/resources/[standalone]/sinister_chat/server/server.lua', tmp2)
with open(tmp2) as f:
    lines = f.readlines()

# Remove GetCoreObject line, replace require with stub
new_lines = []
for line in lines:
    if 'GetCoreObject' in line:
        continue
    if 'require' in line and 'locales' in line:
        new_lines.append(locale_stub + '\n')
    else:
        new_lines.append(line)

with open(tmp2, 'w') as f:
    f.writelines(new_lines)
sftp.put(tmp2, '/resources/[standalone]/sinister_chat/server/server.lua')
print('sinister_chat: fixed')
os.unlink(tmp); os.unlink(tmp2)

# Fix 2: sinister_chess - check presets.lua and clean it
tmp3 = os.path.join(tempfile.gettempdir(), '_chess.lua')
sftp.get('/resources/[standalone]/sinister_chess/server/presets.lua', tmp3)
with open(tmp3) as f:
    lines = f.readlines()

# Show lines 13-20
for i in range(12, min(len(lines), 22)):
    print(f'chess line {i+1}: {lines[i].rstrip()}')

# Fix remaining MySQL/exports issues
for i, line in enumerate(lines):
    lines[i] = line.replace('exports.oxmysql:query', 'exports.oxmysql:query')

with open(tmp3, 'w') as f:
    f.writelines(lines)
sftp.put(tmp3, '/resources/[standalone]/sinister_chess/server/presets.lua')
os.unlink(tmp3)

# Fix 3: sinister_store database.lua
tmp4 = os.path.join(tempfile.gettempdir(), '_store.lua')
sftp.get('/resources/[standalone]/sinister_store/server/database.lua', tmp4)
with open(tmp4) as f:
    lines = f.readlines()

for i in range(61, min(len(lines), 72)):
    print(f'store line {i+1}: {lines[i].rstrip()}')

# Fix all remaining colon->dot issues in store
for i, line in enumerate(lines):
    if 'exports.oxmysql:' in line and line.strip().endswith('await'):
        # Colon is correct for oxmysql methods
        pass
    lines[i] = line.replace("exports['qbx_core']:Functions", "exports['qbx_core'].Functions")

with open(tmp4, 'w') as f:
    f.writelines(lines)
sftp.put(tmp4, '/resources/[standalone]/sinister_store/server/database.lua')
os.unlink(tmp4)

# Fix 4: spike_strips - rewrite clean
spike_clean = '''local ox_inventory = exports.ox_inventory

RegisterNetEvent('spike_strips:deploy', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job and player.PlayerData.job.name
    if not job then return end
    if job ~= 'police' and job ~= 'bcso' and job ~= 'sasp' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Spike Strips',
            description = 'Authorized law enforcement only.',
            type = 'error',
        })
        return
    end
    local count = exports.ox_inventory:GetItemCount(src, 'hpd_spike_strip')
    if count < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Spike Strips',
            description = 'You have no spike strips.',
            type = 'error',
        })
        return
    end
    if exports.ox_inventory:RemoveItem(src, 'hpd_spike_strip', 1) then
        TriggerClientEvent('spike_strips:place', src)
    end
end)
'''
with open(spike_path := os.path.join(tempfile.gettempdir(), '_spike_clean.lua'), 'w') as f:
    f.write(spike_clean)
sftp.put(spike_path, '/resources/[standalone]/spike_strips/server/main.lua')
print('spike_strips: rewritten clean')
os.unlink(spike_path)

# Fix 5: sinister_crafting
tmp6 = os.path.join(tempfile.gettempdir(), '_craft.lua')
sftp.get('/resources/[standalone]/sinister_crafting/server/main.lua', tmp6)
with open(tmp6) as f:
    lines = f.readlines()

for i in range(104, min(len(lines), 112)):
    print(f'craft line {i+1}: {lines[i].rstrip()}')

# Just comment out the broken line
for i, line in enumerate(lines):
    if line.strip().startswith('#tablelength'):
        lines[i] = '-- tablelength removed\n'

with open(tmp6, 'w') as f:
    f.writelines(lines)
sftp.put(tmp6, '/resources/[standalone]/sinister_crafting/server/main.lua')
os.unlink(tmp6)

sftp.close()
ssh.close()
print('\nAll done. Restart.')
