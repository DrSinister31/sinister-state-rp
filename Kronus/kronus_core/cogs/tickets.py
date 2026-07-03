import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import asyncio
import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase

TICKET_TYPES = [
    ("general", "General Support", "Need help with the server?"),
    ("report", "Player Report", "Report a rule violation"),
    ("ban_appeal", "Ban Appeal", "Appeal a ban or punishment"),
    ("staff_app", "Staff Application", "Apply to join the staff team"),
    ("tebex", "Donation Support", "Issues with a purchase or donation"),
    ("business", "Business Inquiry", "Questions about businesses or properties"),
]

CATEGORY_NAMES = {
    "general": "support-tickets",
    "report": "player-reports",
    "ban_appeal": "ban-appeals",
    "staff_app": "staff-applications",
    "tebex": "donation-support",
    "business": "business-inquiries",
}


class TicketView(discord.ui.View):
    def __init__(self, cog):
        super().__init__(timeout=None)
        self.cog = cog

        options = [
            discord.SelectOption(label=label, value=value, description=desc, emoji="🎫")
            for value, label, desc in TICKET_TYPES
        ]
        select = discord.ui.Select(
            placeholder="Select ticket type...",
            options=options,
            custom_id="ticket_type_select"
        )
        select.callback = self.select_callback
        self.add_item(select)

    async def select_callback(self, interaction: discord.Interaction):
        await self.cog._create_ticket(interaction, interaction.data["values"][0])


class TicketActionsView(discord.ui.View):
    def __init__(self, cog, ticket_id: str):
        super().__init__(timeout=None)
        self.cog = cog
        self.ticket_id = ticket_id

        claim_btn = discord.ui.Button(label="Claim", style=discord.ButtonStyle.primary, custom_id=f"ticket_claim_{ticket_id}")
        claim_btn.callback = self.claim_callback
        self.add_item(claim_btn)

        close_btn = discord.ui.Button(label="Close", style=discord.ButtonStyle.danger, custom_id=f"ticket_close_{ticket_id}")
        close_btn.callback = self.close_callback
        self.add_item(close_btn)

        delete_btn = discord.ui.Button(label="Delete", style=discord.ButtonStyle.secondary, custom_id=f"ticket_delete_{ticket_id}")
        delete_btn.callback = self.delete_callback
        self.add_item(delete_btn)

    async def claim_callback(self, interaction: discord.Interaction):
        staff_role = await self.cog._get_staff_role()
        if staff_role and staff_role not in interaction.user.roles:
            await interaction.response.send_message("Only staff can claim tickets.", ephemeral=True)
            return
        await interaction.channel.edit(name=f"{interaction.channel.name}-claimed")
        await interaction.response.send_message(f"**{interaction.user.mention}** claimed this ticket.")
        self.cog.supabase.table("tickets").update({"claimed_by": str(interaction.user.id)}).eq("channel_id", str(interaction.channel.id)).execute()

    async def close_callback(self, interaction: discord.Interaction):
        staff_role = await self.cog._get_staff_role()
        is_staff = staff_role and staff_role in interaction.user.roles
        is_creator = str(interaction.user.id) == self._get_creator_id()
        if not is_staff and not is_creator:
            await interaction.response.send_message("Only staff or the ticket creator can close this.", ephemeral=True)
            return

        self.cog.supabase.table("tickets").update({"status": "closed"}).eq("channel_id", str(interaction.channel.id)).execute()

        logs_ch = await self.cog._get_logs_channel()
        if logs_ch:
            msgs = []
            async for msg in interaction.channel.history(limit=100, oldest_first=True):
                msgs.append(f"[{msg.created_at.strftime('%H:%M')}] {msg.author.display_name}: {msg.content or '(attachment)'}")
            transcript = "\n".join(msgs[-50:])
            await logs_ch.send(f"**Ticket #{self.ticket_id} closed by {interaction.user.mention}**\n```\n{transcript[:1800]}\n```")

        await interaction.channel.set_permissions(interaction.guild.default_role, send_messages=False)
        await interaction.response.send_message(f"**Ticket closed** by {interaction.user.mention}. React with 🔒 to delete.")

    def _get_creator_id(self) -> str:
        r = self.cog.supabase.table("tickets").select("creator_id").eq("channel_id", str(self.ticket_id)).execute()
        return r.data[0]["creator_id"] if r.data else ""

    async def delete_callback(self, interaction: discord.Interaction):
        staff_role = await self.cog._get_staff_role()
        is_staff = staff_role and staff_role in interaction.user.roles
        is_creator = str(interaction.user.id) == self._get_creator_id()
        if not is_staff and not is_creator:
            await interaction.response.send_message("Only staff or the ticket creator can delete this.", ephemeral=True)
            return

        self.cog.supabase.table("tickets").delete().eq("channel_id", str(interaction.channel.id)).execute()
        await interaction.response.send_message("Deleting in 3 seconds...")
        await asyncio.sleep(3)
        await interaction.channel.delete()


