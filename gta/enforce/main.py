import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from shared.config import Config
from shared.supabase_client import get_supabase
from auto_ban import run_auto_escalation

config = Config.from_env()
supabase = get_supabase(config)
scheduler = AsyncIOScheduler()


async def issue_strike(citizenid: str, discord_id: int, violation: str, moderator_id: str,
                       fine_amount: int = 0):
    result = supabase.table("strikes").select("strike_count").eq("citizenid", citizenid).execute()
    counts = [r.get("strike_count", 0) for r in (result.data or [])]
    current_count = max(counts) if counts else 0
    new_count = current_count + 1

    supabase.table("strikes").insert({
        "citizenid": citizenid,
        "discord_id": discord_id,
        "violation": violation,
        "strike_count": new_count,
        "fine_amount": fine_amount,
        "moderator_id": moderator_id
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-enforce",
        "action": "strike",
        "context_json": {
            "citizenid": citizenid,
            "violation": violation,
            "strike_count": new_count
        },
        "result": f"strike_{new_count}"
    }).execute()


async def issue_ban(citizenid: str, discord_id: int, reason: str, moderator_id: str, duration: str = "perm"):
    supabase.table("bans").insert({
        "citizenid": citizenid,
        "discord_id": discord_id,
        "reason": reason,
        "moderator_id": moderator_id,
        "duration": duration,
        "active": True
    }).execute()

    supabase.table("rcon_commands").insert({
        "command": f"say [KRONUS ENFORCEMENT] {citizenid} has been banned: {reason}",
        "source": "kronus-enforce",
        "status": "pending"
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-enforce",
        "action": "ban",
        "context_json": {
            "citizenid": citizenid,
            "reason": reason,
            "duration": duration
        },
        "result": "applied"
    }).execute()


async def main():
    scheduler.add_job(run_auto_escalation, "interval", hours=1)
    scheduler.start()

    supabase.table("kronus_logs").insert({
        "service": "kronus-enforce",
        "action": "startup",
        "context_json": {},
        "result": "online"
    }).execute()

    print("[kronus-enforce] Online. Enforcement engine running.")

    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())
