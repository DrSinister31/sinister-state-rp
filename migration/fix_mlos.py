"""Fix missing MLOs: create fxmanifest.lua and move assets to stream/ folder."""
import paramiko
import os

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

# MLO name -> subfolder containing the actual assets
MLOS = {
    "sinister_cigarshop2": "pp_pipedown",
    "sinister_vehiclerental": "berts_car_rental",
    "sinister_realestate": "ace_realestateagency",
    "sinister_medcenter": "medical_center",
    "sinister_militarypolice": "MP-Station",
    "sinister_laundromat": "lev_laundromat",
}

MINIMAL_MANIFEST = """fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

author 'Community MLO'
description 'Sinister H-Town MLO'

files {
    'stream/**/*',
}

data_file 'DLC_ITYP_REQUEST' 'stream/**/*.ytyp'
"""

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)

# Use SSH exec to move files (SFTP can't do renames across dirs)
for mlo_name, asset_folder in MLOS.items():
    base = f"/resources/[standalone]/{mlo_name}"
    stream_dir = f"{base}/stream"
    
    # Check if stream already exists
    sftp = ssh.open_sftp()
    try:
        sftp.stat(stream_dir)
        print(f"  {mlo_name}: stream/ already exists, skipping")
        sftp.close()
        continue
    except:
        sftp.close()
    
    # Create stream folder
    sftp = ssh.open_sftp()
    try:
        sftp.mkdir(stream_dir)
    except:
        pass
    sftp.close()
    
    # Move asset folder contents into stream/
    cmd = f"cd {base} && [ -d '{asset_folder}' ] && mv '{asset_folder}'/* stream/ 2>/dev/null; rmdir '{asset_folder}' 2>/dev/null; echo DONE"
    stdin, stdout, stderr = ssh.exec_command(cmd)
    result = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    print(f"  {mlo_name}: {result or 'moved'} {err if err else ''}")
    
    # Upload fxmanifest.lua
    import tempfile
    tmp = os.path.join(tempfile.gettempdir(), f'_fxmanifest_{mlo_name}.lua')
    with open(tmp, 'w') as f:
        f.write(MINIMAL_MANIFEST)
    
    sftp = ssh.open_sftp()
    sftp.put(tmp, f"{base}/fxmanifest.lua")
    sftp.close()
    os.unlink(tmp)
    
    print(f"  {mlo_name}: fxmanifest.lua created")

ssh.close()
print("\nAll MLO manifests created. Restart server.")
