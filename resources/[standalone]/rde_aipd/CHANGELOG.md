# Changelog — rde_aipd

All notable changes to this project will be documented in this file.

---

## [1.0.6-alpha] — 2026-06-26

> 🔥 **Realism Overhaul Release.** Witness system rebuilt from scratch, cop despawn race conditions fixed, tackle rewritten with proper physics. Drop-in replacement — same config structure, same DB schema, same exports.

### 🩹 Fixed

#### FIX #51 — Cops remain on minimap after wanted level clears

`Police.ClearAllUnits()` started an async `CreateThread()` for blip removal. That thread ran on the *next* tick, not the current frame. In that one-tick gap, in-flight spawn calls could still add units with blips — those blips were never removed.

**Fix:** Blip removal and `ClearPedTasksImmediately()` now run **synchronously** before the `CreateThread()` departure sequence — same frame, no delay, guaranteed.

#### FIX #52 — Cops drive toward player instead of away after wanted clears

Departure target was `cache.coords + random_angle × 500`. A random angle has a 50% chance of having a component pointing toward the player. On bad seeds, the cop drove directly at the player.

**Fix:** Direction is now computed as the exact opposite vector from the player: `normalize(vehiclePos → playerPos) × -1 × 600`. Cops always leave in the correct direction.

#### FIX #53 — Race condition: spawned cop never despawns

**Scenario:** `Police.SpawnUnit()` runs in a thread with `Wait(100)` between spawns. If `ClearAllUnits()` fires during a `Wait()`, it clears `pursuingUnits = {}`. When the spawn resumes, the new cop is added to the now-empty list with no cleanup path — it stays in the world forever.

**Fix:** `policeGeneration` counter (integer, incremented on every `ClearAllUnits()` and `StartPoliceSystem()` call). `SpawnUnit()` checks the generation **after** spawning but **before** `table.insert`. If it doesn't match, the entities are immediately deleted. All three loops in `StartPoliceSystem()` bind to `myGen` and exit when the generation changes.

#### FIX #54 — No witnesses spawn / zero witness calls

`WitnessCanCall()` used `IsPedFleeing()` as a hard filter. GTA V sets *all* nearby NPCs to flee immediately when a crime event fires. By the time `GetNearbyWitnesses()` ran (even 100ms later), every NPC was already flagged as fleeing → zero candidates → zero 911 calls.

**Fix:** `IsPedFleeing()` removed from hard filter. Fleeing NPCs now receive a **50% phone chance penalty** instead (`effectiveChance = phoneChance * 0.5`). Hard filters are now only: dead/dying, ragdolling, active melee combat, severely injured (health < 50), vehicle speed > 80 km/h.

#### FIX #55 — FOV 180° too strict combined with flee behavior

After FIX #54, NPCs fleeing *away* from a crime have their back toward it. With FOV 180° (forward-vector cone), those NPCs fail the check because their forward vector points away from the crime coords. Combined with FIX #54 being unresolved, this was a secondary cause of zero witnesses.

**Fix:** FOV default changed to **240°** (NPCs only blind in a 120° cone directly behind them). Config key `Config.WitnessSystem.fieldOfView` — operators can tune lower for stricter setups.

#### FIX #56 — Proximity grace 5m too small

With the 5m grace, almost no NPC qualified for the "heard it regardless of FOV/LOS" bypass. Combined with 180° FOV this made outdoor crimes especially invisible to witnesses.

**Fix:** Grace distance default changed to **8m**. Config key `Config.WitnessSystem.proximityGraceDistance`.

---

### ✨ Added

#### Witness System v2.0

| Feature | Description |
|---|---|
| **Panic Phase** | Witnesses hesitate 1.5–3.5s before calling (configurable). Gives player a window to act. |
| **Intimidation** | Walking within 8m of a witness causes them to flee *without* calling 911. Works throughout the entire call sequence. |
| **Night Modifier** | Phone chance × 0.60 between 22:00–06:00 (configurable). Fewer people out at night. |
| **Combat Suppression** | Recent gunfire (< 5s) × 0.20 phone chance. Active firefight = witnesses dive for cover. |
| **Time-of-Day Modifier** | Evening (18:00–22:00) × 0.85. Full during daytime. |
| **MURDER no longer `force=true`** | Murder now requires a witness. A kill in an empty alley = no wanted level. MURDER_COP stays `force=true` (other cops are notified instantly). |
| **Reduced phone chance** | CITY_CENTER 0.90 → 0.60 · URBAN 0.85 → 0.50 · SUBURBAN 0.70 → 0.35 · RURAL 0.45 → 0.20 · WILDERNESS 0.15 → 0.06 |
| **Longer call window** | 3000–6000ms → 5000–9000ms. Player has more time to intervene. |
| **Fewer re-scans** | 2 re-scans @ 2500ms → 1 re-scan @ 4000ms. Not every crime gets noticed. |

