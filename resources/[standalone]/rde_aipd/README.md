# rde_aipd

🔥 ULTIMATE AI POLICE SYSTEM V1.0.6-ALPHA - Built on ox_core & StateBags! 🚨

# 🐉 rde_aipd

[![Version](https://img.shields.io/badge/version-1.0.6--alpha-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_aipd)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](https://github.com/RedDragonElite/rde_aipd/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![ox_core](https://img.shields.io/badge/Framework-ox__core-blue?style=for-the-badge)](https://github.com/overextended/ox_core)
[![Nostr](https://img.shields.io/badge/Nostr-Decentralized-purple?style=for-the-badge)](https://github.com/RedDragonElite/rde_nostr_log)
[![Quality](https://img.shields.io/badge/Quality-Production-gold?style=for-the-badge)](https://github.com/RedDragonElite)

**🚨 RDE AIPD | Next-Gen AI Police & Crime System for FiveM ox_core | Ultra-Realistic | StateBag-Synced | Nostr-Logged | Production-Ready**

*Built by [Red Dragon Elite](https://rd-elite.com) | Free Forever | No Paywalls | No Legacy*

[📖 Installation](#-installation) • [⚙️ Configuration](#%EF%B8%8F-configuration) • [🌍 Locales](#-locales) • [🐉 Nostr Logging](#-nostr-logging) • [📡 Exports](#-exports) • [🐛 Troubleshooting](#-troubleshooting) • [🌐 Website](https://rd-elite.com) • [🔭 Terminal](https://rd-elite.com/Files/NOSTR/)

---

## 🚨 Update Notice — v1.0.6-ALPHA

> **v1.0.6-alpha is a significant realism overhaul** — drop-in replacement, same config structure, same DB schema, same exports. No migration needed.  
> Key highlights: complete witness system rewrite, cop despawn race condition fix, physics-based tackle. See [CHANGELOG.md](CHANGELOG.md) for full details.

---

## 🔥 Why This Destroys Every Other Police Script

Every other police script is either paid, ESX/QB-only, or a laggy mess with braindead AI.

We said no.

| ❌ Other Police Scripts | ✅ rde_aipd |
|---|---|
| Static wanted levels | Dynamic, decay-based wanted system |
| Dumb AI that just runs at you | True line-of-sight AI with threat assessment |
| Discord webhooks (deletable, bannable) | Decentralized Nostr logging — permanent & uncensorable |
| ESX / QBCore bloat | ox_core only — the future, not the past |
| 0.5ms+ idle resource usage | < 0.01ms idle — aggressive optimization |
| No locale support | Full EN / DE multilanguage |
| Paid or locked down | 100% free forever — RDE Black Flag |

### 🎯 Key Features

- 🤖 **True Line-of-Sight AI** — cops only react to what they can actually see
- 🧠 **Threat Assessment** — dynamic threat calculation per unit (weapons, speed, cover, escape history)
- 😮‍💨 **Player Fatigue** — sprint enough and you slow down; cops exploit that
- ⭐ **6 Wanted Levels** — from minor warrant to maximum response with helicopters & roadblocks
- 📉 **Realistic Decay** — wanted level drops only when no officer has eyes on you
- 🥊 **Physics Tackle** — cops physically tackle suspects with forward-vector momentum (v1.0.6)
- 🕵️ **Realistic Witness System** — panic phase, intimidation, night modifier, combat suppression (v1.0.6)
- 🚨 **Full Crime Detection** — 13+ crime types, area multipliers, time-of-day effects
- ⛓ **Prison System** — auto-jail, inventory save/restore, persistent state across reconnects
- 🐉 **Nostr Logging** — decentralized, cryptographically signed, uncensorable server logs
- 🌍 **Multilanguage** — EN / DE out of the box, add any language in minutes
- 🛡 **Server-Side Authority** — all sensitive actions validated server-side, statebag-synced
- ⚙️ **Zero-Config Start** — sensible defaults, tables auto-create, no SQL import needed

---

## 📸 Screenshots

PREVIEW: https://www.youtube.com/watch?v=mCWg0jZlSbY

> Drop a PR with your screenshots!

---

## 📦 Dependencies

```
oxmysql        → https://github.com/overextended/oxmysql
ox_lib         → https://github.com/overextended/ox_lib
ox_core        → https://github.com/overextended/ox_core
ox_inventory   → https://github.com/overextended/ox_inventory

optional:
rde_nostr_log  → https://github.com/RedDragonElite/rde_nostr_log
```

---

## 🚀 Installation

### Step 1: Clone or download

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_aipd.git
```

> **Already on a previous version?** Just `git pull` — no schema migration, no config changes needed. Restart the resource and you're done.

### Step 2: Add to server.cfg

```
# Dependencies first — order matters!
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_inventory

# Optional: Nostr logging (highly recommended)
ensure rde_nostr_log

# The AI police system
ensure rde_aipd
```

### Step 3: Configure

Edit `config.lua` — sensible defaults work out of the box. See [Configuration](#%EF%B8%8F-configuration).

### Step 4: Start your server

That's it. No SQL import needed — tables auto-create on first run.

---

## ⚙️ Configuration

`config.lua` is fully self-documented. Key sections:

```lua
-- Master debug toggle
Config.Debug = GetConvar('police_debug', 'false') == 'true'

-- Admin groups (exempt from wanted if configured)
Config.AdminGroups = { 'owner', 'admin', 'superadmin', 'god', 'mod' }

-- Police job names
Config.PoliceJobs = { 'police', 'sheriff', 'leo', 'trooper' }

-- Admin behavior
Config.AdminSettings = {
    exemptFromWanted = false,   -- Set true to make admins immune
    exemptFromArrest = false,
    exemptFromJail   = false,
    showAdminCrimes  = true,
}

-- Language (override with: set ox:locale "de")
Config.Locale = GetConvar('ox:locale', 'en')
```

### Witness System (v1.0.6)

```lua
Config.WitnessSystem = {
    fieldOfView            = 240.0,   -- NPC cone of vision (degrees)
    proximityGraceDistance = 8.0,     -- "Heard it" radius bypassing FOV+LOS
    delayedRescans         = 1,       -- Re-scans after no witness found
    delayedRescanInterval  = 4000,    -- ms between re-scans
    intimidationDistance   = 8.0,     -- Walk toward witness → they flee, no 911
    panicDelay             = { min=1500, max=3500 }, -- Hesitation before calling
    nightTimeModifier      = 0.60,    -- Phone chance multiplier at night
    combatSuppression      = true,    -- Active gunfire suppresses witness calls
    callDurationMin        = 5000,    -- Call window player can interrupt
    callDurationMax        = 9000,
}
```

### Tackle System (v1.0.6)

```lua
Config.CopTackle = {
    enabled            = true,
    sprintTime         = 300,    -- Sprint windup before impact (ms)
    playerRagdollMin   = 3500,   -- Player stays down this long (ms)
    playerRagdollMax   = 6000,
    copRagdollDuration = 1200,   -- Cop recovers faster (trained)
    tackleForce        = 8.0,    -- Impact force on player ped
    cooldown           = 12000,  -- Between tackles (ms)
    triggerDistance    = 4.5,    -- Max distance for tackle (m)
}
```

### Nostr Config

```lua
Config.Nostr = {
    enabled  = true,
    resource = 'rde_nostr_log',
    logLevel = {
        player_connect    = true,
        player_disconnect = true,
        player_wanted     = true,
        player_arrested   = true,
        player_jailed     = true,
        player_released   = true,
        crime_detected    = true,
        cop_killed        = true,
        admin_action      = true,
    }
}
```

---

## 🌍 Locales

All user-facing text lives in `locales/`. Default is English. Switch language:

```
# server.cfg
set ox:locale "de"
```

**Add a new language:**

1. Copy `locales/en.lua` → `locales/xx.lua`
2. Translate all values (keep the keys!)
3. Register it in `fxmanifest.lua` under `files {}`
4. Set `ox:locale "xx"` in your server.cfg

Currently supported:

| Code | Language |
|---|---|
| `en` | 🇬🇧 English |
| `de` | 🇩🇪 Deutsch |

---

## 🐉 Nostr Logging

rde_aipd ships with **first-class [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) integration**.

Every critical event is logged to the decentralized Nostr network — permanent, cryptographically signed, uncensorable. No Discord. No rate limits. No single point of failure.

### Events logged automatically

| Event | Nostr Tag | Toggle Key |
|---|---|---|
| Player joins | `player_connect` | `logLevel.player_connect` |
| Player leaves | `player_disconnect` | `logLevel.player_disconnect` |
| Wanted level change | `wanted_set` | `logLevel.player_wanted` |
| Wanted cleared | `wanted_cleared` | `logLevel.player_wanted` |
| Player arrested | `player_arrested` | `logLevel.player_arrested` |
| Player jailed | `player_jailed` | `logLevel.player_jailed` |
| Player released | `player_released` | `logLevel.player_released` |
| Crime committed | `crime_detected` | `logLevel.crime_detected` |
| Officer killed | `officer_down` | `logLevel.cop_killed` |
| Player surrenders | `player_surrendered` | `logLevel.player_arrested` |
| Player escapes | `player_escaped` | `logLevel.player_wanted` |
| Admin action | `admin_action` | `logLevel.admin_action` |

### Disable Nostr completely

```lua
Config.Nostr.enabled = false
```

Zero overhead. Zero side effects.

---

## 📡 Exports

### Client

```lua
-- Read state
exports['rde_aipd']:getWantedLevel()        -- number
exports['rde_aipd']:isArrested()            -- boolean
exports['rde_aipd']:isSurrendered()         -- boolean
exports['rde_aipd']:isJailed()              -- boolean
exports['rde_aipd']:getJailTime()           -- number (seconds)
exports['rde_aipd']:getPursuingUnits()      -- number
exports['rde_aipd']:copsCanSeePlayer()      -- boolean
exports['rde_aipd']:isDecayActive()         -- boolean
exports['rde_aipd']:getPlayerThreatLevel()  -- number (0-100)
exports['rde_aipd']:getPlayerFatigue()      -- number (0-100)

-- Actions
exports['rde_aipd']:setWantedLevel(3)
exports['rde_aipd']:surrender()
exports['rde_aipd']:clearPolice()

-- Crime system
exports['rde_aipd']:LogCrime('ROBBERY', coords, true)
exports['rde_aipd']:IsCrimeOnCooldown('MURDER')
exports['rde_aipd']:GetCurrentArea()
```

### Server

```lua
exports['rde_aipd']:nostrLog('Custom event message', {
    { 'event', 'my_custom_event' },
    { 'player', playerName }
}, 'crime_detected')
```

---

## 🗂 Folder Structure

```
rde_aipd/
├── fxmanifest.lua
├── config.lua
├── README.md
├── CHANGELOG.md
├── LICENSE
├── locales/
│   ├── en.lua
│   └── de.lua
├── server/
│   ├── main.lua
│   ├── crime_witness_handler.lua
│   └── nostr.lua
├── client/
│   ├── main.lua
│   └── crime.lua
└── html/
    ├── wanted_stars.html
    └── star*.png
```

---

## 🔧 Debug Commands

Enable with `set police_debug "true"` in server.cfg, then in-game:

| Command | Description |
|---|---|
| `debugpolice` | Dump full system state to console |
| `clearcops` | Despawn all pursuing units |
| `testwanted [1-5]` | Set wanted level instantly |
| `spawncop` | Spawn one test unit at current level |
| `testcrime [TYPE]` | Force-trigger a crime (bypasses cooldown) |
| `testwitness [TYPE]` | Force the full witness/911-call flow |
| `crimestatus` | Show current crime system state |
| `listcrimes` | List all registered crime types |
| `testjail [seconds]` | Jail yourself for testing |

---

## 🛡 Security

- All sensitive actions validated **server-side**
- StateBags used for realtime sync — no polling
- ox_core group checks on all privileged callbacks
- ACE permission support
- Nostr logs are cryptographically signed — tamper-proof by design
- `policeGeneration` counter prevents entity leaks from race conditions

---

## 🐛 Troubleshooting

### Cops don't leave the minimap after wanted clears

**Fixed in v1.0.6-alpha.** Was a race condition: blip removal happened in an async thread that ran one tick after `ClearAllUnits()`. Blips and tasks are now cleared synchronously in the same frame.

### Cops drive toward player after wanted clears

**Fixed in v1.0.6-alpha.** Departure direction was `cache.coords + random_angle × 500` — a random angle could point directly at the player. Now always computed as the exact opposite vector from the player.

### No witnesses / cops never spawn

1. Make sure you're on v1.0.6-alpha — older builds had a bug where `IsPedFleeing()` was used as a hard filter (GTA sets all nearby NPCs to flee on crime, so this guaranteed zero witnesses).
2. Set `Config.Debug = true` and run `testwitness ASSAULT` — watch the console for FOV/LOS rejection stats.
3. If playing as admin, check `Config.AdminSettings.exemptFromWanted` — if `true`, crimes are silently blocked.

### Cops spawn but some never despawn

**Fixed in v1.0.6-alpha** via `policeGeneration` counter. Cops spawned during an in-progress `ClearAllUnits()` call are now immediately deleted if the wanted level cleared mid-spawn.

### Tackle doesn't feel physical / no momentum

**Overhauled in v1.0.6-alpha.** Tackle now uses the cop's forward vector (`GetEntityForwardVector`) + `ApplyForceToEntity` like the community reference tackle implementation. Cop sprint animation before impact, short cop ragdoll (1.2s), longer player ragdoll (3.5-6s), auto-arrest attempt after cop recovers.

### `attempt to call a nil value` / resource fails to start

You're on 1.0.0-alpha. Update — that release shipped with truncated `Debug(...)` calls that broke Lua parsing. Fixed in 1.0.1-alpha.

### Nostr logger not connecting

```
[RDE | AIPD | Nostr] ✗ Resource "rde_nostr_log" not found
```

Install [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) and ensure it starts **before** rde_aipd. The system continues to work without it.

---

## 📚 Tech Stack

```
ox_core        → Player & group management
ox_lib         → UI, callbacks, notifications, locale loader
ox_inventory   → Inventory & weapon management
oxmysql        → Async database (auto-create tables)
StateBags      → Realtime player state sync
rde_nostr_log  → Decentralized logging (optional)
```

---

## 🤝 Contributing

PRs are always welcome.

1. **Fork** the repository
2. **Create** a branch: `git checkout -b feature/your-feature`
3. **Test** on a live server before submitting
4. **Commit**: `git commit -m 'feat: your feature description'`
5. **Push**: `git push origin feature/your-feature`
6. **Open** a Pull Request with a clear description

**Guidelines:**

- ✅ Keep the RDE header in all files
- ✅ Follow existing code style — ox_core, ox_lib, StateBags
- ✅ Run `luac -p` on every modified `.lua` file before pushing
- ✅ Test on a live server before PR
- ❌ No telemetry, no paywalls, no ESX/QBCore
- ❌ Don't downgrade security — server-side validation stays
- ❌ Don't hardcode user-facing strings — use `L('key')` and add to all locale files

---

## 📜 License

**RDE Black Flag Source License v6.66**

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_AIPD (NEXT-GEN AI POLICE & CRIME SYSTEM FOR FIVEM OX_CORE)    #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      Use it. Edit it. Break it. Fix it. That is the hacker way. Cost: 0.00€.    #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH                                                   #
#      Find this on a paid store? DMCA incoming. Public shaming on Nostr.         #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. Remove my name = you admit you have no skill.            #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:** ✅ Free forever · ✅ Keep the header · ❌ Don't sell it · ❌ Don't be a skid

---

## ⚡ Related Projects

| Resource | Description |
|---|---|
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | Decentralized FiveM logging via Nostr — replace Discord forever |
| [awesome-ox-rde](https://github.com/RedDragonElite/awesome-ox-rde) | Curated list of the best ox_core resources |

---

## 🌐 Community & Support

| | |
|---|---|
| 🌍 **Website** | [rd-elite.com](https://rd-elite.com) |
| 🔭 **Nostr Terminal** | [rd-elite.com/Files/NOSTR/Terminal](https://rd-elite.com/Files/NOSTR/Terminal/) |
| 🐙 **GitHub** | [github.com/RedDragonElite](https://github.com/RedDragonElite) |
| 🟣 **Nostr** | `npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94` |

---

**Made with 🔥 and pure criminal AI paranoia by [Red Dragon Elite](https://rd-elite.com)**

*The future is ours. We are already inside.*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

**RDE FOREVER. SYSTEM FAILURE. ⚡777⚡**

[![Website](https://img.shields.io/badge/Website-Visit-red?style=for-the-badge&logo=google-chrome)](https://rd-elite.com)
[![Nostr](https://img.shields.io/badge/Nostr-Follow-purple?style=for-the-badge&logo=rss)](https://primal.net/p/npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94)
[![Terminal](https://img.shields.io/badge/Terminal-Live-green?style=for-the-badge&logo=gnome-terminal)](https://rd-elite.com/Files/NOSTR/)
