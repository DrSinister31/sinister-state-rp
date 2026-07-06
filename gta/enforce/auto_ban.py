import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config

config = Config.from_env()
supabase = get_supabase(config)


async def run_auto_escalation():
    strikes = supabase.table("strikes").select("citizenid, discord_id, strike_count, created_at").execute()
    if not strikes.data:
        return

    threshold = await _get_config("ban_strike_threshold", 3)
    recent = datetime.utcnow() - timedelta(hours=72)

    for entry in strikes.data:
        count = entry.get("strike_count", 0)
        if count >= threshold:
            ban_result = supabase.table("bans").select("id").eq("citizenid", entry["citizenid"]).eq("active", True).execute()
            if ban_result.data:
                continue

            reason = f"Auto-ban: {count} strikes accumulated"
            supabase.table("bans").insert({
                "citizenid": entry["citizenid"],
                "discord_id": entry.get("discord_id"),
                "reason": reason,
                "moderator_id": "kronus",
                "duration": "perm",
                "active": True
            }).execute()

            supabase.table("rcon_commands").insert({
                "command": f"say [KRONUS] Player {entry['citizenid']} has been auto-banned for {count} strikes.",
                "source": "kronus-enforce",
                "status": "pending"
            }).execute()

            supabase.table("kronus_logs").insert({
                "service": "kronus-enforce",
                "action": "auto_ban",
                "context_json": {
                    "citizenid": entry["citizenid"],
                    "strike_count": count,
                    "threshold": threshold
                },
                "result": "banned"
            }).execute()


async def _get_config(key: str, default: int) -> int:
    result = supabase.table("bot_config").select("value").eq("key", key).execute()
    if result.data:
        return int(result.data[0]["value"])
    supabase.table("bot_config").insert({"key": key, "value": str(default)}).execute()
    return default
