"""Comprehensive Solis-Grave audit vs D&D 5e SRD standards."""
import psycopg2, json, os, sys
sys.path.insert(0, "..")

c = psycopg2.connect('postgresql://postgres:FamiliaAwesome1!@db.yqfzaugbrwoluhkddcsh.supabase.co:5432/postgres')
c.autocommit = True; cur = c.cursor()

print("=" * 60)
print("SOLIS-GRAVE DM BOT — COMPREHENSIVE AUDIT")
print("=" * 60)

# 1. DATABASE AUDIT
print("\n📊 DATABASE AUDIT")
tables = {
    'compendium_monsters': 'Monsters',
    'compendium_spells': 'Spells', 
    'compendium_rules': 'Rules',
    'compendium_items': 'Items',
    'compendium_feats': 'Feats',
    'compendium_backgrounds': 'Backgrounds',
    'character_sheets': 'Character Sheets',
    'dm_game_state': 'Game State',
    'npc_companions': 'NPC Companions',
    'solo_campaign_channels': 'Solo Channels',
    'campaign_chronicles': 'Chronicles',
    'custom_classes': 'Custom Classes',
}

db_gaps = []
for table, label in tables.items():
    try:
        cur.execute(f"SELECT count(*) FROM {table}")
        cnt = cur.fetchone()[0]
        status = "✅" if cnt > 0 else "⚠️ EMPTY"
        if cnt == 0: db_gaps.append(label)
        print(f"  {label}: {cnt} {status}")
    except Exception as e:
        print(f"  {label}: MISSING TABLE ❌")
        db_gaps.append(f"{label} (table missing)")

# 2. SRD GAP ANALYSIS
print("\n📋 5e SRD GAP ANALYSIS")

srd_standard = {
    "Core Combat Rules": ["Actions in Combat", "Bonus Actions", "Reactions", "Opportunity Attacks", "Grappling", "Shoving", "Cover", "Two-Weapon Fighting", "Mounted Combat", "Underwater Combat"],
    "Conditions": ["Blinded","Charmed","Deafened","Frightened","Grappled","Incapacitated","Invisible","Paralyzed","Petrified","Poisoned","Prone","Restrained","Stunned","Unconscious","Exhaustion"],
    "Spell Schools": ["Abjuration","Conjuration","Divination","Enchantment","Evocation","Illusion","Necromancy","Transmutation"],
    "Damage Types": ["Acid","Bludgeoning","Cold","Fire","Force","Lightning","Necrotic","Piercing","Poison","Psychic","Radiant","Slashing","Thunder"],
    "Movement & Travel": ["Overland travel pace","Difficult terrain","Falling","Suffocating","Vision & Light","Darkvision","Blindsight","Truesight"],
    "Social Encounters": ["Persuasion","Intimidation","Deception","Insight","Faction reputation"],
    "Exploration": ["Traps","Hazards","Diseases","Poisons","Madness","Food & Water needs"],
    "Spellcasting Details": ["Spell slots table","Ritual casting","Components (V,S,M)","Concentration","Spell save DC calculation","Spell attack modifier"],
    "Equipment Packs": ["Burglars Pack","Diplomats Pack","Dungeoneers Pack","Entertainers Pack","Explorers Pack","Priests Pack","Scholars Pack"],
    "Tools": ["Artisans Tools","Disguise Kit","Forgery Kit","Herbalism Kit","Navigators Tools","Poisoners Kit","Thieves Tools"],
    "Weapons": ["Simple Melee (6 types)","Simple Ranged (4 types)","Martial Melee (12+ types)","Martial Ranged (4 types)"],
    "Armor": ["Light (3 types)","Medium (5 types)","Heavy (4 types)","Shields"],
    "Mounts & Vehicles": ["Horses","Ponies","Camels","Elephants","Carts","Wagons","Water vehicles"],
}

# Check what rules we have
cur.execute("SELECT category, name FROM compendium_rules")
rules = cur.fetchall()
rule_map = {}
for cat, name in rules:
    rule_map.setdefault(cat, []).append(name)

