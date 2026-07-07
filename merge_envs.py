import os

master_dir = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"
env_files = [
    r"DiscordBot\.env",
    r"DiscordBot\.env.local",
    r"DiscordBot\bot\.env",
    r"WebApp\.env.local"
]

merged_keys = {}

# We read in reverse order of importance so the most specific ones overwrite
for file_path in env_files:
    full_path = os.path.join(master_dir, file_path)
    if os.path.exists(full_path):
        with open(full_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, val = line.split('=', 1)
                    key = key.strip()
                    val = val.strip()
                    # Only overwrite if the new value is not empty
                    if key not in merged_keys or val:
                        merged_keys[key] = val

master_env_path = os.path.join(master_dir, ".env")
with open(master_env_path, 'w', encoding='utf-8') as f:
    for k, v in merged_keys.items():
        f.write(f"{k}={v}\n")

print(f"Successfully merged {len(merged_keys)} environment variables into {master_env_path}")
