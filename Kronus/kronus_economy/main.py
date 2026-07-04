import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from shared.config import Config
from shared.supabase_client import get_supabase
from toggles import is_enabled as _tk_enabled

from processor import (
    run_disparity_check,
    run_bank_audit,
    run_market_ticker,
    run_delinquency_check,
    process_payroll,
    apply_market_ticker,
    process_delinquency_takeovers,
)
from expenses import bill_weekly_expenses
from pnl import send_weekly_pnl
from ai_density import run_ai_density_update
from perks import run_wealth_perks

config = Config.from_env()
supabase = get_supabase(config)
scheduler = AsyncIOScheduler()


async def process_transaction(from_cid: str, to_cid: str, amount: int, account_type: str, reason: str = ""):
    supabase.table("transactions").insert({
        "from_citizenid": from_cid,
        "to_citizenid": to_cid,
        "amount": amount,
        "account_type": account_type,
        "reason": reason,
        "channel": "transfer"
    }).execute()


async def main():
    scheduler.add_job(run_disparity_check, "interval", minutes=5)
    scheduler.add_job(run_bank_audit, "interval", minutes=15)
    scheduler.add_job(run_market_ticker, "interval", minutes=30)
    scheduler.add_job(run_delinquency_check, "interval", hours=6)
    scheduler.add_job(process_payroll, "cron", minute=0)
    scheduler.add_job(apply_market_ticker, "interval", minutes=30)
    scheduler.add_job(process_delinquency_takeovers, "interval", hours=12)
    scheduler.add_job(bill_weekly_expenses, "cron", day_of_week="sun", hour=0)
    scheduler.add_job(send_weekly_pnl, "cron", day_of_week="sun", hour=1)
    scheduler.add_job(run_ai_density_update, "interval", minutes=5)
    scheduler.add_job(run_wealth_perks, "interval", hours=6)

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "startup",
        "context_json": {},
        "result": "online"
    }).execute()

    print("[kronus-economy] Online. Economy engine running.")
    scheduler.start()

    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())
