import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.supabase_client import get_supabase


class StaffModeration(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.supabase = get_supabase()
        self._staff_role_id = 0

    async def _get_staff_role(self, guild: discord.Guild) -> discord.Role | None:
        if not self._staff_role_id:
            r = self.supabase.table("bot_config").select("value").eq("key", "staff_role_id").execute()
            self._staff_role_id = int(r.data[0]["value"]) if r.data else 0
        return guild.get_role(self._staff_role_id)

    def _is_staff(self, interaction: discord.Interaction) -> bool:
        if not interaction.guild:
            return False
        staff_role = interaction.guild.get_role(self._staff_role_id)
        if not staff_role:
            return True  # fail open if role not found
        return staff_role in interaction.user.roles

    @app_commands.command(name="warn", description="[STAFF] Issue a warning to a player")
    @app_commands.describe(user="Who to warn", reason="Reason for the warning")
    async def warn(self, interaction: discord.Interaction, user: discord.Member, reason: str):
        if not self._is_staff(interaction):
            await interaction.response.send_message("Staff only.", ephemeral=True)
            return
        await interaction.response.send_message(
            f"> **Warning issued**\n> **To:** {user.mention}\n> **Reason:** {reason}\n> **By:** {interaction.user.mention}",
            ephemeral=False
        )
        self.supabase.table("kronus_logs").insert({
            "service": "kronus-core",
            "action": "warn",
            "context_json": {
                "target": str(user.id),
                "target_name": user.display_name,
                "reason": reason,
                "moderator": str(interaction.user.id)
            },
            "result": "issued"
        }).execute()

    @app_commands.command(name="strike", description="[STAFF] Issue a strike to a player")
    @app_commands.describe(user="Who to strike", violation="What they did", fine="Fine amount (0 if none)")
    async def strike(self, interaction: discord.Interaction, user: discord.Member, violation: str, fine: int = 0):
        if not self._is_staff(interaction):
            await interaction.response.send_message("Staff only.", ephemeral=True)
            return
        # Get current strike count
        r = self.supabase.table("strikes").select("strike_count").eq("discord_id", user.id).execute()
        counts = [s["strike_count"] for s in (r.data or [])]
        current = max(counts) if counts else 0
        new_count = current + 1

        self.supabase.table("strikes").insert({
            "citizenid": str(user.id),
            "discord_id": user.id,
            "violation": violation,
            "strike_count": new_count,
            "fine_amount": fine,
            "moderator_id": str(interaction.user.id)
        }).execute()

        threshold_r = self.supabase.table("bot_config").select("value").eq("key", "ban_strike_threshold").execute()
        threshold = int(threshold_r.data[0]["value"]) if threshold_r.data else 3

        warn_text = ""
        if new_count >= threshold:
            warn_text = f"\n> :warning: **{new_count}/{threshold} strikes — auto-ban threshold reached!**"

        await interaction.response.send_message(
            f"> **Strike #{new_count}** issued\n> **To:** {user.mention}\n> **Violation:** {violation}\n> **Fine:** ${fine:,}\n> **By:** {interaction.user.mention}{warn_text}",
            ephemeral=False
        )

    @app_commands.command(name="ban", description="[STAFF] Ban a player")
    @app_commands.describe(user="Who to ban", reason="Reason for the ban", duration="Duration (perm, 7d, 30d)")
    async def ban(self, interaction: discord.Interaction, user: discord.Member, reason: str, duration: str = "perm"):
        if not self._is_staff(interaction):
            await interaction.response.send_message("Staff only.", ephemeral=True)
            return
        self.supabase.table("bans").insert({
            "discord_id": user.id,
            "reason": reason,
            "moderator_id": str(interaction.user.id),
            "duration": duration,
            "active": True
        }).execute()

        self.supabase.table("rcon_commands").insert({
            "command": f"say [MOD] {user.display_name} has been banned ({duration}): {reason}",
            "source": "kronus-core",
            "status": "pending"
        }).execute()

        await interaction.response.send_message(
            f"> :lock: **Banned**\n> **User:** {user.mention}\n> **Duration:** {duration}\n> **Reason:** {reason}\n> **By:** {interaction.user.mention}",
            ephemeral=False
        )

    @app_commands.command(name="announce", description="[STAFF] Post an announcement to #announcements")
    @app_commands.describe(message="The announcement text")
    async def announce(self, interaction: discord.Interaction, message: str):
        if not self._is_staff(interaction):
            await interaction.response.send_message("Staff only.", ephemeral=True)
            return
        guild = interaction.guild
        for ch in guild.text_channels:
            if ch.name == "announcements":
                await ch.send(f"@everyone\n\n{message}")
                await interaction.response.send_message(f"> **Announcement posted** in {ch.mention}", ephemeral=True)
                return
        await interaction.response.send_message("Announcements channel not found.", ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(StaffModeration(bot))
