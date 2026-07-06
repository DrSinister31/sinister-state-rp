# Sinister H-Town RP — Gang, Territory & Criminal Economy Guide

## GANG SYSTEM

### Creating a Gang
1. Gang creation is **admin-only**. Submit a request in Discord #tickets.
2. Requirements: 3+ members minimum, gang name, gang colors, territory preference.
3. Admin creates the gang via EasyAdmin (/gang create [name]).
4. Gang leader gets boss permissions for armory, garage, and bank.

### Gang Ranks
| Rank | Level | Permissions |
|------|-------|-------------|
| Leader | 4 (Boss) | Armory, garage, bank, invite/kick, promote/demote |
| Enforcer | 3 | Armory, garage, invite |
| Soldier | 2 | Armory access |
| Prospect | 1 | Gang chat access |
| Initiate | 0 | Basic membership |

### Gang Commands
- /gang invite [ID] — Invite player to gang
- /gang kick [ID] — Remove member
- /gang promote [ID] — Promote rank
- /gang demote [ID] — Demote rank
- /gangchat [message] — Gang-only chat
- /gang info — View gang stats
- /gang members — List all members
- /gang deposit [amount] — Deposit to gang bank
- /gang withdraw [amount] — Withdraw from gang bank (boss only)

### Gang Bank
Each gang has a shared bank account accessible via the boss menu.
All gang income (territory, drug sales, missions) flows here.
Gang leader distributes payments to members.

---

## TERRITORY SYSTEM

### How Territory Works
Territories are geographic zones controlled by gangs via `sinister_crime`.
Each territory generates passive income based on control percentage.

### Territory Types
| Zone | Area | Income Type |
|------|------|-------------|
| Third Ward | Davis/Strawberry | Drug sales, protection |
| Montrose | Vinewood | High-end crime, jewelry |
| Sunnyside | South LS | Drug spots, weapons |
| Killeen | Sandy Shores | Drug labs, oil theft |
| Bayou | Marshlands | Smuggling, dumping |
| Docks | Port area | Cargo theft, shipping |
| Ft. Worth | Paleto Bay | Rural crime, logging theft |

### Gaining Territory
1. **Eliminate rival gang members** in the contested zone (30-min cooldown per kill)
2. **Complete territory missions** — street deals, drive-bys, tags
3. **Hold territory** — maintain presence (no rival activity for 24+ hours gains points)
4. **Drug spot ownership** — owning multiple spots in a zone increases control
5. Territory updates every hour via Kronus economy cycle

### Losing Territory
1. Being killed by rival gangs in your territory
2. 48+ hours of no gang activity in the zone
3. Police raids on your drug spots
4. Losing drug spot ownership

### Territory Benefits
- Passive income from territory (deposited to gang bank hourly)
- Tax-free drug sales in owned territory
- NPC crew spawns in your territory
- Territory blip shows your gang color on the map
- Territory name shows gang tag when players enter the zone

---

## CRIMINAL ECONOMY

### Drug System (sinister_crime + WZ Methlab + NEX Crafting)
| Drug | Production | Sell Price | Risk Level |
|------|-----------|------------|------------|
| Weed | Grow at drug spots | $200-500/brick | Low |
| Meth | WZ Methlab RV cook | $800-1500/batch | High |
| Crack | NEX Crafting Third Ward Cook | $500-900/rock | Medium |
| Coke | Airdrops only (rare) | $2000-5000/kg | Very High |
| Bluebonnet Batch | Meth + weed concentrate | $1500-3000 | High |
| Hill Country Shine | Moonshine | $300-600 | Low |
| Bayou Blend | Weed concentrate | $800-1200 | Medium |

### Selling Drugs
1. Find an active drug spot via /drugspots
2. Spots cycle every 2 hours (random locations)
3. AI buyers spawn near spots
4. Sell to AI buyer: interact with NPC, choose quantity
5. Payment: dirty_money (must launder through businesses)

