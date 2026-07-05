-- Solis-Grave DM System: Full Database Migration
-- Run in Supabase SQL Editor

-- 1. Campaign Game State
CREATE TABLE IF NOT EXISTS public.dm_game_state (
    id INTEGER PRIMARY KEY DEFAULT 1,
    active_context TEXT DEFAULT '',
    episode_log TEXT DEFAULT '',
    session_active BOOLEAN DEFAULT FALSE,
    session_channel_id BIGINT DEFAULT 0,
    session_type TEXT DEFAULT 'group',
    in_game_date TEXT DEFAULT 'Frostfall 1, Year of the Shattered Crown',
    party_location TEXT DEFAULT 'Citadel of the Dragon-Garrison, exterior approach',
    sovereign_discord_id BIGINT,
    sovereign_revealed BOOLEAN DEFAULT FALSE,
    campaign_status TEXT DEFAULT 'not_started',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO public.dm_game_state (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- 2. Player Characters (D&D sheets)
CREATE TABLE IF NOT EXISTS public.character_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discord_id BIGINT NOT NULL,
    campaign_id INTEGER DEFAULT 1,
    character_name TEXT NOT NULL,
    class TEXT,
    race TEXT,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    hp_current INTEGER NOT NULL DEFAULT 10,
    hp_max INTEGER NOT NULL DEFAULT 10,
    temp_hp INTEGER DEFAULT 0,
    ac INTEGER DEFAULT 10,
    speed INTEGER DEFAULT 30,
    initiative_bonus INTEGER DEFAULT 0,
    stats JSONB NOT NULL DEFAULT '{"str":10,"dex":10,"con":10,"int":10,"wis":10,"cha":10}',
    saving_throws JSONB DEFAULT '{}',
    skill_proficiencies JSONB DEFAULT '{}',
    spell_slots_max JSONB DEFAULT '{"1":0,"2":0,"3":0,"4":0,"5":0,"6":0,"7":0,"8":0,"9":0}',
    spell_slots_used JSONB DEFAULT '{"1":0,"2":0,"3":0,"4":0,"5":0,"6":0,"7":0,"8":0,"9":0}',
    spells_known JSONB DEFAULT '[]',
    inventory JSONB DEFAULT '[]',
    equipment JSONB DEFAULT '{}',
    conditions TEXT[] DEFAULT '{}',
    blood_purity INTEGER DEFAULT 10,
    death_saves_success INTEGER DEFAULT 0,
    death_saves_fail INTEGER DEFAULT 0,
    is_alive BOOLEAN DEFAULT TRUE,
    is_sovereign BOOLEAN DEFAULT FALSE,
    is_npc BOOLEAN DEFAULT FALSE,
    owner_discord_id BIGINT,
    notes TEXT,
    public_message_id BIGINT,
    private_message_id BIGINT,
    public_channel_id BIGINT,
    private_channel_id BIGINT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. NPC Party Members (for solo players)
CREATE TABLE IF NOT EXISTS public.npc_companions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    class TEXT NOT NULL,
    level INTEGER DEFAULT 1,
    hp_current INTEGER NOT NULL DEFAULT 10,
    hp_max INTEGER NOT NULL DEFAULT 10,
    ac INTEGER DEFAULT 10,
    stats JSONB DEFAULT '{"str":10,"dex":10,"con":10,"int":10,"wis":10,"cha":10}',
    personality_trait TEXT,
    flaw TEXT,
    bond TEXT,
    signature_ability_1 TEXT,
    signature_ability_2 TEXT,
    signature_ability_3 TEXT,
    inventory JSONB DEFAULT '[]',
    is_alive BOOLEAN DEFAULT TRUE,
    owner_discord_id BIGINT NOT NULL,
    campaign_id INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Compendium Spells (for /lore and lookups)
CREATE TABLE IF NOT EXISTS public.compendium_spells (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    level INTEGER DEFAULT 0,
    school TEXT,
    casting_time TEXT,
    range TEXT,
    components TEXT,
    duration TEXT,
    description TEXT NOT NULL,
    higher_level TEXT,
    classes TEXT[] DEFAULT '{}',
    subclass TEXT,
    ritual BOOLEAN DEFAULT FALSE,
    concentration BOOLEAN DEFAULT FALSE,
    purity_requirement INTEGER DEFAULT 0,
    aether_burn_risk TEXT,
    spell_safety_modifier INTEGER DEFAULT 0,
    source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Compendium Items (for /lore and lookups)
CREATE TABLE IF NOT EXISTS public.compendium_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    item_type TEXT NOT NULL,
    rarity TEXT DEFAULT 'common',
    cost TEXT,
    weight REAL,
    description TEXT,
    properties TEXT[] DEFAULT '{}',
    attunement BOOLEAN DEFAULT FALSE,
    purity_requirement INTEGER DEFAULT 0,
    enchantment_tier TEXT,
    spell_safety_modifier INTEGER DEFAULT 0,
    aether_burn_resistance TEXT DEFAULT 'None',
    spellcasting_focus BOOLEAN DEFAULT FALSE,
    aether_core_slot BOOLEAN DEFAULT FALSE,
    source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Compendium Rules
CREATE TABLE IF NOT EXISTS public.compendium_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL,
    rule_category TEXT,
    rule_content TEXT NOT NULL,
    source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Solo Campaign Channels (tracking)
CREATE TABLE IF NOT EXISTS public.solo_campaign_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discord_id BIGINT NOT NULL UNIQUE,
    channel_id BIGINT NOT NULL,
    campaign_status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    finished_at TIMESTAMPTZ
);

-- 8. Campaign Chronicles (finished campaign summaries)
CREATE TABLE IF NOT EXISTS public.campaign_chronicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discord_id BIGINT NOT NULL,
    campaign_type TEXT NOT NULL,
    chronicle_text TEXT NOT NULL,
    character_name TEXT,
    in_game_date_range TEXT,
    major_events JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Enable RLS on all new tables
ALTER TABLE public.dm_game_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.character_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.npc_companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compendium_spells ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compendium_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compendium_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solo_campaign_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_chronicles ENABLE ROW LEVEL SECURITY;
