import psycopg2, json, os

KRONUS_DB = 'postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres'
c = psycopg2.connect(KRONUS_DB)
c.autocommit = True
cur = c.cursor()

# Drop and recreate with correct schema
cur.execute("DROP TABLE IF EXISTS compendium_monsters CASCADE")
cur.execute("DROP TABLE IF EXISTS compendium_spells CASCADE")
cur.execute("DROP TABLE IF EXISTS compendium_rules CASCADE")

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
    lore TEXT, source_tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

cur.execute("""
CREATE TABLE compendium_spells (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    level INTEGER DEFAULT 0, school TEXT, casting_time TEXT,
    range TEXT, components TEXT, duration TEXT,
    description TEXT NOT NULL, higher_levels TEXT,
    classes TEXT, source_tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

cur.execute("""
CREATE TABLE compendium_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL, name TEXT NOT NULL,
    description TEXT NOT NULL, source_tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (category, name)
)
""")

print("Tables recreated")

# Seed
seeds = [
    ('compendium_monsters', os.path.join(os.path.dirname(__file__), 'compendium_monsters_seed.json')),
    ('compendium_spells', os.path.join(os.path.dirname(__file__), 'compendium_spells_seed.json')),
    ('compendium_rules', os.path.join(os.path.dirname(__file__), 'compendium_rules_seed.json')),
    ('compendium_items', os.path.join(os.path.dirname(__file__), 'compendium_items_seed.json')),
]

for table, file in seeds:
    if not os.path.exists(file):
        print(f"  {file} not found")
        continue

    data = json.load(open(file))
    seeded = 0
    for row in data:
        # Filter columns to match table schema
        cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name='{table}' ORDER BY ordinal_position")
        valid_cols = {r[0] for r in cur.fetchall()}
        filtered = {k: json.dumps(v) if isinstance(v, (dict, list)) else v for k, v in row.items() if k in valid_cols}

        cols = ', '.join(filtered.keys())
        placeholders = ', '.join(['%s'] * len(filtered))

        try:
            cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", list(filtered.values()))
            seeded += 1
        except Exception as e:
            print(f"  Skip {table}::{row.get('name','?')}: {str(e)[:80]}")

    print(f"  {table}: {seeded} seeded")

# Items table has different column names — fix
cur.execute("""
    ALTER TABLE compendium_items RENAME COLUMN item_type TO type;
""")
print("  compendium_items: fixed column names")

# Re-seed items now that columns match
if os.path.exists(os.path.join(os.path.dirname(__file__), 'compendium_items_seed.json')):
    data = json.load(open(os.path.join(os.path.dirname(__file__), 'compendium_items_seed.json')))
    cur.execute("TRUNCATE compendium_items CASCADE")
    seeded = 0
    for row in data:
        filtered = {k: str(v) if not isinstance(v, (dict, list, bool)) else json.dumps(v) if isinstance(v, (dict, list)) else v
                    for k, v in row.items()}
        # Only include columns that exist
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='compendium_items' ORDER BY ordinal_position")
        valid = {r[0] for r in cur.fetchall()}
        filtered = {k: v for k, v in filtered.items() if k in valid}
        if not filtered:
            continue
        cols = ', '.join(filtered.keys())
        placeholders = ', '.join(['%s'] * len(filtered))
        try:
            cur.execute(f"INSERT INTO compendium_items ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", list(filtered.values()))
            seeded += 1
        except Exception as e:
            print(f"  Skip item::{row.get('name','?')}: {str(e)[:80]}")
    print(f"  compendium_items: {seeded} seeded")

# Final counts
print("\n--- Final Counts ---")
for t in ['compendium_monsters','compendium_spells','compendium_rules','compendium_items']:
    cur.execute(f"SELECT count(*) FROM {t}")
    print(f"  {t}: {cur.fetchone()[0]}")

c.close()
print("Done")
