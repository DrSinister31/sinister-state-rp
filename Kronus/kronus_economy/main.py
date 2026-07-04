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
from ai_density import run_ai_density_update, run_ai_worth_ratio
from perks import run_wealth_perks
from ai_business import run_ai_business_check
from taxation import collect_income_tax, collect_business_tax, collect_sales_tax
from budget import allocate_city_budget
from tax_report import generate_weekly_tax_report, format_tax_report_embed
from drugs import apply_drug_xp_decay
from arms import rotate_arms_stock
from chopshop import decay_chop_heat
from fronts import run_front_audit_check
from gangs import process_gang_income
from tariffs import update_luxury_tariffs
from missions import generate_dispatch_events, run_mission_cycle
from government import run_election_cycle
from payroll import run_universal_payroll
from job_sync import sync_jobs_to_supabase
from housing import process_insurance_renewals
from auctions import generate_luxury_auctions, close_expired_auctions
from hijacking import generate_trailer_contract


async def weekly_tax_discord_report():
    report = await generate_weekly_tax_report()
    embed = format_tax_report_embed(report)

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "weekly_tax_report",
        "context_json": {"report": report, "embed": embed},
        "result": "generated"
    }).execute()

    supabase.table("chronicle_entries").insert({
        "score": 20,
        "title": embed["title"],
        "description": embed["description"],
        "involved_citizenids": [],
        "involved_discord_ids": [],
        "volume_index": 0
    }).execute()

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
    scheduler.add_job(run_ai_worth_ratio, "interval", minutes=15)
    scheduler.add_job(run_wealth_perks, "interval", hours=6)
    scheduler.add_job(run_ai_business_check, "interval", hours=1)
    scheduler.add_job(collect_income_tax, "interval", hours=1)
    scheduler.add_job(collect_business_tax, "interval", hours=2)
    scheduler.add_job(collect_sales_tax, "interval", hours=1)
    scheduler.add_job(allocate_city_budget, "interval", hours=6)
    scheduler.add_job(weekly_tax_discord_report, "cron", day_of_week="sun", hour=2)
    scheduler.add_job(apply_drug_xp_decay, "interval", hours=24)
    scheduler.add_job(rotate_arms_stock, "interval", hours=2)
    scheduler.add_job(decay_chop_heat, "interval", hours=1)
    scheduler.add_job(run_front_audit_check, "interval", hours=6)
    scheduler.add_job(process_gang_income, "interval", hours=1)
    scheduler.add_job(update_luxury_tariffs, "interval", hours=1)
    scheduler.add_job(run_mission_cycle, "interval", minutes=15)
    scheduler.add_job(run_election_cycle, "interval", hours=6)
    scheduler.add_job(run_universal_payroll, "cron", minute=30)
    scheduler.add_job(sync_jobs_to_supabase, "interval", hours=6)
    scheduler.add_job(process_insurance_renewals, "interval", hours=6)
    scheduler.add_job(generate_luxury_auctions, "interval", hours=4)
    scheduler.add_job(close_expired_auctions, "interval", hours=1)
    scheduler.add_job(generate_trailer_contract, "interval", minutes=45)

    await sync_jobs_to_supabase()

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
