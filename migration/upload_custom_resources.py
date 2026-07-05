"""Create resource directory structure on new XGamingServer and upload local custom resources."""
import paramiko
import os
import sys

HOST = "nyc15.xgamingserver.com"
PORT = 2022
USER = "nhxija4f.69162937"
PASS = "Familia1!"

# Directories to create on new server
CREATE_DIRS = [
    "/resources/[ox]",
    "/resources/[qbx]",
    "/resources/[standalone]",
    "/resources/[voice]",
    "/resources/[npwd]",
    "/resources/[npwd-apps]",
    "/resources/[assets]",
]

# Local resources to upload (from the project)
# Root level resources (go in [standalone])
ROOT_RESOURCES = [
    "fix_black",
    "synix_bridge",
    "ps_lib",
]

# Custom sinister_* resources (go in [standalone])
SINISTER_RESOURCES = [
    "sinister_ai",
    "sinister_airspace",
    "sinister_apps",
    "sinister_blips",
    "sinister_cad",
    "sinister_clockin",
    "sinister_clothing",
    "sinister_crime",
    "sinister_hijacking",
    "sinister_licenses",
    "sinister_loadscreen",
    "sinister_realtor",
    "sinister_syntok",
    "sinister_underworld",
    "sinister_zoner",
]

# ps-mdt
MDT_RESOURCE = "ps-mdt"

PROJECT_ROOT = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"

# Files/dirs to exclude from upload
EXCLUDES = {
    "node_modules", ".git", ".pnpm-store", "pnpm-lock.yaml", 
    ".gitignore", ".gitkeep", "__pycache__", ".next",
    "delete", ".opencode", "DiscordBot", "Kronus", "WebApp",
    "pe_extract", "ef_clothing_extracted", "migration",
    ".env", "railway.toml", "requirements.txt", "start.sh",
    "loading_preview.html", "logo_test.html",
    "SESSION_HANDOFF.md", "deploy_fix.py",
}

def create_dirs(sftp):
    for d in CREATE_DIRS:
        try:
            sftp.mkdir(d)
            print(f"  CREATED {d}")
        except IOError:
            print(f"  EXISTS  {d}")

def upload_directory(sftp, local_dir, remote_dir):
    """Upload entire directory recursively via SFTP."""
    file_count = 0
    
    for root, dirs, files in os.walk(local_dir):
        # Filter excluded dirs
        dirs[:] = [d for d in dirs if d not in EXCLUDES]
        
        # Compute remote path
        rel = os.path.relpath(root, local_dir)
        if rel == ".":
            remote_root = remote_dir
        else:
            remote_root = remote_dir + "/" + rel.replace("\\", "/")
        
        # Create remote directory
        try:
            sftp.stat(remote_root)
        except FileNotFoundError:
            try:
                sftp.mkdir(remote_root)
            except:
                pass
        
        for f in files:
            if f in EXCLUDES:
                continue
            local_path = os.path.join(root, f)
            remote_path = remote_root + "/" + f.replace("\\", "/")
            try:
                sftp.put(local_path, remote_path)
                file_count += 1
                if file_count % 50 == 0:
                    print(f"    {file_count} files uploaded...")
            except Exception as e:
                print(f"    FAIL {f}: {e}")
    
    return file_count

def main():
    print("Connecting to new server...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, PORT, USER, PASS, timeout=30)
    sftp = ssh.open_sftp()
    
    # Step 1: Create directories
    print("\n=== Creating resource directories ===")
    create_dirs(sftp)
    
    # Step 2: Upload root-level resources
    print("\n=== Uploading root-level resources ===")
    for res in ROOT_RESOURCES:
        local = os.path.join(PROJECT_ROOT, res)
        if os.path.isdir(local):
            remote = f"/resources/[standalone]/{res}"
            print(f"  {res}...")
            count = upload_directory(sftp, local, remote)
            print(f"    {res}: {count} files")
        else:
            print(f"  SKIP {res}: not found locally")
    
    # Step 3: Upload sinister_* resources
    print("\n=== Uploading sinister_* resources ===")
    for res in SINISTER_RESOURCES:
        local = os.path.join(PROJECT_ROOT, res)
        if os.path.isdir(local):
            remote = f"/resources/[standalone]/{res}"
            print(f"  {res}...")
            count = upload_directory(sftp, local, remote)
            print(f"    {res}: {count} files")
        else:
            print(f"  SKIP {res}: not found locally")
    
    # Step 4: Upload ps-mdt
    print("\n=== Uploading ps-mdt ===")
    local = os.path.join(PROJECT_ROOT, "ps-mdt")
    if os.path.isdir(local):
        count = upload_directory(sftp, local, "/resources/[standalone]/ps-mdt")
        print(f"  ps-mdt: {count} files")
    
    sftp.close()
    ssh.close()
    print("\nDone uploading custom resources!")

if __name__ == "__main__":
    main()
