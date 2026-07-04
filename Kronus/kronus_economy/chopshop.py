import random
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

CHOP_COOLDOWN_MINUTES = 30
MAX_HEAT = 100
HEAT_PER_CHOP = 15
HEAT_DECAY_PER_HOUR = 5
HEAT_ALERT_THRESHOLD = 75

VEHICLE_PAYOUTS = {
    "compact": (1500, 3500),
    "sedan": (2500, 5000),
    "suv": (4000, 8000),
    "sport": (6000, 12000),
    "super": (10000, 25000),
    "motorcycle": (1000, 2500),
    "truck": (3000, 6000),
    "default": (1500, 4000),
}


async def process_chop(citizenid: str, vehicle_class: str = "default") -> dict:
    if not await is_enabled("chop_shop_enabled"):
        return {"error": "Chop shop disabled"}

    payout_range = VEHICLE_PAYOUTS.get(vehicle_class.lower(), VEHICLE_PAYOUTS["default"])
    payout = random.randint(payout_range[0], payout_range[1])

    supabase.rpc("add_funds", {
        "p_citizenid": citizenid,
        "p_amount": payout,
        "p_account": "dirty_money"
    }).execute()

    current_heat = await get_chop_heat()
    new_heat = min(current_heat + HEAT_PER_CHOP, MAX_HEAT)
    supabase.table("bot_config").upsert({
        "key": "chop_shop_heat",
        "value": str(new_heat),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    alerted = new_heat >= HEAT_ALERT_THRESHOLD

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "chop_processed",
        "context_json": {
            "citizenid": citizenid,
            "vehicle_class": vehicle_class,
            "payout": payout,
            "heat": new_heat,
            "alerted": alerted
        },
        "result": "completed"
    }).execute()

    return {
        "payout": payout,
        "heat": new_heat,
        "alerted": alerted,
        "cooldown_minutes": CHOP_COOLDOWN_MINUTES,
    }


async def get_chop_heat() -> int:
    r = supabase.table("bot_config").select("value").eq("key", "chop_shop_heat").execute()
    return int(r.data[0]["value"]) if r.data else 0


async def decay_chop_heat():
    if not await is_enabled("chop_shop_enabled"):
        return
    current = await get_chop_heat()
    if current <= 0:
        return
    new_heat = max(0, current - HEAT_DECAY_PER_HOUR)
    supabase.table("bot_config").upsert({
        "key": "chop_shop_heat",
        "value": str(new_heat),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()
    if new_heat < HEAT_ALERT_THRESHOLD and current >= HEAT_ALERT_THRESHOLD:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "chop_heat_cooldown",
            "context_json": {"old_heat": current, "new_heat": new_heat},
            "result": "heat_normalized"
        }).execute()
