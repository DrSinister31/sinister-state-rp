"""Download all Qbox resources from GitHub per the official recipe.
Saves to: migration/qbox_download/

Handles both git clones and release ZIP downloads.
"""
import os
import sys
import subprocess
import urllib.request
import zipfile
import shutil
import time

BASE_DIR = os.path.join(os.path.dirname(__file__), "qbox_download")

# Resource categories and their download info
# Format: (name, source_type, url)
# source_type: "git" or "zip"

# ===== ox_* core resources (release ZIPs) =====
OX_RESOURCES = [
    ("ox_lib", "zip", "https://github.com/overextended/ox_lib/releases/latest/download/ox_lib.zip"),
    ("oxmysql", "zip", "https://github.com/overextended/oxmysql/releases/latest/download/oxmysql.zip"),
    ("ox_inventory", "zip", "https://github.com/overextended/ox_inventory/releases/latest/download/ox_inventory.zip"),
    ("ox_target", "zip", "https://github.com/overextended/ox_target/releases/latest/download/ox_target.zip"),
    ("ox_doorlock", "zip", "https://github.com/overextended/ox_doorlock/releases/latest/download/ox_doorlock.zip"),
    ("ox_fuel", "git", "https://github.com/overextended/ox_fuel"),
]

# ===== qbx_* resources (git clones) =====
QBX_RESOURCES = [
    "qbx_core",
    "qbx_vehicles",
    "qbx_scoreboard",
    "qbx_adminmenu",
    "qbx_vehiclesales",
    "qbx_vehicleshop",
    "qbx_houserobbery",
    "qbx_hud",
    "qbx_seatbelt",
    "qbx_management",
    "qbx_weed",
    "qbx_lapraces",
    "qbx_garages",
    "qbx_ambulancejob",
    "qbx_medical",
    "qbx_radialmenu",
    "qbx_police",
    "qbx_properties",
    "qbx_vehiclekeys",
    "qbx_mechanicjob",
    "qbx_vineyard",
    "qbx_scrapyard",
    "qbx_towjob",
    "qbx_streetraces",
    "qbx_storerobbery",
    "qbx_spawn",
    "qbx_smallresources",
    "qbx_recyclejob",
    "qbx_diving",
    "qbx_divegear",
    "qbx_cityhall",
    "qbx_truckrobbery",
    "qbx_pawnshop",
    "qbx_taxijob",
    "qbx_busjob",
    "qbx_newsjob",
    "qbx_jewelery",
    "qbx_bankrobbery",
    "qbx_truckerjob",
    "qbx_garbagejob",
    "qbx_drugs",
    "qbx_idcard",
    "qbx_binoculars",
    "qbx_carwash",
    "qbx_fireworks",
    "qbx_density",
    "qbx_customs",
    "qbx_chat_theme",
]

# ===== Standalone resources =====
STANDALONE_RESOURCES = [
    ("bob74_ipl", "git", "https://github.com/Bob74/bob74_ipl"),
    ("safecracker", "git", "https://github.com/Qbox-project/safecracker"),
    ("mhacking", "git", "https://github.com/Qbox-project/mhacking"),
    ("scully_emotemenu", "git", "https://github.com/Scullyy/scully_emotemenu"),
    ("ultra-voltlab", "git", "https://github.com/ultrahacx/ultra-voltlab"),
    ("informational", "git", "https://github.com/Qbox-project/informational"),
    ("MugShotBase64", "git", "https://github.com/BaziForYou/MugShotBase64"),
    ("Renewed-Banking", "zip", "https://github.com/Renewed-Scripts/Renewed-Banking/releases/latest/download/Renewed-Banking.zip"),
    ("illenium-appearance", "zip", "https://github.com/iLLeniumStudios/illenium-appearance/releases/latest/download/illenium-appearance.zip"),
    ("Renewed-Weathersync", "zip", "https://github.com/Renewed-Scripts/Renewed-Weathersync/releases/latest/download/Renewed-Weathersync.zip"),
    ("xt-prison", "zip", "https://github.com/xT-Development/xt-prison/releases/latest/download/xt-prison.zip"),
    ("vehiclehandler", "zip", "https://github.com/QuantumMalice/vehiclehandler/releases/latest/download/vehiclehandler.zip"),
    ("loadscreen", "zip", "https://github.com/D4isDAVID/loadscreen/releases/latest/download/loadscreen.zip"),
    ("mana_audio", "zip", "https://github.com/Manason/mana_audio/releases/latest/download/mana_audio.zip"),
    ("screencapture", "zip", "https://github.com/itschip/screencapture/releases/latest/download/screencapture.zip"),
]

# ===== Voice resources =====
VOICE_RESOURCES = [
    ("pma-voice", "git", "https://github.com/AvarianKnight/pma-voice"),
    ("mm_radio", "zip", "https://github.com/Qbox-project/mm_radio/releases/latest/download/mm_radio.zip"),
]

# ===== NPWD resources =====
NPWD_RESOURCES = [
    ("npwd", "zip", "https://github.com/project-error/npwd/releases/download/3.16.0/npwd.zip"),
    ("qbx_npwd", "git", "https://github.com/Qbox-project/qbx_npwd"),
    ("npwd_qbx_mail", "zip", "https://github.com/Qbox-project/npwd_qbx_mail/releases/latest/download/npwd_qbx_mail.zip"),
    ("npwd_qbx_garages", "zip", "https://github.com/Qbox-project/npwd_qbx_garages/releases/latest/download/npwd_qbx_garages.zip"),
]

