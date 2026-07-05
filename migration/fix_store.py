import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# Fix sinister_store database.lua
tmp = os.path.join(tempfile.gettempdir(), '_fix_store.lua')
sftp.get('/resources/[standalone]/sinister_store/server/database.lua', tmp)

with open(tmp) as f:
    lines = f.readlines()

# Fix: line 99 is return, lines 100-104 are dead code after return
# Restructure: move log insert before return
new_lines = []
skip = False
for i, line in enumerate(lines):
    lineno = i + 1
    if lineno == 98:  # function markFailed
        new_lines.append(line)
    elif lineno == 99:  # return statement
        new_lines.append('    if reason then\n')
        new_lines.append('        MySQL.insert.await(\'INSERT INTO sinister_purchase_log (transaction_id, player_identifier, package_name, action, result, details) VALUES (?, ?, ?, ?, ?, ?)\', {\n')
        new_lines.append('            transactionId, \'\', \'\', \'failed\', \'failure\', tostring(reason)\n')
        new_lines.append('        })\n')
        new_lines.append('    end\n')
        new_lines.append(line)  # the return
        skip = True  # skip old lines 100-104
    elif skip and lineno <= 104:
        pass
    else:
        new_lines.append(line)

with open(tmp, 'w') as f:
    f.writelines(new_lines)

sftp.put(tmp, '/resources/[standalone]/sinister_store/server/database.lua')
print('sinister_store: database.lua fixed')
os.unlink(tmp)

# Check sinister_chat locales
print('\nsinister_chat locales:')
try:
    for item in sorted(sftp.listdir_attr('/resources/[standalone]/sinister_chat/locales')):
        print(f'  {item.filename}')
except Exception as e:
    print(f'  ERROR: {e}')

# Check server.lua line 3
tmp2 = os.path.join(tempfile.gettempdir(), '_chat_srv.lua')
try:
    sftp.get('/resources/[standalone]/sinister_chat/server/server.lua', tmp2)
    with open(tmp2) as f:
        lines = f.readlines()
        for i in range(min(3, len(lines))):
            print(f'  server.lua line {i+1}: {lines[i].rstrip()}')
    os.unlink(tmp2)
except: pass

sftp.close()
ssh.close()
