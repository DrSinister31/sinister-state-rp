import json
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

MAYOR_TERM_DAYS = 14
MIN_WEALTH_TO_RUN = 50000
ELECTION_CANDIDATE_MAX = 10


async def get_current_mayor() -> dict | None:
    r = supabase.table("bot_config").select("value").eq("key", "current_mayor").execute()
    if not r.data:
        return None
    try:
        return json.loads(r.data[0]["value"])
    except:
        return None


async def is_election_active() -> bool:
    r = supabase.table("bot_config").select("value").eq("key", "election_active").execute()
    if not r.data:
        return False
    return r.data[0]["value"].lower() == "true"


async def register_candidate(citizenid: str) -> dict:
    if not await is_enabled("mayor_elections_enabled"):
        return {"error": "Elections disabled"}

    if not await is_election_active():
        return {"error": "No active election"}

    r = supabase.table("bot_config").select("value").eq("key", "election_candidates").execute()
    candidates = json.loads(r.data[0]["value"]) if r.data else []

    if citizenid in [c.get("citizenid") for c in candidates]:
        return {"error": "Already registered"}

    if len(candidates) >= ELECTION_CANDIDATE_MAX:
        return {"error": "Candidate list full"}

    econ = supabase.table("player_economy").select("cash, bank").eq("citizenid", citizenid).execute()
    worth = 0
    if econ.data:
        worth = (econ.data[0].get("cash", 0) or 0) + (econ.data[0].get("bank", 0) or 0)

    if worth < MIN_WEALTH_TO_RUN:
        return {"error": f"Need ${MIN_WEALTH_TO_RUN:,} to run"}

    char = supabase.table("characters").select("first_name, last_name").eq("citizenid", citizenid).execute()
    name = "Unknown"
    if char.data:
        name = f"{char.data[0].get('first_name', '')} {char.data[0].get('last_name', '')}".strip()

    candidates.append({"citizenid": citizenid, "name": name, "registered_at": datetime.utcnow().isoformat()})
    supabase.table("bot_config").upsert({
        "key": "election_candidates",
        "value": json.dumps(candidates),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    return {"status": "registered", "name": name}


async def cast_vote(voter_citizenid: str, candidate_citizenid: str) -> dict:
    if not await is_enabled("mayor_elections_enabled"):
        return {"error": "Elections disabled"}

    if not await is_election_active():
        return {"error": "No active election"}

    r = supabase.table("bot_config").select("value").eq("key", "election_votes").execute()
    votes = json.loads(r.data[0]["value"]) if r.data else {}

    r2 = supabase.table("bot_config").select("value").eq("key", "election_candidates").execute()
    candidates = json.loads(r2.data[0]["value"]) if r2.data else []
    valid_cids = [c["citizenid"] for c in candidates]

    if candidate_citizenid not in valid_cids:
        return {"error": "Not a valid candidate"}

    votes[voter_citizenid] = candidate_citizenid
    supabase.table("bot_config").upsert({
        "key": "election_votes",
        "value": json.dumps(votes),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    return {"status": "vote_cast", "total_votes": len(votes)}


async def start_election() -> dict:
    if not await is_enabled("mayor_elections_enabled"):
        return {"error": "Elections disabled"}

    supabase.table("bot_config").upsert({
        "key": "election_active",
        "value": "true",
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("bot_config").upsert({
        "key": "election_candidates",
        "value": "[]",
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("bot_config").upsert({
        "key": "election_votes",
        "value": "{}",
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "election_started",
        "context_json": {"started_at": datetime.utcnow().isoformat()},
        "result": "active"
    }).execute()

    return {"status": "election_started"}


async def end_election() -> dict:
    r = supabase.table("bot_config").select("value").eq("key", "election_votes").execute()
    votes = json.loads(r.data[0]["value"]) if r.data else {}

    tally = {}
    for voter, candidate in votes.items():
        tally[candidate] = tally.get(candidate, 0) + 1

    winner_cid = max(tally, key=tally.get) if tally else None
    winner_name = "Nobody"

    if winner_cid:
        r2 = supabase.table("bot_config").select("value").eq("key", "election_candidates").execute()
        candidates = json.loads(r2.data[0]["value"]) if r2.data else []
        for c in candidates:
            if c["citizenid"] == winner_cid:
                winner_name = c["name"]
                break

    mayor = {
        "citizenid": winner_cid,
        "name": winner_name,
        "elected_at": datetime.utcnow().isoformat(),
        "term_ends": (datetime.utcnow() + timedelta(days=MAYOR_TERM_DAYS)).isoformat(),
        "total_votes": len(votes),
        "tally": tally,
    }

    supabase.table("bot_config").upsert({
        "key": "current_mayor",
        "value": json.dumps(mayor),
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("bot_config").upsert({
        "key": "election_active",
        "value": "false",
        "updated_at": datetime.utcnow().isoformat()
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "election_ended",
        "context_json": mayor,
        "result": "completed"
    }).execute()

    supabase.table("chronicle_entries").insert({
        "score": 22,
        "title": "Mayor Elected",
        "description": f"{winner_name} won the mayoral election with {tally.get(winner_cid, 0)} votes out of {len(votes)} cast.",
        "involved_citizenids": [winner_cid] if winner_cid else [],
        "involved_discord_ids": [],
        "volume_index": len(votes),
    }).execute()

    return mayor


async def mayor_set_budget(fund_name: str, percentage: float, mayor_citizenid: str) -> dict:
    mayor = await get_current_mayor()
    if not mayor or mayor.get("citizenid") != mayor_citizenid:
        return {"error": "Not the mayor"}

    supabase.table("city_budget_allocations").update({
        "mayor_set_percentage": percentage,
        "last_modified_by": mayor_citizenid,
        "modified_at": datetime.utcnow().isoformat(),
    }).eq("fund_name", fund_name).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "mayor_budget_adjusted",
        "context_json": {
            "fund": fund_name,
            "new_pct": percentage,
            "mayor": mayor_citizenid,
        },
        "result": "completed"
    }).execute()

    return {"fund": fund_name, "percentage": percentage}


async def get_election_results() -> dict:
    active = await is_election_active()
    r = supabase.table("bot_config").select("value").eq("key", "election_candidates").execute()
    candidates = json.loads(r.data[0]["value"]) if r.data else []

    r2 = supabase.table("bot_config").select("value").eq("key", "election_votes").execute()
    votes = json.loads(r2.data[0]["value"]) if r2.data else {}

    tally = {}
    for _, candidate in votes.items():
        tally[candidate] = tally.get(candidate, 0) + 1

    current_mayor = await get_current_mayor()

    return {
        "active": active,
        "candidates": len(candidates),
        "candidate_list": candidates,
        "total_votes": len(votes),
        "tally": tally,
        "current_mayor": current_mayor,
    }


async def run_election_cycle():
    if not await is_enabled("mayor_elections_enabled"):
        return

    mayor = await get_current_mayor()
    if mayor:
        term_ends = datetime.fromisoformat(mayor.get("term_ends", ""))
        if datetime.utcnow() < term_ends:
            return

    active = await is_election_active()
    if not active:
        await start_election()
        return

    election_data = supabase.table("bot_config").select("value").eq("key", "election_votes").execute()
    started_at = datetime.utcnow() - timedelta(days=3)
    if datetime.utcnow() > started_at + timedelta(days=3):
        await end_election()
