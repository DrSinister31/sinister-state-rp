-- Migration: Add passcode + skin_hash to user_skins
-- Run this in Supabase SQL Editor

ALTER TABLE user_skins ADD COLUMN IF NOT EXISTS passcode TEXT UNIQUE;
ALTER TABLE user_skins ADD COLUMN IF NOT EXISTS skin_hash TEXT;

-- Generate passcodes and hashes for existing skins
DO $$
DECLARE
    r RECORD;
    new_passcode TEXT;
    new_hash TEXT;
BEGIN
    FOR r IN SELECT id, steam_id, skin_data FROM user_skins WHERE passcode IS NULL LOOP
        new_passcode := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4))
                     || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4));
        new_hash := substr(encode(digest(r.skin_data::text, 'sha256'), 'hex'), 1, 12);
        
        UPDATE user_skins SET passcode = new_passcode, skin_hash = new_hash WHERE id = r.id;
    END LOOP;
END $$;

-- Add index for passcode lookups
CREATE INDEX IF NOT EXISTS idx_user_skins_passcode ON user_skins(passcode);
CREATE INDEX IF NOT EXISTS idx_user_skins_skin_hash ON user_skins(skin_hash);
