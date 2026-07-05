"""Batch-generate Solis-Grave monsters + spells via DeepSeek and seed Supabase."""
import json, os, time
from openai import OpenAI

BASE = os.path.dirname(__file__)
import os
DEEPSEEK_KEY = os.getenv("DEEPSEEK_API_KEY", "")
if not DEEPSEEK_KEY:
    from shared.config import Config
    DEEPSEEK_KEY = Config.from_env().deepseek_api_key
KRONUS_DB = 'postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres'

client = OpenAI(api_key=DEEPSEEK_KEY, base_url="https://api.deepseek.com/v1")

def parse_json(text):
    """Extract and fix common JSON issues from LLM output."""
    start = text.find('[')
    end = text.rfind(']') + 1
    if start < 0 or end <= start:
        return None
    raw = text[start:end]
    # Fix unescaped quotes in descriptions
    import re
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        pass
    # Try fixing common issues
    raw = re.sub(r'(?<!\\)"([^"]*?)"', lambda m: '"' + m.group(1).replace('"', '\\"') + '"', raw)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        # Save raw output for debugging
        with open('batch_raw_output.txt', 'w') as f:
            f.write(raw)
        print(f"Raw output saved to batch_raw_output.txt")
        return []

def gen_monsters():
    prompt = """Generate 10 D&D 5e monsters for the Solis-Grave grimdark campaign. Output ONLY a valid JSON array. No markdown, no backticks. Start with [ and end with ]. Keep descriptions under 100 chars each.

CR range 0.25 to 3. Include: goblin scout, orc warrior, town guard, Cult fanatic, Aether-warped wolf, giant spider, bandit captain, young sump drake, Inquisitor acolyte, blank laborer-turned-brigand.

Each object: {"name":"...","size":"Small","type":"Humanoid","alignment":"neutral evil","ac":13,"hp":"7 (2d6)","speed":"30 ft.","stats":{"str":8,"dex":14,"con":10,"int":10,"wis":8,"cha":8},"saving_throws":null,"skills":null,"damage_vulnerabilities":null,"damage_resistances":null,"damage_immunities":null,"condition_immunities":null,"senses":"darkvision 60 ft., passive Perception 9","languages":"Common, Goblin","cr":0.25,"xp":50,"traits":[{"name":"Nimble Escape","desc":"Can Disengage or Hide as a bonus action."}],"actions":[{"name":"Scimitar","desc":"Melee Weapon Attack: +4 to hit, reach 5 ft., one target. Hit: 5 (1d6+2) slashing damage."},{"name":"Shortbow","desc":"Ranged Weapon Attack: +4 to hit, range 80/320 ft., one target. Hit: 5 (1d6+2) piercing damage."}],"legendary_actions":null,"lair_actions":null,"lore":"Goblin scouts prowl the borderlands, stealing from caravans.","source_tags":["solis-grave","wilderness"]}"""

    print("Generating monsters...")
    resp = client.chat.completions.create(model="deepseek-chat", messages=[{"role":"user","content":prompt}], max_tokens=6000)
    data = parse_json(resp.choices[0].message.content)
    if data:
        path = os.path.join(BASE, 'compendium_monsters_seed.json')
        existing = json.load(open(path)) if os.path.exists(path) else []
        existing += data
        json.dump(existing, open(path, 'w'), indent=2)
        print(f"Monsters: +{len(data)}, {len(existing)} total")
        return len(data)
    return 0

def gen_spells():
    prompt = """Generate 20 D&D 5e spells for Solis-Grave grimdark campaign. Output ONLY a valid JSON array. No markdown, no backticks, no explanation. Start with [ and end with ].

Each spell object:
{"name":"...","level":0,"school":"Evocation","casting_time":"1 Action","range":"60 feet","components":"V, S","duration":"Instantaneous","description":"...","higher_levels":"...","classes":"Wizard, Sorcerer","source_tags":["solis-grave"]}

Include: 4 cantrips, 6 level-1, 5 level-2, 3 level-3, 2 level-4. Solis-Grave flavor: void magic, blood spells, dragon fire, Aether manipulation, Inquisition-approved, Cult forbidden, Core-Thief techniques, Blank resilience."""

    print("Generating spells...")
    resp = client.chat.completions.create(model="deepseek-chat", messages=[{"role":"user","content":prompt}], max_tokens=4096)
    data = parse_json(resp.choices[0].message.content)
    if data:
        path = os.path.join(BASE, 'compendium_spells_seed.json')
        existing = json.load(open(path)) if os.path.exists(path) else []
        existing += data
        json.dump(existing, open(path, 'w'), indent=2)
        print(f"Spells: +{len(data)}, {len(existing)} total")
        return len(data)
    return 0

def seed_to_db():
    import psycopg2
    c = psycopg2.connect(KRONUS_DB)
    c.autocommit = True
    cur = c.cursor()

    for table, file in [('compendium_monsters','compendium_monsters_seed.json'),('compendium_spells','compendium_spells_seed.json')]:
        data = json.load(open(os.path.join(BASE, file)))
        for row in data:
            vals = [json.dumps(v) if isinstance(v,(dict,list)) else v for v in row.values()]
            cols = ', '.join(row.keys())
            placeholders = ', '.join(['%s']*len(vals))
            try:
                cur.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) ON CONFLICT DO NOTHING", vals)
            except:
                pass
        cur.execute(f"SELECT count(*) FROM {table}")
        print(f"  {table}: {cur.fetchone()[0]} total")
    c.close()

if __name__ == '__main__':
    m = gen_monsters()
    time.sleep(1)
    s = gen_spells()
    seed_to_db()
    print(f"\nDone! {m} monsters + {s} spells generated.")
