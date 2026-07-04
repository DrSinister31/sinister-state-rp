import json
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

AUTO_APPROVE_THRESHOLDS = {
    "min_total_revenue": 5000,
    "min_deliveries": 10,
    "max_firings": 2,
}


async def process_job_application(applicant_citizenid: str, target_job: str = None, target_business_id: str = None) -> dict:
    if not await is_enabled("job_auto_apply_enabled"):
        return {"error": "Auto-apply disabled"}

    char = supabase.table("characters").select("first_name, last_name, job_name, job_grade").eq("citizenid", applicant_citizenid).execute()
    char_data = char.data[0] if char.data else {}

    econ = supabase.table("player_economy").select("cash, bank, wealth_bracket").eq("citizenid", applicant_citizenid).execute()
    econ_data = econ.data[0] if econ.data else {}

    txs = supabase.table("transactions").select("reason", count="exact").eq("from_citizenid", applicant_citizenid).execute()
    total_transactions = txs.count if txs else 0

    deliveries = supabase.table("transactions").select("reason", count="exact").eq("from_citizenid", applicant_citizenid).ilike("reason", "%delivery%").execute()
    delivery_count = deliveries.count if deliveries else 0

    total_raw = supabase.table("transactions").select("amount").eq("to_citizenid", applicant_citizenid).execute()
    total_revenue = sum((t.get("amount", 0) or 0) for t in (total_raw.data or []))

    firing_count = 0
    try:
        firings = supabase.table("transactions").select("reason", count="exact").eq("from_citizenid", applicant_citizenid).ilike("reason", "%fired%").execute()
        firing_count = firings.count if firings else 0
    except:
        pass

    criminal = supabase.table("criminal_records").select("charge", count="exact").eq("citizenid", applicant_citizenid).execute()
    criminal_count = criminal.count if criminal else 0

    metrics = {
        "character_name": f"{char_data.get('first_name', '')} {char_data.get('last_name', '')}".strip(),
        "current_job": char_data.get("job_name", "Unemployed"),
        "current_grade": char_data.get("job_grade", 0),
        "wealth_bracket": econ_data.get("wealth_bracket", "Lower"),
        "total_wealth": (econ_data.get("cash", 0) or 0) + (econ_data.get("bank", 0) or 0),
        "total_revenue_earned": total_revenue,
        "total_transactions": total_transactions,
        "delivery_count": delivery_count,
        "firing_count": firing_count,
        "criminal_records": criminal_count,
    }

    auto_qualifies = (
        total_revenue >= AUTO_APPROVE_THRESHOLDS["min_total_revenue"]
        and delivery_count >= AUTO_APPROVE_THRESHOLDS["min_deliveries"]
        and firing_count <= AUTO_APPROVE_THRESHOLDS["max_firings"]
        and criminal_count == 0
    )

    status = "auto_approved" if auto_qualifies else "pending"

    body = {
        "applicant_citizenid": applicant_citizenid,
        "target_business_id": target_business_id,
        "target_job": target_job,
        "experience_metrics": metrics,
        "approval_status": status,
        "created_at": datetime.utcnow().isoformat(),
    }
    supabase.table("job_applications").insert(body).execute()

    supabase.table("background_checks").insert({
        "subject_citizenid": applicant_citizenid,
        "result": {
            "criminal_records": criminal_count,
            "firing_count": firing_count,
            "auto_qualified": auto_qualifies,
        },
        "status": "completed",
    }).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "job_application_processed",
        "context_json": {
            "citizenid": applicant_citizenid,
            "status": status,
            "auto_qualified": auto_qualifies,
        },
        "result": status,
    }).execute()

    return {
        "status": status,
        "auto_qualified": auto_qualifies,
        "metrics": metrics,
    }


async def review_application(application_id: str, reviewer_citizenid: str, approved: bool) -> dict:
    status = "approved" if approved else "denied"
    supabase.table("job_applications").update({
        "approval_status": status,
        "reviewer_citizenid": reviewer_citizenid,
        "reviewed_at": datetime.utcnow().isoformat(),
    }).eq("id", application_id).execute()

    return {"status": status, "reviewer": reviewer_citizenid}


async def get_pending_applications() -> list:
    r = supabase.table("job_applications").select("*").eq("approval_status", "pending").order("created_at", desc=True).execute()
    return r.data or []
