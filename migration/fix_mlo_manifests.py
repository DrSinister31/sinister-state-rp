import paramiko, os, tempfile

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

for mlo_name, subfolder in MLOS.items():
    base = f'/resources/[standalone]/{mlo_name}'
    
    try:
        files = sftp.listdir_attr(f'{base}/{subfolder}')
        ytyp_files = [f.filename for f in files if f.filename.endswith('.ytyp')]
        ydr_files = [f.filename for f in files if f.filename.endswith('.ydr')]
        print(f'  {mlo_name}: {len(ytyp_files)} ytyp, {len(ydr_files)} ydr')
        
        manifest = f'''fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

author 'Sinister H-Town'
description '{mlo_name} MLO'

files {{
    '{subfolder}/**/*',
}}
'''
        for yt in ytyp_files:
            manifest += f"data_file 'DLC_ITYP_REQUEST' '{subfolder}/{yt}'\n"
        
        tmp = os.path.join(tempfile.gettempdir(), f'_fx_{mlo_name}.lua')
        with open(tmp, 'w') as f:
            f.write(manifest)
        sftp.put(tmp, f'{base}/fxmanifest.lua')
        os.unlink(tmp)
        print(f'    fxmanifest.lua created')
        
    except Exception as e:
        print(f'  {mlo_name}: ERROR {e}')

sftp.close()
ssh.close()
print('\nDone.')
