import psycopg2
c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True
cur = c.cursor()
cur.execute("ALTER TABLE characters ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE")
print("is_public column added")
c.close()
