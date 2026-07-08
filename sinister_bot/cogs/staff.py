import discord, os
from discord.ext import commands
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_URL and SUPABASE_KEY else None

STAFF_ROLES = os.getenv("STAFF_ROLES", "Admin,Senior Admin,Developer").split(",")

def is_staff():
    async def predicate(interaction: discord.Interaction):
        return any(role.name in STAFF_ROLES for role in interaction.user.roles)
    return discord.app_commands.check(predicate)

class Staff(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @discord.app_commands.command(name="warn", description="Warn a player")
    @is_staff()
    async def warn(self, interaction: discord.Interaction, user: discord.User, reason: str):
        if not supabase:
            return await interaction.response.send_message("Supabase not configured.", ephemeral=True)
        result = supabase.table("discord_players").select("citizenid").eq("discord_id", str(user.id)).execute()
        if not result.data:
            return await interaction.response.send_message("Player not linked.", ephemeral=True)
        citizenid = result.data[0]["citizenid"]
        supabase.table("strikes").insert({
            "citizenid": citizenid,
            "issuer": str(interaction.user.id),
            "reason": reason,
            "severity": "warn"
        }).execute()
        embed = discord.Embed(title="Warning Issued", color=discord.Color.orange())
        embed.add_field(name="Player", value=user.mention)
        embed.add_field(name="Reason", value=reason)
        try:
            await user.send(f"You have been warned in Sinister State RP: {reason}")
        except:
            pass
        await interaction.response.send_message(embed=embed)

    @discord.app_commands.command(name="strike", description="Issue a strike to a player")
    @is_staff()
    async def strike(self, interaction: discord.Interaction, user: discord.User, reason: str):
        if not supabase:
            return await interaction.response.send_message("Supabase not configured.", ephemeral=True)
        result = supabase.table("discord_players").select("citizenid").eq("discord_id", str(user.id)).execute()
        if not result.data:
            return await interaction.response.send_message("Player not linked.", ephemeral=True)
        citizenid = result.data[0]["citizenid"]
        supabase.table("strikes").insert({
            "citizenid": citizenid,
            "issuer": str(interaction.user.id),
            "reason": reason,
            "severity": "strike"
        }).execute()
        embed = discord.Embed(title="Strike Issued", color=discord.Color.red())
        embed.add_field(name="Player", value=user.mention)
        embed.add_field(name="Reason", value=reason)
        try:
            await user.send(f"You have received a strike in Sinister State RP: {reason}")
        except:
            pass
        await interaction.response.send_message(embed=embed)

    @discord.app_commands.command(name="announce", description="Send an announcement")
    @is_staff()
    async def announce(self, interaction: discord.Interaction, channel: discord.TextChannel, message: str):
        embed = discord.Embed(title="Announcement", description=message, color=discord.Color.gold())
        embed.set_footer(text=f"Posted by {interaction.user.display_name}")
        await channel.send(embed=embed)
        await interaction.response.send_message("Announcement posted.", ephemeral=True)

async def setup(bot):
    await bot.add_cog(Staff(bot))
