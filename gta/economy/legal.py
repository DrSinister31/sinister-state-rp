import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import json
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

CASE_TYPES = ["Criminal", "Civil", "Traffic", "Family", "Appeal"]
CASE_STATUSES = ["Filed", "Pending", "Active", "Deliberating", "Verdict Reached", "Appealed", "Closed"]


async def create_case(
    case_type: str,
    title: str,
    description: str,
    plaintiff_citizenid: str = None,
    defendant_citizenid: str = None,
    presiding_judge_cid: str = None,
    prosecutor_cid: str = None,
    defense_counsel_cid: str = None,
) -> dict:
    if not await is_enabled("court_system_enabled"):
        return {"error": "Court system disabled"}

    if case_type not in CASE_TYPES:
        return {"error": f"Invalid case type. Must be one of: {CASE_TYPES}"}

    case_data = {
        "case_type": case_type,
        "title": title,
        "description": description,
        "status": "Filed",
        "plaintiff_citizenid": plaintiff_citizenid,
        "defendant_citizenid": defendant_citizenid,
        "presiding_judge_cid": presiding_judge_cid,
        "prosecutor_cid": prosecutor_cid,
        "defense_counsel_cid": defense_counsel_cid,
        "filed_at": datetime.utcnow().isoformat(),
        "docket_number": f"TX-{datetime.utcnow().strftime('%Y')}-{datetime.utcnow().strftime('%j')}-{case_type[:3].upper()}",
    }

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "court_case_filed",
        "context_json": case_data,
        "result": "filed"
    }).execute()

    supabase.table("chronicle_entries").insert({
        "score": 12,
        "title": f"Court Case Filed: {title}",
        "description": f"Case Type: {case_type}. Docket: {case_data['docket_number']}. {description[:200]}",
        "involved_citizenids": [x for x in [plaintiff_citizenid, defendant_citizenid] if x],
        "involved_discord_ids": [],
        "volume_index": 0,
    }).execute()

    return case_data


async def update_case_status(docket_number: str, new_status: str, updated_by: str) -> dict:
    if new_status not in CASE_STATUSES:
        return {"error": f"Invalid status. Must be one of: {CASE_STATUSES}"}

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "court_case_updated",
        "context_json": {
            "docket": docket_number,
            "status": new_status,
            "updated_by": updated_by,
        },
        "result": "updated"
    }).execute()

    return {"docket": docket_number, "status": new_status}


async def issue_verdict(
    docket_number: str,
    verdict: str,
    sentence: str = None,
    fine: int = 0,
    jail_time_days: int = 0,
    judge_citizenid: str = None,
) -> dict:
    if not await is_enabled("court_system_enabled"):
        return {"error": "Court system disabled"}

    result = {
        "docket": docket_number,
        "verdict": verdict,
        "sentence": sentence,
        "fine": fine,
        "jail_time_days": jail_time_days,
        "issued_by": judge_citizenid,
        "issued_at": datetime.utcnow().isoformat(),
    }

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "verdict_issued",
        "context_json": result,
        "result": verdict
    }).execute()

    score = 18
    if fine > 100000 or jail_time_days > 30:
        score = 24

    supabase.table("chronicle_entries").insert({
        "score": score,
        "title": f"Verdict Reached: {docket_number}",
        "description": f"Verdict: {verdict}. Fine: ${fine:,}. Jail: {jail_time_days} days. {sentence or ''}"[:300],
        "involved_citizenids": [judge_citizenid] if judge_citizenid else [],
        "involved_discord_ids": [],
        "volume_index": 0,
    }).execute()

    return result


async def get_court_docket(status: str = None) -> list:
    r = supabase.table("kronus_logs").select("*").eq("action", "court_case_filed").order("created_at", desc=True).limit(50).execute()
    cases = []
    for entry in (r.data or []):
        ctx = entry.get("context_json", {})
        if isinstance(ctx, str):
            ctx = json.loads(ctx)
        if status and ctx.get("status") != status:
            continue
        cases.append(ctx)
    return cases


async def get_public_defender_case_load() -> list:
    defenders = supabase.table("characters").select("citizenid, first_name, last_name").eq("job_name", "publicdefender").eq("active", True).execute()
    result = []
    for d in (defenders.data or []):
        cid = d["citizenid"]
        cases = supabase.table("kronus_logs").select("context_json", count="exact").eq("action", "court_case_filed").contains("context_json", {"defense_counsel_cid": cid}).execute()
        result.append({
            "name": f"{d.get('first_name','')} {d.get('last_name','')}".strip(),
            "citizenid": cid,
            "case_count": cases.count if cases else 0,
        })
    return result
