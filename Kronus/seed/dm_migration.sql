-- DM Game State — run this in Supabase SQL Editor
-- Project: https://supabase.com/dashboard/project/yqfzaugbrwoluhkddcsh/sql/new

CREATE TABLE IF NOT EXISTS public.dm_game_state (
    id INTEGER PRIMARY KEY DEFAULT 1,
    active_context TEXT DEFAULT '',
    episode_log TEXT DEFAULT '',
    session_active BOOLEAN DEFAULT FALSE,
    session_channel_id BIGINT DEFAULT 0,
    in_game_date TEXT DEFAULT 'Frostfall 1, Year of the Shattered Crown',
    party_location TEXT DEFAULT 'Citadel of the Dragon-Garrison, exterior approach',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

INSERT INTO public.dm_game_state (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
