from datetime import datetime, timedelta
from shared.supabase_client import get_supabase
from shared.config import Config
from toggles import is_enabled

config = Config.from_env()
supabase = get_supabase(config)


# ─── MARRIAGE ──────────────────────────────────────────────────────

async def officiate_marriage(spouse1_cid: str, spouse2_cid: str, officiant: str = "City Clerk", location: str = "Travis County Courthouse") -> dict:
    if not await is_enabled("marriage_system_enabled"):
        return {"error": "Marriage system disabled"}

    existing1 = supabase.table("marriage_records").select("id").eq("spouse1_citizenid", spouse1_cid).eq("status", "active").execute()
    existing2 = supabase.table("marriage_records").select("id").eq("spouse2_citizenid", spouse1_cid).eq("status", "active").execute()
    if existing1.data or existing2.data:
        return {"error": "Already married"}

    existing3 = supabase.table("marriage_records").select("id").eq("spouse1_citizenid", spouse2_cid).eq("status", "active").execute()
    existing4 = supabase.table("marriage_records").select("id").eq("spouse2_citizenid", spouse2_cid).eq("status", "active").execute()
    if existing3.data or existing4.data:
        return {"error": "Partner already married"}

    record = {
        "spouse1_citizenid": spouse1_cid,
        "spouse2_citizenid": spouse2_cid,
        "officiant": officiant,
        "ceremony_location": location,
        "status": "active",
    }
    supabase.table("marriage_records").insert(record).execute()

    char1 = supabase.table("characters").select("first_name, last_name").eq("citizenid", spouse1_cid).execute()
    char2 = supabase.table("characters").select("first_name, last_name").eq("citizenid", spouse2_cid).execute()
    name1 = f"{char1.data[0].get('first_name','')} {char1.data[0].get('last_name','')}" .strip() if char1.data else spouse1_cid
    name2 = f"{char2.data[0].get('first_name','')} {char2.data[0].get('last_name','')}" .strip() if char2.data else spouse2_cid

    supabase.table("chronicle_entries").insert({
        "score": 5,
        "title": "Marriage Ceremony",
        "description": f"{name1} and {name2} were married at {location} by {officiant}.",
        "involved_citizenids": [spouse1_cid, spouse2_cid],
        "involved_discord_ids": [],
        "volume_index": 0,
    }).execute()

    return {"status": "married", "spouse1": name1, "spouse2": name2}


async def file_divorce(spouse_cid: str) -> dict:
    if not await is_enabled("marriage_system_enabled"):
        return {"error": "Marriage system disabled"}

    r = supabase.table("marriage_records").select("id").or_(f"spouse1_citizenid.eq.{spouse_cid},spouse2_citizenid.eq.{spouse_cid}").eq("status", "active").execute()
    if not r.data:
        return {"error": "No active marriage found"}

    supabase.table("marriage_records").update({
        "divorced_at": datetime.utcnow().isoformat(),
        "status": "divorced"
    }).eq("id", r.data[0]["id"]).execute()

    return {"status": "divorced"}


# ─── INSURANCE ─────────────────────────────────────────────────────

INSURANCE_TYPES = {
    "vehicle": {"premium": 200, "coverage": 10000, "deductible": 500},
    "health": {"premium": 150, "coverage": 5000, "deductible": 250},
    "property": {"premium": 300, "coverage": 25000, "deductible": 1000},
    "business": {"premium": 500, "coverage": 50000, "deductible": 2000},
    "life": {"premium": 100, "coverage": 20000, "deductible": 0},
}


async def purchase_insurance(holder_cid: str, policy_type: str) -> dict:
    if not await is_enabled("insurance_system_enabled"):
        return {"error": "Insurance disabled"}

    template = INSURANCE_TYPES.get(policy_type.lower())
    if not template:
        return {"error": f"Invalid type. Options: {list(INSURANCE_TYPES.keys())}"}

    existing = supabase.table("insurance_policies").select("id").eq("policy_holder_citizenid", holder_cid).eq("policy_type", policy_type).eq("active", True).execute()
    if existing.data:
        return {"error": f"Already have active {policy_type} insurance"}

    econ = supabase.table("player_economy").select("bank").eq("citizenid", holder_cid).execute()
    if econ.data:
        bank = econ.data[0].get("bank", 0) or 0
        if bank < template["premium"]:
            return {"error": f"Insufficient funds. Need ${template['premium']}"}
        supabase.rpc("add_funds", {"p_citizenid": holder_cid, "p_amount": -template["premium"], "p_account": "bank"}).execute()

    policy = {
        "policy_holder_citizenid": holder_cid,
        "policy_type": policy_type,
        "coverage_description": f"{policy_type.title()} Insurance Policy",
        "coverage_amount": template["coverage"],
        "monthly_premium": template["premium"],
        "deductible": template["deductible"],
        "next_payment_due": (datetime.utcnow() + timedelta(days=30)).isoformat(),
    }
    supabase.table("insurance_policies").insert(policy).execute()

    return {"status": "active", "type": policy_type, "coverage": template["coverage"], "premium": template["premium"]}


async def file_insurance_claim(holder_cid: str, policy_type: str, claim_amount: int, reason: str) -> dict:
    if not await is_enabled("insurance_system_enabled"):
        return {"error": "Insurance disabled"}

    policy_r = supabase.table("insurance_policies").select("*").eq("policy_holder_citizenid", holder_cid).eq("policy_type", policy_type).eq("active", True).execute()
    if not policy_r.data:
        return {"error": "No active policy found"}

    policy = policy_r.data[0]
    coverage = policy.get("coverage_amount", 0) or 0
    deductible = policy.get("deductible", 0) or 0

    payout = min(claim_amount - deductible, coverage)
    if payout <= 0:
        return {"error": "Claim below deductible"}

    supabase.rpc("add_funds", {"p_citizenid": holder_cid, "p_amount": payout, "p_account": "bank"}).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "insurance_claim",
        "context_json": {
            "holder": holder_cid,
            "type": policy_type,
            "claimed": claim_amount,
            "payout": payout,
            "reason": reason,
        },
        "result": "paid"
    }).execute()

    return {"status": "paid", "payout": payout, "deductible": deductible}


