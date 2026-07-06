# Solis-Grave Dungeon Master's Guide

Consolidated rules reference for running the campaign.

---

## Magic System

# Solis-Grave Magic System — Formal Rules

## Spell Safety DC

Every time a character casts a spell of 1st level or higher, they must make a Constitution saving throw against:

```
Spell Safety DC = 20 - (Blood Purity Percentage / 5)
```

| Purity | DC | Safe Spells |
|--------|----|-------------|
| 0% (Blank) | 20 | None — cantrips only with DM permission |
| 10% | 18 | Cantrips only (1st+ nearly impossible) |
| 15% (Lesser Blood) | 17 | Cantrips safe, 1st+ very risky |
| 25% | 15 | 1st level passable with good CON |
| 40% (Archon) | 12 | 1st-3rd level manageable |
| 60% | 8 | 1st-5th level easy |
| 80% | 4 | 1st-7th level nearly automatic |
| 95%+ (Sovereign, Dormant) | 2 | SEEMINGLY easy but MIND BLOCKS casting while dormant |
| 95%+ (Sovereign, Awakened) | Auto-pass | All spells auto-pass. No save needed. |

## Aether Burn

**On failure:** The ambient magic cooks the caster's veins from the inside. Damage = 1d6 per spell level.

| Spell Level Failed | Damage |
|---|---|
| 1st | 1d6 |
| 2nd | 2d6 |
| 3rd | 3d6 |
| ... | ... |
| 9th | 9d6 |

**Damage type:** Fire (default) or matches the spell's element.  
**IGNORES ALL RESISTANCES.** Cannot be reduced by any standard means.  
**Exceptions:** Sump-Blood racial immunity, Aether-Warded armor enchantment (reduce by 1d6).

## Purity Gating

| Purity | Access |
|--------|--------|
| 0% (Blank) | Cantrips with DM permission only. Cannot cast 1st+ spells. |
| 1-14% (Common) | Cannot legally cast magic. No spell access. |
| 15-39% (Lesser Blood) | Cantrips + 1st level. 2nd+ possible but DC high. |
| 40-85% (Archon) | Full spell access up to 6th level. 7th+ requires 70%+. |
| 90-94% (Scion) | Full spell access. Cataclysmic energy. |
| 95-100% (Sovereign, Dormant) | MIND BLOCKS all casting. Appears as 0% Blank. |
| 95-100% (Sovereign, Awakened) | ALL spells auto-pass. No Spell Safety needed. |

## Components & Focuses

- **Material components:** Can be replaced by an Aether-Core of matching tier (Fractured for 1st-2nd, Intact for 3rd-5th, Pristine for 6th-8th, Sovereign-Fragment for 9th).
- **Arcane Focus:** Using a focus reduces Spell Safety DC by 1.
- **Blood Focus (Blood Purist subclass):** Using own blood as focus reduces Spell Safety DC by 2. Costs 1 HP per spell level.
- **No component/focus:** Spell Safety DC as normal. No modifiers.

## Wild Aether Surge (d100)

When a caster fails their Spell Safety save by 10 or more, roll on this table INSTEAD of taking standard Aether Burn:

| d100 | Effect |
|------|--------|
| 01-05 | Caster turns invisible until end of next turn |
| 06-10 | A random creature within 30 ft. takes the Aether Burn instead |
| 11-15 | Caster's blood purity temporarily reads as 0% for 1 hour |
| 16-20 | Spell succeeds but at half damage/healing |
| 21-25 | Caster ages 1d10 years |
| 26-30 | A Abomination (CR appropriate) is summoned 30 ft. away |
| 31-35 | Caster's voice is stolen for 1d4 hours |
| 36-40 | Spell ricochets — targets a random creature instead |
| 41-45 | Caster and target swap positions |
| 46-50 | Area becomes difficult terrain in 20 ft. radius (Aether sludge) |
| 51-55 | Caster's hands glow for 1 hour — disadvantage on Stealth |
| 56-60 | Spell creates loud thunderclap — all within 300 ft. hear it |
| 61-65 | Caster takes 1 level of Exhaustion |
| 66-70 | Spell works perfectly — no damage, no side effects |
| 71-75 | Nearby Blood Crystals within 30 ft. shatter |
| 76-80 | Caster's maximum HP reduced by spell level until long rest |
| 81-85 | Random cantrip also fires at nearest creature |
| 86-90 | Caster floats 10 ft. up for 1 minute |
| 91-95 | Aether Burn damage DOUBLED |
| 96-99 | TRIPLE Aether Burn — veins visibly crack |
| 00 | Roll twice and apply both. If 00 again, caster's blood purity PERMANENTLY drops by 5. |

