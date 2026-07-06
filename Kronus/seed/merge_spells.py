import json, psycopg2, os

# Merge all spell files
all_spells = []
for f in ['spells_0_1.json','spells_2_3.json','spells_4_5.json','spells_6_7.json','spells_8_9.json']:
    if os.path.exists(f):
        d = json.load(open(f))
        all_spells += d
        print(f'{f}: {len(d)} spells')

json.dump(all_spells, open('spells_compendium.json','w'), indent=2)
print(f'\nTotal: {len(all_spells)} spells')

# Level distribution
from collections import Counter
levels = Counter(s.get('level',0) for s in all_spells)
for lvl in sorted(levels.keys()):
    print(f'  Level {lvl}: {levels[lvl]} spells')

# Seed Supabase
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()
cur.execute('DELETE FROM compendium_spells')
count = 0
for row in all_spells:
    vals = [json.dumps(v) if isinstance(v,(dict,list)) else str(v) if v is not None else None for v in row.values()]
    cols = ', '.join(row.keys())
    placeholders = ', '.join(['%s']*len(vals))
    try:
        cur.execute(f'INSERT INTO compendium_spells ({cols}) VALUES ({placeholders})', vals)
        count += 1
    except Exception as e:
        if count < 3:
            name = row.get('name', '?')
            print(f'  Skip {name}: {str(e)[:60]}')

cur.execute('SELECT count(*) FROM compendium_spells')
print(f'\nSupabase: {cur.fetchone()[0]} spells')
c.close()
