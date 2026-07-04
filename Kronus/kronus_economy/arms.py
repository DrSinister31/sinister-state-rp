import random
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

TIER_PRICE_RANGES = {
    1: (50, 500),
    2: (3000, 15000),
    3: (12000, 35000),
    4: (20000, 50000),
    5: (35000, 80000),
}


async def rotate_arms_stock():
    if not await is_enabled("arms_dealer_enabled"):
        return

    cfg = supabase.table("bot_config").select("value").eq("key", "arms_dealer_max_tier").execute()
    max_tier = int(cfg.data[0]["value"]) if cfg.data else 2

    current = supabase.table("arms_dealer_stock").select("*").execute()
    changed = 0

    for item in (current.data or []):
        tier = item.get("tier", 1)
        if tier > max_tier:
            continue

        active = random.random() < 0.6
        min_p, max_p = TIER_PRICE_RANGES.get(tier, (100, 5000))
        new_price = random.randint(min_p, max_p)
        new_stock = random.randint(1, 10) if active else 0

        supabase.table("arms_dealer_stock").update({
            "stock": new_stock,
            "price": new_price,
            "active": active
        }).eq("id", item["id"]).execute()
        changed += 1

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "arms_stock_rotated",
        "context_json": {"items_changed": changed, "max_tier": max_tier},
        "result": "completed"
    }).execute()


async def get_active_stock(tier: int = None) -> list:
    q = supabase.table("arms_dealer_stock").select("*").eq("active", True).gt("stock", 0)
    if tier:
        q = q.eq("tier", tier)
    result = q.execute()
    return result.data or []


async def increase_max_tier():
    cfg = supabase.table("bot_config").select("value").eq("key", "arms_dealer_max_tier").execute()
    current = int(cfg.data[0]["value"]) if cfg.data else 2
    if current >= 5:
        return

    new_tier = current + 1
    supabase.table("bot_config").upsert({
        "key": "arms_dealer_max_tier",
        "value": str(new_tier),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("arms_dealer_stock").update({"active": True}).eq("tier", new_tier).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "arms_max_tier_increased",
        "context_json": {"old_tier": current, "new_tier": new_tier},
        "result": "completed"
    }).execute()
