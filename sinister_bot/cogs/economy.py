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

class Economy(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @discord.app_commands.command(name="setcash", description="Set a player's cash balance [Staff]")
    @is_staff()
    async def setcash(self, interaction: discord.Interaction, user: discord.User, amount: int):
        if not supabase:
            return await interaction.response.send_message("Supabase not configured.", ephemeral=True)
        result = supabase.table("discord_players").select("citizenid").eq("discord_id", str(user.id)).execute()
        if not result.data:
            return await interaction.response.send_message("Player not linked.", ephemeral=True)
        citizenid = result.data[0]["citizenid"]
        supabase.table("player_economy").update({"cash": amount}).eq("citizenid", citizenid).execute()
        embed = discord.Embed(title="Cash Updated", color=discord.Color.green())
        embed.add_field(name="Player", value=user.mention)
        embed.add_field(name="New Cash", value=f"${amount:,.2f}")
        await interaction.response.send_message(embed=embed)

    @discord.app_commands.command(name="addcash", description="Add cash to a player [Staff]")
    @is_staff()
    async def addcash(self, interaction: discord.Interaction, user: discord.User, amount: int):
        if not supabase:
            return await interaction.response.send_message("Supabase not configured.", ephemeral=True)
        result = supabase.table("discord_players").select("citizenid").eq("discord_id", str(user.id)).execute()
        if not result.data:
            return await interaction.response.send_message("Player not linked.", ephemeral=True)
        citizenid = result.data[0]["citizenid"]
        current = supabase.table("player_economy").select("cash").eq("citizenid", citizenid).execute()
        new_cash = (current.data[0]["cash"] or 0) + amount
        supabase.table("player_economy").update({"cash": new_cash}).eq("citizenid", citizenid).execute()
        embed = discord.Embed(title="Cash Added", color=discord.Color.green())
        embed.add_field(name="Player", value=user.mention)
        embed.add_field(name="Amount", value=f"+${amount:,.2f}")
        await interaction.response.send_message(embed=embed)

async def setup(bot):
    await bot.add_cog(Economy(bot))