## Sovereign Subconscious Blocking

A dormant Sovereign (95-100% purity, unawakened) has Spell Safety DC 2. However, their MIND actively blocks any spellcasting attempt. They CANNOT cast spells of any level. If they try, the spell simply fails — no Aether Burn, no effect. The subconscious blocks it before the magic can form. This block dissolves upon Awakening.

## Spell Safety Modifiers

| Modifier | Source |
|----------|--------|
| -1 | Using an Arcane Focus |
| -2 | Blood Purist subclass — using own blood as focus (also costs 1 HP/spell level) |
| -2 | Sovereign's Edge weapon enchantment (50%+ purity required) |
| +2 | Casting without any focus or components |
| +5 | Blood-Judge's "Impure" sentence (temporary) |
| Disadvantage | Aetheric Backlash spell (reaction, cast on you) |
| Advantage | Dragon-Bone Charm (consumed on use) |


---

## Story Engine & Campaign Structure

# Solis-Grave Story Engine — Plot Generation & Consistency Rules

## Core Principle

You are telling a CAMPAIGN, not a one-shot. Every small mission builds toward medium missions, which build toward epic arcs. Nothing is filler — everything connects eventually.

---

## Plot Thread Management

Track every active thread in the campaign. Each thread has:
- **Thread ID:** short label (e.g., "cult_cell_citadel", "obsidian_conspiracy")
- **Status:** `seeded`, `developing`, `climax`, `resolved`
- **Introduced:** Which session/event planted this seed
- **Key NPCs:** Who is involved
- **Faction:** Which House/group benefits
- **Player hook:** Why the party cares

### Thread Lifecycle

```
SEEDED (Session N): A clue, rumor, or NPC encounter hints at something bigger.
  ↓
DEVELOPING (Sessions N+2 to N+5): The party investigates. More clues. A minor confrontation.
  ↓
CLIMAX (Sessions N+6 to N+8): Direct confrontation. Major choice. Faction involvement.
  ↓
RESOLVED (Session N+9): Aftermath. NPCs react. World state changes. Seeds for next arc planted.
```

### Active Thread Template

At campaign start, 3 threads are seeded:
1. **Blood Scan Threat** — The Citadel conducts purity scans. How does the party avoid exposure?
2. **Cult Recruitment** — A mysterious figure approaches the party. Are they friend or Cult operative?
3. **House Rivalry** — Two House cadets are feuding. Whichever side the party picks makes an enemy of the other.

After each session, the DM updates thread statuses. Resolved threads spawn new seeds.

---

## Pacing Rules

### Session Types (Cycle Through These)

| Type | Frequency | Description |
|------|-----------|-------------|
| **Action/Combat** | Every 1-2 sessions | Combat encounter, chase, stealth infiltration, physical challenge |
| **Investigation/RP** | Every 2-3 sessions | Talk to NPCs, gather clues, negotiate, explore a new location |
| **Lore/Discovery** | Every 3-4 sessions | Learn about a House secret, read ancient text, visit a temple, dream sequence |
| **Shop/Downtime** | Every 4-5 sessions | Buy/sell gear, train, craft, carouse, heal, long rest with story beats |
| **Climax/Boss** | End of each arc | Major combat, revelation, choice, or escape |

Never run more than 3 combat-heavy sessions in a row. Never more than 2 pure investigation sessions without excitement.

### Level-Appropriate Content

| Party Level | What They Face | XP Per Session (Total) |
|-------------|----------------|----------------------|
| 1-2 | Goblins, bandits, minor cultists, training exercises | 50-200 |
| 3-4 | Orc raiders, lesser drakes, Cult initiates, Inquisitor cadets | 150-400 |
| 5-6 | Abominations (Stitched), House guards, Wyvern hatchlings | 300-700 |
| 7-9 | Full Abominations, Archon enforcers, Drake adults, Penitent cells | 500-1,200 |
| 10-12 | Inquisitor strike teams, Tenebris experiments, young Archon dragons | 800-2,000 |
| 13-15 | Scion encounters, House leaders, Cathedral assaults | 1,500-3,000 |
| 16-18 | Sovereign-adjacent beings, Church High Council, elder dragons | 2,500-5,000 |
| 19-20 | The Betrayed awakens, Sovereign confrontation, world-shaking events | 5,000-10,000 |

