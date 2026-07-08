import discord, os
from discord.ext import commands
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_URL and SUPABASE_KEY else None

class Player(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @discord.app_commands.command(name="lookup", description="Look up a player's character info by Discord user")
    async def lookup(self, interaction: discord.Interaction, user: discord.User):
        if not supabase:
            return await interaction.response.send_message("Supabase not configured.", ephemeral=True)
        result = supabase.table("discord_players").select("citizenid").eq("discord_id", str(user.id)).execute()
        if not result.data:
            return await interaction.response.send_message("That user is not linked to any FiveM character.", ephemeral=True)
        citizenid = result.data[0]["citizenid"]
        char = supabase.table("characters").select("*").eq("citizenid", citizenid).execute()
        econ = supabase.table("player_economy").select("cash, bank").eq("citizenid", citizenid).execute()
        embed = discord.Embed(title=f"Player: {user.display_name}", color=discord.Color.blue())
        if char.data:
            c = char.data[0]
            embed.add_field(name="Character", value=f"{c.get('firstname', '?')} {c.get('lastname', '?')}")
            embed.add_field(name="Job", value=c.get("job", "Unemployed"))
            embed.add_field(name="DOB", value=c.get("dob", "Unknown"))
        if econ.data:
            e = econ.data[0]
            embed.add_field(name="Cash", value=f"${e.get('cash', 0):,.2f}")
            embed.add_field(name="Bank", value=f"${e.get('bank', 0):,.2f}")
        embed.set_footer(text=f"Citizen ID: {citizenid}")
        await interaction.response.send_message(embed=embed)

async def setup(bot):
    await bot.add_cog(Player(bot))
