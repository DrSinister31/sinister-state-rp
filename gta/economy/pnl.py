import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase

supabase = get_supabase()

async def send_weekly_pnl():
    businesses = supabase.table("businesses").select("id, owner_citizenid, name, business_type, bank_account, revenue, active").eq("active", True).execute()
    week_start = (datetime.utcnow() - timedelta(days=7)).strftime("%Y-%m-%d")
    today = datetime.utcnow().strftime("%Y-%m-%d")

    for biz in (businesses.data or []):
        txs = supabase.table("transactions").select("amount, reason").eq("business_id", biz["id"]).gte("created_at", week_start).execute()
        revenue = sum(t["amount"] for t in (txs.data or []) if "expense" not in (t.get("reason") or ""))
        expenses = sum(t["amount"] for t in (txs.data or []) if "expense" in (t.get("reason") or ""))
        profit = revenue - expenses
        balance = biz.get("bank_account", 0)

        supabase.table("business_pnl").insert({
            "business_id": biz["id"],
            "period_start": week_start,
            "period_end": today,
            "gross_income": revenue,
            "total_expenses": expenses,
            "net_profit": profit,
            "employee_count": 0,
            "ai_employee_count": 0,
            "revenue_breakdown": {"total": revenue},
            "expense_breakdown": {"total": expenses},
        }).execute()

        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "weekly_pnl",
            "context_json": {
                "business_id": str(biz["id"]),
                "business_name": biz["name"],
                "revenue": revenue,
                "expenses": expenses,
                "profit": profit,
                "balance": balance,
            },
            "result": "completed"
        }).execute()
