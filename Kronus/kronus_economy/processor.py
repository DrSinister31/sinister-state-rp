import json
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config

config = Config.from_env()
supabase = get_supabase(config)


async def run_disparity_check():
    players = supabase.table("player_economy").select("citizenid, cash, bank").execute()
    if not players.data:
        return

    total_wealth = sum(p.get("cash", 0) + p.get("bank", 0) for p in players.data)
    count = len(players.data)
    avg = total_wealth / count if count > 0 else 0

    supabase.table("kronus_metrics").insert({
        "metric_name": "avg_player_wealth",
        "value": avg,
        "metadata_json": {"player_count": count},
        "recorded_at": datetime.utcnow().isoformat()
    }).execute()


async def run_bank_audit():
    players = supabase.table("player_economy").select("citizenid, cash, bank").execute()
    if not players.data:
        return

    sorted_players = sorted(players.data, key=lambda p: p.get("cash", 0) + p.get("bank", 0), reverse=True)
    total = len(sorted_players)
    lower = total // 3
    upper = total // 5

    brackets = {"Lower": 0, "Middle": 0, "Upper": 0}
    for i, p in enumerate(sorted_players):
        if i < upper:
            bracket = "Upper"
        elif i < (total - lower):
            bracket = "Middle"
        else:
            bracket = "Lower"
        brackets[bracket] += 1

        supabase.table("player_economy").update({"wealth_bracket": bracket}).eq("citizenid", p["citizenid"]).execute()

    inflation = brackets["Upper"] > total * 0.25
    status = "inflating" if inflation else "stable"

    supabase.table("kronus_metrics").insert({
        "metric_name": "inflation_state",
        "value": 1.0 if inflation else 0.0,
        "metadata_json": {"brackets": brackets, "status": status},
        "recorded_at": datetime.utcnow().isoformat()
    }).execute()


async def run_market_ticker():
    import random
    events = [
        {"name": "Labor Strike", "desc": "Restaurant workers on strike. Food yields cut by 50%.", "modifier": 0.5},
        {"name": "Oil Shortage", "desc": "Ron Oil supply crisis. Trucking route payouts boosted +40%.", "modifier": 1.4},
        {"name": "Severe Weather", "desc": "Rockslides alter delivery routes. All logistics delayed.", "modifier": 0.75},
        {"name": "Market Boom", "desc": "Consumer confidence high. All business revenue +20%.", "modifier": 1.2},
        {"name": "Stable Market", "desc": "No significant fluctuations.", "modifier": 1.0},
    ]
    event = random.choice(events)

    supabase.table("bot_config").upsert({
        "key": "active_market_event",
        "value": json.dumps(event),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "market_ticker",
        "context_json": event,
        "result": "applied"
    }).execute()


async def run_delinquency_check():
    threshold = datetime.utcnow() - timedelta(days=14)
    cutoff = threshold.isoformat()

    result = supabase.table("businesses").select("id, name, owner_citizenid").eq("active", True).lt("created_at", cutoff).execute()
    for biz in (result.data or []):
        employees = supabase.table("business_employees").select("citizenid").eq("business_id", biz["id"]).execute()
        supabase.table("businesses").update({"delinquent": True, "delinquent_since": datetime.utcnow().isoformat()}).eq("id", biz["id"]).execute()

        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "delinquency",
            "context_json": {
                "business_id": str(biz["id"]),
                "business_name": biz["name"],
                "owner_citizenid": biz["owner_citizenid"],
                "employee_count": len(employees.data or [])
            },
            "result": "flagged_delinquent"
        }).execute()


async def process_payroll():
    businesses = supabase.table("businesses").select("id, name, owner_citizenid, revenue, bank_account").eq("active", True).execute()
    for biz in (businesses.data or []):
        employees = supabase.table("business_employees").select("citizenid, salary, is_ai, hourly_wage").eq("business_id", biz["id"]).execute()
        biz_bank = biz.get("bank_account", 0)
        for emp in (employees.data or []):
            if emp.get("is_ai"):
                salary = int((emp.get("hourly_wage", 100) or 100) * 0.33)
            else:
                salary = emp.get("salary", 0)
            if salary > 0 and biz_bank >= salary:
                supabase.rpc("add_funds", {"p_citizenid": emp["citizenid"], "p_amount": salary, "p_account": "bank"}).execute()
                supabase.table("businesses").update({"bank_account": biz_bank - salary}).eq("id", biz["id"]).execute()
                biz_bank -= salary
                supabase.table("transactions").insert({
                    "from_citizenid": biz["owner_citizenid"],
                    "to_citizenid": emp["citizenid"],
                    "amount": salary,
                    "account_type": "bank",
                    "reason": f"Payroll - {biz['name']}",
                    "channel": "payroll",
                    "business_id": biz["id"]
                }).execute()


async def apply_market_ticker():
    result = supabase.table("bot_config").select("value").eq("key", "active_market_event").execute()
    if not (result.data and result.data[0].get("value")):
        return
    import json
    event = json.loads(result.data[0]["value"])
    modifier = event.get("modifier", 1.0)
    if modifier == 1.0:
        return

    businesses = supabase.table("businesses").select("id, revenue, bank_account").eq("active", True).execute()
    for biz in (businesses.data or []):
        current = biz.get("revenue", 0)
        adjusted = int(current * modifier)
        supabase.table("businesses").update({"revenue": adjusted}).eq("id", biz["id"]).execute()


async def process_delinquency_takeovers():
    from datetime import datetime, timedelta
    cutoff = datetime.utcnow() - timedelta(days=7)
    delinquent = supabase.table("businesses").select("id, name, owner_citizenid, delinquent_since").eq("delinquent", True).lte("delinquent_since", cutoff.isoformat()).execute()
    for biz in (delinquent.data or []):
        supabase.table("businesses").update({"active": False, "ai_placeholder": True}).eq("id", biz["id"]).execute()
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "takeover",
            "context_json": {"business_id": str(biz["id"]), "business_name": biz["name"], "owner": biz.get("owner_citizenid")},
            "result": "foreclosed"
        }).execute()
