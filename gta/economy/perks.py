import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))
from shared.supabase_client import get_supabase

supabase = get_supabase()

async def run_wealth_perks():
    players = supabase.table("player_economy").select("citizenid, wealth_bracket").execute()
    for p in (players.data or []):
        bracket = p.get("wealth_bracket", "Lower")
        perks = {}
        if bracket == "Lower":
            perks = {"food_discount": 20, "medical_discount": 20, "subsidized_bandages": True}
        elif bracket == "Upper":
            perks = {"luxury_tax": 5, "investment_yield": 2, "premium_services": True}

        supabase.table("bot_config").upsert({
            "key": f"perks_{p['citizenid']}",
            "value": str(perks),
            "updated_at": "now()"
        }).execute()
