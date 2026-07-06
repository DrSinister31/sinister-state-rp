"""Generate Solis-Grave Reference Books from seed JSON data."""
import json, os
from collections import defaultdict

BASE = os.path.dirname(os.path.abspath(__file__))
PROMPTS = os.path.join(os.path.dirname(BASE), "prompts", "solis_grave")

def generate_monster_manual():
    """Organize monsters by CR bracket and environment, produce markdown."""
    data = json.load(open(os.path.join(BASE, "compendium_monsters_seed.json")))
    
    # Group by CR bracket
    by_cr = defaultdict(list)
    for m in data:
        cr = m.get("cr", 0)
        if cr <= 0.5: bracket = "CR 0–½"
        elif cr <= 1: bracket = "CR 1"
        elif cr <= 4: bracket = "CR 2–4"
        elif cr <= 8: bracket = "CR 5–8"
        elif cr <= 12: bracket = "CR 9–12"
        elif cr <= 16: bracket = "CR 13–16"
        else: bracket = "CR 17+"
        by_cr[bracket].append(m)
    
    out = f"# Solis-Grave Monster Manual\n\n"
    out += f"**{len(data)} creatures** catalogued across all challenge ratings.\n\n"
    out += "---\n\n"
    
    for bracket in ["CR 0–½", "CR 1", "CR 2–4", "CR 5–8", "CR 9–12", "CR 13–16", "CR 17+"]:
        monsters = sorted(by_cr.get(bracket, []), key=lambda m: (m.get("cr", 0), m.get("name", "")))
        if not monsters: continue
        
        out += f"## {bracket}\n\n"
        for m in monsters:
            name = m.get("name", "Unknown")
            size = m.get("size", "Medium")
            mtype = m.get("type", "Unknown")
            alignment = m.get("alignment", "unaligned")
            ac = m.get("ac", 10)
            hp = m.get("hp", "?")
            speed = m.get("speed", "30 ft.")
            stats = m.get("stats", {})
            cr = m.get("cr", 0)
            xp = m.get("xp", 0)
            lore = m.get("lore", "")
            
            out += f"### {name}\n"
            out += f"*{size} {mtype}, {alignment}*  \n"
            out += f"**AC** {ac} | **HP** {hp} | **Speed** {speed}  \n"
            if isinstance(stats, dict):
                stat_line = f"**STR** {stats.get('str','?')} | **DEX** {stats.get('dex','?')} | **CON** {stats.get('con','?')} | **INT** {stats.get('int','?')} | **WIS** {stats.get('wis','?')} | **CHA** {stats.get('cha','?')}"
            elif isinstance(stats, list) and len(stats) >= 6:
                stat_line = f"**STR** {stats[0]} | **DEX** {stats[1]} | **CON** {stats[2]} | **INT** {stats[3]} | **WIS** {stats[4]} | **CHA** {stats[5]}"
            else:
                stat_line = "**Stats:** Unknown"
            out += stat_line + "  \n"
            xp_val = int(float(m.get("xp", 0)))
            out += f"**CR** {cr} ({xp_val} XP)\n\n"
            
            # Traits
            traits = m.get("traits")
            if traits:
                out += "**Traits:**  \n"
                items = traits if isinstance(traits, list) else [traits]
                for t in items:
                    if isinstance(t, dict):
                        out += f"- *{t.get('name','Trait')}.* {t.get('desc','')}\n"
                    elif isinstance(t, str):
                        out += f"- {t}\n"
                out += "\n"
            
            # Actions
            actions = m.get("actions")
            if actions:
                out += "**Actions:**  \n"
                items = actions if isinstance(actions, list) else [actions]
                for a in items:
                    if isinstance(a, dict):
                        out += f"- *{a.get('name','Action')}.* {a.get('desc','')}\n"
                    elif isinstance(a, str):
                        out += f"- {a}\n"
                out += "\n"
            
            if lore:
                out += f"*{lore[:300]}*\n\n"
            
            out += "---\n\n"
    
    path = os.path.join(PROMPTS, "monster_manual.md")
    open(path, "w").write(out)
    print(f"Monster Manual: {len(data)} monsters → {path}")
    return len(data)


def generate_spell_grimoire():
    """Organize spells by level, produce markdown."""
    data = json.load(open(os.path.join(BASE, "spells_compendium.json")))
    
    # Group by level
    by_level = defaultdict(list)
    for s in data:
        lvl = s.get("level", 0)
        by_level[lvl].append(s)
    
    out = f"# Solis-Grave Spell Grimoire\n\n"
    out += f"**{len(data)} spells** across all levels.\n\n"
    out += "---\n\n"
    
    for lvl in sorted(by_level.keys()):
        label = "Cantrips (Level 0)" if lvl == 0 else f"Level {lvl}"
        spells = sorted(by_level[lvl], key=lambda s: s.get("name", ""))
        
        out += f"## {label} — {len(spells)} spells\n\n"
        
        for s in spells:
            name = s.get("name", "Unknown")
            school = s.get("school", "Unknown")
            casting = s.get("casting_time", "1 Action")
            range_ = s.get("range", "Self")
            components = s.get("components", "V, S")
            duration = s.get("duration", "Instantaneous")
            desc = s.get("description", "")
            higher = s.get("higher_levels", "")
            classes = s.get("classes", "")
            
            out += f"### {name}\n"
            out += f"*{label}, {school}*  \n"
            out += f"**Casting Time:** {casting} | **Range:** {range_}  \n"
            out += f"**Components:** {components} | **Duration:** {duration}  \n"
            if classes:
                out += f"**Classes:** {classes}  \n"
            out += f"\n{desc[:500]}\n"
            if higher:
                out += f"\n***At Higher Levels.*** {higher[:200]}\n"
            out += "\n---\n\n"
    
    path = os.path.join(PROMPTS, "spell_grimoire.md")
    open(path, "w").write(out)
    print(f"Spell Grimoire: {len(data)} spells → {path}")
    return len(data)


