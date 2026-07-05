"""Download missing MLOs and companion resources with CORRECT names from old server.cfg."""
import ftplib
import os

HOST = "79.127.172.121"
PORT = 21
USER = "FEN8gHlIbozd1X"
PASS = "'CPb4{ams3Lzv=t~UlViy8(PJ)pqnA"

RESOURCES_BASE = "/servers/QboxProject_4826CC.base/resources"
OUTDIR = os.path.join(os.path.dirname(__file__), "texas_files")

# CORRECT MLO names from old server.cfg ensure list
MLO_CORRECT_NAMES = [
    "sinister_parkranger",
    "sinister_cigarshop2", 
    "sinister_vehiclerental",
    "sinister_realestate",
    "sinister_hackerspace",
    "sinister_medcenter",
    "sinister_militarypolice",
    "sinister_firestation",
    "sinister_courthouse",  # already downloaded
    "sinister_mansion",     # already downloaded
    "sinister_postop",      # already downloaded
    "sinister_motels",      # already downloaded
    "sinister_laundromat",  # already downloaded
    "sinister_clinic",      # already downloaded
]

# Companion resources from old server.cfg
COMPANION_NAMES = [
    "qbx_lockpick",
    "qbx_evidence",
    "qbx_dutyblips",
    "qbx_helicam",
    "distortionz_cad",
    "popcornrp_zancudoalert",  # already downloaded
]

EXCLUDES = {".", ".."}

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def download_file(ftp, remote, local):
    try:
        ensure_dir(os.path.dirname(local))
        with open(local, 'wb') as f:
            ftp.retrbinary(f"RETR {remote}", f.write)
        return os.path.getsize(local)
    except:
        return 0

def download_dir(ftp, remote_base, local_base):
    file_count = 0
    total_size = 0
    
    def walk(dir_path, base_remote, local_root):
        nonlocal file_count, total_size
        try:
            ftp.cwd(dir_path)
            items = []
            ftp.dir(items.append)
        except Exception as e:
            return
        
        for line in items:
            parts = line.split()
            if len(parts) < 9:
                continue
            name = " ".join(parts[8:])
            if name in EXCLUDES:
                continue
            is_dir = line[0] == 'd'
            
            full_remote = dir_path if dir_path.endswith("/") else dir_path + "/"
            full_remote += name
            
            rel_path = full_remote[len(base_remote):].lstrip("/")
            local_path = os.path.join(local_root, rel_path.replace("/", os.sep))
            
            if is_dir:
                walk(full_remote, base_remote, local_root)
            else:
                size = download_file(ftp, full_remote, local_path)
                if size > 0:
                    file_count += 1
                    total_size += size
                    if file_count % 30 == 0:
                        print(f"        {file_count} files ({total_size:,} bytes)...")
    
    walk(remote_base, remote_base, local_base)
    return file_count, total_size

def main():
    print("Connecting to old server...")
    ftp = ftplib.FTP()
    ftp.connect(HOST, PORT, timeout=30)
    ftp.login(USER, PASS)
    print("Connected!\n")
    
    total_files = 0
    total_bytes = 0
    
    # Download remaining MLOs
    print("=" * 60)
    print("Downloading MLOs (correct names from server.cfg)")
    print("=" * 60)
    for mlo in MLO_CORRECT_NAMES:
        local_path = os.path.join(OUTDIR, "mlos", mlo)
        if os.path.isdir(local_path) and len(os.listdir(local_path)) > 0:
            print(f"  {mlo} - already downloaded, skipping")
            continue
        remote_path = f"{RESOURCES_BASE}/[standalone]/{mlo}"
        try:
            ftp.cwd(remote_path)
            print(f"  {mlo}...", end="", flush=True)
            count, size = download_dir(ftp, remote_path, local_path)
            print(f" {count} files ({size:,} bytes)")
            total_files += count
            total_bytes += size
        except Exception as e:
            print(f"  {mlo} - NOT FOUND")
    
    # Download companion resources  
    print("\n" + "=" * 60)
    print("Downloading companion resources")
    print("=" * 60)
    for comp in COMPANION_NAMES:
        local_path = os.path.join(OUTDIR, "extra", comp)
        if os.path.isdir(local_path) and len(os.listdir(local_path)) > 0:
            print(f"  {comp} - already downloaded, skipping")
            continue
        remote_path = f"{RESOURCES_BASE}/[standalone]/{comp}"
        try:
            ftp.cwd(remote_path)
            print(f"  {comp}...", end="", flush=True)
            count, size = download_dir(ftp, remote_path, local_path)
            print(f" {count} files ({size:,} bytes)")
            total_files += count
            total_bytes += size
        except:
            print(f"  {comp} - NOT FOUND")
    
    # Also try to find assets resource in standalone base
    print("\n" + "=" * 60)
    print("Looking for assets resource")
    print("=" * 60)
    assets_path = f"{RESOURCES_BASE}/[standalone]/assets"
    try:
        ftp.cwd(assets_path)
        local_path = os.path.join(OUTDIR, "extra", "assets")
        print(f"  assets...", end="", flush=True)
        count, size = download_dir(ftp, assets_path, local_path)
        print(f" {count} files ({size:,} bytes)")
        total_files += count
        total_bytes += size
    except:
        print("  assets - NOT FOUND")
    
    ftp.quit()
    print(f"\n{'=' * 60}")
    print(f"Total: {total_files} files ({total_bytes:,} bytes)")
    print(f"Saved to: {OUTDIR}")

if __name__ == "__main__":
    main()
