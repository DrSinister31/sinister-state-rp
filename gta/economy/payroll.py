import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

DEFAULT_PAY_SCALES = {
    "leo": [50, 75, 100, 125, 150, 200, 300, 400, 500, 600],
    "ems": [50, 100, 200, 300, 400, 500, 600],
    "mechanic": [50, 75, 100, 125, 150],
    "none": [50, 75, 100, 150, 250],
    "default": [50, 75, 100, 150, 250, 350, 500],
}

MINIMUM_WAGE = 50


async def get_default_pay(job_type: str, grade_level: int) -> int:
    scale = DEFAULT_PAY_SCALES.get(job_type, DEFAULT_PAY_SCALES["default"])
    if grade_level < len(scale):
        return scale[grade_level]
    return scale[-1] + (grade_level - len(scale) + 1) * 50


async def run_universal_payroll():
    if not await is_enabled("universal_payroll_enabled"):
        return

    characters = supabase.table("characters").select("citizenid, job_name, job_grade, first_name, last_name").eq("active", True).execute()
    if not characters.data:
        return

    total_paid = 0
    job_counts = {}

    for char in characters.data:
        cid = char["citizenid"]
        job = char.get("job_name", "unemployed")
        grade = char.get("job_grade", 0) or 0

        if job == "unemployed":
            continue

        pay = MINIMUM_WAGE
        try:
            cfg = supabase.table("bot_config").select("value").eq("key", f"pay_{job}_grade_{grade}").execute()
            if cfg.data:
                pay = int(cfg.data[0]["value"])
            else:
                pay = await get_default_pay(job, grade)
                supabase.table("bot_config").upsert({
                    "key": f"pay_{job}_grade_{grade}",
                    "value": str(pay),
                    "updated_at": datetime.utcnow().isoformat()
                }).execute()
        except:
            pay = MINIMUM_WAGE

        supabase.rpc("add_funds", {
            "p_citizenid": cid,
            "p_amount": pay,
            "p_account": "bank"
        }).execute()

        supabase.table("transactions").insert({
            "from_citizenid": "treasury",
            "to_citizenid": cid,
            "amount": pay,
            "account_type": "bank",
            "reason": f"Universal Payroll — {job} Grade {grade}",
            "channel": "payroll"
        }).execute()

        total_paid += pay
        job_counts[job] = job_counts.get(job, 0) + 1

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "universal_payroll",
        "context_json": {
            "total_paid": total_paid,
            "employees_paid": len(characters.data),
            "jobs_covered": len(job_counts),
            "job_breakdown": job_counts,
        },
        "result": "completed"
    }).execute()


async def set_job_pay(job_name: str, grade_level: int, payment: int):
    supabase.table("bot_config").upsert({
        "key": f"pay_{job_name}_grade_{grade_level}",
        "value": str(payment),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()
    return {"job": job_name, "grade": grade_level, "payment": payment}


async def get_all_pay_scales() -> dict:
    r = supabase.table("bot_config").select("key, value").ilike("key", "pay_%").execute()
    scales = {}
    for row in (r.data or []):
        scales[row["key"]] = row["value"]
    return scales