#### Tackle System v2.0 — Physics-Based

Ported from the community forward-vector tackle reference implementation.

| Change | Detail |
|---|---|
| **Forward Vector** | Tackle direction = cop's `GetEntityForwardVector()` — same as the reference player tackle. Was previously cop→player direction vector which felt mechanical. |
| **Sprint windup** | Cop sprints 300ms toward player before impact (configurable). Visible approach before tackle. |
| **`ApplyForceToEntity`** | Momentum force applied to player ped matching the tackle direction. |
| **Cop ragdoll** | Cop falls forward briefly (1200ms default). Trained officer → recovers fast. |
| **Player ragdoll** | 3500–6000ms random. Player is down long enough for cop to attempt arrest. |
| **Auto-arrest** | Cop recovers → waits 200–600ms → calls `Police.AttemptArrest()` if player is still down. |
| **Multiplayer sound sync** | `police:syncTackleSound` server event broadcasts tackle sound to nearby clients (< 80m). |
| **Config** | All values in `Config.CopTackle` — cooldown, forces, durations, trigger distance. |

#### New Config Sections

- `Config.CopTackle` — full tackle tuning
- `Config.WitnessSystem.panicDelay` — panic hesitation range
- `Config.WitnessSystem.intimidationDistance` — flee trigger radius
- `Config.WitnessSystem.nightTimeModifier` + `nightHoursStart` / `nightHoursEnd`
- `Config.WitnessSystem.combatSuppression` + window + multiplier
- `Config.PoliceDisengage.departureSpeed` — cop departure speed (was hardcoded 25.0)

#### New Server Event

- `police:syncTackleSound` — broadcasts tackle sound to all clients within 80m of the tackled player

#### New Locale Keys

Added to `locales/en.lua` and `locales/de.lua`:

- `witness_intimidated` — shown when witness flees due to player proximity
- `witness_fled` — shown when witness flees during panic phase
- `wanted_decay_start` — shown when decay begins (no LOS)

---

### 🔧 Changed

- `Police.ClearAllUnits()` — synchronous blip/task cleanup before async thread; direction fix; timeout 25s → 15s; departure distance 200m → 250m
- `WantedSystem.StartPoliceSystem()` — all 3 loops now bound to `myGen` generation
- `Police.SpawnUnit()` — generation check before `table.insert`; siren+lights off immediately on `ClearAllUnits()`
- `police:applySyncedTackle` client handler — uses `Config.CopTackle` values instead of hardcoded 4000/5000ms

---

### ⚠️ Known Edge Cases (tracking for v1.0.7)

- NPCs inside buildings with complex streaming portals may occasionally fail LOS raycast even when visually nearby
- `TaskSmartFleePed` (intimidated witness) can occasionally navigate the witness back toward the player in dense urban areas
- NPC K.O. wakeup timing (from `rde_aimd`) sometimes conflicts with tackle ragdoll if both fire in the same frame
- Cop departure pathfinding may stall in parking garages (no road surface found → cop stands still until force-despawn at 15s)

---

## [1.0.5-alpha] — 2026-06-XX

Internal build — not released publicly.

---

## [1.0.1-alpha] — 2026-05-06

> 🚑 **Hotfix release.** 1.0.0-alpha had pre-existing Lua syntax errors and an admin-block regression.

### Fixed

| # | Fix |
|---|---|
| **#30** | 7 truncated `Debug(...)` calls — resource now loads on all servers |
| **#28** | Admin crime block now respects `Config.AdminSettings.exemptFromWanted` |
| **#29** | Removed redundant "Witness called 911" notification (was 3 notifs per crime, now 2) |
| **#27** | Locale loader added to all 4 client/server files — `ox:locale` now works everywhere |

### Added

New locale keys: `witness_spotted_you`, `no_witnesses_nearby`, `witness_killed_before_call`, `witness_killed_during_call`, `dragged_from_vehicle`, `arrest_cancelled`, `connection_issue`

---

## [1.0.0-alpha] — 2026-05-06

Initial public release.
