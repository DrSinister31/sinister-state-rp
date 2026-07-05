import paramiko, os

HOST = 'nyc15.xgamingserver.com'
PORT = 2022
USER = 'nhxija4f.69162937'
PASS = 'Familia1!'
base = r'C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master\resources\[standalone]'

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()

resources = ['sinister_chat', 'ravn_logs', 'easyadmin', 'sinister_store',
             'sinister_loadingv2', 'sinister_weather', 'sinister_emotes']
total = 0

for r in resources:
    local_dir = os.path.join(base, r)
    remote_dir = f'/resources/[standalone]/{r}'
    
    count = 0
    for root, dirs, files in os.walk(local_dir):
        rel = os.path.relpath(root, local_dir)
        if rel == '.':
            remote_root = remote_dir
        else:
            remote_root = remote_dir + '/' + rel.replace('\\', '/')
        
        d = ''
        for part in remote_root.strip('/').split('/'):
            d += '/' + part
            try: sftp.mkdir(d)
            except: pass
        
        for f in files:
            local = os.path.join(root, f)
            remote = remote_root + '/' + f
            try:
                sftp.put(local, remote)
                count += 1
            except Exception as e:
                pass
    
    total += count
    print(f'  {r}: {count} files')

sftp.close()
ssh.close()
print(f'\nTotal: {total} files. Restart server.')
