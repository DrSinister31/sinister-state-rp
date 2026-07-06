import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import json, random
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

ORG_ARCHETYPES = ["cartel", "mafia", "gang", "biker", "syndicate"]

SLOT_CAPS = {
    5: {"cartel": 1, "mafia": 0, "gang": 1, "biker": 1, "syndicate": 0},
    15: {"cartel": 1, "mafia": 1, "gang": 2, "biker": 1, "syndicate": 0},
    30: {"cartel": 2, "mafia": 1, "gang": 3, "biker": 2, "syndicate": 1},
    50: {"cartel": 2, "mafia": 2, "gang": 4, "biker": 2, "syndicate": 1},
    80: {"cartel": 3, "mafia": 2, "gang": 5, "biker": 3, "syndicate": 2},
    128: {"cartel": 3, "mafia": 3, "gang": 6, "biker": 3, "syndicate": 2},
}

AI_ORG_NAMES = {
    "cartel": ["Ranchero Cartel", "Gulf Coast Cartel", "Sinaloa Tejas", "Loma Cartel"],
    "mafia": ["Conti Family", "Moretti Family", "Romano Outfit", "Tarrant Syndicate"],
    "gang": ["Cypress Kings", "Davis Ave Mafia", "Sunnyside Soldiers", "East End Reapers"],
    "biker": ["Desert Vultures MC", "Lone Star Nomads", "Iron Wraiths MC", "Satan's Outlaws MC"],
    "syndicate": ["Houston Exchange", "Harris County Group", "Bay City Partners", "Fort Worth Capital"],
}

TERRITORY_ZONES = [
    "Loma Vista", "Third Ward", "Sunnyside", "Rancier Ave", "East End",
    "Channelview", "The Heights", "Downtown Houston", "Montrose", "Nolanville",
    "Stockyards", "Galveston", "Acres Homes", "Pasadena",
]

ZONE_ARCHETYPE_AFFINITY = {
    "cartel": ["Loma Vista", "Channelview", "Nolanville", "Rancier Ave", "Galveston"],
    "mafia": ["Downtown Houston", "Montrose", "The Heights", "River Oaks", "Stockyards"],
    "gang": ["Third Ward", "Sunnyside", "East End", "Acres Homes", "Pasadena"],
    "biker": ["Rancier Ave", "Loma Vista", "Nolanville", "Stockyards"],
    "syndicate": ["Downtown Houston", "Montrose", "River Oaks"],
}


async def get_player_count() -> int:
    r = supabase.table("characters").select("citizenid", count="exact").eq("active", True).execute()
    return r.count if r.count else 0


async def get_slot_caps() -> dict:
    count = await get_player_count()
    for threshold in sorted(SLOT_CAPS.keys()):
        if count <= threshold:
            return SLOT_CAPS[threshold]
    return SLOT_CAPS[128]


async def run_org_slot_check():
    if not await is_enabled("criminal_empire_enabled"):
        return

    caps = await get_slot_caps()
    player_count = await get_player_count()

    for arch in ORG_ARCHETYPES:
        cap = caps.get(arch, 1)
        active = supabase.table("organizations").select("id", count="exact").eq("archetype", arch).eq("active", True).execute()
        current = active.count if active else 0

        supabase.table("criminal_slots").upsert({
            "archetype": arch, "max_slots": cap, "current_slots": current,
            "ai_filled": 0, "min_players": player_count
        }, on_conflict="archetype").execute()

        if current < cap and await is_enabled("ai_organizations_enabled"):
            ai_count = 0
            ai_orgs = supabase.table("organizations").select("id", count="exact").eq("archetype", arch).eq("is_ai", True).eq("active", True).execute()
            ai_count = ai_orgs.count if ai_orgs else 0
            needed = cap - current - ai_count
            for _ in range(max(0, needed)):
                await spawn_ai_organization(arch)


