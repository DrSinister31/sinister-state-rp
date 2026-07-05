import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

# 1. Remove from NPWD apps
p = os.path.join(tmp, '_npwd.json')
sftp.get('/resources/[npwd]/npwd/config.json', p)
with open(p) as f: content = f.read()
content = content.replace(', "sinister_weather"', '')
with open(p, 'w') as f: f.write(content)
sftp.put(p, '/resources/[npwd]/npwd/config.json')
print('NPWD config: sinister_weather removed')
os.unlink(p)

# 2. Disable ensure
p = os.path.join(tmp, '_weather.cfg')
sftp.get('/resources/[standalone]/_cfg/weather_ensures.cfg', p)
with open(p) as f: c = f.read()
c = c.replace('ensure sinister_weather', '-- ensure sinister_weather DISABLED (UI overflow)')
with open(p, 'w') as f: f.write(c)
sftp.put(p, '/resources/[standalone]/_cfg/weather_ensures.cfg')
print('weather_ensures: disabled')
os.unlink(p)

sftp.close()
ssh.close()
print('Restart.')
