import json
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from brain import get_brain

config = Config.from_env()
supabase = get_supabase(config)
brain = get_brain(config)


async def run_weekly_self_learn():
    week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    metrics = supabase.table("kronus_metrics").select("*").gte("recorded_at", week_ago).execute()
    policies = supabase.table("kronus_policies").select("*").execute()
    economy = supabase.table("player_economy").select("cash, bank, wealth_bracket").execute()

    players = economy.data or []
    if players:
        avg_cash = sum(p.get("cash", 0) for p in players) / len(players)
        avg_bank = sum(p.get("bank", 0) for p in players) / len(players)
        brackets = {"Lower": 0, "Middle": 0, "Upper": 0}
        for p in players:
            b = p.get("wealth_bracket", "Lower")
            brackets[b] = brackets.get(b, 0) + 1
    else:
        avg_cash, avg_bank = 0, 0
        brackets = {}

    tx = supabase.table("transactions").select("amount").gte("created_at", week_ago).execute()
    tx_volume = sum(t.get("amount", 0) for t in (tx.data or []))

    active_businesses = supabase.table("businesses").select("id", count="exact").eq("active", True).execute()

    metrics_data = {
        "avg_cash": int(avg_cash),
        "avg_bank": int(avg_bank),
        "wealth_distribution": brackets,
        "tx_volume": tx_volume,
        "active_businesses": active_businesses.count if active_businesses.count else 0,
        "inflation_state": _get_inflation_status(players),
        "current_policies": {p["policy_key"]: p.get("value") for p in (policies.data or [])},
    }

    audit_result = brain.audit_economy(metrics_data)

    if audit_result:
        supabase.table("kronus_logs").insert({
            "service": "kronus-ai",
            "action": "weekly_self_learn",
            "context_json": {
                "metrics_snapshot": metrics_data,
                "policies_reviewed": len(policies.data or []),
            },
            "result": audit_result[:1000]
        }).execute()

    print(f"[kronus-ai] Weekly self-learning complete. Audit generated: {bool(audit_result)}")


def _get_inflation_status(players: list) -> str:
    if not players:
        return "stable"
    total = len(players)
    upper = sum(1 for p in players if p.get("wealth_bracket") == "Upper")
    return "inflating" if upper > total * 0.25 else "stable"
