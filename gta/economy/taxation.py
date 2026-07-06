import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import json
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

INCOME_TAX_BRACKETS = [
    {"min": 0, "max": 50000, "rate": 0.05},
    {"min": 50001, "max": 150000, "rate": 0.10},
    {"min": 150001, "max": 500000, "rate": 0.18},
    {"min": 500001, "max": 2000000, "rate": 0.25},
    {"min": 2000001, "max": float("inf"), "rate": 0.32},
]

BUSINESS_TAX_RATE = 0.08
SALES_TAX_RATE = 0.06


async def collect_income_tax():
    if not await is_enabled("income_tax_enabled"):
        return

    players = supabase.table("player_economy").select("citizenid, cash, bank").execute()
    total_collected = 0
    count = 0

    for p in (players.data or []):
        total_wealth = (p.get("cash", 0) or 0) + (p.get("bank", 0) or 0)
        if total_wealth <= 5000:
            continue

        bracket = None
        for b in INCOME_TAX_BRACKETS:
            if total_wealth >= b["min"] and total_wealth <= b["max"]:
                bracket = b
                break
        if not bracket:
            continue

        tax = int(total_wealth * bracket["rate"] * 0.01)
        if tax < 1:
            continue

        cid = p["citizenid"]
        bank_balance = p.get("bank", 0) or 0
        cash_balance = p.get("cash", 0) or 0

        if bank_balance >= tax:
            supabase.rpc("add_funds", {"p_citizenid": cid, "p_amount": -tax, "p_account": "bank"}).execute()
        elif cash_balance >= tax:
            supabase.rpc("add_funds", {"p_citizenid": cid, "p_amount": -tax, "p_account": "cash"}).execute()
        else:
            combined = cash_balance + bank_balance
            if combined >= tax:
                if bank_balance > 0:
                    supabase.rpc("add_funds", {"p_citizenid": cid, "p_amount": -bank_balance, "p_account": "bank"}).execute()
                remaining = tax - bank_balance
                if remaining > 0:
                    supabase.rpc("add_funds", {"p_citizenid": cid, "p_amount": -remaining, "p_account": "cash"}).execute()

        supabase.table("tax_transactions").insert({
            "citizenid": cid,
            "tax_type": "income",
            "amount": tax,
            "fund_name": "general_fund",
            "collected_at": datetime.utcnow().isoformat()
        }).execute()

        treasury = supabase.table("city_treasury").select("balance").eq("fund_name", "general_fund").execute()
        current = (treasury.data[0]["balance"] if treasury.data else 0) or 0
        supabase.table("city_treasury").update({"balance": current + tax, "last_updated": datetime.utcnow().isoformat()}).eq("fund_name", "general_fund").execute()

        total_collected += tax
        count += 1

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "income_tax_collected",
        "context_json": {"players_taxed": count, "total_collected": total_collected},
        "result": "completed"
    }).execute()


async def collect_business_tax():
    if not await is_enabled("business_tax_enabled"):
        return

    businesses = supabase.table("businesses").select("id, name, owner_citizenid, revenue, bank_account").eq("active", True).execute()
    total_collected = 0
    count = 0

    for biz in (businesses.data or []):
        revenue = biz.get("revenue", 0) or 0
        if revenue <= 0:
            continue

        tax = int(revenue * BUSINESS_TAX_RATE * 0.01)
        if tax < 1:
            continue

        bank = biz.get("bank_account", 0) or 0
        if bank >= tax:
            supabase.table("businesses").update({"bank_account": bank - tax}).eq("id", biz["id"]).execute()
        else:
            tax = bank
            if tax <= 0:
                continue
            supabase.table("businesses").update({"bank_account": 0}).eq("id", biz["id"]).execute()

        supabase.table("tax_transactions").insert({
            "citizenid": biz["owner_citizenid"],
            "business_id": str(biz["id"]),
            "tax_type": "business",
            "amount": tax,
            "fund_name": "general_fund",
            "collected_at": datetime.utcnow().isoformat()
        }).execute()

        treasury = supabase.table("city_treasury").select("balance").eq("fund_name", "general_fund").execute()
        current = (treasury.data[0]["balance"] if treasury.data else 0) or 0
        supabase.table("city_treasury").update({"balance": current + tax, "last_updated": datetime.utcnow().isoformat()}).eq("fund_name", "general_fund").execute()

        total_collected += tax
        count += 1

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "business_tax_collected",
        "context_json": {"businesses_taxed": count, "total_collected": total_collected},
        "result": "completed"
    }).execute()


async def collect_sales_tax():
    if not await is_enabled("sales_tax_enabled"):
        return

    now = datetime.utcnow()
    hour_ago = (now.replace(minute=0, second=0, microsecond=0)).isoformat()

    transactions = supabase.table("transactions").select("id, amount, from_citizenid, channel").gte("created_at", hour_ago).neq("channel", "payroll").neq("channel", "tax").execute()
    total_collected = 0
    count = 0

    for tx in (transactions.data or []):
        amount = tx.get("amount", 0) or 0
        if amount <= 0:
            continue

        tax = int(amount * SALES_TAX_RATE)
        if tax < 1:
            continue

        supabase.table("tax_transactions").insert({
            "citizenid": tx.get("from_citizenid"),
            "tax_type": "sales",
            "amount": tax,
            "fund_name": "general_fund",
            "collected_at": datetime.utcnow().isoformat()
        }).execute()

        treasury = supabase.table("city_treasury").select("balance").eq("fund_name", "general_fund").execute()
        current = (treasury.data[0]["balance"] if treasury.data else 0) or 0
        supabase.table("city_treasury").update({"balance": current + tax, "last_updated": datetime.utcnow().isoformat()}).eq("fund_name", "general_fund").execute()

        total_collected += tax
        count += 1

    if count > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "sales_tax_collected",
            "context_json": {"transactions_taxed": count, "total_collected": total_collected},
            "result": "completed"
        }).execute()
