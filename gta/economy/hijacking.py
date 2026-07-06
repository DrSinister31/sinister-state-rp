import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)


async def get_active_hijacks() -> list:
    r = supabase.table("hijack_incidents").select("*").eq("outcome", "in_progress").order("started_at", desc=True).execute()
    return r.data or []


async def get_hijack_stats(days: int = 7) -> dict:
    since = (datetime.utcnow().isoformat())
    r = supabase.table("hijack_incidents").select("outcome, cargo_value, cargo_tier").order("started_at", desc=True).limit(100).execute()

    total = 0
    succeeded = 0
    failed = 0
    total_value = 0

    for h in (r.data or []):
        total += 1
        if h.get("outcome") == "succeeded":
            succeeded += 1
        else:
            failed += 1
        total_value += h.get("cargo_value", 0) or 0

    return {
        "total_hijacks": total,
        "succeeded": succeeded,
        "failed": failed,
        "total_value": total_value,
        "avg_value": total_value // max(total, 1),
    }


async def generate_trailer_contract() -> dict:
    if not await is_enabled("hijack_alerts_enabled"):
        return {"error": "Hijack system disabled"}

    import random
    cargo_types = ["luxury_cars", "weapons", "ron_oil", "default"]
    cargo = random.choice(cargo_types)

    payouts = {"luxury_cars": (15000, 40000), "weapons": (20000, 60000), "ron_oil": (10000, 30000), "default": (5000, 15000)}
    prange = payouts[cargo]
    payout = random.randint(prange[0], prange[1])

    contract = {
        "contract_type": "Trailer Hijack",
        "target": f"{cargo.replace('_', ' ').title()} Cargo",
        "payout": payout,
        "requirements": {"cargo_type": cargo},
        "status": "open",
    }

    supabase.table("darknet_contracts").insert(contract).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "hijack_contract_generated",
        "context_json": {"cargo": cargo, "payout": payout},
        "result": "created"
    }).execute()

    return contract
