"""Regenerate spell grimoire with class-based organization."""
import json, os
from collections import defaultdict

BASE = os.path.dirname(os.path.abspath(__file__))
PROMPTS = os.path.join(os.path.dirname(BASE), "prompts", "solis_grave")

# Load spells
data = json.load(open(os.path.join(BASE, "spells_compendium.json")))

# Group by class → level
classes_map = {
    "Vanguard": ["fighter","barbarian","monk","vanguard"],
    "Strider-Garrison": ["rogue","ranger","strider","strider-garrison"],
    "Archon-Caster": ["wizard","sorcerer","archon","archon-caster"],
    "Ordained": ["cleric","paladin","ordained"],
    "Penitent": ["warlock","penitent"],
    "Sovereign": ["sovereign"],
}

by_class = defaultdict(lambda: defaultdict(list))
by_level = defaultdict(list)

for s in data:
    lvl = s.get("level", 0)
    by_level[lvl].append(s)
    
    classes_str = str(s.get("classes", "")).lower()
    for class_name, keywords in classes_map.items():
        if any(k in classes_str for k in keywords):
            by_class[class_name][lvl].append(s)

out = f"# Solis-Grave Spell Grimoire\n\n**{len(data)} spells** — organized by level and class.\n\n---\n\n"

# SECTION 1: By Class
out += "## Spells by Class\n\n"
for class_name in classes_map:
    spells_by_lvl = by_class[class_name]
    total = sum(len(v) for v in spells_by_lvl.values())
    if total == 0: continue
    
    out += f"### {class_name} — {total} spells\n\n"
    for lvl in sorted(spells_by_lvl.keys()):
        label = "Cantrips" if lvl == 0 else f"Level {lvl}"
        spells = sorted(spells_by_lvl[lvl], key=lambda x: x.get("name",""))
        out += f"**{label} ({len(spells)}):** "
        out += ", ".join(s.get("name","?") for s in spells)
        out += "\n\n"
    out += "---\n\n"

# SECTION 2: By Level (quick reference)
out += "\n## All Spells by Level\n\n"
for lvl in sorted(by_level.keys()):
    label = "Cantrips (Level 0)" if lvl == 0 else f"Level {lvl}"
    spells = sorted(by_level[lvl], key=lambda x: x.get("name",""))
    out += f"### {label} — {len(spells)} spells\n\n"
    
    for s in spells:
        name = s.get("name","?")
        school = s.get("school","?")
        casting = s.get("casting_time","1 Action")
        range_ = s.get("range","Self")
        components = s.get("components","V, S")
        duration = s.get("duration","Instantaneous")
        desc = s.get("description","")[:300]
        classes = s.get("classes","")
        
        out += f"#### {name}\n"
        out += f"*{school}* | **{casting}** | **{range_}**\n"
        out += f"**Components:** {components} | **Duration:** {duration}\n"
        if classes: out += f"**Classes:** {classes}\n"
        out += f"\n{desc}\n\n---\n\n"

path = os.path.join(PROMPTS, "spell_grimoire.md")
open(path, "w", encoding="utf-8").write(out)
print(f"Spell Grimoire regenerated: {len(data)} spells, {len(by_level)} levels")
for cn in classes_map:
    total = sum(len(v) for v in by_class[cn].values())
    if total: print(f"  {cn}: {total}")

# Also regenerate HTML
from generate_books import md_to_html, _fmt, STYLE, BOOKS
import re

md = open(path, encoding="utf-8").read()
html = md_to_html(md, "Solis-Grave Spell Grimoire")
html_path = os.path.join(BOOKS, "Solis-Grave_Spell_Grimoire.html")
open(html_path, "w", encoding="utf-8").write(html)
print(f"HTML regenerated: {os.path.getsize(html_path)} bytes")
