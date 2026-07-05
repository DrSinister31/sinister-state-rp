import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from shared.config import Config
from shared.supabase_client import get_supabase
from lookup import get_lookup
from generator import get_generator

config = Config.from_env()
supabase = get_supabase(config)
scheduler = AsyncIOScheduler()

SEED_TARGET = 250

SEED_CATEGORIES = [
    {"monster_type": "goblinoid", "cr_min": 0.125, "cr_max": 5, "count": 20, "description": "Goblins and Hobgoblins"},
    {"monster_type": "orc", "cr_min": 0.25, "cr_max": 7, "count": 20, "description": "Orcs and half-orcs"},
    {"monster_type": "troll", "cr_min": 3, "cr_max": 10, "count": 10, "description": "Trolls and variants"},
    {"monster_type": "undead", "cr_min": 0.25, "cr_max": 8, "count": 25, "description": "Skeletons, zombies, wraiths"},
    {"monster_type": "beast", "cr_min": 0, "cr_max": 8, "count": 25, "description": "Wolves, bears, wildlife"},
    {"monster_type": "dragon", "cr_min": 2, "cr_max": 12, "count": 15, "description": "Wyverns, drakes, young dragons"},
    {"monster_type": "construct", "cr_min": 1, "cr_max": 8, "count": 10, "description": "Golems, automatons"},
    {"monster_type": "aberration", "cr_min": 1, "cr_max": 10, "count": 10, "description": "Aether-warped mutants"},
    {"region": "swamp", "cr_min": 0.125, "cr_max": 6, "count": 15, "description": "Swamp creatures"},
    {"region": "mountain", "cr_min": 0.25, "cr_max": 8, "count": 15, "description": "Mountain beasts"},
    {"cr_min": 0.125, "cr_max": 5, "count": 25, "description": "Mixed NPC templates"},
    {"region": "forest", "cr_min": 0.125, "cr_max": 7, "count": 20, "description": "Forest creatures"},
    {"cr_min": 0.125, "cr_max": 10, "count": 40, "description": "Classic D&D monsters for Solis-Grave"},
]


async def seed_database():
    lookup = get_lookup(config)
    generator = get_generator(config)

    current = lookup.count_monsters()
    if current >= SEED_TARGET:
        print(f"[kronus-compendium] Database already seeded: {current} monsters. Skipping seed.")
        return

    print(f"[kronus-compendium] Seeding: {current} monsters, need {SEED_TARGET - current} more.")

    for category in SEED_CATEGORIES:
        if lookup.count_monsters() >= SEED_TARGET:
            break

        desc = category.get("description", "monsters")
        cnt = category.get("count", 10)
        print(f"[kronus-compendium] Generating: {desc} ({cnt} requested)...")

        monsters = generator.generate(
            region=category.get("region"),
            monster_type=category.get("monster_type"),
            cr_min=category.get("cr_min"),
            cr_max=category.get("cr_max"),
            count=cnt
        )

        if monsters:
            inserted = lookup.insert_monsters(monsters)
            print(f"[kronus-compendium] Inserted {inserted}/{len(monsters)}. Total: {lookup.count_monsters()}")

        await asyncio.sleep(2)

    total = lookup.count_monsters()
    print(f"[kronus-compendium] Seed complete. Total monsters: {total}")

    supabase.table("kronus_logs").insert({
        "service": "kronus-compendium",
        "action": "seed_complete",
        "context_json": {"total_monsters": total, "target": SEED_TARGET},
        "result": "online"
    }).execute()


async def main():
    print("[kronus-compendium] Starting...")

    supabase.table("kronus_logs").insert({
        "service": "kronus-compendium",
        "action": "startup",
        "context_json": {"mode": "compendium", "seed_target": SEED_TARGET},
        "result": "online"
    }).execute()

    await seed_database()

    print("[kronus-compendium] Online. Idle — generation via Discord commands.")
    scheduler.start()

    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())