async def spawn_ai_organization(arch: str) -> dict:
    name_pool = AI_ORG_NAMES.get(arch, ["Unknown"])
    name = random.choice(name_pool) + " #" + str(random.randint(100, 999))
    zones = ZONE_ARCHETYPE_AFFINITY.get(arch, TERRITORY_ZONES[:3])

    existing = supabase.table("org_territories").select("zone_name").execute()
    taken = set(t.get("zone_name") for t in (existing.data or []))
    available = [z for z in zones if z not in taken]
    if not available:
        available = [z for z in TERRITORY_ZONES if z not in taken][:3]

    hq = available[0] if available else "Loma Vista"
    org = {
        "name": name, "archetype": arch, "color": "#888888",
        "founder_citizenid": "AI_SYSTEM", "hq_territory": hq,
        "is_ai": True, "member_count": random.randint(5, 15),
        "total_rep": random.randint(100, 500),
    }
    result = supabase.table("organizations").insert(org).execute()
    org_id = result.data[0]["id"] if result.data else None

    if org_id:
        for zone in available[:min(3, len(available))]:
            supabase.table("org_territories").upsert({
                "org_id": org_id, "zone_name": zone
            }, on_conflict="zone_name").execute()

        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "ai_org_spawned",
            "context_json": {"org_id": str(org_id), "name": name, "arch": arch, "hq": hq},
            "result": "created"
        }).execute()

    return {"name": name, "archetype": arch, "hq": hq}


async def ai_gang_war():
    if not await is_enabled("gang_wars_enabled"):
        return

    orgs = supabase.table("organizations").select("id, name, archetype, hq_territory").eq("active", True).execute()
    if not orgs.data or len(orgs.data) < 2:
        return

    a = random.choice(orgs.data)
    others = [o for o in orgs.data if o["id"] != a["id"]]
    b = random.choice(others)

    a_turf = supabase.table("org_territories").select("zone_name").eq("org_id", a["id"]).execute()
    b_turf = supabase.table("org_territories").select("zone_name").eq("org_id", b["id"]).execute()
    a_zones = [t["zone_name"] for t in (a_turf.data or [])]
    b_zones = [t["zone_name"] for t in (b_turf.data or [])]

    adjacent = set(a_zones) & set(b_zones)
    if not adjacent:
        if a_zones and b_zones:
            adjacent = set(b_zones) if random.random() < 0.5 else set(a_zones)
        else:
            return

    zone = random.choice(list(adjacent))
    physical = random.random() < 0.05

    score = 20 if physical else 14
    desc = f"{'PHYSICAL CONFRONTATION' if physical else 'Territory dispute'} at {zone}. "
    desc += f"{a['name']} vs {b['name']}."

    supabase.table("chronicle_entries").insert({
        "score": score,
        "title": f"Gang War — {a['name']} vs {b['name']}",
        "description": desc,
        "involved_citizenids": [],
        "involved_discord_ids": [],
        "volume_index": 0,
    }).execute()

    if physical:
        supabase.table("org_territories").update({"contested_by": b["id"]}).eq("zone_name", zone).eq("org_id", a["id"]).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "gang_war",
        "context_json": {
            "org_a": str(a["id"]), "org_b": str(b["id"]),
            "zone": zone, "physical": physical, "score": score,
        },
        "result": "logged"
    }).execute()


async def run_drug_spot_cycle():
    if not await is_enabled("drug_spots_enabled"):
        return

    spots = supabase.table("drug_spots").select("*").eq("active", True).execute()
    hour = datetime.utcnow().hour
    time_of_day = "night" if hour >= 20 or hour <= 5 else "afternoon" if 12 <= hour <= 17 else "evening" if 17 <= hour <= 20 else "morning"

    active_buyers = 0
    for spot in (spots.data or []):
        density = spot.get("buyer_density", 3) or 3
        best = spot.get("best_time", "night")
        multiplier = 1.0
        if time_of_day == best: multiplier = 2.0
        elif time_of_day == "morning": multiplier = 0.3
        buyers = max(0, int(density * multiplier * random.uniform(0.7, 1.3)))
        active_buyers += buyers

    if active_buyers > 0:
        supabase.table("kronus_metrics").insert({
            "metric_name": "active_drug_buyers",
            "value": float(active_buyers),
            "metadata_json": {"time_of_day": time_of_day, "spots_active": len(spots.data or [])},
            "recorded_at": datetime.utcnow().isoformat()
        }).execute()