srd_gaps = []
print("\n  Core rules coverage:")
for group, items in srd_standard.items():
    found = sum(1 for item in items if any(item.lower() in (name or '').lower() for name in rule_map.get('combat',[]) + rule_map.get('conditions',[]) + rule_map.get('setting',[])))
    status = "✅" if found >= len(items) * 0.7 else "⚠️" if found > 0 else "❌"
    if status != "✅": srd_gaps.append(f"{group}: {found}/{len(items)} covered")
    print(f"    {group}: {found}/{len(items)} {status}")

# 3. MONSTER COVERAGE
print("\n🐉 MONSTER COVERAGE")
cur.execute("SELECT cr, count(*) FROM compendium_monsters GROUP BY cr ORDER BY cr")
cr_data = cur.fetchall()
cr_gaps = []
for cr, cnt in cr_data:
    if cnt < 2:
        cr_gaps.append(f"CR {cr}: only {cnt}")
        print(f"  CR {cr}: {cnt} ⚠️")
    else:
        print(f"  CR {cr}: {cnt}")

# Check CR bracket coverage
brackets = [(0.25,4, "Low CR 0-4"), (5,10, "Mid CR 5-10"), (11,16, "High CR 11-16"), (17,30, "Epic CR 17+")]
for lo, hi, label in brackets:
    cur.execute(f"SELECT count(*) FROM compendium_monsters WHERE cr >= {lo} AND cr <= {hi}")
    cnt = cur.fetchone()[0]
    print(f"  {label}: {cnt}")

# 4. SPELL COVERAGE
print("\n✨ SPELL COVERAGE")
cur.execute("SELECT level, count(*) FROM compendium_spells GROUP BY level ORDER BY level")
spell_data = cur.fetchall()
for lvl, cnt in spell_data:
    target = {0:45,1:60,2:55,3:50,4:45,5:40,6:35,7:30,8:25,9:15}.get(lvl, 0)
    status = "✅" if cnt >= target * 0.7 else "⚠️"
    print(f"  Level {lvl}: {cnt} (target {target}) {status}")

# 5. RACE vs CLASS coverage
print("\n🧬 RACE/CLASS COVERAGE")
sr_rules = open("C:/Users/Dilla/OneDrive/Desktop/Sinister_Project_Master/Kronus/prompts/solis_grave/rules/classes.json").read()
has_classes = "Vanguard" in sr_rules and "Strider-Garrison" in sr_rules and "Archon-Caster" in sr_rules
print(f"  Classes defined: {has_classes}")

# Check system prompt mentions all 8 races
with open("C:/Users/Dilla/OneDrive/Desktop/Sinister_Project_Master/Kronus/kronus_core/cogs/dm_session.py") as f:
    prompt = f.read()
races = ["Human","Dracon-Kin","Stone-Blood","Ash-Walker","Deep-Blood","Sump-Blood","Bone-Wrought","Half-Breed"]
for r in races:
    if r in prompt: print(f"  {r}: ✅ in system prompt")
    else: print(f"  {r}: ❌ missing")

# 6. COG COMMAND COUNT
print("\n🤖 COMMAND AUDIT")
import re
for cog_file in ['kronus_core/cogs/dm_session.py','kronus_core/cogs/dm_sheets.py','kronus_core/cogs/dm_voice.py','kronus_core/cogs/compendium.py']:
    path = f"C:/Users/Dilla/OneDrive/Desktop/Sinister_Project_Master/Kronus/{cog_file}"
    if os.path.exists(path):
        text = open(path).read()
        cmds = re.findall(r'@app_commands\.command\(name="([^"]+)"', text)
        print(f"  {cog_file}: {len(cmds)} commands — {', '.join(cmds[:10])}{'...' if len(cmds) > 10 else ''}")
    else:
        print(f"  {cog_file}: FILE MISSING")

print(f"\n{'='*60}")
print(f"AUDIT COMPLETE")
print(f"DB gaps: {len(db_gaps)}")
print(f"SRD rule gaps: {len(srd_gaps)}")
print(f"CR gaps: {len(cr_gaps)}")
c.close()
