import psycopg2
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()

for t in ['compendium_monsters','compendium_spells','compendium_rules','compendium_items']:
    try:
        cur.execute(f"SELECT column_name, data_type FROM information_schema.columns WHERE table_name='{t}' ORDER BY ordinal_position")
        cols = cur.fetchall()
        if cols:
            names = [c[0] for c in cols]
            print(f'{t}: {len(cols)} cols — {" ".join(names)}')
        else:
            print(f'{t}: MISSING')
    except Exception as e:
        print(f'{t}: MISSING ({e})')
c.close()
