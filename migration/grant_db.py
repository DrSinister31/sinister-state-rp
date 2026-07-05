import pymysql

conn = pymysql.connect(
    host='91.99.71.34', port=3307,
    user='u10208_dSneZNQyLN',
    password='c.=ib4KPvLDR@Z4yLPH8oSkX',
    database='s10208_MySQL', charset='utf8mb4',
    connect_timeout=30
)
cursor = conn.cursor()

# Check current hosts
cursor.execute("SELECT user, host FROM mysql.user WHERE user='u10208_dSneZNQyLN'")
print("Current hosts:")
for row in cursor.fetchall():
    print(f"  {row[0]}@{row[1]}")

# Grant from game server IP
try:
    cursor.execute("GRANT ALL PRIVILEGES ON s10208_MySQL.* TO 'u10208_dSneZNQyLN'@'172.93.104.174' IDENTIFIED BY 'c.=ib4KPvLDR@Z4yLPH8oSkX'")
    print("Granted @172.93.104.174")
except Exception as e:
    print(f"Grant IP: {e}")

# Also try wildcard
try:
    cursor.execute("GRANT ALL PRIVILEGES ON s10208_MySQL.* TO 'u10208_dSneZNQyLN'@'%' IDENTIFIED BY 'c.=ib4KPvLDR@Z4yLPH8oSkX'")
    print("Granted @%")
except Exception as e:
    print(f"Grant wildcard: {e}")

cursor.execute("FLUSH PRIVILEGES")
print("Privileges flushed")

# Verify
cursor.execute("SELECT user, host FROM mysql.user WHERE user='u10208_dSneZNQyLN'")
print("Updated hosts:")
for row in cursor.fetchall():
    print(f"  {row[0]}@{row[1]}")

cursor.close()
conn.close()
print("\nDone. Restart the server.")
