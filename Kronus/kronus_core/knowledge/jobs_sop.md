# Sinister H-Town RP — Job SOPs & Commands

## LAW ENFORCEMENT

### Houston PD (job: police)
**Type:** LEO | **Grades:** Recruit → Officer → Sergeant → Lieutenant → Chief
**Duty Location:** Houston Police HQ (Legion Square area)
**Vehicles:** Police Cruiser, Police SUV, Police Bike, Police Helicopter
**SOPs:**
1. Clock in at any police station using /clockin or the duty menu
2. Respond to 911 calls and dispatch alerts from ps-dispatch
3. Conduct traffic stops — use LGD PoliceRadar for speed/plate scanning
4. File incident reports via /mdt (ps-mdt) or /uofreport for use-of-force
5. Use Spike Strips (/hpd_spike_strip) for vehicle pursuits
6. Coordinate with Texas DPS for highway patrol, Ft. Worth Sheriff for county
7. Evidence collection: use Evidence Forensic for shells/blood/fingerprints
8. Arrest processing: /jail [ID] [time] — book suspects into MDT
**Commands:** /clockin, /mdt, /uofreport, /911, /jail, /fine, /seize, /cuff

### Ft. Worth Sheriff (job: bcso)
**Type:** LEO | **Grades:** Recruit → Officer → Sergeant → Lieutenant → Chief
**Duty Location:** Ft. Worth Sheriff Station (Paleto Bay)
**SOPs:** Same as Houston PD — jurisdiction covers Paleto Bay and Blaine County
**Commands:** Same as Houston PD

### Texas DPS (job: sasp)
**Type:** LEO | **Grades:** Recruit → Officer → Sergeant → Lieutenant → Chief
**Duty Location:** DPS Barracks (Sandy Shores / highway stations)
**SOPs:**
1. Primary jurisdiction: highways and state roads
2. Speed enforcement using PoliceRadar
3. Commercial vehicle inspections (truckers)
4. Assist HPD and Sheriff as needed
5. Coordinate aerial surveillance with sinister_airspace
**Commands:** Same as Houston PD + /inspect (commercial vehicle)

### FIB (job: fib)
**Type:** LEO | **Grades:** Agent → Senior Agent → Supervisory Agent → Assistant Director → Director
**Duty Location:** FIB Building (Downtown)
**SOPs:**
1. Handle federal crimes: bank robbery, hijacking, organized crime
2. Access to all evidence databases via /mdt
3. Coordinate with all LE agencies for multi-jurisdiction operations
4. Can authorize lethal force in hostage/terror situations
**Commands:** Same as Houston PD + /federal [ID]

### Texas National Guard (job: military)
**Type:** LEO | **Grades:** Private → Corporal → Sergeant → Lieutenant → Colonel
**Duty Location:** Fort Zancudo
**SOPs:**
1. Base security at Fort Zancudo
2. Respond to Priority 5 (maximum threat) alerts
3. Airspace violations — coordinate with sinister_airspace and ATC
4. Martial law scenarios only
**Commands:** /clockin, /mdt

---

## EMERGENCY SERVICES

