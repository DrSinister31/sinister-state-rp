# Solis-Grave Player's Handbook

## Welcome, Wayfarer

You stand before the **Citadel of the Dragon-Garrison**, an obsidian-and-brass fortress whose walls are carved with the sigils of every bloodline the Inquisition has ever catalogued. Beyond its gates lies a continent scarred by draconic wars, where magic is not learned — it is *inherited*.

In Solis-Grave, your bloodline decides your destiny. A **Blank** (0%) cannot cast so much as a candle-flame. A **Sovereign** (50%+) can level cities. And the **Inquisition** hunts them all.

---

## Table of Contents

1. [The World of Solis-Grave](#the-world-of-solis-grave)
2. [The Magic System](#the-magic-system)
3. [Classes](#classes)
4. [Character Creation](#character-creation)
5. [Equipment & Items](#equipment--items)
6. [Spells Quick Reference](#spells-quick-reference)
7. [Combat Rules](#combat-rules)
8. [Conditions & Death](#conditions--death)
9. [Campaign Modes](#campaign-modes)
10. [The Secret Sovereign](#the-secret-sovereign)
11. [Glossary](#glossary)

---

## The World of Solis-Grave

### History in Brief

Millennia ago, seven Ancient Dragons — the Progenitors — waged war across the continent. Their blood soaked the soil. Their bones became mountains. And their essence, the **Aether**, seeped into mortal bloodlines.

Today, every living creature carries a trace of draconic blood. The percentage of that blood — your **Blood Purity** — determines whether you can work magic, and at what cost.

### Factions

| Faction | Motto | Role |
|---------|-------|------|
| **The Citadel** | "Order through blood." | Ruling government. Registers bloodlines, grants casting licenses. |
| **The Inquisition** | "Purity is truth." | Hunts unregistered and hidden bloodlines. Feared by all. |
| **The Dragon-Gods** | Pantheon of the Seven | Objects of worship. Clerics and Paladins draw power from them. |
| **The Unbound** | Underground resistance | Hidden Sovereigns, rogue Archons, Penitents fleeing blood-debts. |
| **The Crimson Oath** | Monster hunters | Legal Blood Hunters. Respected by Inquisitors for their work. |

### Key Locations

- **Citadel of the Dragon-Garrison** — Starting location. Inquisitor headquarters. Blood scans mandatory.
- **The Ash-Wastes** — Where the Progenitor War ended. Aether storms. Wild magic.
- **The Sump** — Goblin/orc slums beneath the Citadel. Lawless. Greenskin territory.
- **Dragon-Graves** — Ley line intersections. +10% purity while nearby.
- **The Black Citadel** — Ruined fortress. Rumored to be the tomb of the last Progenitor.

### Social Rules

- **Greenskin racism**: Goblins, orcs, and trolls are legally **non-persons** in civilized territories. Playing a Greenskin means constant hostility from NPCs and potential arrest on sight.
- **Blood scans**: The Citadel scans all new arrivals. A high-purity reading means registration, surveillance, or worse.
- **Dormancy**: You can *suppress* your bloodline to appear as a lower purity. This gives you a **-4 penalty** on all standard rolls while suppressed.

---

## The Magic System

### Core Principle

**Magic comes exclusively from draconic bloodlines.** There is no divine/arcane/nature/primal split. A Cleric's healing prayer and a Wizard's fireball come from the same source — the Progenitor blood in your veins.

### Blood Purity Brackets

| Purity | Title | Max Spell Level | Notable |
|--------|-------|:--:|---------|
| 0% | **Blank** | Cantrips only | Most civilians. Cannot cast leveled spells. |
| 1-10% | **Tainted** | 2nd | Thin bloodline. Cantrips + low magic. |
| 11-25% | **Lesser Blood / Scion** | 5th | Common among adventurers. |
| 26-49% | **Half-Sovereign / Heir** | 5th | Rare. Attracts Inquisitor attention. |
| 50-74% | **Sovereign** | 7th | The elite. The hunted. |
| 75-89% | **Greater Sovereign / Archon** | 8th | Near-legendary. |
| 90-99% | **Dragon-Lord** | 9th | One per generation, if that. |
| 100% | **God-Forged** | 9th (no DC) | Immune to Aether Burn. Theoretical. |

### Casting a Spell

Every time you cast a spell of any level:

1. **Declare the spell** and expend the slot
2. **Provide components**: V (Old Tongue words), S (bloodline sigil gestures), M (Aether-Core of matching element)
3. **Roll Spell Safety save**: `d20 + spellcasting ability modifier` vs. the DC below

### Spell Safety DC

```
Spell Safety DC = 8 + spell_level + (15 - purity ÷ 7, rounded down)
```

| Purity | Cantrip | 1st | 3rd | 5th | 7th | 9th |
|--------|:--:|:--:|:--:|:--:|:--:|:--:|
| 0% | 23 | — | — | — | — | — |
| 10% | 21 | 22 | — | — | — | — |
| 25% | 19 | 20 | 22 | 24 | — | — |
| 50% | 15 | 16 | 18 | 20 | 22 | — |
| 75% | 12 | 13 | 15 | 17 | 19 | 21 |
| 90% | 10 | 11 | 13 | 15 | 17 | 19 |
| 100% | Auto | Auto | Auto | Auto | Auto | Auto |

**On success:** Spell casts normally.

**On failure:** Spell fizzles (slot is expended). You suffer **Aether Burn**.

**On natural 1:** Double Aether Burn + roll on the **Wild Aether Surge table**.

### Aether Burn

```
Aether Burn = (spell_level + 1)d6 psychic damage
```

| Level | Cantrip | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th | 8th | 9th |
|-------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Damage | 1d6 | 2d6 | 3d6 | 4d6 | 5d6 | 6d6 | 7d6 | 8d6 | 9d6 | 10d6 |

Aether Burn is **psychic damage** that cannot be reduced by resistance. It manifests as searing cracks of light along your veins.

### Purity Gating

| Spell Level | Rule |
|:-----------:|------|
| **Cantrips** | Anyone can cast, any purity. |
| **1st-2nd** | Soft gate: 10%+ or succeed on Spell Safety with +5 DC penalty. |
| **3rd-5th** | Soft gate: 25%+ or succeed with +5 DC penalty. |
| **6th-7th** | **Hard gate: 50%+ required.** No exceptions. |
| **8th-9th** | **Hard gate: 75%+ required.** No exceptions. |

### Spell Components

| Component | Name | Description |
|-----------|------|-------------|
| **V** | Old Tongue | Draconic syllables. Whispered for subtle spells, roared for evocations. |
| **S** | Bloodline Sigil | Hand gesture tracing your unique sigil. Wrong sigil = auto-fail. |
| **M** | Aether-Core | Harvested from slain monsters. Replace ALL standard D&D components. |

### Aether-Cores

| Core Tier | Source CR | Fuels | Cost |
|-----------|:---------:|-------|------|
| **Fractured** | CR 1-4 | Cantrips, 1st-2nd | 5-50 GC |
| **Intact** | CR 5-10 | 3rd-5th | 50-500 GC |
| **Pristine** | CR 11-16 | 6th-7th | 500-5,000 GC |
| **Sovereign-Fragment** | CR 17+ | 8th-9th | 5,000-50,000 GC |

Cores are **NOT consumed** on successful casting. They shatter only when you fail a Spell Safety save — absorbing the backlash that would otherwise kill you.

**Matching the core's element to the spell reduces your Spell Safety DC by 1.**

Core elements: Fire, Storm, Void, Earth, Frost, Flesh, Law, Wild (universal, no DC reduction).

### Purity Modifiers

| Situation | Effect | Duration |
|-----------|:--:|----------|
| Sovereign Surge (class ability) | +15% | 1 minute, 1/short rest |
| Dormancy (hiding bloodline) | -20% | While suppressed |
| Inquisitor within 60ft | -10% | While in range |
| Dragon-Touched location | +10% | While in area |
| Aether Storm weather | -15% | Storm duration |
| Blood Offering (1d4 self-damage) | +5% per 1d4 | 1 round |
| God-Shroud Armor (attuned) | Resets to 90% | While worn |

### Aether Burn Risk Tags

Every spell is tagged with one of:

| Tag | +DC | Typical Spells |
|-----|:--:|----------------|
| **None** | +0 | Cantrips, ritual-only spells |
| **Low** | +1 | Defensive buffs, divination, minor utility |
| **Moderate** | +2 | Most combat spells |
| **Severe** | +3 | High-damage evocations, necromancy, conjuration |
| **Catastrophic** | +5 | 9th level, bloodline manipulation, resurrection |

This is ADDED to the base Spell Safety DC.

### Concentration & Aether Burn

When you're concentrating on a spell and suffer Aether Burn, make a **Concentration save** at DC 10 or half the burn damage (whichever is higher), in addition to any other concentration triggers that round.

---

## Classes

### Standard Classes (12)

| Class | Solis-Grave Name | Casting | Start Purity | Max Lvl |
|-------|-----------------|:-------:|:------------:|:-------:|
| **Barbarian** | War-Scion | None (cantrips at 10%+) | 10% | 0 |
| **Bard** | Lore-Keeper | Full | 25% | 9 |
| **Cleric** | Ordained | Full | 50% | 9 |
| **Druid** | Wild-Blood | Full | 25% | 9 |
| **Fighter** | Vanguard | None (EK: 1/3 caster) | 10% | 4 (EK) |
| **Monk** | Iron-Soul | None (cantrips at 10%+) | 10% | 0 |
| **Paladin** | Oath-Sworn | Half | 50% | 5 |
| **Ranger** | Strider | Half | 25% | 5 |
| **Rogue** | Shadow-Blood | None (AT: 1/3 caster) | 10% | 4 (AT) |
| **Sorcerer** | Archon | Full | 50% | 9 |
| **Warlock** | Penitent | Pact | 10% | 9 |
| **Wizard** | Archon Caster | Full | 25% | 9 |

### Homebrew Classes (3)

| Class | Solis-Grave Name | Casting | Start Purity | Max Lvl |
|-------|-----------------|:-------:|:------------:|:-------:|
| **Artificer** | Aether-Smith | Half | 10% | 5 |
| **Blood Hunter** | Crimson Oath | Half | 25% | 5 |
| **Sovereign** | Dragon-Heir | Full | 50% | 9 |

### Blood Awakening

At **3rd level**, non-caster classes (Barbarian, Fighter, Monk, Rogue) with 10%+ purity unlock **Blood Awakening**. They learn 2 cantrips from their linked spell list, cast with a +2 spellcasting mod regardless of stats. Their draconic blood stirs, enough to channel ambient aether without formal training.

| Non-Caster | Cantrip Source |
|------------|:--:|
| Barbarian | Druid |
| Fighter | Wizard |
| Monk | Cleric |
| Rogue | Wizard |

### Class Spotlight: Warlock (Penitent)

You made a pact with an Ancient Dragon-God, a Void entity, or a Sovereign spirit. Your magic is *borrowed* — and the interest is blood. Penitents are the most hunted class in Solis-Grave. Choose your patron carefully:

- **Archfiend** → Ancient Red Dragon (cinder/fire)
- **Great Old One** → Void Progenitor (abyssal/void)
- **Celestial** → Dragon-God of Law (celestial/law)
- **Fathomless** → Deep Wyrm (frost/storm)
- **Hexblade** → Bound weapon forged from a sovereign's bone

### Class Spotlight: Sorcerer (Archon)

You didn't study. You didn't pray. You were *born* this way. Archons are the face of legal magic — registered, taxed, and watched. Your bloodline is random: a wild surge of draconic essence that manifested at puberty, a stress event, or birth.

Metamagic — the ability to reshape spells on the fly — is unique to Archons and Sovereigns.

### Class Spotlight: Sovereign (Dragon-Heir) — SECRET

You don't pick Sovereign. **Sovereign picks you.**

At campaign start, one player is randomly and secretly chosen as a dormant Sovereign. They play a normal class. Their bloodline awakens through story events — a failed Inquisitor blood scan, a near-death experience at a Dragon-Grave, or their first spell cast.

When the bloodline awakens:
- You **gain the Sovereign class features ON TOP of your existing class**
- Your purity jumps to 50% immediately
- You gain `Sovereign Surge`: 1/short rest, +15% purity for 1 minute
- You gain access to the Sovereign spell list (signature spells like *Bloodline Severance*, *Dragon Apotheosis*, *Sovereign's Decree*)
- Your purity increases by +5% at levels 5, 10, 15, 20
- At level 20, you can reach **100% purity** — the only class that can
- The Inquisition will hunt you relentlessly from the moment your bloodline is revealed

**If you're solo,** you ARE the Sovereign. No random selection — you're the main character.

---

## Character Creation

### Step-by-Step

1. **Choose a class** from the 14 selectable classes (Sovereign is not selectable — it's granted secretly)
2. **Choose a race** — Human, Elf, Dwarf, Half-Orc, Tiefling, etc. (standard D&D races)
3. **Set your name**
4. **Roll or assign stats** — STR, DEX, CON, INT, WIS, CHA (standard array, point buy, or 4d6k3)
5. **Note your starting Blood Purity** from the class table above
6. **Choose starting equipment** from your class options
7. **Create your sheet** with `/character_create` in Discord

### Discord Character Commands

| Command | Effect |
|---------|--------|
| `/character_create name: class: race: level:` | Create your sheet |
| `/character_view name:` | View a character's public embed |
| `/character_mine` | Bot DMs you your FULL private sheet |
| `/character_list` | See all campaign characters |
| `/character_edit name: field: value:` | DM-only: adjust stats |
| `/character_longrest` | Reset HP/spell slots/conditions |
| `/character_shortrest` | Roll hit dice, recover HP |

---

## Equipment & Items

### Currency

| Coin | Value | Abbreviation |
|------|-------|:--:|
| Gold Crown | Base | GC |
| Silver Scale | 1/10 GC | SS |
| Copper Farthing | 1/100 GC | CF |

### Starting Wealth by Class

| Archetype | Classes | Gold |
|-----------|---------|------|
| Vanguard | Fighter, Barbarian | 5d4 × 10 GC |
| Strider | Rogue, Ranger | 4d4 × 10 GC |
| Archon Caster | Wizard, Sorcerer | 4d4 × 10 GC |
| Ordained | Cleric, Paladin | 5d4 × 10 GC |
| Penitent | Warlock | 2d4 × 10 GC |
| Wild-Blood | Druid | 3d4 × 10 GC |
| Iron-Soul | Monk | 1d4 × 10 GC |
| Aether-Smith | Artificer | 5d4 × 10 GC |
| Crimson Oath | Blood Hunter | 3d4 × 10 GC |

### Enchantments

Enchanted weapons and armor require **Blood Purity** to activate. In a Blank's hands, an enchanted blade is just a well-made weapon.

| Tier | Purity Required | Rarity | Cost Modifier |
|------|:--:|--------|:---:|
| Minor | 10%+ | Uncommon | +200 GC |
| Greater | 25%+ | Rare | +2,000 GC |
| Sovereign | 50%+ | Very Rare | +20,000 GC |
| God-Forged | 90%+ | Legendary | +100,000 GC |

### Key Magic Items

| Item | Effect | Purity |
|------|--------|:--:|
| **God-Shroud Armor** | Sets purity to 90% while worn. Immune to Aether Burn. Cast 5th-level spell without Spell Safety check 1/long rest. | 90% |
| **Sovereign's Edge** | Reroll failed Spell Safety save 1/day. | 50% |
| **Aether-Warded Shield** | Advantage on Spell Safety saves. | 25% |
| **Void-Touched Blade** | Reduces target's Spell Safety DC by 2 when used as focus. | 25% |
| **Dragon-Bone Charm** | +5% temporary purity 1/long rest. | 10% |
| **Core Injector Kit** | Inject Aether-Core essence into your veins. Gain +15% purity for 1 minute. Take 2d6 damage. Blood Hunter signature item. | 25% |

---

## Spells Quick Reference

The full compendium contains **334 spells** across all 15 classes and levels 0-9. Use `/lore fire` or `/lore heal` to search in Discord.

### Cantrips by Class

| Class | Cantrips Known (Max) | Examples |
|-------|:--:|----------|
| Bard | 4 | *Wyrm's Whisper, Dread-Shift, Vigor-Touch* |
| Cleric | 5 | *Healing Chant, Argent Beam, Bone-Knell* |
| Druid | 4 | *Thorn-Whip, Wyrm's Ember, Frostbite Sigil* |
| Sorcerer | 6 | *Cinder Bolt, Death-Stilling, Wing-Gust, Venom Ward, Aether-Pocket* |
| Warlock | 4 | *Sapping Bolt, Ghost-Scale, Aether-Veil* |
| Wizard | 5 | *Cinder Bolt, Death-Stilling, Wing-Gust, Aether-Pocket, Forge-Touch* |
| Artificer | 4 | *Aether-Sight, Forge-Touch, Wyrm's Grasp, Gear-Whisper* |
| Blood Hunter | 4 | *Blood-Surge, Hunt-Sight, Crimson Dart, Titan-Blood* |
| Sovereign | 6 | *Blood-Surge, Dragon-Breath, Wyrm's Command, Sovereign's Whisper, Hunt-Sight, Cinder Bolt* |

### Iconic Solis-Grave Spells

| Level | Spell | Class | Effect |
|:--:|-------|-------|--------|
| 0 | **Cinder Bolt** | Sor/Wiz/Sov | 1d10 fire, range 120ft. *The standard attack cantrip.* |
| 1 | **Blood-Mend** | Clr/Drd/Brd | Heal 1d8+mod. *Replaces Cure Wounds.* |
| 1 | **Sigil Dart** | Sor/Wiz | 3 darts, 1d4+1 each, auto-hit. *Replaces Magic Missile.* |
| 3 | **Cinder Burst** | Sor/Wiz | 8d6 fire, 20ft radius. *Replaces Fireball.* |
| 3 | **Death-Defy** | Clr/Pal | Revive creature that died within 1 minute. *Replaces Revivify.* |
| 5 | **Sovereign's Decree** | Sov/Pal | Command all enemies in 60ft, WIS save. 1 minute. |
| 6 | **Wyrm's Unmaking** | Sor/Wiz/Sov | 10d6+40 force, single target. *Replaces Disintegrate.* |
| 7 | **Draconic Ascension** | Sov/Sor | Transform: wings, breath weapon, +5 AC. 1 min. |
| 8 | **God-Shroud** | Sov/Clr | Grant creature 90% purity + Aether Burn immunity. 1 hour. |
| 9 | **Bloodline Severance** | Sov ONLY | Permanently reduce target's purity to 0%. 50,000 GC cost. |
| 9 | **Dragon Apotheosis** | Sov ONLY | Become an Ancient Dragon. 1 minute. |
| 9 | **Bloodline Awakening** | Sov/Wiz | Permanently grant 25% purity to a 0% Blank. |

---

## Combat Rules

### Initiative

When combat begins, the DM announces `⚔️ COMBAT START — Roll initiative!` Each player rolls `d20 + DEX mod`. NPCs and enemies roll automatically. The DM tracks turn order.

Use `/initiative <name> <roll>` to add yourself to the tracker.

### Your Turn

On your turn, you can:
- **Move** up to your Speed in feet
- Take **one Action** (attack, cast a spell, dash, disengage, dodge, help, hide, ready, search, use an object)
- Take **one Bonus Action** if you have an ability that uses one
- **One free object interaction** (draw a weapon, open a door)

### Rolling Checks

Use `/roll <dice>` in Discord. Examples:
- `/roll 1d20+5` — Attack roll, ability check, saving throw
- `/roll 1d20` — Initiative
- `/roll 2d6+3` — Damage
- `/roll 4d6k3` — Stat generation (roll 4, keep highest 3)

### Damage

The DM bot tracks damage automatically via `[SHEET:]` tags in narration:
- `[SHEET: Bob: hp=-6]` — Bob takes 6 damage
- `[SHEET: Goblin: hp=+8]` — Goblin is healed 8

Your character sheet embed updates live.

### Solis-Grave Combat Mechanics

| Mechanic | Rule |
|----------|------|
| **Dual-Heartbeat** | Hidden Sovereigns roll d20 at combat start and when Inquisitors are within 60ft. On 1-5, the bloodline *surges* uncontrollably — the Sovereign is revealed to all within line of sight. |
| **Sovereign Surge** | Sovereign class ability. 1/short rest. +15% purity for 1 minute. The surge is visible — your eyes glow, veins light up, and sigils manifest on your skin. |
| **Aether Burn in Combat** | When you fail a Spell Safety save, you take the burn AND must make a Concentration save. A natural 1 on the Spell Safety save triggers the Wild Aether Surge table. |

---

## Conditions & Death

### Conditions

| Condition | Effect |
|-----------|--------|
| Blinded | Auto-fail sight checks. Attacks against you have advantage. Your attacks have disadvantage. |
| Charmed | Can't attack charmer. Charmer has advantage on social checks against you. |
| Deafened | Auto-fail hearing checks. |
| Frightened | Disadvantage on checks/attacks while source is visible. Can't willingly move closer. |
| Grappled | Speed = 0. Ends if grappler is incapacitated or moved. |
| Incapacitated | Can't take actions, bonus actions, or reactions. |
| Invisible | Heavily obscured. Advantage on attacks. Attacks against you have disadvantage. |
| Paralyzed | Incapacitated + auto-fail STR/DEX saves. Attacks within 5ft are crits. |
| Petrified | Incapacitated + resistance to all damage + immune to poison/disease + weight ×10. |
| Poisoned | Disadvantage on all attacks and checks. |
| Prone | Disadvantage on attacks. Attacks within 5ft have advantage. Ranged attacks have disadvantage. |
| Restrained | Speed = 0. Disadvantage on attacks. Attacks against you have advantage. Disadvantage on DEX saves. |
| Stunned | Incapacitated + auto-fail STR/DEX saves. Attacks against you have advantage. |
| Unconscious | Incapacitated + prone + auto-fail STR/DEX saves. Attacks within 5ft are crits. |

### Death & Dying

When your HP drops to 0:
1. You fall **unconscious**
2. At the start of each of your turns, roll a **Death Saving Throw** (d20, no modifiers)
3. **10 or higher** = success. **9 or lower** = failure. **Natural 20** = regain 1 HP. **Natural 1** = two failures.
4. **3 successes** = stabilized (unconscious but not dying)
5. **3 failures** = dead

Death saves are tracked on your character sheet embed automatically by the DM bot.

### Returning from Death

| Method | Spell Level | Cost |
|--------|:--:|------|
| Death-Defy (*Revivify*) | 3rd | 300 GC Pristine Core |
| Blood-Rebirth (*Reincarnate*) | 5th | 1,000 GC Pristine Core |
| Scale-Mend (*Raise Dead*) | 5th | 500 GC Pristine Core |
| Rebirth of the Bloodline (*Resurrection*) | 7th | 5,000 GC Sovereign-Fragment |
| Second Breath of the Fallen (*True Resurrection*) | 9th | 25,000 GC Sovereign-Fragment |

---

## Campaign Modes

### Solo + NPC Party

You are the **main character**. You ARE the Sovereign.

Your private channel is created under `Dungeons & Dragons` named `#solo-yourname`. Only you, the bot, and the DM can see it.

**Your Party:** The DM generates **4 NPC companions** — a tank, a healer, a caster, and a scout. Each has a full personality, backstory, and simplified combat sheet. You can issue them commands:
- "Tell the cleric to heal me"
- "Kolgrim, hold the door"
- "Scout ahead, Vex"

NPCs can **die permanently**. They'll be replaced at the next safe location (town, camp, etc.). They gain XP and level with you.

View your party: `/npc_list`

**Cross-Play:** If another solo player is in the same region, your parties may meet. The DM rolls a d100 each in-game day — on 85+, the encounter happens.

### Group Play

2-5 players. One of you is secretly the Sovereign — the DM reveals it through story. Everyone plays together in a shared channel.

---

## The Secret Sovereign

One player per campaign is **randomly selected** to carry the dormant Sovereign bloodline. You won't know it's you until the story reveals it.

### How It Awakens

The DM may trigger the awakening through:
- A failed blood scan at the Citadel gates
- Your first spell cast in combat
- A near-death experience at a Dragon-Grave
- An Inquisitor sensing something "wrong" about you
- Touching a Sovereign-Fragment Aether-Core

### After Awakening

- Your purity jumps to 50%
- You gain the Sovereign class features alongside your existing class
- You gain access to the Sovereign spell list
- The Inquisition is now hunting you
- You can reach **100% purity** by level 20 — the only character who can

### Playing as a Hidden Sovereign

Before awakening, you're affected by:
- **Dormancy Penalty:** -4 on all standard rolls (your body is suppressing something immense)
- **Dual-Heartbeat:** At combat start or Inquisitor proximity, roll d20. On 1-5, the bloodline surges and you're revealed.

---

## Glossary

| Term | Definition |
|------|------------|
| **Aether** | Raw draconic energy permeating the world. The source of all magic. |
| **Aether Burn** | Psychic backlash suffered when a spell fails its Spell Safety check. `(spell_level+1)d6`. |
| **Aether-Core** | Crystallized Aether harvested from slain monsters. Required spell component. Tiers: Fractured → Intact → Pristine → Sovereign-Fragment. |
| **Archon** | Solis-Grave term for a Sorcerer — innate caster whose bloodline manifested randomly. |
| **Archon Caster** | Solis-Grave term for a Wizard — scholarly caster who studies the Old Tongue rather than channeling instinctively. |
| **Blank** | A person with 0% blood purity. Cannot cast leveled spells. Common. |
| **Blood Purity** | Percentage of draconic blood in your lineage. Determines casting ability, Spell Safety DC, and social status. |
| **Bloodline Sigil** | A unique hand gesture/symbol representing your draconic bloodline. Required somatic component for all spells. |
| **Citadel** | The ruling government and primary city. Headquarters of the Inquisition. |
| **Crimson Oath** | Blood Hunters — legal monster hunters who inject Aether-Core essence. |
| **Dormancy** | Voluntarily suppressing your bloodline. Appears as lower purity on scans. Inflicts -4 penalty on all rolls while active. |
| **Dragon-Gods** | The seven Progenitor Dragons, now worshipped as deities. |
| **Dragon-Heir** | Solis-Grave term for a Sovereign. |
| **Dual-Heartbeat** | A hidden Sovereign's bloodline destabilizing under stress. d20 check, 1-5 triggers. |
| **God-Forged** | 90%+ purity tier. Items at this tier are legendary. |
| **Inquisition** | The Citadel's enforcement arm. They register bloodlines, hunt hidden Sovereigns, and execute rogue casters. |
| **Old Tongue** | The language of dragons. Required verbal component for all spells. |
| **Ordained** | Solis-Grave term for a Cleric — a caster chosen by a Dragon-God. Tolerated by the Inquisition. |
| **Penitent** | Solis-Grave term for a Warlock — a caster who made a pact for borrowed power. Hated by the Inquisition. |
| **Progenitors** | The seven Ancient Dragons whose war created Solis-Grave. Their blood is in everyone. |
| **Sovereign** | A person with 50%+ blood purity. Can be a class (Dragon-Heir) or just a purity bracket. |
| **Sovereign Surge** | Class ability: +15% purity for 1 minute, 1/short rest. Visible to all. |
| **Spell Safety DC** | The check required to cast any spell without suffering Aether Burn. Formula: `8 + spell_level + (15 - purity/7)`. |
| **Wild Aether Surge** | d100 table of chaotic magical effects, triggered on a natural 1 Spell Safety save. |
| **Blanks** | 0% purity civilians. Cannot cast leveled spells. The majority of the population. |
| **Greenskin** | Derogatory term for goblins, orcs, and trolls. Legally non-persons. |

---

*"Your blood remembers the dragons. The question is: does it remember enough?"*

*— Inquisitor-General Veydris, Citadel Blood Registry*
