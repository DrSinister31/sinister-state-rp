import psycopg2
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()

cur.execute("SELECT count(*) FROM compendium_rules")
print(f"Rules: {cur.fetchone()[0]}")
cur.execute("SELECT count(*) FROM compendium_monsters")
print(f"Monsters: {cur.fetchone()[0]}")
cur.execute("SELECT count(*) FROM compendium_spells")
print(f"Spells: {cur.fetchone()[0]}")
cur.execute("SELECT count(*) FROM compendium_items")
print(f"Items: {cur.fetchone()[0]}")
c.close()
