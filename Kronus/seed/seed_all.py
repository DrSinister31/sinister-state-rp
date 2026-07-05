import psycopg2, json, os

KRONUS_DB = 'postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres'
SEED_DIR = 'seed'

c = psycopg2.connect(KRONUS_DB)
c.autocommit = True
cur = c.cursor()

# Check existing table counts
tables = ['compendium_monsters','compendium_spells','compendium_rules','compendium_items','compendium_feats']
for t in tables:
    try:
        cur.execute(f"SELECT count(*) FROM {t}")
        print(f"{t}: {cur.fetchone()[0]} entries")
    except Exception as e:
        print(f"{t}: MISSING — {e}")

# Seed what we have
seeds = [
    ('compendium_monsters', 'seed/compendium_monsters_seed.json'),
    ('compendium_spells', 'seed/compendium_spells_seed.json'),
    ('compendium_rules', 'seed/compendium_rules_seed.json'),
    ('compendium_items', 'seed/compendium_items_seed.json'),
]

for table, file in seeds:
    if not os.path.exists(file):
        print(f"{file} not found, skipping")
        continue
    data = json.load(open(file))
    for row in data:
        try:
            cols = ', '.join(row.keys())
            placeholders = ', '.join(['%s'] * len(row))
            cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", list(row.values()))
        except Exception as e:
            print(f"  Skip {table}::{row.get('name','?')}: {str(e)[:80]}")

# Re-count
print("\n--- After seed ---")
for t in tables:
    try:
        cur.execute(f"SELECT count(*) FROM {t}")
        print(f"{t}: {cur.fetchone()[0]} entries")
    except:
        print(f"{t}: MISSING")

c.close()
print("\nSeed complete")
