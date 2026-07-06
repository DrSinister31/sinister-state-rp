import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import random
import json
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

EVENT_POOL = {
    "police": [
        {"title": "Armed Robbery", "desc": "Silent alarm triggered. Armed suspects reported.", "base_score": 18, "urgency": "high"},
        {"title": "Vehicle Pursuit", "desc": "High-speed chase in progress. Suspect vehicle fleeing.", "base_score": 15, "urgency": "high"},
        {"title": "Officer Down", "desc": "10-33. Officer requires immediate backup.", "base_score": 25, "urgency": "critical"},
        {"title": "Shots Fired", "desc": "Multiple gunshots reported. Units dispatched.", "base_score": 16, "urgency": "high"},
        {"title": "Hostage Situation", "desc": "Barricaded suspect holding hostages. SWAT requested.", "base_score": 27, "urgency": "critical"},
        {"title": "Street Racing", "desc": "Illegal street racing reported. Multiple vehicles involved.", "base_score": 10, "urgency": "medium"},
        {"title": "Domestic Disturbance", "desc": "Noise complaint escalated. Units en route.", "base_score": 8, "urgency": "low"},
        {"title": "Drug Deal in Progress", "desc": "Narcotics transaction observed. Plainclothes responding.", "base_score": 12, "urgency": "medium"},
        {"title": "Bank Alarm", "desc": "Fleeca Bank silent alarm triggered. All units respond.", "base_score": 22, "urgency": "critical"},
        {"title": "Stolen Vehicle", "desc": "Vehicle theft reported. BOLO issued.", "base_score": 9, "urgency": "low"},
    ],
    "ems": [
        {"title": "Cardiac Arrest", "desc": "Medical emergency. CPR in progress.", "base_score": 14, "urgency": "high"},
        {"title": "Multi-Vehicle Collision", "desc": "MVC with injuries. Multiple ambulances requested.", "base_score": 16, "urgency": "high"},
        {"title": "Industrial Accident", "desc": "Worker injured at industrial site. Heavy rescue needed.", "base_score": 13, "urgency": "medium"},
        {"title": "Overdose", "desc": "Possible drug overdose. Narcan administered.", "base_score": 11, "urgency": "medium"},
        {"title": "Structure Fire", "desc": "Residential fire reported. Fire & Rescue dispatched.", "base_score": 20, "urgency": "critical"},
    ],
    "criminal": [
        {"title": "Chop Shop Drop", "desc": "Hot vehicle delivered to chop shop. Boost crew active.", "base_score": 10, "urgency": "medium"},
        {"title": "Drug Shipment Incoming", "desc": "Large narcotics shipment arriving at docks. Cartel involved.", "base_score": 18, "urgency": "high"},
        {"title": "Arms Deal", "desc": "Illegal weapons transaction scheduled. High-risk trade.", "base_score": 22, "urgency": "critical"},
        {"title": "Gang Turf War", "desc": "Territory dispute escalating. Rival gangs clashing.", "base_score": 24, "urgency": "critical"},
        {"title": "Prison Break", "desc": "Convict escaped custody. Manhunt underway.", "base_score": 26, "urgency": "critical"},
    ],
    "environment": [
        {"title": "Hurricane Warning", "desc": "Severe weather approaching. Citizens advised to shelter.", "base_score": 15, "urgency": "high"},
        {"title": "Oil Spill", "desc": "Ron Oil pipeline ruptured. Environmental hazard declared.", "base_score": 12, "urgency": "medium"},
        {"title": "Labor Strike", "desc": "Union workers walking off. Port operations halted.", "base_score": 8, "urgency": "low"},
        {"title": "Power Outage", "desc": "Regional blackout. Backup generators failing.", "base_score": 10, "urgency": "medium"},
    ],
}

LOCATIONS = [
    {"zone": "Downtown Houston", "coords": [-540, -212]},
    {"zone": "Davis Ave", "coords": [150, -1300]},
    {"zone": "Cypress Flats", "coords": [900, -2300]},
    {"zone": "Mirror Park", "coords": [1100, -700]},
    {"zone": "Terminal Docks", "coords": [1300, -3100]},
    {"zone": "Sandy Shores", "coords": [2400, 3100]},
    {"zone": "Paleto Bay", "coords": [-440, 6000]},
    {"zone": "Vespucci Beach", "coords": [-1300, -1400]},
    {"zone": "Fort Zancudo", "coords": [-2200, 3250]},
    {"zone": "Grapevine", "coords": [1700, 4900]},
]


async def generate_dispatch_events():
    if not await is_enabled("dispatch_events_enabled"):
        return

    player_count = supabase.table("characters").select("citizenid", count="exact").eq("active", True).execute()
    online = player_count.count if player_count else 0

    event_count = max(1, min(4, online // 8))
    generated = []

    for _ in range(event_count):
        category = random.choices(
            ["police", "ems", "criminal", "environment"],
            weights=[0.35, 0.20, 0.25, 0.20],
            k=1
        )[0]

        pool = EVENT_POOL[category]
        event_template = random.choice(pool)
        location = random.choice(LOCATIONS)

        score = event_template["base_score"] + random.randint(-2, 3)
        score = max(1, min(30, score))

        entry = {
            "score": score,
            "title": f"[{category.upper()}] {event_template['title']}",
            "description": f"{event_template['desc']} Location: {location['zone']}. Urgency: {event_template['urgency']}.",
            "involved_citizenids": [],
            "involved_discord_ids": [],
            "volume_index": online,
        }

        supabase.table("chronicle_entries").insert(entry).execute()
        generated.append(entry)

    if generated:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "dispatch_events_generated",
            "context_json": {"events": len(generated), "players_online": online},
            "result": "completed"
        }).execute()


async def run_mission_cycle():
    if not await is_enabled("mission_system_enabled"):
        return

    await generate_dispatch_events()

    active_missions = supabase.table("chronicle_entries").select("id, score, title").gte("score", 15).order("created_at", desc=True).limit(10).execute()
    crisis_count = sum(1 for m in (active_missions.data or []) if m.get("score", 0) >= 23)

    if crisis_count > 0:
        supabase.table("kronus_metrics").insert({
            "metric_name": "active_crises",
            "value": float(crisis_count),
            "metadata_json": {"crisis_missions": crisis_count},
            "recorded_at": datetime.utcnow().isoformat()
        }).execute()
