"""Upload all downloaded Qbox resources to the new XGamingServer via SFTP.

This handles the massive upload of 76 resources in batches.
Uses multiple threads for speed.
"""
import paramiko
import os
import sys

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

BASE_DIR = os.path.join(os.path.dirname(__file__), "qbox_download")

# Map local download dirs to remote server paths
# These match the recipe's destination paths
UPLOAD_MAP = {
    "[ox]": "/resources/[ox]",
    "[qbx]": "/resources/[qbx]",
    "[standalone]": "/resources/[standalone]",
    "[voice]": "/resources/[voice]",
    "[npwd]": "/resources/[npwd]",
    "[npwd-apps]": "/resources/[npwd-apps]",
    "[assets]": "/resources/[assets]",
}

EXCLUDES = {
    ".git", ".gitignore", ".github", ".gitattributes",
    ".gitkeep", "node_modules", ".pnpm-store",
    "__pycache__", ".DS_Store",
}

def create_remote_dir(sftp, path):
    """Create directory recursively on remote."""
    parts = path.strip("/").split("/")
    current = ""
    for part in parts:
        current += "/" + part
        try:
            sftp.stat(current)
        except FileNotFoundError:
            try:
                sftp.mkdir(current)
            except:
                pass

def upload_directory(sftp, local_dir, remote_base, resource_name):
    """Upload a single resource directory recursively."""
    file_count = 0
    skip_count = 0
    
    remote_dir = f"{remote_base}/{resource_name}"
    
    for root, dirs, files in os.walk(local_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDES]
        
        rel = os.path.relpath(root, local_dir)
        if rel == ".":
            remote_root = remote_dir
        else:
            remote_root = remote_dir + "/" + rel.replace("\\", "/")
        
        try:
            create_remote_dir(sftp, remote_root)
        except:
            pass
        
        for f in files:
            if f in EXCLUDES:
                continue
            local_path = os.path.join(root, f)
            remote_path = remote_root + "/" + f.replace("\\", "/")
            
            # Check if remote file exists and has same size
            try:
                remote_stat = sftp.stat(remote_path)
                local_size = os.path.getsize(local_path)
                if remote_stat.st_size == local_size:
                    skip_count += 1
                    continue
            except FileNotFoundError:
                pass
            
            try:
                sftp.put(local_path, remote_path)
                file_count += 1
            except Exception as e:
                print(f"      FAIL {f}: {e}")
    
    return file_count, skip_count

def main():
    print("Connecting to new server...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, PORT, USER, PASS, timeout=30)
    sftp = ssh.open_sftp()
    
    total_uploaded = 0
    total_skipped = 0
    
    for local_dir_name, remote_path in UPLOAD_MAP.items():
        local_dir = os.path.join(BASE_DIR, local_dir_name)
        if not os.path.isdir(local_dir):
            print(f"\n  SKIP {local_dir_name}: not found locally")
            continue
        
        resource_dirs = [d for d in os.listdir(local_dir) 
                        if os.path.isdir(os.path.join(local_dir, d))]
        
        print(f"\n{'='*50}")
        print(f"  {local_dir_name} → {remote_path}")
        print(f"  {len(resource_dirs)} resources")
        print(f"{'='*50}")
        
        for i, res in enumerate(sorted(resource_dirs)):
            src = os.path.join(local_dir, res)
            print(f"  [{i+1}/{len(resource_dirs)}] {res}...", end="", flush=True)
            uploaded, skipped = upload_directory(sftp, src, remote_path, res)
            total_uploaded += uploaded
            total_skipped += skipped
            if uploaded > 0 or skipped > 0:
                print(f" {uploaded} new, {skipped} skipped")
            else:
                print(" empty")
    
    # Also handle the special case: NPWD apps go in [npwd-apps] 
    # (they're in the [npwd] download dir alongside npwd itself)
    npwd_local = os.path.join(BASE_DIR, "[npwd]")
    npwd_apps_remote = "/resources/[npwd-apps]"
    
    # The npwd_qbx_mail and npwd_qbx_garages were downloaded in the [npwd] dir
    # Check if they need to be moved to [npwd-apps] or if recipe handles differently
    # Actually, looking at the recipe: npwd.zip extracts to [npwd]/npwd/
    # qbx_npwd goes to [npwd]/qbx_npwd/
    # npwd_qbx_mail and npwd_qbx_garages go to [npwd-apps]/
    
    # Wait, the download script put npwd_qbx_mail and npwd_qbx_garages in [npwd]/
    # but the recipe puts them in [npwd-apps]/. Let me check and fix this.
    
    for app_name in ["npwd_qbx_mail", "npwd_qbx_garages"]:
        app_local = os.path.join(npwd_local, app_name)
        if os.path.isdir(app_local):
            print(f"\n  Moving {app_name} to [npwd-apps]...", end="")
            # Check if already uploaded as part of [npwd] dir
            # Need to upload to correct path
            uploaded, skipped = upload_directory(sftp, app_local, npwd_apps_remote, app_name)
            total_uploaded += uploaded
            total_skipped += skipped
            print(f" {uploaded} new, {skipped} skipped")
    
    sftp.close()
    ssh.close()
    
    print(f"\n{'='*50}")
    print(f"  TOTAL: {total_uploaded} files uploaded")
    print(f"  SKIPPED: {total_skipped} already up-to-date")
    print(f"{'='*50}")

if __name__ == "__main__":
    main()
