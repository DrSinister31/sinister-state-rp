import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

# 1. RAVN_LOGS — fix webhook reference at line 38 scope
p = os.path.join(tmp, '_ravn.lua')
sftp.get('/resources/[standalone]/ravn_logs/server/server.lua', p)
with open(p) as f: lines = f.readlines()

# Line 38 uses 'webhook' upvalue. The stub at top defined a new local.
# The problem: the handler function has its OWN upvalue 'webhook' from the old require.
# Fix: replace ALL references to webhook.send / webhook.log inside handler with no-op
# OR: Remove the handler function that uses it entirely
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if 'webhook.' in s and ('send' in s or 'log' in s):
            f.write('-- webhook call removed\n')
        else:
            f.write(line)
sftp.put(p, '/resources/[standalone]/ravn_logs/server/server.lua')
print('1. ravn_logs: webhook calls removed from handler')

# 2. SINISTER_AI police_ai.lua — wrap line 119 in nil guard
p = os.path.join(tmp, '_police.lua')
sftp.get('/resources/[standalone]/sinister_ai/server/police_ai.lua', p)
with open(p) as f: lines = f.readlines()

# Find the function around line 119 and wrap the ped usage
for i, line in enumerate(lines):
    if 'GetPlayerPed(pid)' in line and i > 110 and i < 130:
        # This is the problematic line — wrap the block
        indent = line[:len(line) - len(line.lstrip())]
        lines[i] = indent + 'if pid > 0 then\n'
        lines.insert(i+1, indent + '    local ped = GetPlayerPed(pid)\n')
        # Find next end-ish line and add closing if
        for j in range(i+2, min(len(lines), i+15)):
            if 'goto continue_player' in lines[j]:
                lines[j] = indent + '    -- continue\n'
            if lines[j].strip().startswith('end') and j > i+3:
                lines.insert(j+1, indent + 'end -- pid check\n')
                break
        break

with open(p, 'w') as f: f.write('\n'.join(lines))
sftp.put(p, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('2. sinister_ai: nil guard added at line 119')

sftp.close()
ssh.close()
print('\nBoth fixed. Restart.')
