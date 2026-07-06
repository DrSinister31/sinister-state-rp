import psycopg2, json
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True; cur = c.cursor()

cur.execute("ALTER TABLE compendium_spells ADD COLUMN IF NOT EXISTS purity_requirement INTEGER DEFAULT 0")
cur.execute("ALTER TABLE compendium_spells ADD COLUMN IF NOT EXISTS spell_safety_modifier INTEGER DEFAULT 0")
print("Columns ensured")

# Get valid column list once
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='compendium_spells'")
valid_cols = {r[0] for r in cur.fetchall()}

cur.execute("DELETE FROM compendium_spells")
data = json.load(open("spells_compendium.json"))
count = 0
for row in data:
    filtered = {}
    for k, v in row.items():
        if k not in valid_cols: continue
        filtered[k] = json.dumps(v) if isinstance(v, (dict, list)) else str(v) if v is not None else None
    if not filtered: continue
    cols = ", ".join(filtered.keys())
    placeholders = ", ".join(["%s"] * len(filtered))
    try:
        cur.execute(f"INSERT INTO compendium_spells ({cols}) VALUES ({placeholders})", list(filtered.values()))
        count += 1
    except: pass

cur.execute("SELECT count(*) FROM compendium_spells")
print(f"Seeded: {cur.fetchone()[0]} spells from {len(data)} in JSON")
c.close()