# ===== Assets =====
ASSETS_RESOURCES = [
    ("pillbox", "git", "https://github.com/Lorenc95/pillbox"),
]

def run_cmd(cmd, cwd=None):
    """Run command and return success."""
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=120)
        return result.returncode == 0
    except:
        return False

def download_file_simple(url, dest):
    """Download a file with progress."""
    try:
        urllib.request.urlretrieve(url, dest)
        return os.path.exists(dest) and os.path.getsize(dest) > 0
    except Exception as e:
        print(f"      Download error: {e}")
        return False

def clone_git(name, url, dest):
    """Clone a git repository shallow."""
    if os.path.exists(dest):
        print(f"      Already exists, pulling...")
        if run_cmd(["git", "-C", dest, "pull", "--ff-only"]):
            return True
        print(f"      Pull failed, recloning...")
        shutil.rmtree(dest, ignore_errors=True)
    
    print(f"      Cloning from {url}...")
    return run_cmd(["git", "clone", "--depth", "1", url, dest])

def download_zip(name, url, dest):
    """Download and extract a ZIP release."""
    if os.path.exists(dest):
        print(f"      Already exists, skipping")
        return True
    
    zip_path = os.path.join(BASE_DIR, f"_tmp_{name}.zip")
    print(f"      Downloading from {url}...")
    
    if not download_file_simple(url, zip_path):
        print(f"      FAILED to download")
        return False
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            # Extract to temp dir first
            tmp_dir = os.path.join(BASE_DIR, f"_tmp_{name}")
            if os.path.exists(tmp_dir):
                shutil.rmtree(tmp_dir)
            zf.extractall(tmp_dir)
        
        # Move contents to dest (handle nested single dir)
        entries = os.listdir(tmp_dir)
        if len(entries) == 1 and os.path.isdir(os.path.join(tmp_dir, entries[0])):
            # Single nested directory - move it
            shutil.move(os.path.join(tmp_dir, entries[0]), dest)
        else:
            os.makedirs(dest, exist_ok=True)
            for entry in entries:
                shutil.move(os.path.join(tmp_dir, entry), os.path.join(dest, entry))
        
        shutil.rmtree(tmp_dir, ignore_errors=True)
        os.remove(zip_path)
        return True
    except Exception as e:
        print(f"      Extract error: {e}")
        return False

def process_batch(resources, category_name, dest_subdir):
    """Process a batch of resources."""
    dest_dir = os.path.join(BASE_DIR, dest_subdir)
    os.makedirs(dest_dir, exist_ok=True)
    
    print(f"\n{'='*60}")
    print(f"  {category_name} → {dest_subdir}")
    print(f"{'='*60}")
    
    success = 0
    for res in resources:
        if len(res) == 3:
            name, rtype, url = res
        else:
            name = res
            rtype = "git"
            url = f"https://github.com/Qbox-project/{name}"
        
        dest = os.path.join(dest_dir, name)
        print(f"  [{rtype.upper()}] {name}")
        
        if rtype == "git":
            ok = clone_git(name, url, dest)
        else:
            ok = download_zip(name, url, dest)
        
        if ok:
            success += 1
            print(f"      OK")
        else:
            print(f"      FAILED")
    
    print(f"  → {success}/{len(resources)} succeeded")
    return success == len(resources)

def main():
    os.makedirs(BASE_DIR, exist_ok=True)
    total = 0
    total_ok = 0
    
    # Download in order per recipe
    
    # 1. OX resources
    count = len(OX_RESOURCES)
    ok = process_batch(OX_RESOURCES, "OX Core", "[ox]")
    total += count
    if ok: total_ok += count
    
    # 2. QBX resources (with waste time to avoid throttling)
    for i in range(0, len(QBX_RESOURCES), 10):
        batch = QBX_RESOURCES[i:i+10]
        ok = process_batch(batch, f"QBX ({i+1}-{min(i+10, len(QBX_RESOURCES))})", "[qbx]")
        total += len(batch)
        if ok: total_ok += len(batch)
        if i + 10 < len(QBX_RESOURCES):
            print("\n  [Waiting 10s to avoid GitHub throttling...]")
            time.sleep(10)
    
    # 3. Standalone
    ok = process_batch(STANDALONE_RESOURCES, "Standalone", "[standalone]")
    total += len(STANDALONE_RESOURCES)
    if ok: total_ok += len(STANDALONE_RESOURCES)
    
    # 4. Voice
    ok = process_batch(VOICE_RESOURCES, "Voice", "[voice]")
    total += len(VOICE_RESOURCES)
    if ok: total_ok += len(VOICE_RESOURCES)
    
    # 5. NPWD
    ok = process_batch(NPWD_RESOURCES, "NPWD", "[npwd]")
    total += len(NPWD_RESOURCES)
    if ok: total_ok += len(NPWD_RESOURCES)
    
    # 6. Assets
    ok = process_batch(ASSETS_RESOURCES, "Assets", "[assets]")
    total += len(ASSETS_RESOURCES)
    if ok: total_ok += len(ASSETS_RESOURCES)
    
    print(f"\n{'='*60}")
    print(f"  TOTAL: {total_ok}/{total} resources downloaded successfully")
    print(f"  Saved to: {BASE_DIR}")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
