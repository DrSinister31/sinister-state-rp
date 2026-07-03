import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import discord
from discord.ext import commands


class ChannelManager(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.Cog.listener()
    async def on_message(self, message):
        if message.author.bot:
            return

    async def create_faction_category(self, guild_id: int, business_name: str, owner_id: int):
        guild = self.bot.get_guild(guild_id)
        if not guild:
            return
        category = await guild.create_category(business_name)
        owner = guild.get_member(owner_id)
        overwrites = {
            guild.default_role: discord.PermissionOverwrite(read_messages=False),
        }
        if owner:
            overwrites[owner] = discord.PermissionOverwrite(read_messages=True)
        owner_ch = await guild.create_text_channel("owner-desk", category=category, overwrites=overwrites)
        lounge_ch = await guild.create_text_channel("employee-lounge", category=category)
        logs_ch = await guild.create_text_channel("logistics-kpis", category=category)
        return category.id, owner_ch.id, lounge_ch.id, logs_ch.id

    async def purge_faction_category(self, guild_id: int, category_id: int):
        guild = self.bot.get_guild(guild_id)
        if not guild:
            return
        category = guild.get_channel(category_id)
        if category:
            for ch in category.channels:
                await ch.delete()
            await category.delete()


async def setup(bot: commands.Bot):
    await bot.add_cog(ChannelManager(bot))
