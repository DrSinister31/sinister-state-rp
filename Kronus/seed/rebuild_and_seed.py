import psycopg2, json, os

BASE = os.path.dirname(__file__)
KRONUS_DB = 'postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres'
c = psycopg2.connect(KRONUS_DB)
c.autocommit = True
cur = c.cursor()

# Drop all compendium tables
for t in ['compendium_monsters','compendium_spells','compendium_rules','compendium_items','compendium_feats']:
    cur.execute(f"DROP TABLE IF EXISTS {t} CASCADE")

# MONSTERS — matches seed JSON exactly
cur.execute("""
CREATE TABLE compendium_monsters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    size TEXT NOT NULL, type TEXT NOT NULL, alignment TEXT,
    ac INTEGER NOT NULL, hp TEXT NOT NULL, speed TEXT,
    stats JSONB DEFAULT '{"str":10,"dex":10,"con":10,"int":10,"wis":10,"cha":10}',
    saving_throws JSONB, skills JSONB,
    damage_vulnerabilities TEXT, damage_resistances TEXT, damage_immunities TEXT,
    condition_immunities TEXT, senses TEXT, languages TEXT,
    cr REAL NOT NULL, xp INTEGER NOT NULL,
    traits JSONB, actions JSONB, legendary_actions JSONB, lair_actions JSONB,
    lore TEXT, source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

# SPELLS — matches seed JSON exactly
cur.execute("""
CREATE TABLE compendium_spells (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    level INTEGER DEFAULT 0, school TEXT,
    casting_time TEXT, range TEXT, components TEXT,
    duration TEXT, description TEXT NOT NULL,
    higher_levels TEXT, classes TEXT,
    source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

# RULES — matches seed JSON exactly
cur.execute("""
CREATE TABLE compendium_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL, name TEXT NOT NULL,
    description TEXT NOT NULL,
    source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (category, name)
)
""")

# ITEMS — matches seed JSON exactly
cur.execute("""
CREATE TABLE compendium_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL, rarity TEXT DEFAULT 'common',
    cost TEXT, weight TEXT,
    description TEXT NOT NULL, properties JSONB,
    source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

print("Tables created matching seed JSON schemas")

# Seed
def to_pg(val):
    if val is None: return None
    if isinstance(val, (dict, list)): return json.dumps(val)
    return str(val)

seeds = [
    ('compendium_monsters', 'compendium_monsters_seed.json'),
    ('compendium_spells', 'compendium_spells_seed.json'),
    ('compendium_rules', 'compendium_rules_seed.json'),
    ('compendium_items', 'compendium_items_seed.json'),
]

for table, file in seeds:
    path = os.path.join(BASE, file)
    if not os.path.exists(path):
        print(f"  {file}: not found")
        continue

    data = json.load(open(path))
    seeded = 0
    for row in data:
        try:
            vals = [to_pg(v) for v in row.values()]
            cols = ', '.join(row.keys())
            placeholders = ', '.join(['%s'] * len(vals))
            cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", vals)
            seeded += 1
        except Exception as e:
            print(f"  Skip {row.get('name','?')}: {str(e)[:80]}")

    print(f"  {table}: {seeded} seeded")

# Final counts
print("\n=== Final ===")
for t in ['compendium_monsters','compendium_spells','compendium_rules','compendium_items']:
    cur.execute(f"SELECT count(*) FROM {t}")
    print(f"  {t}: {cur.fetchone()[0]} entries")

c.close()
print("Done!")
