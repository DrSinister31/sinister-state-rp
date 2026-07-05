import psycopg2, json, os
BASE = os.path.dirname(__file__)
KRONUS = 'postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres'

c = psycopg2.connect(KRONUS)
c.autocommit = True
cur = c.cursor()

# Create new tables
cur.execute("""
CREATE TABLE IF NOT EXISTS compendium_backgrounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    skill_proficiencies TEXT,
    tool_proficiencies TEXT,
    languages TEXT,
    equipment TEXT,
    feature TEXT,
    feature_desc TEXT,
    source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
)
""")

print("Tables created")

# Seed all
def seed(table, file):
    if not os.path.exists(file): return 0
    data = json.load(open(file))
    if isinstance(data, dict):
        # Single object - for traits, store as a row
        cur.execute(f"SELECT count(*) FROM {table}")
        if cur.fetchone()[0] == 0:
            vals = {k: json.dumps(v) if isinstance(v,(dict,list)) else v for k,v in data.items()}
            cols = ', '.join(vals.keys())
            placeholders = ', '.join(['%s']*len(vals))
            cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders})", list(vals.values()))
        return 1
    if not isinstance(data, list): return 0
    for row in data:
        vals = [json.dumps(v) if isinstance(v,(dict,list)) else v for v in row.values()]
        cols = ', '.join(row.keys())
        placeholders = ', '.join(['%s']*len(vals))
        try:
            cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", vals)
        except: pass
    cur.execute(f"SELECT count(*) FROM {table}")
    return cur.fetchone()[0]

seeds = [
    ('compendium_monsters', 'compendium_monsters_seed.json'),
    ('compendium_spells', 'compendium_spells_seed.json'),
    ('compendium_rules', 'compendium_rules_seed.json'),
    ('compendium_items', 'compendium_items_seed.json'),
    ('compendium_backgrounds', 'compendium_backgrounds_seed.json'),
]

print("\nSeeding...")
for table, file in seeds:
    c2 = seed(table, os.path.join(BASE, file))
    print(f'  {table}: {c2} entries')

# Traits - store in json file for now, load into system prompt
print(f'\nTraits: loaded from compendium_traits_seed.json into system prompt at session start')

c.close()
print('Done!')
