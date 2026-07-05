import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()

# Fix sinister_store package_handler.lua - colon -> dot
tmp = os.path.join(tempfile.gettempdir(), '_fix_pkg.lua')
sftp.get('/resources/[standalone]/sinister_store/server/package_handler.lua', tmp)
with open(tmp) as f:
    content = f.read()

# Fix all instances of exports['qbx_core']:Functions -> exports['qbx_core'].Functions
content = content.replace("exports['qbx_core']:Functions", "exports['qbx_core'].Functions")
content = content.replace("exports.qbx_core:GetPlayer", "exports.qbx_core.GetPlayer")

with open(tmp, 'w') as f:
    f.write(content)

sftp.put(tmp, '/resources/[standalone]/sinister_store/server/package_handler.lua')
print('sinister_store: package_handler.lua fixed (colon->dot)')
os.unlink(tmp)

# Also fix database.lua similarly 
tmp2 = os.path.join(tempfile.gettempdir(), '_fix_db.lua')
sftp.get('/resources/[standalone]/sinister_store/server/database.lua', tmp2)
with open(tmp2) as f:
    content = f.read()

content = content.replace("exports['qbx_core']:Functions", "exports['qbx_core'].Functions")
content = content.replace("exports.qbx_core:GetPlayer", "exports.qbx_core.GetPlayer")
# Also fix MySQL.* calls
content = content.replace("MySQL.", "exports.oxmysql:")

with open(tmp2, 'w') as f:
    f.write(content)

sftp.put(tmp2, '/resources/[standalone]/sinister_store/server/database.lua')
print('sinister_store: database.lua fixed')
os.unlink(tmp2)

# Fix server.lua too
tmp3 = os.path.join(tempfile.gettempdir(), '_fix_srv.lua')
try:
    sftp.get('/resources/[standalone]/sinister_store/server/server.lua', tmp3)
    with open(tmp3) as f:
        content = f.read()
    content = content.replace("exports['qbx_core']:Functions", "exports['qbx_core'].Functions")
    content = content.replace("MySQL.", "exports.oxmysql:")
    with open(tmp3, 'w') as f:
        f.write(content)
    sftp.put(tmp3, '/resources/[standalone]/sinister_store/server/server.lua')
    print('sinister_store: server.lua fixed')
    os.unlink(tmp3)
except: pass

sftp.close()
ssh.close()
print('Done. Restart.')
