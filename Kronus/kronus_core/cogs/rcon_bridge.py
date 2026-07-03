import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import asyncio
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase


class RconBridge(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)

    def queue_command(self, command: str, source: str = "kronus"):
        self.supabase.table("rcon_commands").insert({
            "command": command,
            "source": source,
            "status": "pending"
        }).execute()

    async def say(self, message: str):
        self.queue_command(f"say {message}")

    async def restart_resource(self, resource_name: str):
        self.queue_command(f"ensure {resource_name}")

    @commands.Cog.listener()
    async def on_ready(self):
        print(f"[rcon_bridge] Ready (host: {self.config.rcon_host}:{self.config.rcon_port})")


async def setup(bot: commands.Bot):
    await bot.add_cog(RconBridge(bot))
