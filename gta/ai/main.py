import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from shared.config import Config
from shared.supabase_client import get_supabase
from self_learn import run_weekly_self_learn

config = Config.from_env()
supabase = get_supabase(config)
scheduler = AsyncIOScheduler()


async def main():
    scheduler.add_job(run_weekly_self_learn, "cron", day_of_week="sun", hour=3, minute=0)

    supabase.table("kronus_logs").insert({
        "service": "kronus-ai",
        "action": "startup",
        "context_json": {"mode": "lean", "deepseek_calls": "weekly_only"},
        "result": "online"
    }).execute()

    print("[kronus-ai] Online (lean mode). Deepseek reserved for weekly audits + crisis narration only.")
    scheduler.start()

    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())
