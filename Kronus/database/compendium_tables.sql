-- Solis-Grave Monster Compendium Tables
-- Run against the Supabase instance used by Kronus

CREATE TABLE IF NOT EXISTS compendium_monsters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  size TEXT CHECK (size IN ('Tiny', 'Small', 'Medium', 'Large', 'Huge', 'Gargantuan')),
  type TEXT NOT NULL,
  alignment TEXT DEFAULT 'unaligned',
  ac INTEGER DEFAULT 10,
  hp TEXT DEFAULT '1 (1d4-1)',
  speed TEXT DEFAULT '30 ft.',
  stats JSONB DEFAULT '{"str":10,"dex":10,"con":10,"int":10,"wis":10,"cha":10}',
  saving_throws JSONB,
  skills JSONB,
  damage_vulnerabilities TEXT,
  damage_resistances TEXT,
  damage_immunities TEXT,
  condition_immunities TEXT,
  senses TEXT DEFAULT 'passive Perception 10',
  languages TEXT,
  cr REAL NOT NULL,
  xp INTEGER DEFAULT 0,
  traits JSONB DEFAULT '[]',
  actions JSONB DEFAULT '[]',
  legendary_actions JSONB DEFAULT '[]',
  lair_actions JSONB DEFAULT '[]',
  reactions JSONB DEFAULT '[]',
  lore TEXT DEFAULT '',
  aether_core JSONB DEFAULT '{"tier":"None","element":"None","value_gc":0}',
  source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
  biome_tags TEXT[] DEFAULT '{}',
  public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compendium_monsters_name ON compendium_monsters (name);
CREATE INDEX IF NOT EXISTS idx_compendium_monsters_cr ON compendium_monsters (cr);
CREATE INDEX IF NOT EXISTS idx_compendium_monsters_type ON compendium_monsters (type);
CREATE INDEX IF NOT EXISTS idx_compendium_monsters_public ON compendium_monsters (public);
CREATE INDEX IF NOT EXISTS idx_compendium_monsters_biome ON compendium_monsters USING GIN (biome_tags);

-- Spell compendium (for future use)
CREATE TABLE IF NOT EXISTS compendium_spells (
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
  ritual BOOLEAN DEFAULT FALSE,
  concentration BOOLEAN DEFAULT FALSE,
  purity_requirement INTEGER DEFAULT 0,
  aether_burn_risk TEXT,
  source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compendium_spells_name ON compendium_spells (name);
CREATE INDEX IF NOT EXISTS idx_compendium_spells_level ON compendium_spells (level);

-- Items & equipment compendium (for future use)
CREATE TABLE IF NOT EXISTS compendium_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  item_type TEXT NOT NULL,
  rarity TEXT DEFAULT 'common',
  cost TEXT,
  weight REAL,
  description TEXT DEFAULT '',
  properties TEXT[] DEFAULT '{}',
  attunement BOOLEAN DEFAULT FALSE,
  purity_requirement INTEGER DEFAULT 0,
  enchantment_tier TEXT,
  source_tags TEXT[] DEFAULT ARRAY['solis-grave'],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compendium_items_name ON compendium_items (name);
CREATE INDEX IF NOT EXISTS idx_compendium_items_type ON compendium_items (item_type);

-- Session log for DM-only access control
CREATE TABLE IF NOT EXISTS compendium_session_state (
  id INTEGER PRIMARY KEY DEFAULT 1,
  session_active BOOLEAN DEFAULT FALSE,
  player_access_enabled BOOLEAN DEFAULT TRUE,
  dm_discord_id BIGINT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO compendium_session_state (id, session_active, player_access_enabled)
VALUES (1, FALSE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- RLS: Service role only (same as all other Kronus tables)
ALTER TABLE compendium_monsters ENABLE ROW LEVEL SECURITY;
ALTER TABLE compendium_spells ENABLE ROW LEVEL SECURITY;
ALTER TABLE compendium_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE compendium_session_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON compendium_monsters FOR ALL TO service_role USING (true);
CREATE POLICY "Service role full access" ON compendium_spells FOR ALL TO service_role USING (true);
CREATE POLICY "Service role full access" ON compendium_items FOR ALL TO service_role USING (true);
CREATE POLICY "Service role full access" ON compendium_session_state FOR ALL TO service_role USING (true);
