# Bot's Understanding of Official D&D 5e Resources

## What The Bot Knows

The DM bot uses **two sources** for rules:

### 1. D&D 5e SRD — Mechanical Engine
The bot is trained on the D&D 5e SRD (Systems Reference Document). It knows:
- Ability checks, saving throws, skill checks
- Attack rolls, armor class, damage types
- Combat actions (Attack, Dash, Disengage, Dodge, Help, Hide, Ready, Search)
- Spellcasting rules (slots, components, concentration, ritual casting)
- Advantage/Disadvantage mechanics
- Movement, cover, difficult terrain
- Conditions (blinded, charmed, etc.)
- Resting rules (short rest, long rest)
- Basic equipment and weapon properties
- Proficiency bonus scaling by level
- Death saving throws
- Challenge Rating (CR) system
- Standard race and class mechanics (re-skinned for Solis-Grave)

This is NOT from downloaded PDFs — it's from the bot's training data and the rules embedded in the system prompt.

### 2. Solis-Grave World Bible — Identity Layer
The bot has comprehensive knowledge of:
- All 6 Sovereign Dragons and the Church/Cult split
- The Betrayed (Nyx) and Void mechanics
- 8 playable races with Ascension ages and purity rules
- 6 classes with re-skinned mechanics
- The Blood Purity caste system
- Spell Safety DC and Aether Burn
- 6 Great Houses with faction traits and political dynamics
- Grimdark world tone (slavery, racism, feudal oppression)
- 191 spells, 65 monsters, 46 rules, 35 items, 21 feats, 8 backgrounds

## What We DON'T Have

| Resource | Status |
|---|---|
| SRD v5.2.1 PDF | Not downloaded |
| SRD v5.1 PDF | Not downloaded |
| Player's Handbook PDF | Not owned (paid content) |
| Dungeon Master's Guide PDF | Not owned (paid content) |
| Monster Manual PDF | Not owned (paid content) |
| Physical reference files | We have our own markdown versions |

## What We DO Have (Our Reference Books)

| Book | File | Content |
|---|---|---|
| Player's Handbook | `players_handbook.md` (25KB) | Rules, races, classes, spell overview |
| Monster Manual | `monster_manual.md` (generated) | 115 creatures, organized by CR |
| Spell Grimoire | `spell_grimoire.md` (generated) | 229 spells, organized by level |
| DM's Guide | `dm_guide.md` (generated) | Consolidated rules, quick reference tables |
| Item Catalog | `item_catalog.md` (generated) | 35 items, organized by type |
| Magic System | `rules/magic_system.md` | Spell Safety DC, Aether Burn, Wild Surge |
| Story Engine | `rules/story_engine.md` | Plot arcs, mission templates, entity profiles |
| Races Guide | `races_guide.md` (14KB) | All 8 races with full traits |
| Equipment Guide | `equipment_guide.md` (13KB) | Weapons, armor, enchantments |
| World Bible | `sovereigns_and_gods.md` + `the_betrayed.md` | Complete pantheon and lore |
| Welcome Script | `welcome_template.md` (6KB) | Campaign intro with house politics |
| Bot Guide | `discord_bot_guide.md` (15KB) | Player-facing how-to |
| Treasure System | `treasure_system.md` + `.json` | Loot tables by CR and region |

## How To Add the SRD

If you want the bot to have the actual SRD text available for reference (not just from training data):
1. Download the free SRD v5.2.1 PDF from D&D Beyond: https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf
2. Save it in `Kronus/documents/` or a reference directory
3. The bot can reference it for rules questions but still applies the adaptation rule — never copy SRD content without re-skinning for Solis-Grave
