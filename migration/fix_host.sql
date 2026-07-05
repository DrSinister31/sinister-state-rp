-- Fix: Grant the game server IP access to the database
-- Import this via your XGamingServer MySQL panel

-- Try granting access from the game server IP
GRANT ALL PRIVILEGES ON s10208_MySQL.* TO 'u10208_dSneZNQyLN'@'172.93.104.174' IDENTIFIED BY 'c.=ib4KPvLDR@Z4yLPH8oSkX';

-- Also try wildcard (any host)
GRANT ALL PRIVILEGES ON s10208_MySQL.* TO 'u10208_dSneZNQyLN'@'%' IDENTIFIED BY 'c.=ib4KPvLDR@Z4yLPH8oSkX';

FLUSH PRIVILEGES;