class TicketSystem(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self._staff_role_id = 0
        self._logs_channel_id = 0

    async def _get_staff_role(self) -> discord.Role | None:
        if not self._staff_role_id:
            r = self.supabase.table("bot_config").select("value").eq("key", "staff_role_id").execute()
            self._staff_role_id = int(r.data[0]["value"]) if r.data else 0
        guild = self.bot.get_guild(self.config.discord_guild_id)
        return guild.get_role(self._staff_role_id) if guild else None

    async def _get_logs_channel(self) -> discord.TextChannel | None:
        if not self._logs_channel_id:
            r = self.supabase.table("bot_config").select("value").eq("key", "log_channel_id").execute()
            self._logs_channel_id = int(r.data[0]["value"]) if r.data else 0
        guild = self.bot.get_guild(self.config.discord_guild_id)
        return guild.get_channel(self._logs_channel_id) if guild else None

    async def _get_or_create_category(self, guild: discord.Guild, name: str) -> discord.CategoryChannel:
        for cat in guild.categories:
            if cat.name == name:
                return cat
        return await guild.create_category(name)

    @app_commands.command(name="ticket", description="Open a support ticket")
    async def ticket_command(self, interaction: discord.Interaction):
        view = TicketView(self)
        embed = discord.Embed(
            title="Support Ticket System",
            description="Select the type of support you need below.",
            color=discord.Color.blurple()
        )
        embed.set_footer(text="Sinister State Support")
        await interaction.response.send_message(embed=embed, view=view, ephemeral=True)

    @app_commands.command(name="ticketpanel", description="[STAFF] Creates a ticket panel in this channel")
    async def ticket_panel(self, interaction: discord.Interaction):
        staff_role = await self._get_staff_role()
        if not staff_role or staff_role not in interaction.user.roles:
            await interaction.response.send_message("Staff only.", ephemeral=True)
            return

        view = TicketView(self)
        embed = discord.Embed(
            title="Sinister State Support",
            description="Open a ticket by selecting an option below.\nA staff member will assist you shortly.",
            color=discord.Color.blurple()
        )
        embed.add_field(name="Categories", value="\n".join(f"• **{l}** — {d}" for _, l, d in TICKET_TYPES))
        await interaction.channel.send(embed=embed, view=view)
        await interaction.response.send_message("Panel created.", ephemeral=True)

    async def _create_ticket(self, interaction: discord.Interaction, ticket_type: str):
        label = dict(TICKET_TYPES).get(ticket_type, ticket_type)
        cat_name = CATEGORY_NAMES.get(ticket_type, "support-tickets")
        guild = interaction.guild
        category = await self._get_or_create_category(guild, cat_name)

        staff_role = await self._get_staff_role()
        overwrites = {
            guild.default_role: discord.PermissionOverwrite(read_messages=False),
            interaction.user: discord.PermissionOverwrite(read_messages=True, send_messages=True),
            self.bot.user: discord.PermissionOverwrite(read_messages=True, send_messages=True),
        }
        if staff_role:
            overwrites[staff_role] = discord.PermissionOverwrite(read_messages=True, send_messages=True)

        ticket_num = self.supabase.table("tickets").select("id", count="exact").execute().count + 1
        channel = await guild.create_text_channel(
            f"ticket-{ticket_num:04d}",
            category=category,
            overwrites=overwrites
        )

        self.supabase.table("tickets").insert({
            "channel_id": str(channel.id),
            "creator_id": str(interaction.user.id),
            "ticket_type": ticket_type,
            "status": "open"
        }).execute()

        actions = TicketActionsView(self, str(channel.id))
        embed = discord.Embed(
            title=f"{label} — Ticket #{ticket_num:04d}",
            description=f"**Created by:** {interaction.user.mention}\n**Type:** {label}\n\nStaff will assist you shortly. Use the buttons below.",
            color=discord.Color.green()
        )
        embed.set_footer(text=f"Ticket #{ticket_num:04d} | Sinister State")
        await channel.send(f"{interaction.user.mention} {staff_role.mention if staff_role else ''}", embed=embed, view=actions)

        view = TicketView(self)
        await interaction.response.edit_message(view=view)


async def setup(bot: commands.Bot):
    await bot.add_cog(TicketSystem(bot))
