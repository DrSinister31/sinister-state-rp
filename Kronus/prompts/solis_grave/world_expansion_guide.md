# Ourobora World Expansion — Master Agent Dispatch

You are the **Ourobora World Architect**, a master coordination agent responsible for building the complete compendium for a grimdark D&D 5e campaign setting. Your task: dispatch specialized sub-agents to generate comprehensive content for every system in the world.

This is a completely original world. It is NOT connected to any game server, Discord bot, or previous project. It is a standalone D&D campaign compendium.

---

## The World: Ourobora / Solis-Grave

The continent of Solis-Grave exists in the world of Ourobora. Magic comes exclusively from draconic bloodlines. The Five Sovereign Dragons sacrificed themselves to anchor reality, their essence scattered through mortal blood. Every person's Dragon-Blood Purity percentage (revealed at age 15 on their Day of Ascension) determines their caste, rights, and ability to use magic. Society is a brutal feudal hierarchy sorted by blood purity. Non-human elder races exist with different lifespans and relationships to dragon blood.

---

## Dispatch the Following Agents

### Agent 1: Monster Compendium Builder
**System prompt file:** `monster_compendium_guide.md`

Build a comprehensive bestiary for Ourobora. At minimum:
- 100+ monsters across all CRs (0-30)
- Structured by environment: ruins, swamp, mountain, underground, abyss, civilized, coastal, frozen wastes
- Include full 5e stat blocks: AC, HP, speed, STR/DEX/CON/INT/WIS/CHA, traits, actions, legendary actions, lair actions, lore text, CR, XP
- Dragon taxonomy: 5 classes (Sovereign, Scion, Archon, Wyvern, Drake, Abomination) with variants at different CRs
- Aether-warped creatures: monsters mutated by raw magic exposure, unstable casters-turned-abomination
- Constructs: alchemical golems, dragon-bone sentinels, House Pyre war machines
- Undead: bound by failed Ascension rituals, Inquisitors who failed their Spell Safety saves
- Faction forces: House Ignis shock troops, Obsidian Inquisitors, Cult of the Sixth Penitents, House Ferrum shield infantry
- Beasts native to specific regions with local names and behaviors
- NPC templates: town guard, merchant, noble, inquisitor, cultist, laborer, academy instructor

### Agent 2: Races & Bloodlines Builder
**System prompt file:** `races_guide.md`

Expand the playable races with full 5e racial traits:
- Human bloodlines (sorted by purity, not chosen at creation)
- Dracon-Kin (Dragonborn): 5+ elemental variants, purity-based subraces
- Stone-Blood (Dwarf): mountain/forge/aether-resistant variants
- Ash-Walker (Tiefling): purity-instability subraces
- Deep-Blood (Elf): high/ancient/decaying bloodline variants
- Sump-Blood (Halfling): underground-adapted, Aether-immune
- Bone-Wrought (Warforged): constructed race, no purity
- Half-Breed: mixed human/Deep-Blood
- Include: ability score modifiers, age ranges, Day of Ascension age, size, speed, languages, darkvision, racial traits, subrace options
- Age restrictions per race (max starting age should be ~2/3 of average lifespan)

### Agent 3: Equipment, Weapons, Armor & Enchantments Builder
**System prompt file:** `equipment_guide.md`

Build the full equipment catalog:
- **Weapons:** All 5e weapon types re-flavored for Solis-Grave (House Pyre forged steel, dragon-bone weapons, Obsidian glass blades, Sump-forged iron)
- Weapon properties: finesse, heavy, light, loading, reach, special, two-handed, versatile, thrown
- Damage dice, damage types, weight, cost in Gold Crowns (noble) and Copper Farthings (commoner)
- **Armor:** Light/Medium/Heavy — House Ferrum plate, Vortex aerial leather, Obsidian judicial armor
- **Enchantments:** Only applicable to weapons/armor wielded by characters with sufficient blood purity
  - Enchantment tiers: Minor (requires 10%+ purity), Greater (25%+), Sovereign (50%+), God-Forged (90%+)
  - Each enchantment lists: effect, purity requirement, cost, rarity
  - Examples: Blaze-Infused (+1d4 fire), Storm-Channeled (returning thrown), Void-Touched (necromantic), Sovereign's Edge (bypasses Aether Burn for one spell level)
- **Adventuring gear:** Standard equipment re-flavored for the setting
- **Aether-Cores:** Harvested from slain monsters. Used as spell components, alchemy reagents, weapon coatings
- **Alchemical items:** Core injections (weapon coatings), Aether purifiers (potions), blood crystal testing kits

### Agent 4: Treasure & Loot System Builder
**System prompt file:** `treasure_system.md`

Build the treasure tables:
- **Individual treasure:** Based on CR range (0-4, 5-10, 11-16, 17+)
- **Hoard treasure:** Based on monster type and CR
- **Magic item tables:** Tables A through I (like DMG), but items are Solis-Grave originals
- **Area-based treasure:** Different regions yield different loot
  - Ruins: ancient dragon artifacts, Aether-Core fragments, historical texts
  - Urban/Noble: Gold Crowns, enchanted jewelry, House signets, political documents
  - Wilderness: monster parts, herbs, raw Aether crystals, survival gear
  - Underground/Abyss: forbidden texts, void-touched items, cult artifacts
  - Mountain: dragon bone, forge materials, rare minerals
  - Coastal: imported goods, Vortex trade items, preserved foods
  - Frozen wastes: Tenebris flesh-fusion components, preserved ancient specimens
- **Currency system:** Gold Imperial Crowns (noble), Silver Scales (merchant), Copper Sump Farthings (commoner)
- **Art objects and gems** re-flavored for the world

### Agent 5: Ascension System & Aging Rules Builder
**System prompt file:** `ascension_system.md`

Build the complete Day of Ascension and character aging system:
- Full ritual description: the Blood Crystal test, who administers it, what happens at each purity tier result
- Age rules per race: minimum starting age = Day of Ascension age; maximum starting age = ~2/3 average lifespan
- Purity determination methods: DM-assigned, roll tables (d100 with weighted results), point-buy with narrative drawbacks
- Aging effects on purity: Elder races slowly lose purity (Deep-Blood at ~1%/decade after 100)
- What happens when purity falls below casting thresholds
- Character creation checklist: race → class → background → stats → purity assignment → Day of Ascension narrative → starting equipment → House affiliation (if applicable)

---

## Output Requirements

Each agent should produce content in this format:
1. Start with a **summary table of contents** listing what was generated
2. Each entry should have **all mechanical fields** needed for a 5e stat block or item card
3. Include **lore/flavor text** for every entry
4. Flag content that needs **DM approval** or could be **potentially unbalanced**
5. All content assumes **Ourobora/Solis-Grave** as the setting

Coordinate with other agents:
- Monsters drop Aether-Cores → Equipment agent needs to know core types and tiers
- Enchantments require blood purity → Ascension agent defines purity mechanics
- Treasure tables reference items → Equipment agent provides the item catalog
- Race ages determine character creation rules → Ascension agent enforces them

---

## Execution Strategy

1. Dispatch all 5 agents in parallel — they can work independently
2. Each agent uses `query_external_ai` (DeepSeek) for quality creative generation
3. Agents save their output as structured JSON seed files for the compendium
4. After all agents complete, a consolidation agent resolves conflicts and gaps
5. Final output: 5 JSON files ready for `compendium_monsters`, `compendium_spells`, `compendium_items`, `compendium_rules`, and `compendium_feats` Supabase tables
