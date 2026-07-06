import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)


async def file_flight_plan(pilot_cid: str, aircraft: str, departure: str, destination: str, altitude: int = 100) -> dict:
    if not await is_enabled("flight_intercept_enabled"):
        return {"error": "Flight system disabled"}

    clearance = {
        "pilot_citizenid": pilot_cid,
        "aircraft_model": aircraft,
        "departure_location": departure,
        "destination_location": destination,
        "filed_altitude": altitude,
        "clearance_status": "pending",
        "squawk_code": "1200",
    }
    resp = supabase.table("flight_clearances").insert(clearance).execute()

    result = resp.data[0] if resp.data else clearance
    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "flight_plan_filed",
        "context_json": {"pilot": pilot_cid, "aircraft": aircraft, "route": f"{departure} -> {destination}"},
        "result": "filed"
    }).execute()

    return result


async def approve_flight_plan(clearance_id: str, cleared_by: str) -> dict:
    supabase.table("flight_clearances").update({
        "clearance_status": "approved",
        "cleared_by": cleared_by,
    }).eq("id", clearance_id).execute()

    return {"status": "approved", "clearance_id": clearance_id}


async def log_intercept_event(clearance_id: str, pilot_cid: str, aircraft: str,
                                stage_reached: int, aircraft_destroyed: bool = False,
                                pilot_ejected: bool = False, outcome: str = "intercepted") -> dict:
    now = datetime.utcnow().isoformat()
    intercept = {
        "flight_clearance_id": clearance_id,
        "pilot_citizenid": pilot_cid,
        "aircraft_model": aircraft,
        "stage_1_triggered": stage_reached >= 1,
        "stage_1_at": now if stage_reached == 1 else None,
        "stage_2_triggered": stage_reached >= 2,
        "stage_2_at": now if stage_reached == 2 else None,
        "stage_3_triggered": stage_reached >= 3,
        "stage_3_at": now if stage_reached == 3 else None,
        "stage_4_triggered": stage_reached >= 4,
        "stage_4_at": now if stage_reached == 4 else None,
        "aircraft_destroyed": aircraft_destroyed,
        "pilot_ejected": pilot_ejected,
        "outcome": outcome,
    }
    supabase.table("intercept_logs").insert(intercept).execute()

    severity = "Escalation" if stage_reached >= 4 else "Warning" if stage_reached <= 2 else "Alert"
    score = stage_reached * 6

    supabase.table("chronicle_entries").insert({
        "score": min(score, 28),
        "title": f"National Guard Intercept — Stage {stage_reached}",
        "description": f"Aircraft {aircraft} intercepted at stage {stage_reached}. Outcome: {outcome}. {severity} logged.",
        "involved_citizenids": [pilot_cid],
        "involved_discord_ids": [],
        "volume_index": 0,
    }).execute()

    return intercept


async def purchase_airspace_easement(owner_cid: str, label: str, coords: dict, radius: float = 100,
                                      altitude_max: int = 100, purpose: str = "crop_dusting") -> dict:
    if not await is_enabled("airspace_easements_enabled"):
        return {"error": "Easement system disabled"}

    easement = {
        "owner_citizenid": owner_cid,
        "label": label,
        "bounds_coords": coords,
        "radius": radius,
        "altitude_max": altitude_max,
        "purpose": purpose,
        "expires_at": (datetime.utcnow().isoformat()),
    }
    supabase.table("airspace_easements").insert(easement).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "airspace_purchased",
        "context_json": {"owner": owner_cid, "label": label, "purpose": purpose},
        "result": "completed"
    }).execute()

    return {"status": "active", "label": label, "radius": radius}


async def get_active_easements(owner_cid: str = None) -> list:
    q = supabase.table("airspace_easements").select("*").eq("active", True)
    if owner_cid:
        q = q.eq("owner_citizenid", owner_cid)
    r = q.execute()
    return r.data or []


async def get_active_clearances(pilot_cid: str = None) -> list:
    q = supabase.table("flight_clearances").select("*").eq("clearance_status", "approved")
    if pilot_cid:
        q = q.eq("pilot_citizenid", pilot_cid)
    r = q.execute()
    return r.data or []


async def get_intercept_history(pilot_cid: str = None, limit: int = 20) -> list:
    q = supabase.table("intercept_logs").select("*")
    if pilot_cid:
        q = q.eq("pilot_citizenid", pilot_cid)
    r = q.order("started_at", desc=True).limit(limit).execute()
    return r.data or []
