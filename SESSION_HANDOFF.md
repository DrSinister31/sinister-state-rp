You are continuing development of **Sinister State TX** — a Texas-themed FiveM Grand Theft Auto V roleplay server running on the Qbox framework. Below is the complete state of the project, what's been built, what remains, and how everything connects.

---

## INFRASTRUCTURE

| Component | Location | Details |
|-----------|----------|---------|
| **FiveM Server** | Nodecraft | IP: 79.127.172.121:30120, FTP at same IP port 21 |
| **Qbox Framework** | `/servers/QboxProject_4826CC.base/` | 104 resources, txAdmin-managed |
| **Database (Qbox)** | MySQL at sqlm-us-chicago.nodecraft.com:3306 | np2_99ot_GBDr97P / np2_dprmBpX95fXv3MeVFg |
| **Supabase** | https://yqfzaugbrwoluhkddcsh.supabase.co | service_role key for all access |
| **Kronus Bot** | Railway (kronus service) | 4 sub-services (core/ai/economy/enforce) |
| **Discord** | Guild ID: 1383941224460713994 | 29 channels, bot token available in Railway env |
| **GitHub** | https://github.com/DrSinister31/sinister-state-rp | master branch |

## CREDENTIALS (Railway env vars)

All services use these env vars (set on Railway for kronus service):
```
SUPABASE_URL=https://yqfzaugbrwoluhkddcsh.supabase.co
SUPABASE_SERVICE_KEY=(use service_role key)
DISCORD_TOKEN=(bot token)
DISCORD_GUILD_ID=1383941224460713994
DEEPSEEK_API_KEY=(from platform.deepseek.com)
OWNER_ID=1370770707507708047
ADMIN_IDS=1370770707507708047
RCON_HOST=79.127.172.121
RCON_PORT=30120
RCON_PASSWORD=SinisterKronus16a8eaa0!
```

---

## WHAT'S BEEN BUILT

### Server (Nodecraft/FiveM/Qbox)

| Resource | Purpose |
|----------|---------|
| Full Qbox recipe | 104 resources — qbx_core, all ox_*, all qbx_*, NPWD phone, Renewed-Banking |
| `sinister_loadscreen` | Custom loading screen — full-bleed Texas flag SVG with brand colors. UPDATED: now uses logo.png (512x512 from Downloads/Gemini image). Lives at `resources/sinister_loadscreen/` |
| `synix_bridge` | Lua resource connecting Qbox ↔ Supabase. Polls rcon_commands every 2s, pushes player data on join. Lives at `resources/[standalone]/synix_bridge/` |
| `sinister_blips` | 36 Texas-themed map blips with proper FiveM sprite IDs. Lives at `resources/[standalone]/sinister_blips/` |
| `sinister_ai` | Ambient AI system — police (4-level SOP state machine), criminal dealers/boosters, civilian NPCs with identity state bags. Lives at `resources/[standalone]/sinister_ai/` |
| `sinister_apps` | Phone apps NUI — Business Banking (reads from Supabase), Texas Browser (server services with GPS), syntok (media clipper). Lives at `resources/[standalone]/sinister_apps/` |
| 17 free MLOs | Courthouse, Fire Station, Military Police, Laundromat, Motels, Clinic, Cigar Shop (x2), Fuel Station, PostOP, Medical Center, Hacker Space, Mansion, Real Estate, Vehicle Rentals, Park Ranger |
| 6 companion Qbox resources | qbx_helicam, qbx_dutyblips, qbx_evidence, qbx_lockpick, popcornrp_zancudoalert, distortionz_cad |
| 22 Texas jobs | All renamed in qbx_core/shared/jobs.lua — Houston PD, Ft. Worth Sheriff, Texas DPS, Texas EMS, Texas Fire & Rescue, FIB, Texas National Guard, ATC, plus FIB/Military/ATC/Fire job definitions ADDED |
| All config text | 5+ config files updated — police, ambulance, vehicleshop, medical, cityhall configs all renamed to Texas names |
| server.cfg | Clean 88-line config. 128 slots, OneSync Infinity on, Aurum license key, build 3258 (Qbox standard), qbx:acknowledge=true, all custom ensures |

### Kronus (Railway — 4 Python services in one container via start.sh)

