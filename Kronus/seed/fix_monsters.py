import psycopg2, json
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()

cur.execute('DROP TABLE IF EXISTS compendium_monsters CASCADE')
cur.execute("""
CREATE TABLE compendium_monsters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    size TEXT DEFAULT 'Medium',
    type TEXT DEFAULT 'Beast',
    alignment TEXT DEFAULT 'unaligned',
    ac INTEGER DEFAULT 10,
    hp TEXT DEFAULT '1 (1d4-1)',
    speed TEXT DEFAULT '30 ft.',
    stats JSONB DEFAULT '{"str":10,"dex":10,"con":10,"int":10,"wis":10,"cha":10}',
    skills TEXT,
    senses TEXT DEFAULT 'passive Perception 10',
    languages TEXT DEFAULT '',
    cr REAL DEFAULT 0,
    xp INTEGER DEFAULT 10,
    traits JSONB DEFAULT '[]',
    actions JSONB DEFAULT '[]',
    damage_vulnerabilities TEXT,
    damage_resistances TEXT,
    damage_immunities TEXT,
    condition_immunities TEXT,
    saving_throws JSONB,
    legendary_actions JSONB,
    lair_actions JSONB,
    lore TEXT DEFAULT '',
    source_tags JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now()
)
""")
print("Table recreated")

data = json.load(open('compendium_monsters_seed.json'))
count = 0
for row in data:
    if 'abilities' in row and 'stats' not in row:
        row['stats'] = row.pop('abilities')
    if 'source' in row and 'source_tags' not in row:
        row['source_tags'] = row.pop('source')
    if 'description' in row and 'lore' not in row:
        row['lore'] = row.pop('description')

    if isinstance(row.get('traits'), str):
        row['traits'] = [{'name': 'Trait', 'desc': row['traits']}]
    if isinstance(row.get('actions'), str):
        row['actions'] = [{'name': 'Attack', 'desc': row['actions']}]

    vals = [json.dumps(v) if isinstance(v,(dict,list)) else str(v) if v is not None else None for v in row.values()]
    cols = ', '.join(row.keys())
    placeholders = ', '.join(['%s']*len(vals))
    try:
        cur.execute(f"INSERT INTO compendium_monsters ({cols}) VALUES ({placeholders})", vals)
        count += 1
    except Exception as e:
        if count < 3:
            print(f"  Skip {row.get('name','?')}: {str(e)[:80]}")

cur.execute('SELECT count(*) FROM compendium_monsters')
print(f"Monsters: {cur.fetchone()[0]} inserted from {len(data)} JSON entries")
c.close()
