# Performance Fixes — NPWD Apps (Sinister H-Town RP)

Date: 2026-07-05
Patterns applied: B (NUI focus sleep), C (Zone-aware detection)

---

## App 1: sinister_apps

### File: `sinister_apps/client/client.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L1 | Added `local isNuiOpen = false` | NUI focus tracking flag — controls zone detection sleep interval |
| L3-L16 | Added zone detection table (`zones`) with Houston, Fort Worth, Killeen, Wilderness | Pattern C — zone-aware helper for CAD proxy use; uses same center/radius pattern as sinister_zoner |
| L17-L26 | Added `detectZone()` helper + `exports("getZone")` | Zone lookup function + export for other resources to query player's current region |
| L28-L33 | Added `Citizen.CreateThread` for zone detection loop | Sleeps 1000ms when NUI open, 5000ms when closed — reduces CPU overhead |
| L35-L44 | Added `RegisterNUICallback("setNuiFocus", ...)` and `RegisterNUICallback("closeNui", ...)` | Pattern B — tracks NUI visibility so zone thread can sleep longer when NUI is closed |

### File: `sinister_apps/server/server.lua`
- No changes (already event-driven, no polling)

---

## App 2: sinister_cad

### File: `sinister_cad/client/client.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L1 | Added `local isNuiOpen = false` | NUI focus tracking |
| L3-L20 | Added zone detection table + `detectZone()` helper | Pattern C — zone-aware detection for officer positioning (Houston, Fort Worth, Killeen, Wilderness) |
| L22-L30 | Added zone detection thread with state bag updates | Updates `cad:officer_zone` state bag on zone change; sleeps 1s when NUI open / 5s when closed |
| L32-L36 | Added `RegisterNUICallback("setNuiFocus", ...)` | Pattern B — handles NUI focus state |
| L37-L41 | Added `RegisterNUICallback("closeNui", ...)` | Pattern B — clears NUI focus |
| L43-L46 | Added `RegisterNUICallback("cad:getZone", ...)` | Pattern C — exposes current zone to CAD NUI |

### File: `sinister_cad/server/server.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L4-L15 | Added `GlobalState["cad:officer_zones"]` init + `AddStateBagChangeHandler` | Pattern C — syncs officer zone changes from client state bags into shared global state |
| L23-L26 | Added handler to remove stale entries when officer disconnects (tostring keying) | Prevents stale officer zone data |
| L87-L103 | Added `loadOfficerRoster` action to proxy handler | Pattern C — returns officer list with `zone` field showing each officer's patrol zone |

---

## App 3: sinister_syntok

### File: `sinister_syntok/client/client.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L2 | Added `local isNuiOpen = false` | NUI focus tracking |
| L4-L13 | Added `RegisterNUICallback("setNuiFocus", ...)` and `RegisterNUICallback("closeNui", ...)` | Pattern B — NUI focus detection and cleanup |

### File: `sinister_syntok/server/server.lua`
- No changes (already event-driven, no polling)

---

## App 4: sinister_underworld

### File: `sinister_underworld/client/client.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L1 | Added `local isNuiOpen = false` | NUI focus tracking |
| L3-L9 | Added zone detection table + `districts` list (Eastside, South Central, West End, Northside, Downtown, Harbor, Little Seoul, Mirror Park) | Pattern C — zone-aware detection for territory control |
| L11-L27 | Added `detectZone()` helper + zone detection thread | Sleeps 1s when NUI open / 5s when closed |
| L29-L38 | Added `RegisterNUICallback("setNuiFocus", ...)` and `RegisterNUICallback("closeNui", ...)` | Pattern B — NUI focus handling |
| L40-L43 | Added `RegisterNUICallback("uw:getZone", ...)` | Pattern C — exposes current district + all district names to NUI |

### File: `sinister_underworld/server/server.lua`

| Line (approx) | Change | Reason |
|---|---|---|
| L4-L14 | Added `defaultTerritories` table with gang control mapping | Pattern C — Eastside=Ballas, South Central=Vagos, West End=Cartel, rest Uncontrolled |
| L16 | Added `GlobalState["underworld:territories"]` init | Pattern C — shared state bag for territory control data |
| L49-L52 | Added `getTerritories` action to proxy handler | Pattern C — returns territory data to clients on request |