def generate_item_catalog():
    """Organize items by type and rarity, produce markdown."""
    data = json.load(open(os.path.join(BASE, "compendium_items_seed.json")))
    
    by_type = defaultdict(list)
    for item in data:
        t = item.get("type", "gear")
        by_type[t].append(item)
    
    out = f"# Solis-Grave Magic Item Catalog\n\n"
    out += f"**{len(data)} items** — weapons, armor, potions, enchantments, and adventuring gear.\n\n"
    out += "---\n\n"
    
    type_order = ["weapon", "armor", "enchantment", "potion", "wondrous", "tool", "gear"]
    type_labels = {"weapon": "Weapons", "armor": "Armor & Shields", "enchantment": "Enchantments", 
                   "potion": "Potions & Consumables", "wondrous": "Wondrous Items", "tool": "Tools & Kits", "gear": "Adventuring Gear"}
    
    for t in type_order:
        items = by_type.get(t, [])
        if not items: continue
        out += f"## {type_labels.get(t, t.title())} — {len(items)} items\n\n"
        
        for item in sorted(items, key=lambda i: i.get("name", "")):
            name = item.get("name", "Unknown")
            rarity = item.get("rarity", "common")
            cost = item.get("cost", "—")
            weight = item.get("weight", "—")
            desc = item.get("description", "")
            
            out += f"### {name}\n"
            out += f"*{rarity.title()}* | Cost: {cost} | Weight: {weight}\n\n"
            out += f"{desc[:400]}\n\n"
            out += "---\n\n"
    
    path = os.path.join(PROMPTS, "item_catalog.md")
    open(path, "w").write(out)
    print(f"Item Catalog: {len(data)} items → {path}")
    return len(data)


def generate_dm_guide():
    """Consolidate core rules from magic_system, story_engine, and system prompt into one DM reference."""
    rules_dir = os.path.join(PROMPTS, "rules")
    
    out = "# Solis-Grave Dungeon Master's Guide\n\n"
    out += "Consolidated rules reference for running the campaign.\n\n---\n\n"
    
    # Magic System
    try:
        magic = open(os.path.join(rules_dir, "magic_system.md")).read()
        out += "## Magic System\n\n" + magic + "\n\n---\n\n"
    except: pass
    
    # Story Engine (first 200 lines)
    try:
        story = open(os.path.join(rules_dir, "story_engine.md")).read()
        out += "## Story Engine & Campaign Structure\n\n" + story[:5000] + "\n\n---\n\n"
    except: pass
    
    # Ascension System
    try:
        asc = open(os.path.join(PROMPTS, "ascension_system.md")).read()
        out += "## Ascension System & Character Creation\n\n" + asc[:4000] + "\n\n---\n\n"
    except: pass
    
    # Gear reference
    try:
        eq = open(os.path.join(PROMPTS, "equipment_guide.md")).read()
        out += "## Equipment & Enchantments\n\n" + eq[:4000] + "\n\n---\n\n"
    except: pass
    
    # Quick reference tables
    out += "## Quick Reference\n\n"
    out += "### Spell Safety DC\n"
    out += "| Purity | DC | Safe Spells |\n|---|---|---|\n"
    out += "| 0% (Blank) | 20 | Cantrips only |\n"
    out += "| 15% (Lesser) | 17 | Cantrips + 1st |\n"
    out += "| 40% (Archon) | 12 | 1st–3rd |\n"
    out += "| 60% | 8 | 1st–5th |\n"
    out += "| 80% | 4 | 1st–7th |\n"
    out += "| 95%+ (Sovereign) | 2 | Cannot cast while dormant |\n\n"
    
    out += "### Aether Burn Damage\n"
    out += "| Spell Level | Damage |\n|---|---|\n"
    for l in range(1, 10):
        out += f"| {l} | {l}d6 |\n"
    out += "\n**Damage ignores all resistances.**\n\n"
    
    out += "### Races & Ascension Ages\n"
    out += "| Race | Ascension Age | Lifespan | Purity Range |\n|---|---|---|---|\n"
    out += "| Human | 15 | 70 | 0–100% |\n"
    out += "| Dracon-Kin | 12 | 80 | 25–100% |\n"
    out += "| Stone-Blood | 25 | 350 | 10–30% |\n"
    out += "| Ash-Walker | 15 | 120 | 1d100 |\n"
    out += "| Deep-Blood | 30 | 750 | Age-decay |\n"
    out += "| Sump-Blood | 15 | 150 | 0–15% |\n"
    out += "| Bone-Wrought | N/A | N/A | 0% |\n"
    out += "| Half-Breed | 18 | 180 | 11–60% |\n\n"
    
    out += "### XP Thresholds\n"
    for i in range(1, 11):
        xp = [0,300,900,2700,6500,14000,23000,34000,48000,64000,85000][i]
        out += f"- Level {i}: {xp:,} XP\n"
    out += "\n"
    
    path = os.path.join(PROMPTS, "dm_guide.md")
    open(path, "w").write(out)
    print(f"DM's Guide → {path}")
    return True


if __name__ == "__main__":
    print("Generating reference books...\n")
    m = generate_monster_manual()
    s = generate_spell_grimoire()
    i = generate_item_catalog()
    d = generate_dm_guide()
    print(f"\n✅ Done: {m} monsters, {s} spells, {i} items, 1 DM's Guide")
