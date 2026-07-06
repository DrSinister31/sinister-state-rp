import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import random
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

TERRITORY_ZONES = [
    {"id": "davis", "name": "Davis", "type": "urban"},
    {"id": "cypress", "name": "Cypress Flats", "type": "industrial"},
    {"id": "grove", "name": "Grove Street", "type": "urban"},
    {"id": "strawberry", "name": "Strawberry", "type": "urban"},
    {"id": "vespucci", "name": "Vespucci", "type": "coastal"},
    {"id": "mirror_park", "name": "Mirror Park", "type": "suburban"},
    {"id": "sandy", "name": "Sandy Shores", "type": "rural"},
    {"id": "paleto", "name": "Paleto Cove", "type": "rural"},
    {"id": "docks", "name": "Terminal Docks", "type": "industrial"},
    {"id": "airport", "name": "Airport District", "type": "industrial"},
]

TERRITORY_INCOME_BASE = {
    "urban": (500, 2000),
    "industrial": (1000, 5000),
    "coastal": (800, 3500),
    "suburban": (400, 1500),
    "rural": (300, 1200),
}


async def claim_territory(zone_id: str, gang_name: str, citizenid: str) -> dict:
    if not await is_enabled("gang_territory_enabled"):
        return {"error": "Gang territory disabled"}

    zone = next((z for z in TERRITORY_ZONES if z["id"] == zone_id), None)
    if not zone:
        return {"error": "Invalid zone"}

    existing = supabase.table("bot_config").select("value").eq("key", f"territory_{zone_id}").execute()
    if existing.data:
        current_data = eval(existing.data[0]["value"]) if isinstance(existing.data[0]["value"], str) else existing.data[0]["value"]
        if isinstance(current_data, str):
            import json
            current_data = json.loads(current_data)
    else:
        current_data = None

    territory = {
        "zone_id": zone_id,
        "zone_name": zone["name"],
        "gang_name": gang_name,
        "controlled_by": citizenid,
        "claimed_at": datetime.utcnow().isoformat(),
        "previous_owner": current_data.get("gang_name") if current_data else None,
    }

    supabase.table("bot_config").upsert({
        "key": f"territory_{zone_id}",
        "value": str(territory),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "territory_claimed",
        "context_json": territory,
        "result": "completed"
    }).execute()

    return territory


async def get_all_territories() -> list:
    territories = []
    for zone in TERRITORY_ZONES:
        r = supabase.table("bot_config").select("value").eq("key", f"territory_{zone['id']}").execute()
        if r.data:
            import json
            val = r.data[0]["value"]
            if isinstance(val, str):
                territories.append(json.loads(val))
            else:
                territories.append(val)
    return territories


async def process_gang_income():
    if not await is_enabled("gang_territory_enabled"):
        return

    territories = await get_all_territories()
    total_paid = 0

    for t in territories:
        zone_id = t.get("zone_id", "")
        zone = next((z for z in TERRITORY_ZONES if z["id"] == zone_id), None)
        if not zone:
            continue

        income_range = TERRITORY_INCOME_BASE.get(zone["type"], (200, 1000))
        income = random.randint(income_range[0], income_range[1])
        cid = t.get("controlled_by")

        if cid:
            supabase.rpc("add_funds", {
                "p_citizenid": cid,
                "p_amount": income,
                "p_account": "dirty_money"
            }).execute()
            total_paid += income

    if total_paid > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "gang_income_distributed",
            "context_json": {"territories": len(territories), "total_paid": total_paid},
            "result": "completed"
        }).execute()
