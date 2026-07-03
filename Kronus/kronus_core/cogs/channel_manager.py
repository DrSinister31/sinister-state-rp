import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord.ext import commands
from shared.supabase_client import get_supabase


class ChannelManager(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.supabase = get_supabase()

    async def _get_role_id(self, key: str) -> int:
        r = self.supabase.table("bot_config").select("value").eq("key", key).execute()
        if r.data:
            return int(r.data[0]["value"])
        return 0

    async def create_faction_category(self, guild_id: int, business_name: str, owner_id: int):
        guild = self.bot.get_guild(guild_id)
        if not guild:
            return None, None, None, None

        category = await guild.create_category(business_name)
        owner_role = await self._get_role_id("business_owner_role_id")
        emp_role = await self._get_role_id("business_employee_role_id")

        overwrites = {
            guild.default_role: discord.PermissionOverwrite(read_messages=False),
        }
        if owner_role:
            role_obj = guild.get_role(owner_role)
            if role_obj:
                overwrites[role_obj] = discord.PermissionOverwrite(read_messages=True, send_messages=True)

        owner_ch = await guild.create_text_channel("owner-desk", category=category, overwrites=overwrites)

        emp_overwrites = {guild.default_role: discord.PermissionOverwrite(read_messages=False)}
        if emp_role:
            role_obj = guild.get_role(emp_role)
            if role_obj:
                emp_overwrites[role_obj] = discord.PermissionOverwrite(read_messages=True, send_messages=True)

        lounge_ch = await guild.create_text_channel("employee-lounge", category=category, overwrites=emp_overwrites)
        logs_ch = await guild.create_text_channel("logistics-kpis", category=category, overwrites=emp_overwrites)

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
