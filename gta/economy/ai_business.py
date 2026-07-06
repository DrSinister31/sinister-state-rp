import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))
from datetime import datetime
from shared.supabase_client import get_supabase

supabase = get_supabase()

AI_BUSINESSES = [
    {"name": "Lone Star Grill", "type": "restaurant", "location": "Mirror Park", "revenue": 5000},
    {"name": "Bayou Catch Seafood", "type": "restaurant", "location": "Del Perro", "revenue": 4000},
    {"name": "Houston Haulers", "type": "trucking", "location": "La Puerta Industrial", "revenue": 8000},
    {"name": "Ft. Worth Fuels", "type": "gas_station", "location": "Paleto Bay", "revenue": 6000},
    {"name": "Bert's Garage", "type": "mechanic", "location": "Route 68", "revenue": 4500},
    {"name": "Killeen Convenience", "type": "convenience", "location": "Sandy Shores", "revenue": 3000},
    {"name": "Texas Air Cargo", "type": "airfield", "location": "Fort Worth Regional", "revenue": 12000},
    {"name": "The Yellow Rose Saloon", "type": "bar", "location": "Grapeseed", "revenue": 3500},
    {"name": "Lone Star Realty & Trust", "type": "realestate", "location": "Downtown Houston", "revenue": 7000},
    {"name": "Sandy Shores Ranch", "type": "farm", "location": "Sandy Shores", "revenue": 4000},
]

async def create_ai_business(biz_data):
    supabase.table("businesses").insert({
        "owner_citizenid": "ai_system",
        "name": biz_data["name"],
        "business_type": biz_data["type"],
        "revenue": biz_data["revenue"],
        "bank_account": 10000,
        "ai_placeholder": True,
        "active": True,
        "employee_count": 0,
        "location": {"area": biz_data.get("location", "")},
        "created_at": datetime.utcnow().isoformat()
    }).execute()

async def run_ai_business_check():
    # Count non-AI businesses
    r = supabase.table("businesses").select("id", count="exact").eq("ai_placeholder", False).eq("active", True).execute()
    player_count = r.count if r.count else 0
    
    if player_count > 0:
        return  # Don't create AI businesses if players have their own
    
    # Count existing AI businesses
    r2 = supabase.table("businesses").select("id", count="exact").eq("ai_placeholder", True).eq("active", True).execute()
    ai_count = r2.count if r2.count else 0
    
    # Create AI businesses if none exist
    if ai_count == 0:
        for biz in AI_BUSINESSES:
            await create_ai_business(biz)
        
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "ai_businesses_created",
            "context_json": {"count": len(AI_BUSINESSES), "reason": "no_player_businesses"},
            "result": "seed_complete"
        }).execute()

async def replace_ai_business(business_id, player_citizenid):
    """When a real player buys an AI business, replace the placeholder"""
    supabase.table("businesses").update({
        "owner_citizenid": player_citizenid,
        "ai_placeholder": False,
        "name": None
    }).eq("id", business_id).eq("ai_placeholder", True).execute()
