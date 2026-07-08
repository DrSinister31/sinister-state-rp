import os, discord
from discord.ext import commands
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN = os.getenv("DISCORD_TOKEN")
GUILD_ID = int(os.getenv("DISCORD_GUILD_ID", "0"))

intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = commands.Bot(command_prefix="!", intents=intents)

@bot.event
async def on_ready():
    print(f"Logged in as {bot.user} (ID: {bot.user.id})")
    if GUILD_ID:
        guild = bot.get_guild(GUILD_ID)
        if guild:
            bot.tree.copy_global_to(guild=discord.Object(id=GUILD_ID))
            await bot.tree.sync(guild=discord.Object(id=GUILD_ID))
            print(f"Synced commands to guild: {guild.name}")

async def load_cogs():
    cogs_dir = os.path.join(os.path.dirname(__file__), "cogs")
    for file in os.listdir(cogs_dir):
        if file.endswith(".py") and not file.startswith("_"):
            await bot.load_extension(f"cogs.{file[:-3]}")
            print(f"Loaded cog: {file[:-3]}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(load_cogs())
    bot.run(BOT_TOKEN)
