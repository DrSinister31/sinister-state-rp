"""Download all files from old Nodecraft server we need for migration."""
import ftplib
import os
import sys

HOST = "79.127.172.121"
PORT = 21
USER = "FEN8gHlIbozd1X"
PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"

QBOX_BASE = "/servers/QboxProject_4826CC.base"
RESOURCES_BASE = f"{QBOX_BASE}/resources"
OUTDIR = os.path.join(os.path.dirname(__file__), "texas_files")

# Texas-modified config files to grab (overwrite Qbox defaults)
CONFIG_FILES = {
    # Texas job names + DOJ roles
    f"{RESOURCES_BASE}/[qbx]/qbx_core/shared/jobs.lua": 
        os.path.join(OUTDIR, "qbx_core/shared/jobs.lua"),
    # Fixed "Texas EMS" quoted keys  
    f"{RESOURCES_BASE}/[qbx]/qbx_ambulancejob/config/shared.lua":
        os.path.join(OUTDIR, "qbx_ambulancejob/config/shared.lua"),
    # Police configs
    f"{RESOURCES_BASE}/[qbx]/qbx_police/config.lua":
        os.path.join(OUTDIR, "qbx_police/config.lua"),
    # NPWD config (from old server, has their app list)
    f"{RESOURCES_BASE}/[npwd]/npwd/config.json":
        os.path.join(OUTDIR, "npwd_old/config.json"),
    # Old server.cfg for reference
    f"{QBOX_BASE}/server.cfg":
        os.path.join(OUTDIR, "old_server.cfg"),
}

# MLO resources to download entirely
MLO_RESOURCES = [
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
    "sinister_mansion",
    "sinister_real_estate",
    "sinister_vehicle_rentals",
    "sinister_park_ranger",
    "sinister_realtor_office",
]

# Other resources to download
EXTRA_DIRS = [
    "assets",
    "qbx_helicam",
    "qbx_dutyblips", 
    "qbx_evidence",
    "qbx_lockpick",
    "popcornrp_zancudoalert",
    "distortionz_cad",
]

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def download_file(ftp, remote, local):
    """Download a single file."""
    try:
        ensure_dir(os.path.dirname(local))
        with open(local, 'wb') as f:
            ftp.retrbinary(f"RETR {remote}", f.write)
        size = os.path.getsize(local)
        return size
    except Exception as e:
        print(f"      FAIL: {e}")
        return 0

def download_dir(ftp, remote_base, local_base):
    """Download an entire directory recursively, preserving structure."""
    file_count = 0
    total_size = 0
    
    def walk(dir_path, local_root):
        nonlocal file_count, total_size
        try:
            items = ftp.mlsd(dir_path)
        except:
            return
        
        for name, facts in items:
            if name in (".", ".."):
                continue
            full_remote = f"{dir_path}/{name}" if dir_path and not dir_path.endswith("/") else f"{dir_path}{name}"
            
            if facts.get("type") == "dir":
                walk(full_remote, local_root)
            elif facts.get("type") == "file":
                # Determine relative path
                rel_path = full_remote[len(remote_base):].lstrip("/")
                local_path = os.path.join(local_root, rel_path)
                
                size = download_file(ftp, full_remote, local_path)
                if size > 0:
                    file_count += 1
                    total_size += size
                    if file_count % 20 == 0:
                        print(f"        {file_count} files ({total_size:,} bytes)...")
    
    try:
        ftp.cwd(remote_base)
    except Exception as e:
        print(f"      Cannot access directory: {e}")
        return 0, 0
    
    walk(remote_base, local_base)
    return file_count, total_size

def main():
    print(f"Connecting to old server...")
    ftp = ftplib.FTP()
    ftp.connect(HOST, PORT, timeout=30)
    ftp.login(USER, PASS)
    print("Connected!\n")
    
    # Step 1: Download config files
    print("=" * 60)
    print("STEP 1: Downloading Texas-modified config files")
    print("=" * 60)
    for remote, local in CONFIG_FILES.items():
        filename = os.path.basename(local)
        print(f"  {filename}...", end="", flush=True)
        size = download_file(ftp, remote, local)
        if size > 0:
            print(f" {size:,} bytes OK")
        else:
            print(" FAILED")
    
    # Step 2: Download MLO resources
    print("\n" + "=" * 60)
    print("STEP 2: Downloading MLO resources")
    print("=" * 60)
    total_mlo_files = 0
    total_mlo_size = 0
    for mlo in MLO_RESOURCES:
        remote_path = f"{RESOURCES_BASE}/[standalone]/{mlo}"
        local_path = os.path.join(OUTDIR, "mlos", mlo)
        print(f"  {mlo}...")
        count, size = download_dir(ftp, remote_path, local_path)
        print(f"    {count} files ({size:,} bytes)")
        total_mlo_files += count
        total_mlo_size += size
    print(f"\n  MLOs total: {total_mlo_files} files ({total_mlo_size:,} bytes)")
    
    # Step 3: Download extra resources
    print("\n" + "=" * 60)
    print("STEP 3: Downloading companion + assets resources")
    print("=" * 60)
    for extra in EXTRA_DIRS:
        remote_path = f"{RESOURCES_BASE}/[standalone]/{extra}"
        local_path = os.path.join(OUTDIR, "extra", extra)
        print(f"  {extra}...")
        count, size = download_dir(ftp, remote_path, local_path)
        print(f"    {count} files ({size:,} bytes)")
    
    ftp.quit()
    print(f"\nAll files saved to: {OUTDIR}")

if __name__ == "__main__":
    main()