async def process_insurance_renewals():
    if not await is_enabled("insurance_system_enabled"):
        return

    due = supabase.table("insurance_policies").select("*").eq("active", True).lte("next_payment_due", datetime.utcnow().isoformat()).execute()
    for policy in (due.data or []):
        holder = policy["policy_holder_citizenid"]
        premium = policy.get("monthly_premium", 0) or 0

        econ = supabase.table("player_economy").select("bank").eq("citizenid", holder).execute()
        if econ.data:
            bank = econ.data[0].get("bank", 0) or 0
            if bank >= premium:
                supabase.rpc("add_funds", {"p_citizenid": holder, "p_amount": -premium, "p_account": "bank"}).execute()
                supabase.table("insurance_policies").update({
                    "next_payment_due": (datetime.utcnow() + timedelta(days=30)).isoformat()
                }).eq("id", policy["id"]).execute()
            else:
                supabase.table("insurance_policies").update({"active": False}).eq("id", policy["id"]).execute()


# ─── WILLS ─────────────────────────────────────────────────────────

async def file_will(testator_cid: str, beneficiary_cid: str, asset_description: str, asset_value: int = 0) -> dict:
    if not await is_enabled("will_system_enabled"):
        return {"error": "Will system disabled"}

    will = {
        "testator_citizenid": testator_cid,
        "beneficiary_citizenid": beneficiary_cid,
        "asset_type": "general",
        "asset_value": asset_value,
        "asset_description": asset_description,
    }
    supabase.table("wills").insert(will).execute()

    return {"status": "filed", "beneficiary": beneficiary_cid}


async def execute_will(will_id: str, executor_cid: str = "court") -> dict:
    if not await is_enabled("will_system_enabled"):
        return {"error": "Will system disabled"}

    will_r = supabase.table("wills").select("*").eq("id", will_id).eq("executed", False).execute()
    if not will_r.data:
        return {"error": "Will not found or already executed"}

    will = will_r.data[0]
    beneficiary = will["beneficiary_citizenid"]
    value = will.get("asset_value", 0) or 0

    if value > 0:
        supabase.rpc("add_funds", {"p_citizenid": beneficiary, "p_amount": value, "p_account": "bank"}).execute()

    supabase.table("wills").update({
        "executed_at": datetime.utcnow().isoformat(),
        "executed": True,
    }).eq("id", will_id).execute()

    supabase.table("kronus_logs").insert({
        "service": "kronus-economy",
        "action": "will_executed",
        "context_json": {
            "testator": will["testator_citizenid"],
            "beneficiary": beneficiary,
            "amount": value,
            "executor": executor_cid,
        },
        "result": "completed"
    }).execute()

    return {"status": "executed", "beneficiary": beneficiary, "amount": value}


# ─── PROPERTY ──────────────────────────────────────────────────────

async def list_property_for_sale(owner_cid: str, property_id: str, price: int, property_type: str = "residential", address: str = "") -> dict:
    if not await is_enabled("property_listings_enabled"):
        return {"error": "Property system disabled"}

    listing = {
        "property_id": property_id,
        "property_type": property_type,
        "address": address,
        "price": price,
        "owner_citizenid": owner_cid,
        "listing_status": "available",
    }
    supabase.table("property_listings").upsert(listing).execute()

    return {"status": "listed", "property_id": property_id, "price": price}


async def buy_property(buyer_cid: str, listing_id: str) -> dict:
    listing_r = supabase.table("property_listings").select("*").eq("id", listing_id).eq("listing_status", "available").execute()
    if not listing_r.data:
        return {"error": "Listing not found"}

    listing = listing_r.data[0]
    if listing.get("owner_citizenid") == buyer_cid:
        return {"error": "Cannot buy your own property"}

    price = listing.get("price", 0) or 0
    econ = supabase.table("player_economy").select("bank").eq("citizenid", buyer_cid).execute()
    if econ.data:
        bank = econ.data[0].get("bank", 0) or 0
        if bank < price:
            return {"error": "Insufficient funds"}

    seller_cid = listing["owner_citizenid"]
    supabase.rpc("add_funds", {"p_citizenid": buyer_cid, "p_amount": -price, "p_account": "bank"}).execute()
    supabase.rpc("add_funds", {"p_citizenid": seller_cid, "p_amount": price, "p_account": "bank"}).execute()

    supabase.table("property_listings").update({
        "listing_status": "sold",
        "owner_citizenid": buyer_cid,
        "sold_at": datetime.utcnow().isoformat(),
    }).eq("id", listing_id).execute()

    supabase.table("transactions").insert({
        "from_citizenid": buyer_cid,
        "to_citizenid": seller_cid,
        "amount": price,
        "account_type": "bank",
        "reason": f"Property purchase — {listing.get('address', listing.get('property_id', ''))}",
        "channel": "property"
    }).execute()

    return {"status": "sold", "buyer": buyer_cid, "seller": seller_cid, "price": price}


async def get_active_listings(property_type: str = None) -> list:
    q = supabase.table("property_listings").select("*").eq("listing_status", "available")
    if property_type:
        q = q.eq("property_type", property_type)
    r = q.order("listed_at", desc=True).execute()
    return r.data or []

