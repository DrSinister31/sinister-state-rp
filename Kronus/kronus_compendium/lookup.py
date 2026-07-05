import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from shared.supabase_client import get_supabase
from shared.config import Config


class CompendiumLookup:
    def __init__(self, config: Config):
        self.supabase = get_supabase(config)

    def count_monsters(self) -> int:
        try:
            r = self.supabase.table("compendium_monsters").select("id", count="exact").execute()
            return r.count or 0
        except Exception as e:
            print(f"[kronus-compendium] Count query failed: {e}")
            return 0

    def count_public_monsters(self) -> int:
        try:
            r = self.supabase.table("compendium_monsters").select("id", count="exact").eq("public", True).execute()
            return r.count or 0
        except Exception as e:
            print(f"[kronus-compendium] Public count query failed: {e}")
            return 0

    def search(self, query: str = None, cr_min: float = None, cr_max: float = None,
               monster_type: str = None, size: str = None, biome: str = None,
               public_only: bool = False, limit: int = 5, offset: int = 0) -> list[dict]:
        try:
            builder = self.supabase.table("compendium_monsters").select("*")

            if query:
                builder = builder.ilike("name", f"%{query}%")
            if cr_min is not None:
                builder = builder.gte("cr", cr_min)
            if cr_max is not None:
                builder = builder.lte("cr", cr_max)
            if monster_type:
                builder = builder.ilike("type", f"%{monster_type}%")
            if size:
                builder = builder.eq("size", size)
            if public_only:
                builder = builder.eq("public", True)

            builder = builder.order("cr", desc=False).order("name", desc=False)
            builder = builder.range(offset, offset + limit - 1)

            r = builder.execute()
            return r.data or []
        except Exception as e:
            print(f"[kronus-compendium] Search failed: {e}")
            return []

    def get_by_name(self, name: str, public_only: bool = False) -> dict | None:
        try:
            builder = self.supabase.table("compendium_monsters").select("*").ilike("name", name)
            if public_only:
                builder = builder.eq("public", True)
            r = builder.limit(1).execute()
            return r.data[0] if r.data else None
        except Exception as e:
            print(f"[kronus-compendium] Name lookup failed: {e}")
            return None

    def get_random(self, public_only: bool = False) -> dict | None:
        try:
            builder = self.supabase.table("compendium_monsters").select("*")
            if public_only:
                builder = builder.eq("public", True)
            r = builder.limit(100).execute()
            if not r.data:
                return None
            import random
            return random.choice(r.data)
        except Exception as e:
            print(f"[kronus-compendium] Random lookup failed: {e}")
            return None

    def insert_monsters(self, monsters: list[dict]) -> int:
        inserted = 0
        for monster in monsters:
            try:
                self.supabase.table("compendium_monsters").insert(monster).execute()
                inserted += 1
            except Exception as e:
                print(f"[kronus-compendium] Insert failed for {monster.get('name', 'unknown')}: {e}")
        return inserted

    def set_public(self, name: str, public: bool) -> bool:
        try:
            r = self.supabase.table("compendium_monsters").update({"public": public}).ilike("name", name).execute()
            return bool(r.data)
        except Exception as e:
            print(f"[kronus-compendium] Set public failed: {e}")
            return False

    def get_distinct_types(self) -> list[str]:
        try:
            r = self.supabase.table("compendium_monsters").select("type").execute()
            if not r.data:
                return []
            types = set(row["type"] for row in r.data if row.get("type"))
            return sorted(types)
        except Exception as e:
            print(f"[kronus-compendium] Type list failed: {e}")
            return []

    def get_distinct_biomes(self) -> list[str]:
        try:
            r = self.supabase.table("compendium_monsters").select("biome_tags").execute()
            if not r.data:
                return []
            biomes = set()
            for row in r.data:
                tags = row.get("biome_tags") or []
                biomes.update(tags)
            return sorted(biomes)
        except Exception as e:
            print(f"[kronus-compendium] Biome list failed: {e}")
            return []


_lookup: CompendiumLookup | None = None


def get_lookup(config: Config | None = None) -> CompendiumLookup:
    global _lookup
    if _lookup is None:
        if config is None:
            config = Config.from_env()
        _lookup = CompendiumLookup(config)
    return _lookup