### Money Laundering
Dirty money can be cleaned through:
1. **Player-owned businesses** — deposit dirty money, withdraw clean at reduced rate (80%)
2. **Texas Suds Car Wash** — run washes, dirty money comes out clean
3. **Lone Star Logistics** — trucking payments clean dirty money
4. **Galveston Bay Oyster House** — restaurant businesses clean 85%
5. Laundering cooldown: 30 minutes per transaction

### Drug Labs
- **WZ Methlab RV** — Mobile meth lab (Journey RV). 3-stage cook. Can explode on failure.
- **NEX Crafting Stations** — Hill Country Still (Killeen), Third Ward Lab (Davis), Lone Star Forge (Docks)
- **Weed Grow** — Plant weed at owned drug spots. Harvest every 2 hours.

### Drug Spot Ownership
1. Find unclaimed drug spot (map blip)
2. Hold the spot for 5 minutes without being killed
3. Claim the spot via interaction menu
4. Plant weed or set up lab equipment
5. Spots generate passive income every hour
6. Max 3 spots per player, 5 per gang

---

## ROBBERIES & HEISTS

### Robbery Types (sinister_robberies)
| Type | Location | Reward | Heat Cooldown |
|------|----------|--------|---------------|
| Liquor Store | Various | $500-1500 cash | 15 min |
| Bayou Dock Theft | Docks area | $1000-3000 goods | 20 min |
| Gas Station | Killeen | $300-800 cash | 10 min |
| Jewelry Heist | Montrose | $5000-15000 jewels | 45 min |
| Bank Job | Ft. Worth | $20000-50000 | 2 hours |

### Truck Heist (sinister_hijacking + Truck Heist)
1. Armored Gruppe Sechs trucks spawn randomly on highways
2. Ambush truck — disable it, eliminate armed guards
3. Blow open the back — collect loot
4. Loot: dirty_money ($5000-15000), weapons, armor
5. Police alert: automatic high-priority dispatch

### Airdrops (sinister_airdrops)
1. Flare drops at random coordinates trigger airdrops
2. Plane flies overhead, drops parachute crate
3. Timed opening creates combat zone
4. Loot tiers: Common (80%), Uncommon (15%), Rare (5%)
5. Kamikaze Crop Duster: 1% chance pilot dives plane at caller
6. Cooldown: 30 minutes per zone

---

## CRIMINAL PROGRESSION

### Reputation System
Your criminal reputation (sinister_underworld) tracks:
- Successful heists
- Drug sales volume
- Territory control contribution
- PvP kills in gang wars
- Time without arrest

### Underworld Tiers
| Tier | Requirements | Perks |
|------|-------------|-------|
| Street Rat | Default | Basic drug deals |
| Hustler | 100 rep | Unlock advanced crafting |
| Enforcer | 500 rep | Territory claiming, gang armory |
| Kingpin | 2000 rep | All drug routes, max territory income |
| Legend | 5000 rep | Global respect, NPC crew spawns |

---

## STREET RACING (sinister_racing)

### H-Town Midnight Runs
1. Talk to race organizer NPC at Vinewood dealer spot
2. Wager dirty_money on races
3. 5 routes: Galveston Drag, Killeen Dust Sprint, Third Ward Circuit, Ft. Worth Mountain Pass, Bayou Backroads
4. Muscle cars only (class 6)
5. Reputation-gated routes (higher rep = more routes)
6. Commands: /joinrace [ID], /leaverace, /startrace, /raceleaderboard

---

## BAYOU GRAVE DIGGIN' (sinister_graverob)

1. Visit NPC at Paleto cemetery (Ft. Worth)
2. Receive shovel and grave locations
3. Dig graves at night for better loot
4. Loot: jewelry, watches, lockpicks, dirty_money
5. Police alert: 35% chance per grave, multi-dig alert at 3+ graves
6. Special loot: advancedlockpick (8% bonus roll)
