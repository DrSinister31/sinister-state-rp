import paramiko, os, tempfile, struct, zlib

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

def get_file(remote): p = os.path.join(tmp, os.path.basename(remote).replace('/','_')); sftp.get(remote, p); return p
def put_file(local, remote): sftp.put(local, remote)

# 1. EASYADMIN - remove goto from config.lua
p = get_file('/resources/[standalone]/easyadmin/config.lua')
with open(p) as f: lines = f.readlines()
with open(p, 'w') as f:
    for line in lines:
        if 'goto ' in line or ('::' in line and 'function' not in line):
            f.write('-- goto removed\n')
        else:
            f.write(line)
put_file(p, '/resources/[standalone]/easyadmin/config.lua')

p2 = get_file('/resources/[standalone]/easyadmin/server/commands.lua')
with open(p2) as f: lines = p2_lines = f.readlines()
with open(p2, 'w') as f:
    for line in lines:
        if 'goto ' in line or ('::' in line and 'function' not in line):
            f.write('-- goto removed\n')
        else:
            f.write(line)
put_file(p2, '/resources/[standalone]/easyadmin/server/commands.lua')
print('1. easyadmin: goto removed from config + commands')

# 2. SINISTER_CHESS presets.lua
p3 = get_file('/resources/[standalone]/sinister_chess/server/presets.lua')
with open(p3) as f: lines = f.readlines()
with open(p3, 'w') as f:
    for line in lines:
        line = line.replace('MySQL.query.await', 'exports.oxmysql:query')
        line = line.replace('MySQL.insert.await', 'exports.oxmysql:insert')
        f.write(line)
put_file(p3, '/resources/[standalone]/sinister_chess/server/presets.lua')
print('2. sinister_chess: MySQL->oxmysql')

# 3. SINISTER_STORE database.lua - fix ALL remaining MySQL.* patterns
p4 = get_file('/resources/[standalone]/sinister_store/server/database.lua')
with open(p4) as f: lines = f.readlines()
with open(p4, 'w') as f:
    for line in lines:
        line = line.replace('exports.oxmysql:query.await', 'exports.oxmysql:query')
        line = line.replace('exports.oxmysql:insert.await', 'exports.oxmysql:insert')
        line = line.replace('exports.oxmysql:update.await', 'exports.oxmysql:update')
        f.write(line)
put_file(p4, '/resources/[standalone]/sinister_store/server/database.lua')
print('3. sinister_store: MySQL patterns fixed')

# 4. RAVN_LOGS - comment out broken require
p5 = get_file('/resources/[standalone]/ravn_logs/server/server.lua')
with open(p5) as f: lines = f.readlines()
with open(p5, 'w') as f:
    for line in lines:
        if 'require' in line and ('webhook' in line or 'server.webhook' in line):
            f.write('-- require fixed\n')
        else:
            f.write(line)
put_file(p5, '/resources/[standalone]/ravn_logs/server/server.lua')
print('4. ravn_logs: webhook require removed')

# 5. SINISTER_CRAFTING - fix orphaned return
p6 = get_file('/resources/[standalone]/sinister_crafting/server/main.lua')
with open(p6) as f: lines = f.readlines()
clean = []
skip = False
for line in lines:
    s = line.strip()
    if '-- tablelength function removed' in s:
        skip = True
        clean.append('-- removed\n')
        continue
    if skip:
        if s.startswith('-- removed') or s == '':
            clean.append('-- removed\n')
        elif 'return' in s or s.startswith('end'):
            skip = False
            if s.startswith('end') and 'function' not in s:
                clean.append('-- removed end\n')
            else:
                clean.append(line)
        else:
            clean.append('-- removed\n')
    else:
        clean.append(line)
with open(p6, 'w') as f: f.writelines(clean)
put_file(p6, '/resources/[standalone]/sinister_crafting/server/main.lua')
print('5. sinister_crafting: orphaned code removed')

# 6. SINISTER_CHAT - clean server.lua
pc = os.path.join(tmp, '_chat_clean.lua')
with open(pc, 'w') as f:
    f.write('local locales = { en = { chat_title = "Sinister H-Town", job_prefix = "[Job]", ooc = "OOC" } }\n')
    f.write('print("^2[sinister_chat] ^7Server ready")\n')
put_file(pc, '/resources/[standalone]/sinister_chat/server/server.lua')
print('6. sinister_chat: server.lua rewritten clean')

# 7. SINISTER_AI police_ai.lua
p7 = get_file('/resources/[standalone]/sinister_ai/server/police_ai.lua')
with open(p7) as f: c = f.read()
c = c.replace('GetPlayerPed(source)', 'GetPlayerPed(pid)')
with open(p7, 'w') as f: f.write(c)
put_file(p7, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('7. sinister_ai: GetPlayerPed(source)->GetPlayerPed(pid)')

# 8. SINISTER_LOADINGV2 - create placeholder logo
def make_png(w, h, r, g, b):
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    raw = b''
    for y in range(h): raw += b'\x00' + bytes([r, g, b]) * w
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
logo_path = os.path.join(tmp, 'logo.png')
with open(logo_path, 'wb') as f: f.write(make_png(1, 1, 191, 87, 0))
d = '/resources/[standalone]/sinister_loadingv2/html/media'
for part in d.strip('/').split('/'):
    try: sftp.mkdir('/' + '/'.join(d.strip('/').split('/')[:d.strip('/').split('/').index(part)+1]))
    except: pass
try:
    put_file(logo_path, '/resources/[standalone]/sinister_loadingv2/html/media/logo.png')
    print('8. sinister_loadingv2: logo.png created')
except Exception as e:
    print(f'8. logo error: {e}')
os.unlink(logo_path)

sftp.close()
ssh.close()
print('\nAll done. Restart.')
