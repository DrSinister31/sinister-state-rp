import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import asyncio
import discord
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase

intents = discord.Intents.default()
intents.message_content = True
intents.members = True
intents.voice_states = True

bot = commands.Bot(command_prefix="!", intents=intents)
config = Config.from_env()
supabase = get_supabase(config)

GUIDE_EMBED = discord.Embed(
    title="📜 Solis-Grave Player Guide — How to Play",
    description=(
        "Welcome to **Solis-Grave: Shadows of the Crown**, a dark fantasy D&D 5e campaign "
        "set in a world where dragon blood determines your fate. Here's how everything works.\n\n"
        "**I am your AI Dungeon Master, powered by DeepSeek.** I narrate the story, control NPCs, "
        "resolve combat, and track your party's progress. You play your character — I handle everything else."
    ),
    color=0x8B0000
)
GUIDE_EMBED.add_field(
    name="🔰 Getting Started — Your First Session",
    value=(
        "1️⃣ **Create your character.** Type `/create` in the character creation channel. I'll guide you through race, age, purity, class, and backstory.\n"
        "2️⃣ **Check your sheet.** Use `/character_mine` to view your full character sheet in DMs. `/character_list` shows the party.\n"
        "3️⃣ **Start a session.** The DM uses `/session_start` to begin. All actions typed in the session channel go to me.\n"
        "4️⃣ **Play!** Type your character's actions naturally. I respond in-character, roll dice, and advance the story."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="🎲 Rolling Dice & Taking Actions",
    value=(
        "• **Combat:** I track initiative, HP, conditions, and monster stats behind the screen. "
        "Tell me what you do — \"I swing my sword at the guard\" — and I handle the math.\n"
        "• **Skill checks:** I'll ask for DC checks. \"Give me a DC 15 Perception check.\"\n"
        "• **Rolling:** Use the dice bot in <#1514245057350209597>. I read the results automatically.\n"
        "• **Saving throws & reactions:** Describe them and I resolve. \"I dive behind the pillar!\""
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="📈 Leveling Up & XP",
    value=(
        "All characters start at **Level 1**. You gain XP through:\n"
        "⚔️ **Combat** — defeating enemies\n"
        "🎯 **Quests** — completing missions and discovering secrets\n"
        "🎭 **Roleplay** — staying true to your character's personality, flaws, and alignment "
        "earns hidden bonus XP\n\n"
        "Check your progress anytime with `/xp`."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="🗣️ Voice Chat & Narration",
    value=(
        "• **TTS Narration:** The DM can speak scene descriptions aloud in voice chat. Use `/dm_join` to invite me.\n"
        "• **Voice-switching:** Different NPCs get different voices automatically — guards, nobles, children, monsters.\n"
        "• **Stream detection:** I detect when you go live and can read dice from screenshots.\n"
        "• **Voice-to-voice (experimental):** Set `DM_WHISPER_ENABLED=1` to enable speech recognition."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="🛡️ Combat Rules",
    value=(
        "• Initiative is tracked automatically. Use `/initiative <name> <roll>`.\n"
        "• I track your HP, AC, conditions, death saves, and spell slots.\n"
        "• Use `/character_longrest` or `/character_shortrest` to recover resources.\n"
        "• Combat is cinematic — I narrate hits, misses, and kills. The math stays behind the screen."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="🧬 Blood Purity & Magic",
    value=(
        "Magic comes from **dragon blood purity** — a percentage revealed on your 15th birthday (Day of Ascension).\n"
        "• **0% (Blank):** No magic. Resistant to spells targeting you.\n"
        "• **1-14% (Common):** No magic. Standard citizen.\n"
        "• **15-39% (Lesser Blood):** Cantrips + low-level magic. Spell Safety checks required.\n"
        "• **40-85% (Archon):** Full magic. Noble status. Reduced Spell Safety DC.\n"
        "• **90%+ (Scion/Sovereign):** Cataclysmic power. Hidden. Hunted.\n\n"
        "Casting spells without sufficient purity causes **Aether Burn** — internal damage that ignores resistances. "
        "Use `/lore aether burn` for the full rules."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="🏛️ The World",
    value=(
        "Solis-Grave is a brutal feudal continent governed by **six Great Houses** descended from ancient Sovereign Dragons. "
        "The **Church of the Five Skulls** maintains order through Inquisitors who hunt illegal spellcasters.\n\n"
        "You begin at the **Citadel of the Dragon-Garrison**, a cutthroat military academy. "
        "Your blood purity determines your caste. Your choices determine your fate.\n\n"
        "Use `/lore <topic>` to search the compendium anytime."
    ),
    inline=False
)
GUIDE_EMBED.add_field(
    name="⚙️ Useful Commands",
    value=(
        "`/help` — Full command list\n"
        "`/create` — Make a character\n"
        "`/character_view <name>` — View any sheet\n"
        "`/character_mine` — Your full sheet in DMs\n"
        "`/xp` — Check level progress\n"
        "`/roll 2d6+3` — Roll dice\n"
        "`/lore <query>` — Compendium lookup\n"
        "`/session_start` / `/session_end` — Control sessions\n"
        "`/dm_voices` — Preview TTS voices"
    ),
    inline=False
)
GUIDE_EMBED.set_footer(text="Solis-Grave: Shadows of the Crown · AI Dungeon Master powered by DeepSeek")


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
    dm_mode = os.getenv("DM_MODE", "1") == "1"  # DM mode is DEFAULT
    print(f"[kronus-core] Online as {bot.user} on {len(bot.guilds)} guild(s) (DM Mode: {dm_mode})")

    guild = bot.get_guild(config.discord_guild_id)
    if not guild:
        print(f"[kronus-core] Guild {config.discord_guild_id} not found!")
        return

    if not dm_mode:
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

        guide_cog = bot.get_cog("ChannelManager")
        if guide_cog:
            guide_cat_id = await guide_cog.ensure_guide_channels(config.discord_guild_id)
            print(f"  GUIDE category: {guide_cat_id}")
    else:
        print(f"[kronus-core] DM Mode — skipping GTA RP auto-config")

    await asyncio.sleep(2)
    guild_obj = discord.Object(id=config.discord_guild_id)
    bot.tree.copy_global_to(guild=guild_obj)
    synced = await bot.tree.sync(guild=guild_obj)
    print(f"[kronus-core] {len(synced)} slash commands synced. Auto-config complete.")

    if config.dm_guide_channel_id:
        guide_ch = guild.get_channel(config.dm_guide_channel_id)
        if guide_ch and isinstance(guide_ch, discord.TextChannel):
            try:
                msgs = [m async for m in guide_ch.history(limit=5)]
                if not any("Solis-Grave Player Guide" in (m.content or "") for m in msgs):
                    await guide_ch.send(embed=GUIDE_EMBED)
                    print(f"  Posted player guide to #{guide_ch.name}")
            except Exception as e:
                print(f"  Guide post skipped: {e}")


async def main():
    dm_mode = os.getenv("DM_MODE", "1") == "1"  # DM mode is DEFAULT

    if dm_mode:
        cogs = [
            "cogs.compendium",
            "cogs.dm_voice",
            "cogs.dm_session",
            "cogs.dm_sheets",
        ]
        print("[kronus-core] DM MODE — Loading D&D cogs only")
    else:
        cogs = [
            "cogs.channel_manager",
            "cogs.role_sync",
            "gta.cogs.rcon_bridge",
            "cogs.chronicles",
            "gta.cogs.assistant",
            "cogs.tickets",
            "cogs.staff",
            "cogs.channel_memory",
            "cogs.compendium",
            "cogs.dm_voice",
            "cogs.dm_session",
            "cogs.dm_sheets",
        ]
        print("[kronus-core] GTA MODE — Loading all cogs")

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
