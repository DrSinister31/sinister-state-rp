import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from datetime import datetime
import discord
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase


class Chronicles(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self.volume_index = 1

    async def publish_event(self, score: int, title: str, description: str,
                            involved_citizenids: list, involved_discord_ids: list):
        if score < 15:
            return

        is_major = score >= 23
        channel = self.bot.get_channel(self.config.chronicles_channel_id)
        if not channel:
            return

        embed = discord.Embed(
            title=title,
            description=description[:4096],
            color=discord.Color.red() if is_major else discord.Color.dark_gray(),
            timestamp=datetime.utcnow()
        )
        embed.set_footer(text=f"Volume {self.volume_index}")
        embed.set_author(name="EMERGENCY CRISIS ALERT" if is_major else "Investigative Chronicle")

        mentions = " ".join(f"<@{did}>" for did in involved_discord_ids if did)
        if mentions:
            embed.add_field(name="Involved Parties", value=mentions[:1024], inline=False)

        await channel.send(embed=embed)
        self.volume_index += 1


async def setup(bot: commands.Bot):
    await bot.add_cog(Chronicles(bot))
