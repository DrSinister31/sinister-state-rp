import random
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)


FRONT_COVER_TYPES = [
    "Laundromat",
    "Vape Shop",
    "Used Car Lot",
    "Pawn Shop", 
    "Check Cashing",
    "Smoke Shop",
    "Massage Parlor",
    "Gentleman's Club",
    "Arcade",
    "Storage Units",
]


async def mask_business_as_front(business_id: str, cover_type: str = None) -> dict:
    if not await is_enabled("criminal_fronts_enabled"):
        return {"error": "Front masking disabled"}

    biz = supabase.table("businesses").select("id, name, revenue, bank_account").eq("id", business_id).execute()
    if not biz.data:
        return {"error": "Business not found"}

    b = biz.data[0]
    cover = cover_type or random.choice(FRONT_COVER_TYPES)
    real_revenue = b.get("revenue", 0) or 0
    masked_revenue = int(real_revenue * random.uniform(0.3, 0.6))

    supabase.table("businesses").update({
        "front_name": cover,
        "front_masked": True,
        "front_real_revenue": real_revenue,
    }).eq("id", business_id).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "front_masked",
        "context_json": {
            "business_id": str(business_id),
            "business_name": b.get("name"),
            "cover_type": cover,
            "real_revenue": real_revenue,
            "masked_revenue": masked_revenue,
        },
        "result": "completed"
    }).execute()

    return {
        "business_name": b.get("name"),
        "cover_type": cover,
        "real_revenue": real_revenue,
        "masked_revenue": masked_revenue,
    }


async def calculate_front_audit_risk(business_id: str) -> dict:
    biz = supabase.table("businesses").select("id, name, revenue, front_masked, front_real_revenue").eq("id", business_id).execute()
    if not biz.data:
        return {"error": "Not found"}

    b = biz.data[0]
    if not b.get("front_masked"):
        return {"risk": 0, "status": "clean"}

    real = b.get("front_real_revenue", 0) or 0
    declared = b.get("revenue", 0) or 0
    ratio = declared / max(real, 1)
    risk = max(0, int((1 - ratio) * 100))
    status = "safe" if risk < 30 else "suspicious" if risk < 60 else "critical"

    return {
        "business_name": b.get("name"),
        "risk_pct": risk,
        "status": status,
        "real_revenue": real,
        "declared_revenue": declared,
    }


async def run_front_audit_check():
    if not await is_enabled("criminal_fronts_enabled"):
        return

    fronts = supabase.table("businesses").select("id, name, revenue, front_masked, front_real_revenue").eq("front_masked", True).execute()
    critical = 0

    for f in (fronts.data or []):
        risk = await calculate_front_audit_risk(f["id"])
        if risk.get("status") == "critical":
            critical += 1
            supabase.table("kronus_logs").insert({
                "service": "kronus-economy",
                "action": "front_audit_alert",
                "context_json": risk,
                "result": "critical_risk"
            }).execute()

    if critical > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "front_audit_round",
            "context_json": {"fronts_checked": len(fronts.data or []), "critical": critical},
            "result": "completed"
        }).execute()
