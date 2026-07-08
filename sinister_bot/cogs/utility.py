import discord
from discord.ext import commands

class Utility(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @discord.app_commands.command(name="ping", description="Check bot latency")
    async def ping(self, interaction: discord.Interaction):
        latency = round(self.bot.latency * 1000)
        await interaction.response.send_message(f"Pong! `{latency}ms`", ephemeral=True)

    @discord.app_commands.command(name="help", description="List all available commands")
    async def help(self, interaction: discord.Interaction):
        cmds = []
        for cog_name in self.bot.cogs:
            cog = self.bot.cogs[cog_name]
            for cmd in cog.walk_app_commands():
                cmds.append(f"`/{cmd.name}` - {cmd.description}")
        embed = discord.Embed(title="Sinister Bot Commands", color=discord.Color.blue())
        embed.description = "\n".join(cmds) if cmds else "No commands loaded."
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.app_commands.command(name="about", description="About this bot")
    async def about(self, interaction: discord.Interaction):
        embed = discord.Embed(
            title="Sinister Bot",
            description="FiveM server management bot for Sinister State RP",
            color=discord.Color.gold()
        )
        embed.add_field(name="Version", value="1.0.0")
        embed.add_field(name="Commands", value="Command-only (no AI)")
        await interaction.response.send_message(embed=embed, ephemeral=True)

async def setup(bot):
    await bot.add_cog(Utility(bot))
