# Solis-Grave Magic System — Formal Rules

## Core Principle

All magic in Solis-Grave originates from **draconic bloodlines**. There is no divine/arcane/nature/primal distinction. A spell's power, risk, and accessibility are determined solely by the caster's **Blood Purity** (0-100%).

## Blood Purity Brackets

| Bracket | % Range | Title | Max Spell Level (Soft) | Max Spell Level (Hard Gate) |
|---------|:-------:|-------|:----------------------:|:---------------------------:|
| Blank | 0% | Mundane | Cantrips only | 0 |
| Tainted | 1-10% | Touched | 1st | 2nd |
| Lesser Blood | 11-25% | Scion | 3rd | 5th |
| Half-Sovereign | 26-49% | Heir | 4th | 5th |
| Sovereign | 50-74% | Lord/Lady | 6th | 7th |
| Greater Sovereign | 75-89% | Archon | 8th | 8th |
| Dragon-Lord | 90-99% | Ascendant | 9th | 9th |
| Pure Dragon | 100% | God-Forged | 9th (no DC) | None |

## Spell Safety DC

When casting a spell of any level, the caster must make a **Spell Safety saving throw** using their spellcasting ability modifier.

```
Spell Safety DC = 8 + spell_level + purity_penalty
purity_penalty = floor(15 - (purity / 7))
```

| Purity | Cantrip DC | 1st DC | 2nd DC | 3rd DC | 4th DC | 5th DC | 6th DC | 7th DC | 8th DC | 9th DC |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 0% | 23 | — | — | — | — | — | — | — | — | — |
| 10% | 21 | 22 | 23 | — | — | — | — | — | — | — |
| 25% | 19 | 20 | 21 | 22 | 23 | — | — | — | — | — |
| 50% | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | — | — |
| 75% | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 |
| 90% | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 |
| 100% | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass | Auto-pass |

**Save Roll:** `d20 + spellcasting_ability_modifier`

**Success:** Spell casts normally.

**Failure:** Spell fizzles (slot is expended, no effect). Caster suffers **Aether Burn**.

**Critical Failure (Natural 1):** Spell fizzles. Caster suffers **Double Aether Burn** and rolls on the **Wild Aether Surge Table**.

## Aether Burn

```
Aether Burn Damage = (spell_level + 1)d6 psychic damage
```

| Spell Level | Burn (normal) | Burn (crit fail) |
|:-----------:|:------------:|:----------------:|
| Cantrip | 1d6 | 2d6 |
| 1st | 2d6 | 4d6 |
| 2nd | 3d6 | 6d6 |
| 3rd | 4d6 | 8d6 |
| 4th | 5d6 | 10d6 |
| 5th | 6d6 | 12d6 |
| 6th | 7d6 | 14d6 |
| 7th | 8d6 | 16d6 |
| 8th | 9d6 | 18d6 |
| 9th | 10d6 | 20d6 |

Aether Burn is **psychic damage** that cannot be reduced by resistance (it targets the soul, not the mind). It manifests as searing pain along the caster's veins, visible as glowing cracks in their skin.

## Hybrid Purity Gating

| Gate Type | Applies To | Rule |
|-----------|-----------|------|
| **Free** | Cantrips | Any purity can cast. Normal Spell Safety DC applies. |
| **Soft Gate** | 1st-5th level | Caster must meet minimum purity OR succeed on Spell Safety save. Below minimum purity: Spell Safety DC +5 penalty. |
| **Hard Gate** | 6th-7th level | 50% purity absolute minimum. Cannot cast below this regardless of saves. |
| **Hard Gate** | 8th level | 75% purity absolute minimum. |
| **Hard Gate** | 9th level | 75% purity absolute minimum. |
| **Perfect Cast** | All levels | 100% purity: Spell Safety saves auto-succeed. Immune to Aether Burn. |

## Spell Components

All spells require three components, reflavored for Solis-Grave:

| Component | Solis-Grave Name | Description |
|-----------|-----------------|-------------|
| **V** | Draconic Words | Spoken syllables of the Old Tongue, the language of dragons. Volume and pronunciation matter — whispers for subtle spells, roars for evocations. |
| **S** | Bloodline Sigils | Hand gestures tracing the caster's bloodline crest in the air. Each bloodline has a unique sigil. Wrong sigil = auto-fail. |
| **M** | Aether-Core | Harvested from slain creatures. Replaces ALL standard D&D material components. Core must match spell's element or be Wild (universal). |

### Aether-Core Tiers by Spell Level

| Spell Level | Core Required | Core Element | Cost (GC) |
|:-----------:|:------------:|:------------:|:---------:|
| Cantrip | Fractured | Any matching | 5-25 |
| 1st-2nd | Fractured | Matching element | 25-50 |
| 3rd-5th | Intact | Matching element | 50-500 |
| 6th-7th | Pristine | Matching element | 500-5,000 |
| 8th-9th | Sovereign-Fragment | Matching element | 5,000-50,000 |

