-- Migration script to create the dino_skins table

CREATE TABLE IF NOT EXISTS public.dino_skins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    steam_id TEXT NOT NULL,
    dino_class TEXT NOT NULL,
    skin_code TEXT NOT NULL,
    skin_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Optional: Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_dino_skins_steam_id ON public.dino_skins(steam_id);