async def process_police_response(crime_type: str, zone: str, perpetrator: str) -> dict:
    if not await is_enabled("police_witness_enabled"):
        return {"alerted": False, "reason": "police witness disabled"}

    camera_zones = ["Downtown Houston", "Montrose", "The Heights", "Port of Houston", "Stockyards"]
    has_camera = zone in camera_zones
    witness_nearby = random.random() < 0.30

    alerted = witness_nearby or has_camera
    witness_type = "camera" if has_camera else "civilian" if witness_nearby else "none"

    supabase.table("crime_witnesses").insert({
        "crime_type": crime_type,
        "location": zone,
        "zone_name": zone,
        "perpetrator_citizenid": perpetrator,
        "witness_type": witness_type,
        "reported_to_police": alerted,
        "caught_on_camera": has_camera,
        "ps_mdt_alerted": alerted,
    }).execute()

    if alerted:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "police_alerted",
            "context_json": {"crime": crime_type, "zone": zone, "witness": witness_type},
            "result": "alerted"
        }).execute()

    return {"alerted": alerted, "witness": witness_type, "camera": has_camera}


async def register_organization(
    founder_cid: str, name: str, archetype: str, color: str, hq_zone: str, initiation_fee: int = 0
) -> dict:
    if not await is_enabled("criminal_empire_enabled"):
        return {"error": "Criminal empire disabled"}

    if archetype not in ORG_ARCHETYPES:
        return {"error": f"Invalid archetype. Must be: {ORG_ARCHETYPES}"}

    caps = await get_slot_caps()
    active = supabase.table("organizations").select("id", count="exact").eq("archetype", archetype).eq("active", True).execute()
    current = active.count if active else 0
    cap = caps.get(archetype, 1)
    if current >= cap:
        return {"error": f"No {archetype} slots available ({current}/{cap} used)"}

    existing = supabase.table("organizations").select("id").eq("name", name).execute()
    if existing.data:
        return {"error": "Name taken"}

    zone_taken = supabase.table("org_territories").select("id").eq("zone_name", hq_zone).execute()
    if zone_taken.data:
        return {"error": f"{hq_zone} already claimed"}

    org = {
        "name": name, "archetype": archetype, "color": color,
        "founder_citizenid": founder_cid, "hq_territory": hq_zone,
        "initiation_fee": initiation_fee, "is_ai": False,
    }
    result = supabase.table("organizations").insert(org).execute()
    org_id = result.data[0]["id"] if result.data else None

    if org_id:
        supabase.table("org_territories").insert({
            "org_id": org_id, "zone_name": hq_zone
        }).execute()
        supabase.table("org_members").insert({
            "org_id": org_id, "citizenid": founder_cid, "rank": 4, "rank_title": "Boss"
        }).execute()

    return {"status": "founded", "name": name, "org_id": str(org_id)}


async def calculate_criminal_rep(citizenid: str) -> dict:
    drug = supabase.table("player_drug_xp").select("drug_xp, drug_level").eq("citizenid", citizenid).execute()
    drug_xp = drug.data[0].get("drug_xp", 0) if drug.data else 0
    drug_lvl = drug.data[0].get("drug_level", 0) if drug.data else 0

    street = supabase.table("street_reputation").select("rep_score, territory_control, heat_level").eq("citizenid", citizenid).execute()
    rep = street.data[0].get("rep_score", 0) if street.data else 0

    member = supabase.table("org_members").select("org_id").eq("citizenid", citizenid).execute()
    if member.data:
        org = supabase.table("organizations").select("total_rep").eq("id", member.data[0]["org_id"]).execute()
        org_rep = org.data[0].get("total_rep", 0) if org.data else 0
    else:
        org_rep = 0

    territories = supabase.table("org_members").select("org_id").eq("citizenid", citizenid).execute()
    territory_count = 0
    if territories.data:
        turf = supabase.table("org_territories").select("id", count="exact").eq("org_id", territories.data[0]["org_id"]).execute()
        territory_count = turf.count if turf else 0

    heat = street.data[0].get("heat_level", 0) if street.data else 0

    total = int(drug_xp * 0.3 + rep * 0.4 + territory_count * 50 + org_rep * 0.2 - heat * 0.1)
    total = max(0, total)

    tier = 0
    if total >= 500: tier = 1
    if total >= 2000: tier = 2
    if total >= 8000: tier = 3
    if total >= 25000: tier = 4

    supabase.table("street_reputation").upsert({
        "citizenid": citizenid, "rep_score": total,
        "territory_control": territory_count, "heat_level": heat,
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    return {
        "total": total, "tier": tier,
        "tier_name": ["Street Pusher", "Block Boss", "Made Man", "Kingpin"][min(tier, 3)],
        "eligible_for_org": tier >= 2,
        "eligible_for_kingpin": tier >= 3,
    }
