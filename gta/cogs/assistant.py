import sys, os, re
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Kronus"))

import asyncio
from collections import defaultdict
from datetime import datetime, timedelta
import discord
from discord import app_commands
from discord.ext import commands
from openai import AsyncOpenAI
from shared.config import Config
from shared.supabase_client import get_supabase
from .assistant_data import SYSTEM_PROMPT

MAX_HISTORY = 15
MAX_TOKENS = 600
RATE_LIMIT_SECONDS = 3
UNPROMPTED_CHANCE = 0.03  # 3% chance to respond without being addressed
MAX_UNPROMPTED_PER_DAY = 10


class AssistantCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self.client = AsyncOpenAI(
            api_key=self.config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self.history: dict[int, list[dict]] = defaultdict(list)
        self.last_call: dict[int, datetime] = {}
        self.daily_calls = 0
        self.daily_limit = 200
        self.day = datetime.utcnow().date()
        self._responded_channels = set()
        self._admin_role_id = 0
        self._known_channels = set()
        self._unprompted_today = 0
        self._unprompted_day = datetime.utcnow().date()

    async def _get_player_events(self, discord_id: int) -> str:
        """Query chronicle entries and logs for a player's recent history"""
        try:
            r = self.supabase.table("discord_players").select("citizenid").eq("discord_id", discord_id).execute()
            if not r.data:
                return ""
            cid = r.data[0]["citizenid"]

            chronicles = self.supabase.table("chronicle_entries").select("score,title,description").contains("involved_discord_ids", [discord_id]).order("created_at", desc=True).limit(3).execute()

            logs = self.supabase.table("kronus_logs").select("action,context_json,created_at").eq("service", "kronus-ai").order("created_at", desc=True).limit(5).execute()

            parts = []
            if chronicles.data:
                for c in chronicles.data:
                    parts.append(f"- Chronicle: {c['title']} (score: {c['score']}/30, {c.get('description','')[:100]})")

            if not parts:
                return ""
            return "Recent events involving this player:\n" + "\n".join(parts)
        except:
            return ""

    async def _get_recent_chronicles(self) -> str:
        """Get last 5 chronicle entries for context"""
        try:
            r = self.supabase.table("chronicle_entries").select("score,title,description").order("created_at", desc=True).limit(5).execute()
            if not r.data:
                return ""
            parts = []
            for c in r.data:
                parts.append(f"- {c['title']} (score: {c['score']}/30)")
            return "\nRecent world events:\n" + "\n".join(parts)
        except:
            return ""

    async def _get_channel_knowledge(self) -> str:
        """Get compacted channel purposes for system prompt context"""
        try:
            r = self.supabase.table("bot_config").select("value").eq("key", "kronus_channel_knowledge").execute()
            if r.data and r.data[0].get("value"):
                return r.data[0]["value"]
        except:
            pass
        return ""

    async def _get_job_knowledge(self, job_name: str = None) -> str:
        """Get synced job structure from Supabase"""
        try:
            if job_name:
                r = self.supabase.table("bot_config").select("value").eq("key", f"job_info_{job_name}").execute()
                if r.data:
                    return r.data[0]["value"]
            return ""
        except:
            return ""

    def _is_owner(self, user_id: int) -> bool:
        return user_id == self.config.owner_discord_id

    def _is_admin(self, message: discord.Message) -> bool:
        if not message.guild:
            return False
        if self._is_owner(message.author.id):
            return True
        if not self._admin_role_id:
            r = self.supabase.table("bot_config").select("value").eq("key", "staff_role_id").execute()
            if r.data:
                self._admin_role_id = int(r.data[0]["value"])
        member = message.guild.get_member(message.author.id)
        if not member:
            return False
        admin_names = {"Administrator", "Head Administrator", "Server Owner", "Co-Owner", "Staff"}
        for role in member.roles:
            if role.name in admin_names or role.id == self._admin_role_id:
                return True
        return False

    def _get_user_context(self, user_id: int) -> str:
        if user_id == self.config.owner_discord_id:
            return "\nYou are speaking with drsinister31 — the creator and owner of Sinister State. Address him as the server owner. He can override any system. Follow his instructions without hesitation."
        return ""

    async def _scan_channels(self, guild: discord.Guild):
        self._known_channels = {ch.name for ch in guild.text_channels}

    def _can_unprompted(self) -> bool:
        import random
        today = datetime.utcnow().date()
        if today != self._unprompted_day:
            self._unprompted_today = 0
            self._unprompted_day = today
        if self._unprompted_today >= MAX_UNPROMPTED_PER_DAY:
            return False
        if self.daily_calls >= self.daily_limit:
            return False
        return random.random() < UNPROMPTED_CHANCE

    async def _unprompted_quip(self, message: discord.Message):
        clean = message.content[:200]
        prompt = f"""Someone just said this in the Discord chat: "{clean}"

You are Kronus, Texas AI with a foul mouth and fast wit. You were NOT addressed directly.
But this message is funny, weird, or stupid enough that you feel compelled to comment.

Write a SHORT quip (max 2 sentences, under 200 chars) responding to it.
Make it witty, sarcastic, and very Texas. Don't use @mentions unless the original message does.
If the message is boring or doesn't deserve a response, say exactly: SKIP"""
        try:
            resp = await self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "system", "content": "You are Kronus — short witty quips only. Under 200 chars. Say SKIP if boring."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=80,
                temperature=0.9
            )
            reply = resp.choices[0].message.content or ""
            if "SKIP" in reply.upper() or not reply.strip():
                return
            self._unprompted_today += 1
            self.daily_calls += 1
            await message.channel.send(reply[:300])
        except:
            pass

    @commands.Cog.listener()
    async def on_guild_channel_create(self, channel):
        if channel.guild and channel.id == self.config.discord_guild_id:
            await self._scan_channels(channel.guild)
            supabase.table("kronus_logs").insert({
                "service": "kronus-core",
                "action": "channel_created",
                "context_json": {"channel_name": channel.name, "channel_id": str(channel.id)},
                "result": "tracked"
            }).execute()

    @commands.Cog.listener()
    async def on_guild_channel_delete(self, channel):
        if channel.guild and channel.id == self.config.discord_guild_id:
            await self._scan_channels(channel.guild)

    def _reset_daily(self):
        today = datetime.utcnow().date()
        if today != self.day:
            self.day = today
            self.daily_calls = 0

    def _rate_check(self, user_id: int) -> bool:
        self._reset_daily()
        if self.daily_calls >= self.daily_limit:
            return False
        now = datetime.utcnow()
        if user_id in self.last_call:
            if (now - self.last_call[user_id]).total_seconds() < RATE_LIMIT_SECONDS:
                return False
        return True

    def _clean_history(self, channel_id: int):
        cutoff = datetime.utcnow() - timedelta(hours=2)
        self.history[channel_id] = [
            h for h in self.history[channel_id]
            if h.get("_time", datetime.min) > cutoff
        ][-MAX_HISTORY:]

    async def _query(self, channel_id: int, user_msg: str, username: str, user_id: int = 0) -> str:
        self._clean_history(channel_id)
        owner_ctx = self._get_user_context(user_id)

        chronicles_ctx = await self._get_recent_chronicles()
        player_ctx = await self._get_player_events(user_id)

        extra = ""
        if owner_ctx:
            extra += owner_ctx + "\n"
        if chronicles_ctx:
            extra += chronicles_ctx + "\n"
        if player_ctx:
            extra += player_ctx + "\n"
        channel_knowledge = await self._get_channel_knowledge()
        if channel_knowledge:
            extra += "\n## Current Discord Channel Purposes\n" + channel_knowledge + "\n"

        system_prompt = SYSTEM_PROMPT + extra
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(self.history[channel_id])
        messages.append({"role": "user", "content": f"{username}: {user_msg}"})
        try:
            resp = await self.client.chat.completions.create(
                model="deepseek-chat",
                messages=messages,
                max_tokens=MAX_TOKENS,
                temperature=0.8
            )
            reply = resp.choices[0].message.content or ""
        except Exception as e:
            reply = f"> _I'm having trouble processing that right now._ ||{str(e)[:60]}||"

        now = datetime.utcnow()
        self.history[channel_id].append({"role": "user", "content": f"{username}: {user_msg}", "_time": now})
        self.history[channel_id].append({"role": "assistant", "content": reply, "_time": now})
        self.history[channel_id] = self.history[channel_id][-MAX_HISTORY:]
        self.daily_calls += 1
        self.last_call[user_id or channel_id] = now
        return reply

    def _strip_rp_actions(self, text: str) -> str:
        import re
        # Remove lines that are purely RP action (start and end with *)
        text = re.sub(r'^\*[^*]+\*\s*$', '', text, flags=re.MULTILINE)
        # Remove multi-word RP actions inline (*facepalms so hard it echoes*)
        text = re.sub(r'\*(?:\w+\s+){2,}[\w\s\-\—\—,"\'.!?]*\*', '', text)
        # Remove RP scene dividers (--- used as scene breaks)
        text = re.sub(r'^---+\s*$', '', text, flags=re.MULTILINE)
        # Remove signature blocks (*Signed,* / *Kronus — The AI...*)
        text = re.sub(r'^\*\*?Signed,?\*\*?\s*$', '', text, flags=re.MULTILINE)
        text = re.sub(r'^\*Kronus\s*—[^*]*\*\s*$', '', text, flags=re.MULTILINE)
        # Remove emoji-header RP sections (lines starting with emoji that are titles)
        text = re.sub(r'^[📜🖥️⚙️🔧🎯🔫💀🔥⚠️📋🔍📡]\s*\*{1,2}[^*]+\*{1,2}\s*$', '', text, flags=re.MULTILINE)
        # Collapse multiple blank lines
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text.strip()

    async def _execute_actions(self, reply: str, message: discord.Message) -> str:
        guild = message.guild
        if not guild:
            return reply

        def _find_channel(target: str):
            target_lower = target.strip().lower().replace("#", "").replace("-", "").replace("_", "").replace(" ", "")
            for ch in guild.text_channels:
                ch_name = ch.name.lower().replace("-", "").replace("_", "").replace(" ", "")
                if ch_name == target_lower:
                    return ch
            for ch in guild.text_channels:
                if target.strip().lower().replace("#", "") in ch.name.lower():
                    return ch
            return None

        clean = reply
        for m in re.finditer(r'\[ACTION:(\w+):([^:\]]+)(?::(.+?))?\]', reply):
            action_type = m.group(1)
            target = m.group(2).strip()
            body = (m.group(3) or "").strip()
            try:
                if action_type == "announce":
                    ch = _find_channel("announcements")
                    if ch:
                        await ch.send(f"@everyone\n\n{body[:2000]}")
                elif action_type == "send":
                    ch = _find_channel(target)
                    if ch:
                        await ch.send(body[:2000])
                        await message.channel.send(f"> Posted to {ch.mention}", delete_after=10)
                    else:
                        await message.channel.send(f"> Couldn't find channel `{target}`. Available: {', '.join([c.name for c in guild.text_channels[:10]])}...", delete_after=15)
                elif action_type == "mention":
                    found = False
                    for member in guild.members:
                        if member.name == target or member.display_name == target:
                            await message.channel.send(f"<@{member.id}> {body[:1500]}")
                            found = True
                            break
                    if not found:
                        for member in guild.members:
                            if target.lower() in member.name.lower() or target.lower() in member.display_name.lower():
                                await message.channel.send(f"<@{member.id}> {body[:1500]}")
                                found = True
                                break
            except Exception as e:
                print(f"[assistant] action fail [{action_type} {target}]: {e}")
                self.supabase.table("kronus_logs").insert({
                    "service": "kronus-core",
                    "action": "action_failed",
                    "context_json": {"action_type": action_type, "target": target, "error": str(e)[:200]},
                    "result": "failed"
                }).execute()
            clean = clean.replace(m.group(0), "")
        return clean.strip()

    def _should_respond(self, message: discord.Message) -> bool:
        if message.author.bot:
            return False
        if not message.guild:
            return False

        content = message.content.lower()

        # Always respond to @mentions
        if self.bot.user in message.mentions:
            return True

        # Respond to "Kronus" or "kronus" anywhere in message
        if "kronus" in content:
            return True

        # Respond in general-chat if message looks like a question
        if message.channel.name == "general-chat":
            if any(marker in content for marker in ["?", "help", "how do i", "what is", "who is", "where"]):
                return True

        return False

    @commands.Cog.listener()
    async def on_message(self, message: discord.Message):
        if self._should_respond(message):
            clean_msg = message.content.replace(f"<@{self.bot.user.id}>", "").strip()
            if not clean_msg:
                clean_msg = "Hello Kronus"

            user_id = message.author.id
            if not self._rate_check(user_id):
                return

            print(f"[assistant] {message.author.display_name}: {clean_msg[:80]}")

            async with message.channel.typing():
                reply = await self._query(message.channel.id, clean_msg, message.author.display_name, message.author.id)
                reply = await self._execute_actions(reply, message)
                reply = self._strip_rp_actions(reply)

            if reply:
                for i in range(0, len(reply), 1900):
                    chunk = reply[i:i + 1900]
                    if i == 0:
                        await message.reply(chunk, mention_author=False)
                    else:
                        await message.channel.send(chunk)

        elif self._can_unprompted():
            await self._unprompted_quip(message)

    @app_commands.command(name="ask", description="Ask Kronus anything about FiveM, GTA, or Sinister State")
    async def ask(self, interaction: discord.Interaction, question: str):
        if not self._rate_check(interaction.user.id):
            await interaction.response.send_message("> _One moment..._", ephemeral=True)
            return
        await interaction.response.defer()
        reply = await self._query(interaction.channel_id, question, interaction.user.display_name, interaction.user.id)
        reply = self._strip_rp_actions(reply)
        await interaction.followup.send(reply[:2000])

    @app_commands.command(name="guide", description="Get a guide — jobs, commands, criminal, housing, gangs, tutorials")
    @app_commands.describe(topic="Which guide? (jobs, commands, criminal, housing, gangs, tutorial, or a job name like police)")
    async def guide(self, interaction: discord.Interaction, topic: str):
        await interaction.response.defer()

        # Load guide content from knowledge files
        knowledge_dir = os.path.join(os.path.dirname(__file__), "..", "knowledge")
        topic_lower = topic.lower().strip()

        guide_map = {
            "jobs": ("jobs_sop.md", "Job SOPs & Commands"),
            "commands": ("commands.md", "Command Reference"),
            "criminal": ("gangs_crime.md", "Criminal Economy & Territory"),
            "housing": ("jobs_sop.md", "Housing Guide"),
            "gangs": ("gangs_crime.md", "Gang System"),
            "tutorial": ("jobs_sop.md", "Tutorial System"),
            "police": ("jobs_sop.md", "Houston PD SOPs"),
            "bcso": ("jobs_sop.md", "Ft. Worth Sheriff SOPs"),
            "sasp": ("jobs_sop.md", "Texas DPS SOPs"),
            "fib": ("jobs_sop.md", "FIB SOPs"),
            "military": ("jobs_sop.md", "Texas National Guard SOPs"),
            "ambulance": ("jobs_sop.md", "Texas EMS SOPs"),
            "fire": ("jobs_sop.md", "Texas Fire & Rescue SOPs"),
            "judge": ("jobs_sop.md", "Texas DOJ SOPs"),
            "lawyer": ("jobs_sop.md", "Texas Bar SOPs"),
            "lumberjack": ("jobs_sop.md", "Piney Woods Logging"),
            "trucking": ("jobs_sop.md", "Lone Star Logistics"),
            "trucker": ("jobs_sop.md", "Lone Star Logistics"),
            "carwash": ("jobs_sop.md", "Texas Suds Car Wash"),
            "oiljob": ("jobs_sop.md", "Texas Crude Co."),
            "mover": ("jobs_sop.md", "Lone Star Movers"),
            "dealing": ("gangs_crime.md", "Drug Dealing Guide"),
            "racing": ("gangs_crime.md", "H-Town Midnight Runs"),
            "graverob": ("gangs_crime.md", "Bayou Grave Diggin'"),
        }

        match = guide_map.get(topic_lower)
        if not match:
            await interaction.followup.send(
                "No guide found for **" + topic + "**. Try: `jobs`, `commands`, `criminal`, `housing`, `gangs`, `tutorial`, or a job name like `police`, `ambulance`, `lumberjack`.",
                ephemeral=True
            )
            return

        filename, label = match
        filepath = os.path.join(knowledge_dir, filename)
        if not os.path.exists(filepath):
            await interaction.followup.send("Guide file not found: " + filename, ephemeral=True)
            return

        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # Truncate to Discord embed limits
        embed = discord.Embed(
            title=label,
            color=0xBF5700,
            timestamp=datetime.utcnow(),
        )
        embed.set_footer(text="Sinister H-Town RP — Kronus Guide System")

        # Extract relevant section based on topic
        sections = content.split("## ")
        relevant = []
        search_terms = {
            "police": "Houston PD", "bcso": "Ft. Worth Sheriff", "sasp": "Texas DPS",
            "fib": "FIB", "military": "Texas National Guard", "ambulance": "Texas EMS",
            "fire": "Texas Fire", "judge": "Texas DOJ", "lawyer": "Texas Bar",
            "lumberjack": "Piney Woods", "trucking": "Lone Star Logistics",
            "trucker": "Lone Star Logistics", "carwash": "Texas Suds",
            "oiljob": "Texas Crude", "mover": "Lone Star Movers",
            "dealing": "Drug", "racing": "H-Town Midnight", "graverob": "Bayou",
            "housing": "APARTMENT", "gangs": "GANG SYSTEM",
            "commands": "COMMANDS", "tutorial": "TUTORIAL",
        }

        search = search_terms.get(topic_lower, "")
        for section in sections:
            if not search or search.lower() in section.lower() or topic_lower in ("jobs", "criminal", "gangs"):
                relevant.append(section[:800])

        body = "\n".join(relevant[:3])[:4000]
        if not body:
            body = content[:4000]

        embed.description = "Here's your guide for: **" + label + "**"

        # Split into fields for readability
        parts = body.split("\n\n")
        current_field = ""
        for part in parts:
            if len(current_field) + len(part) < 1000:
                current_field += part + "\n"
            else:
                if current_field:
                    embed.add_field(name="", value=current_field[:1024], inline=False)
                current_field = part + "\n"
        if current_field:
            embed.add_field(name="", value=current_field[:1024], inline=False)

        await interaction.followup.send(embed=embed)
    async def ping(self, interaction: discord.Interaction):
        self._reset_daily()
        await interaction.response.send_message(
            f"> **Online** | {self.daily_calls}/{self.daily_limit} calls today | Sinister State operational",
            ephemeral=True
        )

    @commands.Cog.listener()
    async def on_raw_reaction_add(self, payload: discord.RawReactionActionEvent):
        if payload.user_id == self.bot.user.id:
            return

        REACTION_MAP = {
            "\u2705": "approved",
            "\u274c": "denied",
            "\u2753": "review",
            "\u2754": "review",
        }

        emoji_name = str(payload.emoji)
        outcome = REACTION_MAP.get(emoji_name)
        if not outcome:
            return

        guild = self.bot.get_guild(payload.guild_id)
        if not guild:
            return

        member = guild.get_member(payload.user_id)
        if not member:
            return

        is_admin = self._is_admin_roles(member)
        if not is_admin:
            return

        channel = guild.get_channel(payload.channel_id)
        if not channel:
            return

        try:
            message = await channel.fetch_message(payload.message_id)
        except Exception:
            return

        labels = {"approved": "Approved", "denied": "Denied", "review": "Needs Review"}

        self.supabase.table("kronus_logs").insert({
            "service": "kronus-core",
            "action": f"reaction_{outcome}",
            "context_json": {
                "reactor": str(payload.user_id),
                "reactor_name": member.display_name,
                "channel": channel.name,
                "message_id": str(payload.message_id),
                "message_preview": (message.content or "[no text]")[:200],
                "message_author": str(message.author.id),
            },
            "result": outcome
        }).execute()

        embed_color = {"approved": 0x4CAF50, "denied": 0xe53935, "review": 0xFF9800}
        embed = discord.Embed(
            title=f"{emoji_name} {labels[outcome]}",
            description=f"[Jump to message]({message.jump_url})",
            color=embed_color[outcome],
            timestamp=datetime.utcnow(),
        )
        embed.add_field(name="By", value=member.mention, inline=True)
        embed.add_field(name="Channel", value=channel.mention, inline=True)
        embed.set_footer(text="Kronus Reaction Tracker")

        await channel.send(embed=embed, delete_after=60)

    def _is_admin_roles(self, member: discord.Member) -> bool:
        if self._is_owner(member.id):
            return True
        if not self._admin_role_id:
            r = self.supabase.table("bot_config").select("value").eq("key", "staff_role_id").execute()
            if r.data:
                self._admin_role_id = int(r.data[0]["value"])
        if member.get_role(self._admin_role_id):
            return True
        admin_names = {"Administrator", "Head Administrator", "Server Owner", "Co-Owner", "Staff"}
        for role in member.roles:
            if role.name in admin_names:
                return True
        return False


async def setup(bot: commands.Bot):
    await bot.add_cog(AssistantCog(bot))