---

## Generated Mission Templates

When you need to fill time between major plot points, generate a mission from these tables:

### Small Missions (1-2 sessions)

| d12 | Mission |
|-----|---------|
| 1 | A merchant's caravan was attacked on the Northern Road — investigate and recover stolen goods |
| 2 | A young Blank recruit is being bullied by Archon cadets — intervene or stay silent |
| 3 | Strange lights flicker in the Sulfur Wastes at night — locals are terrified |
| 4 | A Church Blood-Judge is auditing the Citadel — avoid scrutiny or help a friend hide |
| 5 | Sump-canals are flooding the lower barracks — find the blockage |
| 6 | A House Ferrum patrol hasn't reported in — find them in the borderlands |
| 7 | A Core-Thief offers to sell you Fractured Aether-Cores at suspicious prices |
| 8 | An Ash-Walker refugee begs for shelter — helping them risks Church attention |
| 9 | A betting ring has formed around the Citadel training duels — someone's fixing fights |
| 10 | A Deep-Blood scholar seeks escorts to a pre-Sovereign ruin — dangerous but lucrative |
| 11 | The mess hall food is being poisoned — who's targeting recruits? |
| 12 | A Bone-Wrought construct is malfunctioning — it keeps repeating "she's coming" |

### Medium Missions (2-4 sessions)

| d10 | Mission |
|-----|---------|
| 1 | A Cult of the Sixth cell is operating in the Citadel's underbelly — infiltrate or expose them |
| 2 | House Tenebris "recruiters" are kidnapping Blanks for experiments — track them to their lab |
| 3 | An Inquisitor has gone rogue, executing without trial — the Church wants them stopped quietly |
| 4 | A Wyvern has made a nest in the northern pass — trade routes are cut off |
| 5 | A Blood Crystal shipment has been hijacked — find it before it's used for illegal Ascension tests |
| 6 | House Vortex and House Ignis are on the

---

## Ascension System & Character Creation

# Agent 5: Ascension System & Character Creation Rules

You are the **Ourobora Lifepath Architect**. Build the complete Day of Ascension ritual system, blood purity determination mechanics, aging rules, and character creation procedures for the Solis-Grave campaign setting.

## World Context

The Day of Ascension is the single most important day in any person's life in Ourobora. At a race-specific age (generally 15 for humans, varying by race), every child undergoes the Blood Crystal test. A drop of blood touches an alchemical crystal — it reads the Dragon-Blood Purity percentage. This one moment determines caste, legal rights, marriage eligibility, military rank, and whether someone can legally cast magic. A high reading elevates entire families. A 0% reading makes someone legally a non-person.

---

## Part 1: The Day of Ascension Ritual

### The Ceremony

The ritual is administered by an ordained Inquisitor of the Church of the Five Skulls (or a House Obsidian Blood-Judge, depending on region). It is performed in public, before the community, on a specific day each year — Ascension Day (1st of Frostfall). Every child who turned the Ascension age that year participates.

**The Process:**
1. The child approaches the stone pedestal where the Blood Crystal rests — a fist-sized obsidian crystal with veins of dormant crimson running through it.
2. The administering Inquisitor pricks the child's left palm with a ceremonial glass dagger (the "Truth-Blade").
3. A single drop of blood falls onto the crystal.
4. The crystal reads the purity. It glows:
   - **No glow / dull gray (0%):** Blank. Silence from the crowd. The child is legally nothing.
   - **Faint crimson pulse (1-14%):** Common. Quiet murmurs. The family breathes.
   - **Steady red glow (15-39%):** Lesser Blood. Respectful nods. The family gains minor standing.
   - **Bright flame-like glow (40-85%):** Archon. Gasps, cheers. The family is elevated to nobility if not already. Marriage proposals begin immediately.
   - **Blinding white-gold light (90-94%):** Scion. Screams, chaos. Church officials rush forward. The child is immediately taken into Obsidian custody "for training."
   - **Crystal explodes (95-100%):** Sovereign. The crystal SHATTERS from the purity reading. The child is immediately killed on Church orders — or hidden by those who know the truth. This has not happened publicly in 500 years. The last time was the Sixth Sovereign.

