import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import asyncio
import discord
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase

intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = commands.Bot(command_prefix="!", intents=intents)
config = Config.from_env()
supabase = get_supabase(config)


@bot.event
async def on_ready():
    print(f"[kronus-core] Online as {bot.user}")
    await bot.tree.sync()
    print("[kronus-core] Slash commands synced")


@bot.event
async def on_member_join(member: discord.Member):
    pass


async def main():
    cogs = [
        "cogs.channel_manager",
        "cogs.role_sync",
        "cogs.rcon_bridge",
        "cogs.chronicles",
    ]
    for cog in cogs:
        try:
            await bot.load_extension(cog)
            print(f"[kronus-core] Loaded {cog}")
        except Exception as e:
            print(f"[kronus-core] Failed to load {cog}: {e}")

    await bot.start(config.discord_token)


if __name__ == "__main__":
    asyncio.run(main())
