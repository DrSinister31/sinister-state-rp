import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

DEPARTMENT_FUNDS = [
    "police_fund",
    "ems_fund",
    "fire_fund",
    "infrastructure_fund",
    "education_fund",
    "parks_fund",
    "transportation_fund",
    "general_fund",
]


async def allocate_city_budget():
    if not await is_enabled("budget_allocation_enabled"):
        return

    general = supabase.table("city_treasury").select("balance").eq("fund_name", "general_fund").execute()
    general_balance = (general.data[0]["balance"] if general.data else 0) or 0

    if general_balance <= 0:
        return

    allocations = supabase.table("city_budget_allocations").select("fund_name, kronus_default_percentage").execute()
    if not allocations.data:
        return

    total_allocated = 0

    for alloc in allocations.data:
        fund = alloc["fund_name"]
        pct = (alloc.get("kronus_default_percentage", 0) or 0) / 100.0
        if fund == "general_fund" or pct <= 0:
            continue

        amount = int(general_balance * pct)
        if amount <= 0:
            continue

        fund_data = supabase.table("city_treasury").select("balance").eq("fund_name", fund).execute()
        current = (fund_data.data[0]["balance"] if fund_data.data else 0) or 0
        supabase.table("city_treasury").update({"balance": current + amount, "last_updated": datetime.utcnow().isoformat()}).eq("fund_name", fund).execute()

        supabase.table("tax_transactions").insert({
            "citizenid": "city",
            "tax_type": "budget_allocation",
            "amount": amount,
            "fund_name": fund,
            "collected_at": datetime.utcnow().isoformat()
        }).execute()

        total_allocated += amount

    supabase.table("city_treasury").update({"balance": general_balance - total_allocated, "last_updated": datetime.utcnow().isoformat()}).eq("fund_name", "general_fund").execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "budget_allocated",
        "context_json": {"from_general_fund": general_balance, "total_allocated": total_allocated, "remaining": general_balance - total_allocated},
        "result": "completed"
    }).execute()


async def get_treasury_summary() -> dict:
    funds = supabase.table("city_treasury").select("fund_name, balance").execute()
    result = {}
    for f in (funds.data or []):
        result[f["fund_name"]] = f.get("balance", 0) or 0
    return result


async def get_tax_summary_since(since_iso: str) -> dict:
    r = supabase.table("tax_transactions").select("tax_type, amount").gte("created_at", since_iso).execute()
    summary = {"income": 0, "business": 0, "sales": 0, "budget_allocation": 0, "total": 0}
    count = 0
    for t in (r.data or []):
        ttype = t.get("tax_type", "other")
        amt = t.get("amount", 0) or 0
        if ttype in summary:
            summary[ttype] += amt
        summary["total"] += amt
        count += 1
    summary["transaction_count"] = count
    return summary
