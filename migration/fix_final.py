import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

def get(remote):
    name = remote.replace('/', '_').replace('[','').replace(']','')
    p = os.path.join(tmp, name)
    sftp.get(remote, p)
    with open(p) as f: return f.read(), p
    return '', p

def put(p, remote): sftp.put(p, remote)

# 1. easyadmin commands.lua - REAPPLY goto removal (got overwritten)
c, p = get('/resources/[standalone]/easyadmin/server/commands.lua')
lines = c.split('\n')
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if ('goto ' in s or (s.count('::') >= 2 and 'function' not in s)):
            f.write('-- goto removed\n')
        else:
            f.write(line + '\n')
put(p, '/resources/[standalone]/easyadmin/server/commands.lua')
print('1. easyadmin commands.lua: goto re-removed')

# 2. easyadmin ban_system.lua + report_system.lua - MySQL -> exports.oxmysql
for fname in ['ban_system.lua', 'report_system.lua']:
    c, p = get('/resources/[standalone]/easyadmin/server/' + fname)
    c = c.replace('MySQL.query.await', 'exports.oxmysql:query')
    c = c.replace('MySQL.insert.await', 'exports.oxmysql:insert')
    c = c.replace('MySQL.update.await', 'exports.oxmysql:update')
    c = c.replace('MySQL.single.await', 'exports.oxmysql:single')
    c = c.replace('MySQL.scalar.await', 'exports.oxmysql:scalar')
    with open(p, 'w') as f: f.write(c)
    put(p, '/resources/[standalone]/easyadmin/server/' + fname)
print('2. easyadmin ban/report: MySQL->oxmysql')

# 3. sinister_crafting - read exact lines around 109
c, p = get('/resources/[standalone]/sinister_crafting/server/main.lua')
lines = c.split('\n')
print('3. crafting lines 105-115:')
for i in range(104, min(len(lines), 115)):
    print('  %d: %s' % (i+1, lines[i].strip()))
# Remove any line between the function removal and the next valid statement
clean = []
skip = False
for i, line in enumerate(lines):
    s = line.strip()
    if '-- tablelength function removed' in s:
        clean.append('-- removed\n')
        skip = True
        continue
    if '-- removed' in s:
        clean.append('-- removed\n')
        continue
    if skip:
        if s.startswith('local ') or s.startswith('end') or s.startswith('for ') or s.startswith('while '):
            clean.append('-- removed\n')
        else:
            skip = False
            if s.startswith('return') or s.startswith('--'):
                clean.append(line + '\n')
            else:
                clean.append('-- removed\n')
    else:
        clean.append(line + '\n')
with open(p, 'w') as f: f.writelines(clean)
put(p, '/resources/[standalone]/sinister_crafting/server/main.lua')
print('3. sinister_crafting: deep cleaned')

# 4. sinister_chess - ALTER TABLE to add h column
chess_sql = "exports.oxmysql:query('ALTER TABLE chess_tables ADD COLUMN h FLOAT DEFAULT 0', {})"
c, p = get('/resources/[standalone]/sinister_chess/server/presets.lua')
# Add ALTER TABLE before the INSERT logic
c = c.replace("MySQL.query.await('SELECT", chess_sql + "\n    MySQL.query.await('SELECT")
c = c.replace("exports.oxmysql:query('SELECT", chess_sql + "\n    exports.oxmysql:query('SELECT")
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_chess/server/presets.lua')
print('4. sinister_chess: ALTER TABLE added for h column')

# 5. ravn_logs - stub out webhook variable
c, p = get('/resources/[standalone]/ravn_logs/server/server.lua')
# Replace webhook usage with nil-safe stubs
c = c.replace('webhook.send(', '-- webhook.send(')
c = c.replace('webhook.log(', '-- webhook.log(')
c += '\nlocal webhook = { send = function() end, log = function() end }\n'
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/ravn_logs/server/server.lua')
print('5. ravn_logs: webhook stubbed')

# 6. sinister_ai police_ai.lua line 113 - nil check
c, p = get('/resources/[standalone]/sinister_ai/server/police_ai.lua')
lines = c.split('\n')
for i, line in enumerate(lines):
    if 'GetPlayerPed(pid)' in line:
        indent = line[:len(line) - len(line.lstrip())]
        lines[i] = indent + 'if not DoesEntityExist(GetPlayerPed(pid)) then goto continue_player end\n'
        lines.insert(i+1, indent + 'local ped = GetPlayerPed(pid)\n')
        break
# Clean up goto references
with open(p, 'w') as f: f.write('\n'.join(lines))
# Actually simpler: just wrap the problematic native call
c = '\n'.join(lines)
c = c.replace('local ped = GetPlayerPed(pid)', 'if pid <= 0 then goto continue_player end\n        local ped = GetPlayerPed(pid)')
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('6. sinister_ai: nil check added for GetPlayerPed')

# 7. htown_customs - remove copas from manifest
c, p = get('/resources/[standalone]/htown_customs/fxmanifest.lua')
lines = c.split('\n')
with open(p, 'w') as f:
    for line in lines:
        if 'copas/' in line and line.strip().startswith("'"):
            f.write('-- removed copas/\n')
        else:
            f.write(line + '\n')
put(p, '/resources/[standalone]/htown_customs/fxmanifest.lua')
print('7. htown_customs: copas/ removed')

# 8. permissions.cfg - add command.set for qbx_core
c, p = get('/permissions.cfg')
c = c.replace('add_ace resource.qbx_core command.add_principal allow',
    'add_ace resource.qbx_core command.add_principal allow\nadd_ace resource.qbx_core command.set allow')
with open(p, 'w') as f: f.write(c)
put(p, '/permissions.cfg')
print('8. permissions.cfg: command.set added')

sftp.close()
ssh.close()
print('\nAll 8 done. Restart.')
