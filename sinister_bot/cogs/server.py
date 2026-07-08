import discord, os, aiohttp
from discord.ext import commands

HOST = "172.93.104.174"
PORT = 7777

class Server(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @discord.app_commands.command(name="status", description="Check if the FiveM server is online")
    async def status(self, interaction: discord.Interaction):
        url = f"http://{HOST}:{PORT}/info.json"
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=10) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        embed = discord.Embed(title="Sinister H-Town RP", color=discord.Color.green())
                        embed.add_field(name="Status", value="Online")
                        embed.add_field(name="Players", value=f"{data.get('players', '?')} / {data.get('maxplayers', '?')}")
                        embed.add_field(name="Server", value=data.get("hostname", "Sinister H-Town RP")[:100])
                        embed.set_footer(text=f"{HOST}:{PORT}")
                        return await interaction.response.send_message(embed=embed)
        except Exception:
            pass
        embed = discord.Embed(title="Sinister H-Town RP", color=discord.Color.red())
        embed.add_field(name="Status", value="Offline / Unreachable")
        embed.set_footer(text=f"{HOST}:{PORT}")
        await interaction.response.send_message(embed=embed)

    @discord.app_commands.command(name="players", description="List players currently online")
    async def players(self, interaction: discord.Interaction):
        url = f"http://{HOST}:{PORT}/players.json"
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=10) as resp:
                    if resp.status == 200:
                        players = await resp.json()
                        if not players:
                            return await interaction.response.send_message("No players online.", ephemeral=True)
                        lines = [f"{i+1}. **{p.get('name', 'Unknown')}**" for i, p in enumerate(players[:50])]
                        embed = discord.Embed(title=f"Online Players ({len(players)})", color=discord.Color.blue())
                        embed.description = "\n".join(lines)
                        return await interaction.response.send_message(embed=embed)
        except Exception:
            pass
        await interaction.response.send_message("Could not fetch player list.", ephemeral=True)

async def setup(bot):
    await bot.add_cog(Server(bot))
