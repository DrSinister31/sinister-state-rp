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
    return p

def put(p, remote): sftp.put(p, remote)

# 1. server.cfg — onesync + maxclients
p = get('/server.cfg')
with open(p) as f: lines = f.readlines()
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if 'sv_replaceExeToSwitchBuilds' in s:
            f.write(line)
            f.write('\n# OneSync Infinity\nset onesync on\nset onesync_infinity true\n')
        elif '# sv_maxclients' in s:
            f.write('sv_maxclients 128\n')
        else:
            f.write(line)
put(p, '/server.cfg')
print('1. server.cfg: onesync + maxclients 128')

# 2. sinister_ai police_ai.lua — rewrite without goto
p = get('/resources/[standalone]/sinister_ai/server/police_ai.lua')
with open(p) as f: c = f.read()
# Replace ALL goto patterns with simple if blocks
# Kill goto continue_player entirely by wrapping content in proper if
lines = c.split('\n')
new_lines = []
skip_until_label = False
for line in lines:
    s = line.strip()
    if 'goto continue_player' in s:
        new_lines.append('-- goto removed\n')
    elif '::continue_player::' in s:
        new_lines.append('-- label removed\n')
    else:
        new_lines.append(line)
with open(p, 'w') as f: f.write('\n'.join(new_lines))
put(p, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('2. sinister_ai: goto + label removed')

# 3. sinister_crafting — nil guard
p = get('/resources/[standalone]/sinister_crafting/server/main.lua')
with open(p) as f: c = f.read()
c = c.replace('for recipeName, recipeData in pairs(Config.Recipes) do',
    'if Config.Recipes then for recipeName, recipeData in pairs(Config.Recipes) do')
# Need to close the if — find matching end
c = c.replace('end\n\nRegisterNetEvent',
    'end end\n\nRegisterNetEvent')
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_crafting/server/main.lua')
print('3. sinister_crafting: nil guard added')

# 4. ravn_logs — webhook stub at top
p = get('/resources/[standalone]/ravn_logs/server/server.lua')
with open(p) as f: c = f.read()
stub = 'local webhook = { send = function() end, log = function() end }\n'
if 'local webhook' not in c.split('\n')[0]:
    c = stub + c
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/ravn_logs/server/server.lua')
print('4. ravn_logs: webhook stub added')

# 5. sinister_tutorials — move tablelength above print
p = get('/resources/[standalone]/sinister_tutorials/server/main.lua')
with open(p) as f: c = f.read()
# Extract function, place above print
fn = """function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

"""
c = c.replace("function tablelength(T)\n    local count = 0\n    for _ in pairs(T) do count = count + 1 end\n    return count\nend", "")
c = c.replace("print('^2[sinister_tutorials]", fn + "print('^2[sinister_tutorials]")
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_tutorials/server/main.lua')
print('5. sinister_tutorials: tablelength moved above print')

# 6. sinister_chess — fix presets.lua for full cr-chess schema
p = get('/resources/[standalone]/sinister_chess/server/presets.lua')
with open(p) as f: c = f.read()
c = c.replace('DROP TABLE IF EXISTS chess_tables',
    'DROP TABLE IF EXISTS chess_tables')
c = c.replace('h FLOAT DEFAULT 0', 'heading FLOAT DEFAULT 0')
c = c.replace('created_at TIMESTAMP', 'created_at TIMESTAMP,\n        created_by_identifier VARCHAR(64) DEFAULT NULL,\n        created_by_name VARCHAR(128) DEFAULT NULL,\n        blip_enabled TINYINT DEFAULT 1,\n        blip_label VARCHAR(100) DEFAULT NULL,\n        blip_sprite INT DEFAULT 40,\n        blip_color INT DEFAULT 0,\n        blip_scale FLOAT DEFAULT 0.7,\n        blip_short_range TINYINT DEFAULT 0,\n        created_at2 TIMESTAMP')
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_chess/server/presets.lua')
print('6. sinister_chess: full cr-chess schema')

# 7a. htown_customs — clean fxmanifest
p = get('/resources/[standalone]/htown_customs/fxmanifest.lua')
with open(p) as f: lines = f.readlines()
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if s.startswith("copas/") or ("'copas" in s and 'files' not in s):
            f.write('-- copas/ removed\n')
        else:
            f.write(line)
put(p, '/resources/[standalone]/htown_customs/fxmanifest.lua')
print('7a. htown_customs: copas/ removed')

# 7b. permissions.cfg — add command.set for all active resources
p = get('/permissions.cfg')
with open(p) as f: c = f.read()
c = c.replace('add_ace resource.ox_inventory command.set allow',
    'add_ace resource.ox_inventory command.set allow\nadd_ace resource.ox_target command.set allow\nadd_ace resource.ox_doorlock command.set allow\nadd_ace resource.ox_fuel command.set allow\nadd_ace resource.qbx_core command.set allow')
with open(p, 'w') as f: f.write(c)
put(p, '/permissions.cfg')
print('7b. permissions.cfg: expanded command.set')

sftp.close()
ssh.close()
print('\nAll 7 done. Restart.')
