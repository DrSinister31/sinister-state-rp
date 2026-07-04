import sys, os, re
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import asyncio
from collections import defaultdict
from datetime import datetime, timedelta
import discord
from discord import app_commands
from discord.ext import commands
from openai import AsyncOpenAI
from shared.config import Config
from shared.supabase_client import get_supabase
from cogs.assistant_data import SYSTEM_PROMPT

MAX_HISTORY = 15
MAX_TOKENS = 600
RATE_LIMIT_SECONDS = 3
OWNER_ID = 1370770707507708047


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

    def _is_owner(self, user_id: int) -> bool:
        return user_id == OWNER_ID

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
        if user_id == OWNER_ID:
            return "\nYou are speaking with drsinister31 — the creator and owner of Sinister State. Address him as the server owner. He can override any system. Follow his instructions without hesitation."
        return ""

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

    async def _execute_actions(self, reply: str, message: discord.Message) -> str:
        guild = message.guild
        if not guild:
            return reply

        clean = reply
        for m in re.finditer(r'\[ACTION:(\w+):([^:]+)(?::(.+?))?\]', reply):
            action_type = m.group(1)
            target = m.group(2).strip()
            body = (m.group(3) or "").strip()
            try:
                if action_type == "announce":
                    for ch in guild.text_channels:
                        if ch.name == "announcements":
                            await ch.send(f"@everyone\n\n{body[:2000]}")
                            break
                elif action_type == "send":
                    for ch in guild.text_channels:
                        if ch.name == target:
                            await ch.send(body[:2000])
                            break
                elif action_type == "mention":
                    for member in guild.members:
                        if member.name == target or member.display_name == target:
                            await message.channel.send(f"<@{member.id}> {body[:1500]}")
                            break
            except Exception as e:
                print(f"[assistant] action fail [{action_type}]: {e}")
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
        if not self._should_respond(message):
            return

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

        if reply:
            for i in range(0, len(reply), 1900):
                chunk = reply[i:i + 1900]
                if i == 0:
                    await message.reply(chunk, mention_author=False)
                else:
                    await message.channel.send(chunk)

    @app_commands.command(name="ask", description="Ask Kronus anything about FiveM, GTA, or Sinister State")
    async def ask(self, interaction: discord.Interaction, question: str):
        if not self._rate_check(interaction.user.id):
            await interaction.response.send_message("> _One moment..._", ephemeral=True)
            return
        await interaction.response.defer()
        reply = await self._query(interaction.channel_id, question, interaction.user.display_name, interaction.user.id)
        await interaction.followup.send(reply[:2000])

    @app_commands.command(name="ping", description="Check if Kronus is online")
    async def ping(self, interaction: discord.Interaction):
        self._reset_daily()
        await interaction.response.send_message(
            f"> **Online** | {self.daily_calls}/{self.daily_limit} calls today | Sinister State operational",
            ephemeral=True
        )


async def setup(bot: commands.Bot):
    await bot.add_cog(AssistantCog(bot))
