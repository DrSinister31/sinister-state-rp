from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

DRUG_TIERS = [
    {"level": 0, "name": "Street Pusher", "xp_needed": 0, "alert_bonus": 0},
    {"level": 1, "name": "Corner Boss", "xp_needed": 500, "alert_bonus": 5},
    {"level": 2, "name": "Block King", "xp_needed": 2000, "alert_bonus": 10},
    {"level": 3, "name": "District Lord", "xp_needed": 8000, "alert_bonus": 15},
    {"level": 4, "name": "Cartel Boss", "xp_needed": 25000, "alert_bonus": 20},
]

DRUG_TYPES = {
    "weed": {"base_xp": 10, "alert_chance_key": "drug_alert_chance_weed", "base_value": 500},
    "cocaine": {"base_xp": 25, "alert_chance_key": "drug_alert_chance_cocaine", "base_value": 1500},
    "meth": {"base_xp": 40, "alert_chance_key": "drug_alert_chance_meth", "base_value": 3000},
    "heroin": {"base_xp": 60, "alert_chance_key": "drug_alert_chance_heroin", "base_value": 6000},
    "fentanyl": {"base_xp": 100, "alert_chance_key": "drug_alert_chance_fentanyl", "base_value": 12000},
}

XP_DECAY_DAYS = 7
XP_DECAY_RATE = 0.10


async def process_drug_sale(citizenid: str, drug_type: str, quantity: int = 1, sale_price: int = 0):
    if not await is_enabled("drug_system_enabled"):
        return None

    drug = DRUG_TYPES.get(drug_type.lower())
    if not drug:
        return None

    xp_gain = drug["base_xp"] * quantity
    earnings_gain = max(sale_price, drug["base_value"] * quantity)

    player = supabase.table("player_drug_xp").select("*").eq("citizenid", citizenid).execute()
    if player.data:
        p = player.data[0]
        current_xp = (p.get("drug_xp", 0) or 0) + xp_gain
        total_sales = (p.get("total_sales", 0) or 0) + quantity
        lifetime_earnings = (p.get("lifetime_earnings", 0) or 0) + earnings_gain
    else:
        current_xp = xp_gain
        total_sales = quantity
        lifetime_earnings = earnings_gain

    current_level = 0
    for tier in DRUG_TIERS:
        if current_xp >= tier["xp_needed"]:
            current_level = tier["level"]

    supabase.table("player_drug_xp").upsert({
        "citizenid": citizenid,
        "drug_level": current_level,
        "drug_xp": current_xp,
        "total_sales": total_sales,
        "lifetime_earnings": lifetime_earnings,
        "last_sale": datetime.utcnow().isoformat()
    }).execute()

    tier_info = DRUG_TIERS[current_level]

    alert_key = drug["alert_chance_key"]
    cfg = supabase.table("bot_config").select("value").eq("key", alert_key).execute()
    base_chance = int(cfg.data[0]["value"]) if cfg.data else 15
    alert_chance = min(base_chance + tier_info["alert_bonus"], 85)

    return {
        "xp_gained": xp_gain,
        "total_xp": current_xp,
        "level": current_level,
        "tier_name": tier_info["name"],
        "alert_chance": alert_chance,
        "earnings": earnings_gain,
    }


async def apply_drug_xp_decay():
    if not await is_enabled("drug_system_enabled"):
        return

    cutoff = (datetime.utcnow() - timedelta(days=XP_DECAY_DAYS)).isoformat()
    players = supabase.table("player_drug_xp").select("citizenid, drug_xp").lt("last_sale", cutoff).execute()

    for p in (players.data or []):
        current_xp = p.get("drug_xp", 0) or 0
        if current_xp <= 0:
            continue
        decayed = int(current_xp * (1 - XP_DECAY_RATE))
        supabase.table("player_drug_xp").update({"drug_xp": decayed}).eq("citizenid", p["citizenid"]).execute()

    if players.data:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "drug_xp_decay",
            "context_json": {"players_decayed": len(players.data)},
            "result": "completed"
        }).execute()


async def get_drug_rep(citizenid: str) -> dict:
    r = supabase.table("player_drug_xp").select("*").eq("citizenid", citizenid).execute()
    if not r.data:
        return {"level": 0, "xp": 0, "tier_name": "Street Pusher", "total_sales": 0, "lifetime_earnings": 0}
    p = r.data[0]
    xp = p.get("drug_xp", 0) or 0
    level = 0
    for tier in DRUG_TIERS:
        if xp >= tier["xp_needed"]:
            level = tier["level"]
    return {
        "level": level,
        "xp": xp,
        "tier_name": DRUG_TIERS[level]["name"],
        "total_sales": p.get("total_sales", 0) or 0,
        "lifetime_earnings": p.get("lifetime_earnings", 0) or 0,
    }