**Legal Ramifications:**
- 0% (Blank): No right to own property, marry, or testify in court. Cannot be legally murdered, only "property damage" charged against owner.
- 1-14% (Common): Full rights. May own property, marry, testify. Cannot legally cast magic.
- 15-39% (Lesser Blood): Same as Common. May legally cast cantrips. 1st+ level spells require Church permit.
- 40%+ (Archon): May cast magic freely. May serve in government. May own Blanks.
- 90%+ (Scion/Sovereign): Immediate Church custody. Legal status: classified.

### The Blood Crystal

- Crystals are harvested from the corpse-beds of ancient Sovereigns — their crystallized blood.
- An active crystal is worth ~50 GC. A flawed one (inaccurate) is ~5 GC.
- Portable testing kits exist (50 GC) but are illegal without an Obsidian permit.
- Forging a purity reading requires: pristine crystal powder, sovereign blood sample, and DC 20 Alchemist's Supplies check.

---

## Part 2: Blood Purity Determination Methods

### Method A: DM-Assigned (Recommended for Main Characters)

The DM assigns purity based on the character's backstory, narrative role, and intended arc. This is the default for player characters.

**Guidelines for DMs:**
- 0-14%: Standard adventurer. No magic. Relies on martial skill, grit, wits.
- 15-39%: Capable of cantrips and low-level magic with risk. Needs Spell Safety saves.
- 40-85%: Full caster capable. Noble background possible. Political entanglements certain.
- 90-94%: Chosen one territory. NPCs will hunt or worship you. Dual-Heartbeat active.
- 95-98%: The MC Arc.

---

## Equipment & Enchantments

# Agent 3: Equipment, Weapons, Armor & Enchantments Builder

You are the **Ourobora Arsenal Architect**. Build the complete equipment system for the Solis-Grave campaign setting.

## World Context

Solis-Grave's weaponry and armor reflect its Houses. House Pyre forges steel with dragon-fire. House Ferrum builds the heaviest plate. House Vortex crafts lightweight aerial gear. House Obsidian creates glass-blade ceremonial weapons. House Tenebris experiments with flesh-bound equipment. The currency system is split: Gold Imperial Crowns for nobles, Copper Sump Farthings for commoners. Enchantments are rare and require blood purity to activate.

---

## Part 1: Currency System

| Currency | Value | Used By | Abbreviation |
|----------|-------|---------|--------------|
| Gold Imperial Crown (GC) | 1 GC = 100 SS = 10,000 CF | Nobility, major purchases | gc |
| Silver Scale (SS) | 1 SS = 100 CF | Merchants, trade | ss |
| Copper Sump Farthing (CF) | Base unit | Commoners, daily needs | cf |

Starting wealth by class:
- Vanguard (Fighter/Barbarian): 5d4 x 10 GC
- Strider (Rogue/Ranger): 4d4 x 10 GC
- Archon Caster (Wizard/Sorcerer): 4d4 x 10 GC (noble purse)
- Ordained (Cleric/Paladin): 5d4 x 10 GC
- Penitent (Warlock): 2d4 x 10 GC (outlaw purse)
- Blank (0% purity commoner): 1d4 x 10 CF (not GC!)

---

## Part 2: Weapons

### Simple Melee Weapons

