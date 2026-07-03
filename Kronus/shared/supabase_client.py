from supabase import create_client, Client
from .config import Config

_supabase: Client | None = None


def get_supabase(config: Config | None = None) -> Client:
    global _supabase
    if _supabase is None:
        if config is None:
            config = Config.from_env()
        _supabase = create_client(config.supabase_url, config.supabase_key)
    return _supabase
