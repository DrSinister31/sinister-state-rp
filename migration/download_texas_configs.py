"""Download Texas-modified config files from old Nodecraft server via FTP."""
import ftplib
import os
import sys

HOST = "79.127.172.121"
PORT = 21
USER = "FEN8gHlIbozd1X"
PASS = 'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA'

BASE = "/servers/QboxProject_4826CC.base/resources"
OUTDIR = os.path.join(os.path.dirname(__file__), "texas_files")

# Files we need from the old server
TO_GRAB = [
    # Texas-modified configs
    ("[qbx]/qbx_core/shared/jobs.lua", "qbx_core/shared/jobs.lua"),
    ("[qbx]/qbx_ambulancejob/config/shared.lua", "qbx_ambulancejob/config/shared.lua"),
    ("[qbx]/qbx_police/config.lua", "qbx_police/config.lua"),
    ("[qbx]/qbx_police/shared/config.lua", "qbx_police/shared/config.lua"),
    ("[qbx]/qbx_ambulancejob/config.lua", "qbx_ambulancejob/config.lua"),
    ("[qbx]/qbx_management/config.lua", "qbx_management/config.lua"),
    
    # NPWD config (to modify with our apps)
    ("[npwd]/npwd/config.json", "npwd/config.json"),
    
    # Companion resources
    ("[standalone]/qbx_helicam/fxmanifest.lua", "qbx_helicam/fxmanifest.lua"),
    ("[standalone]/qbx_dutyblips/fxmanifest.lua", "qbx_dutyblips/fxmanifest.lua"),
    ("[standalone]/qbx_evidence/fxmanifest.lua", "qbx_evidence/fxmanifest.lua"),
    ("[standalone]/qbx_lockpick/fxmanifest.lua", "qbx_lockpick/fxmanifest.lua"),
    ("[standalone]/popcornrp_zancudoalert/fxmanifest.lua", "companion/popcornrp_zancudoalert/fxmanifest.lua"),
    ("[standalone]/distortionz_cad/fxmanifest.lua", "companion/distortionz_cad/fxmanifest.lua"),
]

# Directories to download entirely
MLO_RESOURCES = [
    "sinister_mansion",
    "sinister_realtor_office",
    "sinister_courthouse",
    "sinister_fire_station",
    "sinister_military_police",
    "sinister_laundromat",
    "sinister_motels",
    "sinister_clinic",
    "sinister_cigar_shop",
    "sinister_cigar_shop2",
    "sinister_fuel_station",
    "sinister_postop",
    "sinister_medical_center",
    "sinister_hacker_space",
    "sinister_real_estate",
    "sinister_vehicle_rentals",
    "sinister_park_ranger",
]

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def download_file(ftp, remote_path, local_path):
    try:
        ensure_dir(os.path.dirname(local_path))
        with open(local_path, 'wb') as f:
            ftp.retrbinary(f"RETR {remote_path}", f.write)
        size = os.path.getsize(local_path)
        print(f"  OK  {local_path} ({size} bytes)")
        return True
    except Exception as e:
        print(f"  FAIL {remote_path}: {e}")
        return False

def download_dir(ftp, remote_base, local_base, resource_name):
    """Download entire resource directory."""
    remote_path = f"{remote_base}/{resource_name}"
    local_path = os.path.join(local_base, "mlos", resource_name)
    
    print(f"\n  Downloading directory: {resource_name}")
    try:
        ftp.cwd(remote_path)
    except:
        print(f"    NOT FOUND on server, skipping")
        return
    
    file_count = 0
    dirs_processed = set()
    
    def walk(dir_path="", depth=0):
        nonlocal file_count
        if depth > 10:
            return
        try:
            items = ftp.mlsd(dir_path if dir_path else ".")
        except:
            return
        
        for name, facts in items:
            if name in (".", ".."):
                continue
            full_remote = f"{dir_path}/{name}" if dir_path else name
            full_local = os.path.join(local_path, full_remote.replace("/", os.sep))
            
            if facts.get("type") == "dir":
                walk(full_remote, depth + 1)
            elif facts.get("type") == "file":
                ensure_dir(os.path.dirname(full_local))
                try:
                    remote_file = f"{remote_path}/{full_remote}"
                    with open(full_local, 'wb') as f:
                        ftp.retrbinary(f"RETR {remote_file}", f.write)
                    file_count += 1
                    if file_count % 10 == 0:
                        print(f"    {file_count} files...")
                except Exception as e:
                    print(f"    FAIL {full_remote}: {e}")
    
    try:
        ftp.cwd(remote_path)
        walk(".")
        print(f"    Downloaded {file_count} files from {resource_name}")
    finally:
        try:
            ftp.cwd(BASE)
        except:
            pass

def main():
    print(f"Connecting to old server at {HOST}:{PORT}...")
    ftp = ftplib.FTP()
    ftp.connect(HOST, PORT, timeout=30)
    ftp.login(USER, PASS)
    print("Connected successfully!")
    
    # Download individual config files
    print("\n=== Downloading Texas-modified config files ===")
    success = 0
    for remote_rel, local_rel in TO_GRAB:
        remote = f"{BASE}/{remote_rel}"
        local = os.path.join(OUTDIR, local_rel)
        if download_file(ftp, remote, local):
            success += 1
    print(f"\nDownloaded {success}/{len(TO_GRAB)} config files")
    
    # Download MLO resources
    print("\n=== Downloading MLO resources ===")
    for mlo in MLO_RESOURCES:
        download_dir(ftp, BASE, OUTDIR, f"[standalone]/{mlo}")
    
    # Also download the assets resource
    print("\n=== Downloading assets resource ===")
    download_dir(ftp, BASE, OUTDIR, "[standalone]/assets")
    
    # Download full companion resources
    print("\n=== Downloading companion resources ===")
    companion_dirs = [
        "[standalone]/qbx_helicam",
        "[standalone]/qbx_dutyblips", 
        "[standalone]/qbx_evidence",
        "[standalone]/qbx_lockpick",
        "[standalone]/popcornrp_zancudoalert",
        "[standalone]/distortionz_cad",
    ]
    for comp_dir in companion_dirs:
        name = comp_dir.split("/")[-1]
        download_dir(ftp, BASE, os.path.join(OUTDIR, "companion"), comp_dir)
    
    ftp.quit()
    print(f"\nAll files saved to: {OUTDIR}")

if __name__ == "__main__":
    main()
