import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import asyncio
import discord
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase

intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = commands.Bot(command_prefix="!", intents=intents)
config = Config.from_env()
supabase = get_supabase(config)


async def _read_config(key: str, default: int = 0) -> int:
    result = supabase.table("bot_config").select("value").eq("key", key).execute()
    if result.data:
        return int(result.data[0]["value"])
    return default


async def _write_config(key: str, value: int) -> None:
    supabase.table("bot_config").upsert({"key": key, "value": str(value), "updated_at": "now()"}).execute()


async def _find_or_create_channel(guild: discord.Guild, name: str, config_key: str) -> int:
    existing = await _read_config(config_key)
    if existing:
        channel = guild.get_channel(existing)
        if channel:
            return channel.id

    for ch in guild.text_channels:
        if ch.name == name:
            await _write_config(config_key, ch.id)
            return ch.id

    overwrites = {guild.default_role: discord.PermissionOverwrite(send_messages=False)}
    channel = await guild.create_text_channel(name, overwrites=overwrites)
    await _write_config(config_key, channel.id)
    return channel.id


async def _find_or_create_role(guild: discord.Guild, name: str, config_key: str,
                               color: discord.Color = discord.Color.default()) -> int:
    existing = await _read_config(config_key)
    if existing:
        role = guild.get_role(existing)
        if role:
            return role.id

    for role in guild.roles:
        if role.name == name:
            await _write_config(config_key, role.id)
            return role.id

    role = await guild.create_role(name=name, color=color, mentionable=True,
                                   reason="Kronus auto-config")
    await _write_config(config_key, role.id)
    return role.id


@bot.event
async def on_ready():
    print(f"[kronus-core] Online as {bot.user} on {len(bot.guilds)} guild(s)")

    guild = bot.get_guild(config.discord_guild_id)
    if not guild:
        print(f"[kronus-core] Guild {config.discord_guild_id} not found!")
        return

    print(f"[kronus-core] Auto-configuring for guild: {guild.name}")

    chronicles_id = await _find_or_create_channel(guild, "chronicles", "chronicles_channel_id")
    print(f"  chronicles channel: {chronicles_id}")

    logs_id = await _find_or_create_channel(guild, "kronus-logs", "log_channel_id")
    print(f"  kronus-logs channel: {logs_id}")

    support_id = await _find_or_create_channel(guild, "support", "support_channel_id")
    print(f"  support channel: {support_id}")

    owner_role = await _find_or_create_role(guild, "Business Owner", "business_owner_role_id",
                                            discord.Color.gold())
    print(f"  Business Owner role: {owner_role}")

    emp_role = await _find_or_create_role(guild, "Business Employee", "business_employee_role_id",
                                          discord.Color.blue())
    print(f"  Business Employee role: {emp_role}")

    staff_role = await _find_or_create_role(guild, "Staff", "staff_role_id", discord.Color.red())
    print(f"  Staff role: {staff_role}")

    await asyncio.sleep(2)
    guild_obj = discord.Object(id=config.discord_guild_id)
    bot.tree.copy_global_to(guild=guild_obj)
    synced = await bot.tree.sync(guild=guild_obj)
    print(f"[kronus-core] {len(synced)} slash commands synced. Auto-config complete.")


@bot.event
async def on_guild_channel_create(channel):
    pass


@bot.event
async def on_guild_role_create(role):
    pass


async def main():
    cogs = [
        "cogs.channel_manager",
        "cogs.role_sync",
        "cogs.rcon_bridge",
        "cogs.chronicles",
        "cogs.assistant",
        "cogs.tickets",
        "cogs.staff",
    ]
    for cog in cogs:
        try:
            await bot.load_extension(cog)
            print(f"[kronus-core] Loaded {cog}")
        except Exception as e:
            print(f"[kronus-core] Failed {cog}: {e}")
            import traceback
            traceback.print_exc()

    await bot.start(config.discord_token)


if __name__ == "__main__":
    asyncio.run(main())
