import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from shared.config import Config
from shared.supabase_client import get_supabase
from processor import (
    run_disparity_check,
    run_bank_audit,
    run_market_ticker,
    run_delinquency_check,
    process_payroll
)

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
