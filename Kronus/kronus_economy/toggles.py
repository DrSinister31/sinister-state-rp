import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from shared.supabase_client import get_supabase

supabase = get_supabase()
_cache: dict = {}
_cache_time = 0

async def is_enabled(key: str) -> bool:
    global _cache, _cache_time
    import time
    now = time.time()
    if now - _cache_time > 300:
        _cache = {}
        _cache_time = now
    if key not in _cache:
        r = supabase.table("bot_config").select("value").eq("key", key).execute()
        _cache[key] = r.data[0]["value"].lower() == "true" if r.data else False
    return _cache[key]

async def enable_feature(key: str):
    supabase.table("bot_config").upsert({"key": key, "value": "true", "updated_at": "now()"}).execute()
    _cache[key] = True

async def disable_feature(key: str):
    supabase.table("bot_config").upsert({"key": key, "value": "false", "updated_at": "now()"}).execute()
    _cache[key] = False
