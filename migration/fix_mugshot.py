"""Fix MugShotBase64 nested resource + upload updated server.cfg."""
import paramiko, os, tempfile, shutil

HOST = 'nyc15.xgamingserver.com'
PORT = 2022
USER = 'nhxija4f.69162937'
PASS = 'Familia1!'

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()

# Fix MugShotBase64
base = '/resources/[standalone]/MugShotBase64'
inner = f'{base}/MugShotBase64'

print('Fixing MugShotBase64...')
tmp_dir = os.path.join(tempfile.gettempdir(), 'mugshot_fix')
if os.path.exists(tmp_dir): shutil.rmtree(tmp_dir)

# Download inner resource
def download_dir(sftp, remote_path, local_path):
    os.makedirs(local_path, exist_ok=True)
    count = 0
    try:
        items = sftp.listdir_attr(remote_path)
    except: return 0
    for item in items:
        remote_full = f'{remote_path}/{item.filename}'
        local_full = os.path.join(local_path, item.filename)
        if item.st_mode & 0o40000:
            count += download_dir(sftp, remote_full, local_full)
        else:
            try:
                sftp.get(remote_full, local_full)
                count += 1
            except Exception as e:
                print(f'  FAIL: {item.filename}')
    return count

def upload_dir(sftp, local_path, remote_path):
    count = 0
    for root, dirs, files in os.walk(local_path):
        rel = os.path.relpath(root, local_path)
        remote_root = f'{remote_path}/{rel.replace(os.sep, "/")}' if rel != '.' else remote_path
        try: sftp.stat(remote_root)
        except:
            d = ''
            for part in remote_root.strip('/').split('/'):
                d += '/' + part
                try: sftp.mkdir(d)
                except: pass
        for f in files:
            try:
                sftp.put(os.path.join(root, f), f'{remote_root}/{f}')
                count += 1
            except: pass
    return count

count = download_dir(sftp, inner, tmp_dir)
print(f'  Downloaded {count} files')
count2 = upload_dir(sftp, tmp_dir, base)
print(f'  Uploaded {count2} files to root')
shutil.rmtree(tmp_dir)

# Upload server.cfg
cfg_local = os.path.join(os.path.dirname(__file__), 'server.cfg')
sftp.put(cfg_local, '/server.cfg')
print(f'server.cfg updated')

sftp.close()
ssh.close()
print('Done. Restart server.')
