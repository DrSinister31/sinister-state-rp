"""Load all generated spells, items, and rules into Supabase."""
import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared.config import Config
from shared.supabase_client import get_supabase

SPELL_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "prompts", "solis_grave", "spells")
ITEMS_FILE = os.path.join(os.path.dirname(__file__), "..", "..", "prompts", "solis_grave", "compendium_items_rebalanced.json")
MAGIC_FILE = os.path.join(os.path.dirname(__file__), "..", "..", "prompts", "solis_grave", "rules", "magic_system.md")

config = Config.from_env()
supabase = get_supabase(config)

# --- LOAD SPELLS ---
total_spells = 0
inserted_spells = 0
for fname in sorted(os.listdir(SPELL_DIR)):
    if not fname.endswith('.json'):
        continue
    path = os.path.join(SPELL_DIR, fname)
    with open(path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    spells = data.get("spells", data) if isinstance(data, dict) else data
    if not isinstance(spells, list):
        print(f"SKIP {fname}: not a list ({type(spells).__name__})")
        continue
    total_spells += len(spells)
    for spell in spells:
        if not isinstance(spell, dict):
            continue
        try:
            clean = {k: v for k, v in spell.items() if k != "source_tags"}
            clean["updated_at"] = "now()"
            supabase.table("compendium_spells").upsert(clean, on_conflict="name").execute()
            inserted_spells += 1
        except Exception as e:
            print(f"  FAIL {spell.get('name', '?')}: {e}")
    print(f"  {fname}: {len(spells)} spells loaded")

print(f"\nSPELLS: {inserted_spells}/{total_spells} inserted into compendium_spells")

# --- LOAD ITEMS ---
if os.path.exists(ITEMS_FILE):
    with open(ITEMS_FILE, 'r', encoding='utf-8-sig') as f:
        items_data = json.load(f)
    compendium = items_data.get("compendium_items", items_data)
    item_count = 0
    for category, items in compendium.items():
        if not isinstance(items, list):
            continue
        for item in items:
            if not isinstance(item, dict):
                continue
            item["updated_at"] = "now()"
            try:
                supabase.table("compendium_items").upsert({"name": item.get("name"), "item_type": category, **item}, on_conflict="name").execute()
                item_count += 1
            except Exception as e:
                print(f"  FAIL item {item.get('name', '?')}: {e}")
    print(f"ITEMS: {item_count} inserted into compendium_items")

# --- LOAD RULES ---
if os.path.exists(MAGIC_FILE):
    with open(MAGIC_FILE, 'r', encoding='utf-8-sig') as f:
        magic_text = f.read()
    supabase.table("compendium_rules").upsert({
        "rule_name": "Solis-Grave Magic System",
        "rule_category": "magic",
        "rule_content": magic_text,
        "source_tags": ["solis-grave", "magic-system"],
        "updated_at": "now()"
    }).execute()
    print("RULES: Magic system loaded into compendium_rules")

print("\nDone.")
