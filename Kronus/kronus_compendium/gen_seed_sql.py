"""Generate a SQL INSERT file from all spell JSON files for Supabase SQL Editor."""
import json, os

SPELL_DIR = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master\prompts\solis_grave\spells"
OUTPUT_SQL = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master\Kronus\database\seed_spells.sql"

all_spells = []
for fname in sorted(os.listdir(SPELL_DIR)):
    if not fname.endswith('.json'):
        continue
    with open(os.path.join(SPELL_DIR, fname), 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    spells = data.get("spells", data) if isinstance(data, dict) else data
    if isinstance(spells, list):
        all_spells.extend(spells)

def pg_escape(s):
    if s is None:
        return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"

def pg_array(arr):
    if not arr:
        return 'ARRAY[]::text[]'
    items = ", ".join(pg_escape(x) for x in arr)
    return f"ARRAY[{items}]::text[]"

lines = ["-- Auto-generated spell seed data for Supabase\n"]
lines.append("-- Run AFTER dm_alter.sql\n\n")

# First clear existing duplicates
lines.append("DELETE FROM public.compendium_spells WHERE source_tags @> ARRAY['solis-grave']::text[];\n\n")

for spell in all_spells:
    if not isinstance(spell, dict):
        continue
    # Build INSERT for only the columns that exist
    name = pg_escape(spell.get("name", "?"))
    level = spell.get("level", 0)
    school = pg_escape(spell.get("school", "?"))
    casting_time = pg_escape(spell.get("casting_time", "?"))
    range_ = pg_escape(spell.get("range", "?"))
    components = pg_escape(spell.get("components", "?"))
    duration = pg_escape(spell.get("duration", "?"))
    description = pg_escape(spell.get("description", ""))
    higher = pg_escape(spell.get("higher_level"))  # note: column is higher_level after rename
    classes = pg_array(spell.get("classes", []))
    source_tags = pg_array(spell.get("source_tags", ["solis-grave"]))
    ritual = "TRUE" if spell.get("ritual") else "FALSE"
    concentration = "TRUE" if spell.get("concentration") else "FALSE"
    purity = spell.get("purity_requirement", 0)
    burn = pg_escape(spell.get("aether_burn_risk", "None"))
    safety = spell.get("spell_safety_modifier", 0)
    subclass = pg_escape(spell.get("subclass"))

    sql = (
        f"INSERT INTO public.compendium_spells "
        f"(name, level, school, casting_time, range, components, duration, description, "
        f"higher_level, classes, source_tags, ritual, concentration, "
        f"purity_requirement, aether_burn_risk, spell_safety_modifier, subclass) "
        f"VALUES ({name}, {level}, {school}, {casting_time}, {range_}, {components}, "
        f"{duration}, {description}, {higher}, {classes}, {source_tags}, "
        f"{ritual}, {concentration}, {purity}, {burn}, {safety}, {subclass}) "
        f"ON CONFLICT (name) DO UPDATE SET "
        f"level=EXCLUDED.level, school=EXCLUDED.school, casting_time=EXCLUDED.casting_time, "
        f"range=EXCLUDED.range, components=EXCLUDED.components, duration=EXCLUDED.duration, "
        f"description=EXCLUDED.description, higher_level=EXCLUDED.higher_level, "
        f"classes=EXCLUDED.classes, source_tags=EXCLUDED.source_tags, "
        f"ritual=EXCLUDED.ritual, concentration=EXCLUDED.concentration, "
        f"purity_requirement=EXCLUDED.purity_requirement, aether_burn_risk=EXCLUDED.aether_burn_risk, "
        f"spell_safety_modifier=EXCLUDED.spell_safety_modifier, subclass=EXCLUDED.subclass, "
        f"updated_at=now();\n"
    )
    lines.append(sql)

with open(OUTPUT_SQL, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"Generated {len(all_spells)} INSERT statements → {OUTPUT_SQL}")
print("Run dm_alter.sql first, then this file in Supabase SQL Editor.")