### Texas EMS (job: ambulance)
**Type:** EMS | **Grades:** Recruit → Paramedic → Doctor → Surgeon → Chief
**Duty Location:** Houston Medical Center / Ft. Worth Clinic / Sandy Shores Medical
**SOPs:**
1. Respond to medical emergencies via /911 dispatch
2. Use /revive on downed players (must be at patient's location)
3. Transport critically injured to hospitals
4. Hospital check-in system at Pillbox and Paleto locations
5. Armory: bandage, painkillers, firstaid, defibrillator, flashlight
**Commands:** /clockin, /revive, /checkin (to take patients to hospital)

### Texas Fire & Rescue (job: fire)
**Type:** EMS | **Grades:** Probationary → Firefighter → Lieutenant → Captain → Chief
**Duty Location:** Fire stations across Houston and Ft. Worth
**SOPs:**
1. Respond to fire emergencies
2. Vehicle extrication — extract players from wrecked vehicles
3. Search and rescue operations
4. Hazmat scenarios
**Commands:** /clockin, /extract

---

## GOVERNMENT & LEGAL

### Texas DOJ (job: judge)
**Type:** DOJ | **Grades:** Clerk → Paralegal → Prosecutor → Magistrate Judge → District Judge
**Duty Location:** Courthouse (Houston)
**SOPs:**
1. Process warrant requests via /mdt
2. Preside over court hearings
3. Issue search warrants and arrest warrants
4. Set bail amounts
5. Review evidence for trial
**Commands:** /mdt, /docket, /warrant [ID], /bail [ID] [amount]

### Texas Bar Association (job: lawyer)
**Type:** Legal | **Grades:** Associate → Attorney → Senior Counsel → Partner → Managing Partner
**Duty Location:** Courthouse / Law Office
**SOPs:**
1. Provide legal representation to arrested suspects
2. File motions via /mdt
3. Negotiate plea deals with prosecutors
4. Review evidence for clients
**Commands:** /mdt, /defend [ID]

### Texas Press Corps (job: reporter)
**Type:** Media | **Grades:** Journalist
**SOPs:**
1. Report on events happening in the city
2. Interview players
3. Publish news stories (via /weazel or chronicles)
4. Maintain press credentials — show badge to LEO upon request
5. Do NOT interfere with active crime scenes or police operations
**Commands:** /reporting, /microphone

---

## CIVILIAN JOBS

### Texas Real Estate (job: realestate)
**Type:** Real Estate | **Grades:** Recruit → House Sales → Business Sales → Broker → Manager
**Duty Location:** Real Estate Office
**SOPs:**
1. Sell houses and businesses to players
2. Process property purchases via sinister_realtor system
3. Show properties to prospective buyers
4. Handle rental agreements
**Commands:** /realtor, /showhouse [ID], /sellproperty [ID]

### Texas Yellow Cab (job: taxi)
**Type:** Civilian | **Grades:** Recruit → Driver → Event Driver → Sales → Manager
**Duty Location:** Taxi Depot
**SOPs:**
1. Pick up passengers — respond to /taxi requests
2. Drive safely — obey traffic laws
3. Fare collection is automatic via Qbox system
4. RD Taxi AI handles overflow when no drivers online
**Commands:** /taxi, /fare [amount]

### Texas Transit (job: bus)
**Type:** Civilian | **Grades:** Driver
**Duty Location:** Bus Depot
**SOPs:**
1. Drive posted bus routes through the city
2. Pick up passengers at bus stops
3. Obey all traffic laws
**Commands:** /busroute

### Lone Star Motors (job: cardealer)
**Type:** Civilian | **Grades:** Recruit → Showroom Sales → Business Sales → Finance → Manager
**Duty Location:** Vehicle Dealership
**SOPs:**
1. Sell vehicles to players via qbx_vehicleshop
2. Process vehicle financing
3. Showcase vehicles for test drives
4. Manage vehicle inventory
**Commands:** /cardealer, /testdrive [vehicle]

### Texas Auto Repair (job: mechanic)
**Type:** Mechanic | **Grades:** Recruit → Novice → Experienced → Advanced → Manager
**Duty Location:** H-Town Auto Shop (Mirror Park)
**SOPs:**
1. Repair player vehicles — use /repair at shop
2. Install vehicle modifications
3. Tow broken-down vehicles (coordinate with Lone Star Towing)
4. Use manual engine control for diagnostics (/sinister_engine toggle)
**Commands:** /repair, /mod, /tow

### Lone Star Towing (job: tow)
**Type:** Civilian | **Grades:** Driver
**Duty Location:** Tow Yard
**SOPs:**
1. Respond to /tow requests
2. Impound illegally parked vehicles
3. Assist police with vehicle removal
**Commands:** /tow, /impound

### Lone Star Logistics (job: trucker) — REPLACED qbx_truckerjob
**Type:** Civilian | **Grades:** Trainee → Driver → Senior Driver → Fleet Manager
**Duty Location:** Killeen Distribution Center (Sandy Shores)
**SOPs:**
1. Pick up cargo from depot
2. Deliver to destinations across Houston, Ft. Worth, Killeen
3. Routes: Gulf Coast Run, Hill Country Haul, Panhandle Express, Bayou Transport
4. Pay scales with distance and grade ($1500-3500 per run)
**Commands:** /truckroute, /loadcargo

### Texas Sanitation (job: garbage)
**Type:** Civilian | **Grades:** Collector
**Duty Location:** Sanitation Yard
**SOPs:**
1. Drive garbage truck on assigned route
2. Collect trash bins
3. Deliver to dump/processing center
**Commands:** /garbageroute

### Hill Country Vineyard (job: vineyard)
**Type:** Civilian | **Grades:** Picker
**Duty Location:** Vineyard (Hill Country)
**SOPs:**
1. Pick grapes at the vineyard
2. Process into wine (use sinister_crafting station)
3. Sell to bars and restaurants
**Commands:** /picking

### Texas Street Eats (job: hotdog)
**Type:** Civilian | **Grades:** Sales
**Duty Location:** Mobile cart
**SOPs:**
1. Set up hot dog cart at designated spots
2. Sell hot dogs to players
3. Restock supplies at warehouse
**Commands:** /setcart, /sellfood

### Piney Woods Logging Co. (job: lumberjack) — NEW
**Type:** Civilian | **Grades:** Rookie → Apprentice → Logger → Lumberjack → Foreman → Legend
**Duty Location:** Paleto Forest (Ft. Worth)
**SOPs:**
1. Use axe minigame to chop trees
2. Load logs into truck — team up for crew XP bonus
3. Deliver logs to Killeen Sawmill
4. Upgrade skills (Speed, Aim, Yield, Load) with XP
**Commands:** /choptree, /loadlogs, /joincrew [ID], /upgrade

### Texas Crude Co. (job: oiljob) — NEW
**Type:** Industrial | **Grades:** Roughneck → Drill Operator → Field Supervisor → Rig Manager
**Duty Location:** Killeen Oil Fields (Sandy Shores)
**SOPs:**
1. Operate drilling equipment at oil rigs
2. Multiplayer co-op for faster production
3. Transport crude oil barrels to refinery
4. Pay: $500-800 per cycle, scales with grade
**Commands:** /drill, /pump

### Lone Star Movers (job: mover) — NEW
**Type:** Civilian | **Grades:** Trainee → Mover → Senior Mover → Crew Chief → Operations Manager
**SOPs:**
1. Accept moving jobs — pick up furniture/boxes
2. Transport to destination
3. Unload at new location
4. Pay: $1500-3000 per job
**Commands:** /acceptmove, /loadcargo, /unload

### Texas Suds Car Wash (job: carwash) — NEW (replaces qbx_carwash)
**Type:** Business | **Grades:** Attendant → Detailer → Shift Lead → Manager → Owner
**Duty Location:** Legion Square, Paleto, Sandy Shores
**SOPs:**
1. Use pressure washer minigame to clean vehicles
2. Tiers: Basic Rinse (40%), Texas Two-Step (75%+repair), Lone Star Supreme (100%+repair)
3. Hire NPC employees (3 max, leveling system)
4. Manage supplies via boss panel
5. Boss panel: sales history, employee management, supply ordering
**Commands:** /wash, /startshift, /bossmenu

### Texas Fuel Co. (job: fuel) — NEW
**Type:** Business | **Dates Gas Station across Houston
**SOPs:**
1. Buy gas stations — manage fuel prices
2. Restock fuel inventory
3. 4 fuel categories with different prices
4. Revenue from player fuel purchases
**Commands:** /fuelmenu, /buyfuel

---

## CRIMINAL JOBS (not official — accessed through gang/unemployed)

### Bluebonnet RV Meth Cook
Uses WZ Methlab system — Journey RV mobile lab
3-stage cooking process with skill checks
Failure causes damage or vehicle explosion
Sell meth to drug spots via sinister_crime

### Bayou Dock Runner
Criminal smuggling — move contraband between docks
Use Multiplayer Oil Job boats for smuggling routes
High risk — police detection chance

---

## GANGS

Gangs are managed through Qbox's built-in gang system.
**Gang creation:** Admin only — contact staff to create a gang
**Gang roles:** Leader (boss), Enforcer, Soldier, Prospect
**Gang commands:** /gang [invite/kick/promote/demote], /gangchat
**Territory:** Controlled through sinister_crime territory system
**Gang perks:** Armory access, vehicle garage, shared bank account

---

## MULTIJOB

Players can hold ONE primary job and up to TWO secondary jobs simultaneously.
Use /multijob to toggle between jobs.
On-duty status is per-job — you can be on-duty for one job while off-duty for another.
Admin-restricted jobs (LEO, EMS) require approval.