**Matching element reduces Spell Safety DC by 1.** Wild cores work for any element but offer no DC reduction.

**Core Consumption:** Aether-Cores are NOT consumed on successful casting. They are consumed only on a **failed Spell Safety save** (the core shatters, absorbing the backlash that would have killed the caster). This is why casters carry multiple cores.

Without a core: spell cannot be cast. Period.

## Purity Modifiers (Situational)

| Situation | Purity Modifier | Duration |
|-----------|:---------------:|----------|
| Sovereign Surge (hidden bloodline revealed) | +15% | 1 minute |
| Dormancy Penalty (hiding bloodline) | -20% | Permanent while suppressed |
| Inquisitor Proximity (within 60ft of an active Inquisitor) | -10% | While in range |
| Dragon-Touched Location (ley lines, dragon graves) | +10% | While in area |
| Aether Storm (wild magic weather) | -15% | Duration of storm |
| Blood Offering (willing creature's blood, 1d4 damage per +5%) | +5% per 1d4 | 1 round |
| God-Shroud Armor (attuned) | Resets to 90% | While worn |

## Wild Aether Surge Table (d100)

Roll when a caster rolls a natural 1 on a Spell Safety save:

| d100 | Effect |
|:----:|--------|
| 1-5 | Caster's bloodline temporarily inverts — all spells deal damage to caster instead for 1 minute |
| 6-10 | Caster polymorphs into a random CR 0 beast for 1d4 rounds |
| 11-15 | A wave of force erupts — all creatures within 30ft make DC 15 STR save or be pushed 20ft |
| 16-20 | Caster's voice becomes draconic — cannot speak Common for 1 hour. Spells auto-fail without verbal components |
| 21-25 | Aether feedback — caster takes an additional 2d6 psychic damage and is stunned for 1 round |
| 26-30 | Spell rebounds — target becomes caster (if offensive) or caster becomes target (if buff) |
| 31-35 | Wild magic zone 30ft radius for 1 minute — all casters in zone have Spell Safety DC +3 |
| 36-40 | Caster's bloodline sigil burns into the ground — visible to all Inquisitors within 1 mile for 24 hours |
| 41-45 | Gravity reverses for caster — they float 20ft up and hang there for 1d4 rounds |
| 46-50 | Spell effect doubles (damage dice ×2, duration ×2, range ×2) but caster is blinded for the duration |
| 51-55 | Caster ages 1d10 years. No mechanical effect but Inquisitors notice "bloodline maturity" |
| 56-60 | A spectral dragon head manifests and roars — all creatures within 60ft make WIS save or be frightened for 1 minute |
| 61-65 | Caster's blood purity temporarily drops by 20% for 1 hour |
| 66-70 | Spell slot is NOT expended (rare mercy — the Aether-Core absorbed the backlash) |
| 71-75 | Caster and target swap positions via teleportation |
| 76-80 | Nearest Aether-Core in caster's possession shatters harmlessly — no other effect |
| 81-85 | Caster's eyes glow with draconic fire — 30ft cone of dim light for 1 hour. Inquisitors auto-detect within 100ft |
| 86-90 | Spell changes target randomly (DM chooses nearest valid target) |
| 91-95 | Caster gains temporary +10% purity for 1 minute but takes 2d6 psychic damage |
| 96-99 | Nothing happens. The Aether chose mercy. |
| 100 | **Dragon Apotheosis Moment** — caster's bloodline fully awakens for 1 round. Spell Auto-Succeeds. Spell Safety DC becomes 0. No Aether Burn. After: gain +5% permanent purity. One use per character EVER. |

## Ritual Casting

Ritual casting DOES NOT require a Spell Safety save OR consume an Aether-Core. The extended casting time (10+ minutes) allows the caster to carefully channel the magic, bypassing the normal risks. Rituals still require the minimum purity soft gate but at -5 to the requirement.

## Concentration

When a concentrating caster takes Aether Burn, they must make an additional **Concentration save** at DC 10 or half the burn damage (whichever is higher), in addition to any other concentration triggers that round.

## Aether Burn Risk Tags

Every spell is tagged with one of:
- **None** — Cantrips and ritual-only spells
- **Low** — Defensive, utility, divination spells
- **Moderate** — Most combat spells
- **Severe** — High-damage evocations, necromancy, conjuration of extraplanar entities
- **Catastrophic** — 9th level spells, bloodline manipulation, resurrection, wish-like effects

This tag modifies the Spell Safety DC by +0 (None) to +5 (Catastrophic) on top of the base formula.
