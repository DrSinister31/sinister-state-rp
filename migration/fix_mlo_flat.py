"""Fix nested MLOs: move contents of inner resource folder to root level."""
import paramiko, os, tempfile, shutil

HOST = 'nyc15.xgamingserver.com'
PORT = 2022
USER = 'nhxija4f.69162937'
PASS = 'Familia1!'

MLOS = {
    'sinister_cigarshop2': 'pp_pipedown',
    'sinister_vehiclerental': 'berts_car_rental',
    'sinister_realestate': 'ace_realestateagency',
    'sinister_medcenter': 'medical_center',
    'sinister_militarypolice': 'MP-Station',
    'sinister_laundromat': 'lev_laundromat',
}

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()

def download_dir(sftp, remote_path, local_path):
    """Download entire directory recursively."""
    os.makedirs(local_path, exist_ok=True)
    count = 0
    try:
        items = sftp.listdir_attr(remote_path)
    except:
        return 0
    
    for item in items:
        remote_full = f'{remote_path}/{item.filename}'
        local_full = os.path.join(local_path, item.filename)
        
        if item.st_mode & 0o40000:  # directory
            count += download_dir(sftp, remote_full, local_full)
        else:
            try:
                sftp.get(remote_full, local_full)
                count += 1
            except Exception as e:
                print(f'      FAIL download: {item.filename} - {e}')
    return count

def upload_dir(sftp, local_path, remote_path):
    """Upload directory recursively."""
    os.makedirs(local_path, exist_ok=True)
    count = 0
    for root, dirs, files in os.walk(local_path):
        rel = os.path.relpath(root, local_path)
        if rel == '.':
            remote_root = remote_path
        else:
            remote_root = f'{remote_path}/{rel.replace(os.sep, "/")}'
        
        try: sftp.stat(remote_root)
        except:
            d = ''
            for part in remote_root.strip('/').split('/'):
                d += '/' + part
                try: sftp.mkdir(d) 
                except: pass
        
        for f in files:
            local_full = os.path.join(root, f)
            remote_full = f'{remote_root}/{f}'
            try:
                sftp.put(local_full, remote_full)
                count += 1
            except Exception as e:
                print(f'      FAIL upload: {f} - {e}')
    return count

for mlo_name, subfolder in MLOS.items():
    base = f'/resources/[standalone]/{mlo_name}'
    sub = f'{base}/{subfolder}'
    
    print(f'\n  {mlo_name}:')
    
    # Download the inner resource to local temp
    tmp_dir = os.path.join(tempfile.gettempdir(), mlo_name)
    if os.path.exists(tmp_dir):
        shutil.rmtree(tmp_dir)
    
    count = download_dir(sftp, sub, tmp_dir)
    print(f'    Downloaded {count} files from {subfolder}/')
    
    # Upload to root of the MLO directory
    # This will place fxmanifest.lua and stream/ directly in the base
    count2 = upload_dir(sftp, tmp_dir, base)
    print(f'    Uploaded {count2} files to root of {mlo_name}')
    
    # Clean up temp
    shutil.rmtree(tmp_dir)

sftp.close()
ssh.close()
print('\nAll MLOs fixed. Restart server.')
