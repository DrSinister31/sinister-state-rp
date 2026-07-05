import psycopg2, json
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()

data = json.load(open('compendium_monsters_seed.json'))
print(f'JSON has {len(data)} entries')

cur.execute('SELECT count(*) FROM compendium_monsters')
print(f'DB has {cur.fetchone()[0]} entries')

skipped = 0
for i, row in enumerate(data):
    vals = [json.dumps(v) if isinstance(v,(dict,list)) else str(v) if v is not None else None for v in row.values()]
    cols = ', '.join(row.keys())
    placeholders = ', '.join(['%s']*len(vals))
    try:
        cur.execute(f'INSERT INTO compendium_monsters ({cols}) VALUES ({placeholders})', vals)
    except Exception as e:
        skipped += 1
        if skipped <= 3:
            name = row.get('name', '?')
            print(f'  Row {i} ({name}): {str(e)[:80]}')

cur.execute('SELECT count(*) FROM compendium_monsters')
print(f'After insert: {cur.fetchone()[0]} entries (skipped {skipped})')
c.close()
