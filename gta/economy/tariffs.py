import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import json
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)


async def update_luxury_tariffs():
    if not await is_enabled("luxury_tariffs_enabled"):
        return

    inflation = supabase.table("kronus_metrics").select("value").eq("metric_name", "inflation_state").order("recorded_at", desc=True).limit(1).execute()
    is_inflating = (inflation.data and len(inflation.data) > 0 and inflation.data[0]["value"] == 1.0)

    brackets = supabase.table("player_economy").select("wealth_bracket", count="exact").eq("wealth_bracket", "Upper").execute()
    upper_count = brackets.count if brackets else 0
    total = supabase.table("player_economy").select("citizenid", count="exact").execute()
    total_count = max(total.count, 1) if total else 1
    upper_pct = upper_count / total_count if total_count > 0 else 0

    categories = supabase.table("tariff_rates").select("*").execute()
    changed = 0

    for cat in (categories.data or []):
        category = cat["category"]
        base = cat.get("base_rate", 1.0) or 1.0

        if is_inflating and upper_pct > 0.2:
            multiplier = 1.0 + min(0.3, (upper_pct - 0.2) * 1.5)
        elif is_inflating:
            multiplier = 1.0 + min(0.15, upper_pct * 0.75)
        else:
            multiplier = 1.0

        new_rate = round(base * multiplier, 3)
        current = cat.get("current_rate", 1.0) or 1.0

        if abs(new_rate - current) > 0.001:
            supabase.table("tariff_rates").update({
                "current_rate": new_rate,
                "inflation_multiplier": multiplier,
                "active": multiplier > 1.0,
                "last_updated": datetime.utcnow().isoformat()
            }).eq("id", cat["id"]).execute()
            changed += 1

    if changed > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "tariffs_updated",
            "context_json": {
                "is_inflating": is_inflating,
                "upper_pct": round(upper_pct, 3),
                "categories_changed": changed,
            },
            "result": "completed"
        }).execute()


async def get_tariff_multiplier(category: str) -> float:
    r = supabase.table("tariff_rates").select("current_rate").eq("category", category).execute()
    if r.data:
        return r.data[0].get("current_rate", 1.0) or 1.0
    return 1.0


async def get_active_tariffs() -> list:
    r = supabase.table("tariff_rates").select("category, current_rate, inflation_multiplier").eq("active", True).execute()
    return r.data or []