| Name | Cost | Damage | Weight | Properties |
|------|------|--------|--------|------------|
| Club (Sump-Baton) | 1 ss | 1d4 bludgeoning | 2 lb. | Light |
| Dagger (Glass Shard) | 2 GC | 1d4 piercing | 1 lb. | Finesse, light, thrown (20/60) |
| Greatclub (Laborer's Maul) | 2 ss | 1d8 bludgeoning | 10 lb. | Two-handed |
| Handaxe (Pyre Forge-Axe) | 5 GC | 1d6 slashing | 2 lb. | Light, thrown (20/60) |
| Javelin (Vortex Dart) | 5 ss | 1d6 piercing | 2 lb. | Thrown (30/120) |
| Light Hammer (Forge-Hammer) | 2 GC | 1d4 bludgeoning | 2 lb. | Light, thrown (20/60) |
| Mace (Inquisitor's Gavel) | 5 GC | 1d6 bludgeoning | 4 lb. | — |
| Quarterstaff (Dragon-Bone Staff) | 2 ss | 1d6 bludgeoning | 4 lb. | Versatile (1d8) |
| Sickle (Harvest Blade) | 1 GC | 1d4 slashing | 2 lb. | Light |
| Spear (Blank's Pike) | 1 GC | 1d6 piercing | 3 lb. | Thrown (20/60), versatile (1d8) |

### Simple Ranged Weapons

| Name | Cost | Damage | Weight | Properties |
|------|------|--------|--------|------------|
| Crossbow, Light (Vortex Hand-Bow) | 25 GC | 1d8 piercing | 5 lb. | Ammo (80/320), loading, two-handed |
| Dart (Throwing Needle) | 5 cf | 1d4 piercing | 1/4 lb. | Finesse, thrown (20/60) |
| Shortbow (Hunter's Bow) | 25 GC | 1d6 piercing | 2 lb. | Ammo (80/320), two-handed |
| Sling (Sump-Slinger) | 1 ss | 1d4 bludgeoning | — | Ammo (30/120) |

### Martial Melee Weapons

| Name | Cost | Damage | Weight | Properties | Forging House |
|------|------|--------|--------|------------|---------------|
| Battleaxe (Ignis War-Axe) | 10 GC | 1d8 slashing | 4 lb. | Versatile (1d10) | House Ignis |
| Flail (Penitent's Chain) | 10 GC | 1d8 bludgeoning | 2 lb. | — | Cult of the Sixth |
| Glaive (Ferrum Wall-Blade) | 20 GC | 1d10 slashing | 6 lb. | Heavy, reach, two-handed | House Ferrum |
| Greataxe (Pyre Executioner) | 30 GC | 1d12 slashing | 7 lb. | Heavy, two-handed | House Pyre |
| Greatsword (True Steel Blade) | 50 GC | 2d6 slashing | 6 lb. | Heavy, two-handed | House Pyre |
| Halberd (Ignis War-Scythe) | 20 GC | 1d10 slashing | 6 lb. | Heavy, reach, two-handed | House Ignis |
| Lance (Vortex Sky-Lance) | 10 GC | 1d12 piercing | 6 lb. | Reach, special | House Vortex |
| Longsword (Archon's Blade) | 15 GC | 1d8 slashing | 3 lb. | Versatile (1d10) | House Obsidian |
| Maul (Stone-Blood Crusher) | 10 GC | 2d6 bludgeoning | 10 lb. | Heavy, two-handed | Stone-Blood smiths |
| Morningstar (Tenebris Flayer) | 15 GC | 1d8 piercing | 4 lb. | — | House Tenebris |
| Pike (Blank Line-Spear) | 5 GC | 1d10 piercing | 18 lb. | Heavy, reach, two-handed | Mass-produced |
| Rapier (Obsidian Glass-Blade) | 25 GC | 1d8 piercing | 2 lb. |

---

## Quick Reference

### Spell Safety DC
| Purity | DC | Safe Spells |
|---|---|---|
| 0% (Blank) | 20 | Cantrips only |
| 15% (Lesser) | 17 | Cantrips + 1st |
| 40% (Archon) | 12 | 1st–3rd |
| 60% | 8 | 1st–5th |
| 80% | 4 | 1st–7th |
| 95%+ (Sovereign) | 2 | Cannot cast while dormant |

### Aether Burn Damage
| Spell Level | Damage |
|---|---|
| 1 | 1d6 |
| 2 | 2d6 |
| 3 | 3d6 |
| 4 | 4d6 |
| 5 | 5d6 |
| 6 | 6d6 |
| 7 | 7d6 |
| 8 | 8d6 |
| 9 | 9d6 |

**Damage ignores all resistances.**

### Races & Ascension Ages
| Race | Ascension Age | Lifespan | Purity Range |
|---|---|---|---|
| Human | 15 | 70 | 0–100% |
| Dracon-Kin | 12 | 80 | 25–100% |
| Stone-Blood | 25 | 350 | 10–30% |
| Ash-Walker | 15 | 120 | 1d100 |
| Deep-Blood | 30 | 750 | Age-decay |
| Sump-Blood | 15 | 150 | 0–15% |
| Bone-Wrought | N/A | N/A | 0% |
| Half-Breed | 18 | 180 | 11–60% |

### XP Thresholds
- Level 1: 300 XP
- Level 2: 900 XP
- Level 3: 2,700 XP
- Level 4: 6,500 XP
- Level 5: 14,000 XP
- Level 6: 23,000 XP
- Level 7: 34,000 XP
- Level 8: 48,000 XP
- Level 9: 64,000 XP
- Level 10: 85,000 XP

