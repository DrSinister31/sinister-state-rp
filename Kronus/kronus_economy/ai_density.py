import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from shared.supabase_client import get_supabase
from toggles import is_enabled

supabase = get_supabase()

AI_DENSITY = {
    0: 1.00, 1: 0.80, 6: 0.60, 11: 0.50, 16: 0.40,
    21: 0.30, 31: 0.20, 41: 0.15, 65: 0.10, 101: 0.05, 129: 0.05
}

JOB_AI_MAX = {
    "police": 15, "houstonpd": 5, "bcso": 5, "texasdps": 5,
    "ambulance": 8, "fire": 5, "fib": 3, "military": 8, "atc": 2,
    "mechanic": 3, "tow": 3, "taxi": 5, "bus": 3,
    "trucker": 8, "warehouse": 8, "garbage": 2,
    "vineyard": 3, "hotdog": 2, "cardealer": 2,
    "judge": 1, "lawyer": 2, "reporter": 2, "realestate": 1,
    "bartender": 2, "farmer": 3, "fisherman": 2,
    "default": 3
}

JOB_REMOVAL_RATIO = {"police": 2, "houstonpd": 2, "ambulance": 2, "fire": 1, "default": 2}

async def get_player_count() -> int:
    r = supabase.table("characters").select("citizenid", count="exact").eq("active", True).execute()
    return r.count if r.count else 0

async def get_density_multiplier() -> float:
    count = await get_player_count()
    multiplier = 1.0
    for threshold, density in sorted(AI_DENSITY.items(), reverse=True):
        if count >= threshold:
            multiplier = density
            break
    return multiplier

async def get_ai_limit_for_job(job_name: str) -> int:
    max_ai = JOB_AI_MAX.get(job_name, JOB_AI_MAX["default"])
    density = await get_density_multiplier()
    limit = int(max_ai * density)
    if limit < 1 and max_ai > 0:
        limit = 1
    return limit

async def calculate_ai_count(job_name: str) -> int:
    if not await is_enabled("ai_workers_enabled"):
        return 0
    max_ai = await get_ai_limit_for_job(job_name)
    removal = JOB_REMOVAL_RATIO.get(job_name, JOB_REMOVAL_RATIO["default"])
    real = supabase.table("characters").select("citizenid", count="exact").eq("job_name", job_name).eq("active", True).execute()
    real_count = real.count if real.count else 0
    ai_count = max_ai - (real_count * removal)
    return max(0, ai_count)

async def run_ai_density_update():
    density = await get_density_multiplier()
    count = await get_player_count()
    supabase.table("kronus_metrics").insert({
        "metric_name": "ai_density",
        "value": density,
        "metadata_json": {"player_count": count},
        "recorded_at": "now()"
    }).execute()

    total = await get_player_count()
    supabase.table("kronus_metrics").insert({
        "metric_name": "active_players",
        "value": float(total),
        "recorded_at": "now()"
    }).execute()

    enabled = await is_enabled("ai_workers_enabled")
    toggle_val = "true" if enabled else "false"
    supabase.table("rcon_commands").insert({
        "command": f"set sinister_ai:global_density {density}; set sinister_ai:ai_toggle {toggle_val}",
        "source": "kronus_economy",
        "status": "pending"
    }).execute()
