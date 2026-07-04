import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from shared.supabase_client import get_supabase
from toggles import is_enabled

supabase = get_supabase()

def _enabled():
    cfg = supabase.table("bot_config").select("value").eq("key", "tax_income_enabled").execute()
    return cfg.data and cfg.data[0]["value"].lower() == "true"

EXPENSE_TEMPLATES = {
    "restaurant": 2000,
    "mechanic": 3000,
    "trucking": 5000,
    "gas_station": 4000,
    "convenience": 2500,
    "airfield": 15000,
    "bar": 2000,
    "farm": 1500,
    "fishery": 800,
    "dealership": 5000,
    "default": 1500,
}

async def bill_weekly_expenses():
    businesses = supabase.table("businesses").select("id, business_type, bank_account, active").eq("active", True).execute()
    now = "now()"
    billed = 0
    for biz in (businesses.data or []):
        rate = EXPENSE_TEMPLATES.get(biz.get("business_type"), EXPENSE_TEMPLATES["default"])
        current_balance = biz.get("bank_account", 0)
        new_balance = current_balance - rate
        supabase.table("businesses").update({
            "bank_account": new_balance,
        }).eq("id", biz["id"]).execute()

        supabase.table("transactions").insert({
            "from_citizenid": biz.get("owner_citizenid", "system"),
            "amount": rate,
            "account_type": "business",
            "reason": f"Weekly expense - {biz.get('business_type', 'business')}",
            "channel": "expense_rent",
            "business_id": biz["id"],
        }).execute()
        billed += 1

        if new_balance < 0:
            supabase.table("kronus_logs").insert({
                "service": "kronus-economy",
                "action": "overdraft",
                "context_json": {"business_id": str(biz["id"]), "balance": new_balance, "expense": rate},
                "result": "flagged"
            }).execute()

    if billed:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "weekly_expenses",
            "context_json": {"businesses_billed": billed},
            "result": "completed"
        }).execute()
