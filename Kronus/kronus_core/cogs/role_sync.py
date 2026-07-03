import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from discord.ext import commands


class RoleSync(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    async def sync_player_role(self, discord_id: int, job_name: str, grade: int):
        pass


async def setup(bot: commands.Bot):
    await bot.add_cog(RoleSync(bot))
