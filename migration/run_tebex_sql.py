"""Run Tebex SQL migration directly on Supabase PostgreSQL."""
import psycopg2
import os

DB_URL = "postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres"

SQL_FILE = os.path.join(os.path.dirname(__file__), "tebex_tables.sql")

def main():
    with open(SQL_FILE) as f:
        sql = f.read()

    print("Connecting to Supabase PostgreSQL...")
    conn = psycopg2.connect(DB_URL, connect_timeout=15)
    conn.autocommit = True
    cur = conn.cursor()

    print("Executing Tebex migration SQL...")
    cur.execute(sql)

    # Verify tables
    for table in ("tebex_purchases", "tebex_webhook_log"):
        cur.execute(f"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '{table}')")
        exists = cur.fetchone()[0]
        status = "CREATED" if exists else "MISSING"
        print(f"  {table}: {status}")

    cur.close()
    conn.close()
    print("Done.")

if __name__ == "__main__":
    main()