**kronus_core/** — Discord bot (discord.py) with cogs:
- `assistant.py` — Deepseek-powered conversational AI with Texas personality (3 speech modes: City Texan/Rancher/H-Town), owner/admin recognition, chronicles awareness, channel awareness, unprompted quips (3% chance, max 10/day)
- `assistant_data.py` — Massive system prompt with full server knowledge, personality rules, channel map, posting rules
- `tickets.py` — Ticket system (/ticket, /ticketpanel), creates private channels, claim/close/delete
- `staff.py` — Staff commands (/warn, /strike, /ban, /announce)
- `channel_manager.py` — Creates faction categories on business creation
- `chronicles.py` — Publishes 30-point rubric events to #chronicles channel
- `rcon_bridge.py` — Queues RCON commands via Supabase rcon_commands table (bridge executes them)
- `role_sync.py` — Discord role ↔ job sync (framework ready)

**kronus_ai/** — Deepseek integration:
- `brain.py` — AsyncOpenAI client with token tracking (200 calls/day limit)
- `scorer.py` — 30-point rubric event scoring + AI courtroom (public defender RNG + jury deliberation)
- `self_learn.py` — Weekly economy audit via Deepseek

**kronus_economy/** — Economic engine (runs every 5 min):
- `processor.py` — Disparity check, bank audit (wealth brackets), market ticker (random events), delinquency checks (14-day flag), payroll, AI payroll at 1/3 rate, market ticker effects, delinquency takeovers
- `expenses.py` — Weekly business rent billing per business type
- `pnl.py` — Weekly P&L generation stored in business_pnl table
- `toggles.py` — Feature flag system with 5-min cache — 27 toggles in bot_config
- `ai_density.py` — AI population calculator: 0 players=100% density, 128=5%
- `ai_business.py` — AI business seeding: 10 auto-businesses when no player businesses exist
- `perks.py` — Wealth bracket perks (Lower class discounts, Upper class luxury tax)

**kronus_enforce/** — Enforcement:
- `auto_ban.py` — Strike auto-escalation (threshold from bot_config, default 3 strikes → ban)

### Supabase (25+ tables)

Key tables: discord_players, characters, player_economy, transactions, businesses (+bank_account column), business_employees (+is_ai, hourly_wage), criminal_records, warrants, mdt_reports, strikes, bans, kronus_logs, kronus_outcomes, kronus_policies, kronus_prompts, kronus_metrics, bot_config, rcon_commands, discord_channels, chronicle_entries, weazel_metrics, tebex_purchases, tickets, player_drug_xp, arms_dealer_stock, business_licenses, business_finances, business_inventory, business_expenses, business_pnl, business_ratings, warehouses, department_inventory, supply_orders, ai_worker_performance, order_bids, robbery_incidents, city_treasury, tax_transactions, city_budget_allocations

### Discord

29 channels in 7 categories: INFORMATION, COMMUNITY, EMERGENCY, SUPPORT, STAFF, KRONUS, VOICE. 14 roles. Admin-only locks on sensitive channels. Server icon set. 8 slash commands registered.

---

## WHAT'S BEEN DEPLOYED TONIGHT (Phase 0 — Lean Economy)

Code written and pushed to GitHub, Railway auto-deployed, Supabase tables created. Server needs restart.

---

## IMMEDIATE NEXT STEPS (You Do)

1. **Restart server** in txAdmin — applies all new resources + config changes
2. **Connect** — F8 → connect 79.127.172.121:30120
3. **Create a character** — this triggers bridge data flow to Supabase
4. **Check Discord** — test @Kronus, /ask, /ping
5. After login, check `http://79.127.172.121:30120/info.json` for player count

---

## MASTER BUILD PLAN (6 Phases Remaining)

### ✅ Phase 0 — Lean Economy (DONE TONIGHT)
Business bank accounts, market ticker effects, weekly expenses, P&L reports, delinquency takeovers, wealth bracket perks, feature toggles, AI density calculator, AI business seeding. ~15 new Python modules, ~17 new Supabase tables.

### 🔲 Phase 1 — Business + Tax (~1.5 hrs)
Dual naming (police vs street names), income/business/sales tax collection, city budget allocation, weekly tax report to Discord.

### 🔲 Phase 2 — Criminal Economy (~2 hrs)
Drug reputation system (5 tiers, XP), arms dealer rotation, chop shop payouts, criminal front masking, smuggler runs, forgery system, gang territory.

### 🔲 Phase 3 — Ambient AI (~3 hrs)  
Full AI police SOP (4-level), AI EMS/Fire response, AI criminal behaviors, civilian density controller, identity markers, business AI workers. NOTE: `sinister_ai` resource is PARTIALLY WRITTEN — identity.lua, police_ai.lua (4 SOP levels defined), criminal_ai.lua (dealer/booster spawn), civilian_ai.lua (9 model types). Server-side spawn logic works. Client-side state bag listener is a stub.

### 🔲 Phase 4 — Mission System (~3 hrs)
Police/EMS dispatch missions, trucking cargo tiers + logistics marketplace, criminal missions, dynamic world events (18+ types), 30-point rubric scoring (partially built in scorer.py).

### 🔲 Phase 5 — Government (~2 hrs)
City budget allocation, mayor elections, mayor powers, public works, corruption detection, insurance pool for robbery replacement.

### 🔲 Phase 6 — Housing & RP (~2 hrs)
qbx_properties MLO integration, marriage system, license system, insurance, will/inheritance, civilian events.

---

## KEY DESIGN DECISIONS

1. **All money flows through Kronus Federal Reserve** — no direct player-to-player payments. Every transaction gets split (tax, insurance, business cut, driver pay, profit).

2. **AI density is inverse to player count** — 0 players = 100% AI (city feels alive), 128 players = 5% AI. Formula: density = max(0.05, 1.0 - (players/128)).

3. **Feature toggles gate everything** — 27 toggles in bot_config. All future features default to `false`. Flip to `true` to enable. Kronus checks every 5 minutes.

4. **Service role only** — Supabase RLS is `FOR ALL TO service_role`. No user JWTs. Bridge and Kronus both use service_key.

5. **Deepseek API** is used ONLY for: weekly economy audits, crisis narration (score 23+), conversational responses to @Kronus mentions. Everything else is rule-based to keep costs low.

6. **Texas theme** — Houston=Los Santos, Ft. Worth=Paleto Bay, Killeen=Sandy Shores. All text, blips, job names, MLO labels reflect this.

7. **File locations on FiveM server** — All custom resources go in `resources/[standalone]/`. Use FTP to upload. Add `ensure [name]` to server.cfg. Restart in txAdmin.

---

## FILE STRUCTURE (GitHub root)

```
Kronus/
├── shared/              # Supabase client, config, Redis, Pydantic schemas
├── kronus_core/         # Discord bot (8 cogs)
├── kronus_ai/           # Deepseek integration
├── kronus_economy/      # Economic engine (8 modules)
├── kronus_enforce/      # Strike/ban enforcement
├── database/            # All SQL files (schema, phase0, criminal_economy)
├── requirements.txt     # Root Python dependencies
└── .env.example         # Template env vars

sinister_loadscreen/     # Custom loading screen (HTML/CSS/JS + SVG logo)
sinister_blips/          # 36 Texas map blips (Lua)
sinister_ai/             # Ambient AI (Lua — identity, police, criminal, civilian)
sinister_apps/           # Phone apps NUI (banking, browser, syntok)
synix_bridge/            # Qbox ↔ Supabase bridge (Lua)

requirements.txt         # Root dependencies for Railway
start.sh                 # Railway startup (launches all 4 Kronus processes)
railway.toml             # Railway single-service config
```

---

## WHEN UPLOADING TO THE FIVEM SERVER

1. FTP: host 79.127.172.121, port 21, user FEN8gHlIbozd1X (pw in env)
2. Upload to: `/servers/QboxProject_4826CC.base/resources/[standalone]/`
3. Edit server.cfg at `/servers/QboxProject_4826CC.base/server.cfg` — add `ensure [resource_name]`
4. Restart in txAdmin

---

## WHAT KRONUS CAN DO (Texas Personality Bot)

- Responds to @Kronus mentions, "kronus" keyword, questions in #general-chat
- 3 speech modes: City Texan (default), Rancher (country), H-Town (street) — adapts to user's speech
- Reads chronicle_entries for player event history and world timeline
- Knows all 20+ Discord channels and posting rules
- Detects new channels, logs them
- Random unprompted quips (3% chance, max 10/day, ~$0.0008 cost)
- Recognizes drsinister31 as sole owner/creator
- Recognizes admins by Discord roles
- Has foul-mouthed, witty, sarcastic Texas personality
- 8 slash commands: /ask, /ping, /ticket, /ticketpanel, /warn, /strike, /ban, /announce

## CURRENT STATE SUMMARY

The server is ready but needs a RESTART in txAdmin to apply all the new resources uploaded tonight. After restart:
- 104+ resources load (base Qbox + sinister_* resources)
- Kronus runs on Railway (4 services, all online)
- Supabase has all Phase 0 tables
- Economy engine starts processing (AI density, payroll, expenses, P&L)
- AI business seeding fires (creates 10 placeholder businesses if none exist)
- Discord bot connects, auto-configures, syncs slash commands
- Players can connect: F8 → connect 79.127.172.121:30120
