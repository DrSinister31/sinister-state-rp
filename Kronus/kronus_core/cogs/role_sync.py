import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord.ext import commands, tasks
from shared.supabase_client import get_supabase


JOB_ROLE_MAP = {
    "hpd": "Houston PD",
    "houstonpd": "Houston PD",
    "bcso": "Ft. Worth Sheriff",
    "sheriff": "Ft. Worth Sheriff",
    "dps": "Texas DPS",
    "texasdps": "Texas DPS",
    "ambulance": "Texas EMS",
    "ems": "Texas EMS",
    "fire": "Texas Fire & Rescue",
    "fib": "FIB",
    "military": "Texas National Guard",
    "nationalguard": "Texas National Guard",
    "atc": "ATC",
    "mechanic": "Mechanic",
    "tow": "Tow",
    "taxi": "Taxi",
    "trucker": "Trucker",
    "judge": "Judge",
    "lawyer": "Lawyer",
    "reporter": "Reporter",
    "realestate": "Real Estate",
    "bartender": "Bartender",
    "farmer": "Farmer",
}

SYNC_INTERVAL_MINUTES = 5


class RoleSync(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.supabase = get_supabase()
        self._guild_id = 0
        self._role_cache = {}

    async def cog_load(self):
        cfg = self.supabase.table("bot_config").select("value").eq("key", "discord_guild_id").execute()
        if cfg.data:
            self._guild_id = int(cfg.data[0]["value"])
        self.role_sync_loop.start()

    def cog_unload(self):
        self.role_sync_loop.cancel()

    async def _get_or_create_role(self, guild: discord.Guild, role_name: str) -> discord.Role | None:
        cache_key = f"{guild.id}:{role_name}"
        if cache_key in self._role_cache:
            role = guild.get_role(self._role_cache[cache_key])
            if role:
                return role

        for role in guild.roles:
            if role.name.lower() == role_name.lower():
                self._role_cache[cache_key] = role.id
                return role

        try:
            role = await guild.create_role(
                name=role_name,
                color=discord.Color.from_rgb(191, 87, 0),
                mentionable=True,
                reason="Kronus role sync — auto-created for job"
            )
            self._role_cache[cache_key] = role.id

            cfg_key = f"discord_role_{role_name.lower().replace(' ', '_')}"
            self.supabase.table("bot_config").upsert({
                "key": cfg_key,
                "value": str(role.id),
                "updated_at": "now()"
            }).execute()

            return role
        except Exception as e:
            print(f"[role_sync] Failed to create role {role_name}: {e}")
            return None

    async def sync_player_role(self, member: discord.Member, job_name: str) -> bool:
        role_name = JOB_ROLE_MAP.get(job_name.lower() if job_name else "")
        if not role_name:
            return False

        role = await self._get_or_create_role(member.guild, role_name)
        if not role:
            return False

        if role in member.roles:
            return False

        try:
            await member.add_roles(role, reason="Kronus role sync — job assignment")
        except Exception as e:
            print(f"[role_sync] Failed to add role {role_name} to {member.display_name}: {e}")
            return False

        for job_key, mapped_name in JOB_ROLE_MAP.items():
            if mapped_name.lower() == role_name.lower():
                continue
            for existing_role in member.roles:
                if existing_role.name.lower() == mapped_name.lower() and existing_role.id != role.id:
                    try:
                        await member.remove_roles(existing_role, reason="Kronus role sync — job changed")
                    except Exception:
                        pass

        return True

    @tasks.loop(minutes=SYNC_INTERVAL_MINUTES)
    async def role_sync_loop(self):
        guild = self.bot.get_guild(self._guild_id)
        if not guild:
            return

        try:
            chars = self.supabase.table("characters").select("citizenid,job_name").eq("active", True).execute()
            if not chars.data:
                return

            for char in chars.data:
                cid = char.get("citizenid")
                job = char.get("job_name", "")
                if not cid or not job:
                    continue

                dp = self.supabase.table("discord_players").select("discord_id").eq("citizenid", cid).execute()
                if not dp.data:
                    continue

                did = int(dp.data[0]["discord_id"])
                member = guild.get_member(did)
                if not member:
                    continue

                await self.sync_player_role(member, job)
        except Exception as e:
            print(f"[role_sync] Loop error: {e}")

    @role_sync_loop.before_loop
    async def before_sync(self):
        await self.bot.wait_until_ready()


async def setup(bot: commands.Bot):
    await bot.add_cog(RoleSync(bot))
