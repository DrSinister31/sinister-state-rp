import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import random
from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)

LUXURY_ASSETS = {
    "hypercar": [
        {"name": "Truffade Thrax (Custom)", "base_price": 2500000},
        {"name": "Pegassi Zentorno (Special Edition)", "base_price": 1800000},
        {"name": "Overflod Autarch (Limited Run)", "base_price": 3200000},
        {"name": "Grotti Itali GTO (Modified)", "base_price": 2100000},
    ],
    "weapon_skin": [
        {"name": "Damascus Combat Pistol Skin", "base_price": 150000},
        {"name": "Gold Tiger Assault Rifle Skin", "base_price": 250000},
        {"name": "Carbon Fiber Sniper Skin", "base_price": 300000},
    ],
    "license": [
        {"name": "Elite Business License (3 extra fronts)", "base_price": 500000},
        {"name": "Airspace Easement Certificate", "base_price": 750000},
        {"name": "Import/Export Dealer Permit", "base_price": 1000000},
    ],
    "property": [
        {"name": "Executive Airfield Hangar Lease", "base_price": 800000},
        {"name": "Yacht Club Marina Slip", "base_price": 450000},
        {"name": "Penthouse Suite Upgrade", "base_price": 600000},
    ],
}

AUCTION_LOCATIONS = [
    "Houston Executive Airfield",
    "Rockford Hills Luxury Dealership",
    "Puerto Del Sol Yacht Club",
    "Maze Bank Tower — Private Floor",
]


async def generate_luxury_auctions():
    if not await is_enabled("luxury_auctions_enabled"):
        return

    inflation = supabase.table("kronus_metrics").select("value").eq("metric_name", "inflation_state").order("recorded_at", desc=True).limit(1).execute()
    is_inflating = (inflation.data and len(inflation.data) > 0 and inflation.data[0]["value"] == 1.0)

    upper_r = supabase.table("player_economy").select("citizenid", count="exact").eq("wealth_bracket", "Upper").execute()
    upper = upper_r.count if upper_r else 0

    if upper < 2 and not is_inflating:
        return

    active = supabase.table("luxury_auctions").select("id", count="exact").eq("status", "active").execute()
    if active and active.count and active.count >= 6:
        return

    count = min(3, max(1, upper // 3))
    generated = 0

    for _ in range(count):
        cat = random.choice(list(LUXURY_ASSETS.keys()))
        asset = random.choice(LUXURY_ASSETS[cat])
        base = asset["base_price"]

        multiplier = 1.0
        if is_inflating:
            multiplier = random.uniform(1.2, 1.5)

        starting_bid = int(base * multiplier * random.uniform(0.7, 1.0))
        location = random.choice(AUCTION_LOCATIONS)

        auction = {
            "asset_type": cat,
            "asset_name": asset["name"],
            "asset_properties": {"base_price": base, "category": cat},
            "starting_bid": starting_bid,
            "auction_location": location,
            "status": "active",
            "expires_at": (datetime.utcnow() + timedelta(hours=random.randint(12, 48))).isoformat(),
        }
        supabase.table("luxury_auctions").insert(auction).execute()
        generated += 1

    if generated > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "auctions_generated",
            "context_json": {"generated": generated, "upper_class": upper, "inflating": is_inflating},
            "result": "completed"
        }).execute()


async def place_bid(auction_id: str, bidder_cid: str, amount: int) -> dict:
    if not await is_enabled("luxury_auctions_enabled"):
        return {"error": "Auctions disabled"}

    auction_r = supabase.table("luxury_auctions").select("*").eq("id", auction_id).eq("status", "active").execute()
    if not auction_r.data:
        return {"error": "Auction not found or closed"}

    auction = auction_r.data[0]
    current = auction.get("current_bid") or auction.get("starting_bid", 0)

    if amount <= current:
        return {"error": f"Bid must exceed ${current:,}"}

    econ = supabase.table("player_economy").select("bank").eq("citizenid", bidder_cid).execute()
    if econ.data:
        bank = econ.data[0].get("bank", 0) or 0
        if bank < amount:
            return {"error": "Insufficient funds"}

    supabase.table("auction_bids").insert({
        "auction_id": auction_id,
        "bidder_citizenid": bidder_cid,
        "amount": amount,
    }).execute()

    supabase.table("luxury_auctions").update({"current_bid": amount}).eq("id", auction_id).execute()

    return {"status": "bid_placed", "amount": amount, "auction": auction["asset_name"]}


async def close_expired_auctions():
    if not await is_enabled("luxury_auctions_enabled"):
        return

    expired = supabase.table("luxury_auctions").select("*").eq("status", "active").lte("expires_at", datetime.utcnow().isoformat()).execute()
    closed = 0
    purged = 0

    for auction in (expired.data or []):
        auction_id = auction["id"]
        winner_cid = None
        final_amount = 0

        top_bid = supabase.table("auction_bids").select("*").eq("auction_id", auction_id).order("amount", desc=True).limit(1).execute()
        if top_bid.data:
            winner_cid = top_bid.data[0]["bidder_citizenid"]
            final_amount = top_bid.data[0]["amount"]

            supabase.rpc("add_funds", {"p_citizenid": winner_cid, "p_amount": -final_amount, "p_account": "bank"}).execute()
            purged += final_amount

        supabase.table("luxury_auctions").update({
            "status": "closed",
            "winner_citizenid": winner_cid,
            "final_amount": final_amount,
            "closed_at": datetime.utcnow().isoformat(),
        }).eq("id", auction_id).execute()
        closed += 1

    if closed > 0:
        supabase.table("kronus_logs").insert({
            "service": "kronus-economy",
            "action": "auctions_closed",
            "context_json": {"closed": closed, "money_purged": purged},
            "result": "completed"
        })


async def get_active_auctions(category: str = None) -> list:
    q = supabase.table("luxury_auctions").select("*, auction_bids(count)").eq("status", "active")
    if category:
        q = q.eq("asset_type", category)
    r = q.order("listed_at", desc=True).execute()
    return r.data or []
