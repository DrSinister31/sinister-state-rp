import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import re
from collections import defaultdict
from datetime import datetime, timedelta
import discord
from discord import app_commands
from discord.ext import commands
from openai import OpenAI
from shared.config import Config
from shared.supabase_client import get_supabase
from cogs.assistant_data import SYSTEM_PROMPT

MAX_HISTORY = 15
MAX_TOKENS = 800
RATE_LIMIT_SECONDS = 4
OWNER_ID = 1370770707507708047


class AssistantCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self.client = OpenAI(
            api_key=self.config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self.history: dict[int, list[dict]] = defaultdict(list)
        self.last_call: dict[int, datetime] = {}
        self.daily_calls = 0
        self.daily_limit = 200
        self.day = datetime.utcnow().date()

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

    def _query(self, channel_id: int, user_msg: str, username: str) -> str:
        self._clean_history(channel_id)

        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.extend(self.history[channel_id])
        messages.append({"role": "user", "content": f"{username}: {user_msg}"})

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=messages,
                max_tokens=MAX_TOKENS,
                temperature=0.8
            )
            reply = response.choices[0].message.content or ""
        except Exception as e:
            reply = f"> _Having trouble thinking right now. Try again in a moment._\n> ||{str(e)[:80]}||"

        now = datetime.utcnow()
        self.history[channel_id].append({"role": "user", "content": f"{username}: {user_msg}", "_time": now})
        self.history[channel_id].append({"role": "assistant", "content": reply, "_time": now})
        self.history[channel_id] = self.history[channel_id][-MAX_HISTORY:]
        self.daily_calls += 1
        self.last_call[user_id or channel_id] = now
        return reply

    async def _execute_actions(self, reply: str, message: discord.Message) -> str:
        """Parse [ACTION:...] tags and execute Discord actions. Returns cleaned reply text."""
        guild = message.guild
        if not guild:
            return reply

        for m in re.finditer(r'\[ACTION:(\w+):([^:]+)(?::(.+?))?\]', reply):
            action_type = m.group(1)
            target = m.group(2).strip()
            body = (m.group(3) or "").strip()
            try:
                if action_type == "announce":
                    for ch in guild.text_channels:
                        if ch.name == "announcements":
                            await ch.send(f"@everyone\n\n{body}")
                            print(f"[assistant] Announced: {body[:80]}")
                            break
                elif action_type == "send":
                    for ch in guild.text_channels:
                        if ch.name == target:
                            await ch.send(body[:2000])
                            print(f"[assistant] Sent to #{target}: {body[:80]}")
                            break
                elif action_type == "edit":
                    for ch in guild.text_channels:
                        if ch.name == target:
                            await ch.edit(topic=body[:1024])
                            print(f"[assistant] Edited #{target}")
                            break
                elif action_type == "mention":
                    for member in guild.members:
                        if member.name == target or member.display_name == target:
                            await message.channel.send(f"<@{member.id}> {body[:1500]}")
                            print(f"[assistant] Mentioned @{target}")
                            break
            except Exception as e:
                print(f"[assistant] Action failed [{action_type}:{target}]: {e}")

        return re.sub(r'\[ACTION:.*?\]', '', reply).strip()

    @commands.Cog.listener()
    async def on_message(self, message: discord.Message):
        if message.author.bot:
            return
        if not message.guild:
            return

        content = message.content
        mentioned = self.bot.user in message.mentions
        is_dm = isinstance(message.channel, discord.DMChannel)
        is_owner = message.author.id == OWNER_ID

        should_respond = mentioned
        if is_dm:
            should_respond = True

        if not should_respond:
            return

        clean = content.replace(f"<@{self.bot.user.id}>", "").strip()
        if not clean:
            clean = "Hey Kronus"

        user_id = message.author.id
        if not self._rate_check(user_id) and not is_owner:
            await message.reply("> _One moment, let me catch up..._", mention_author=False)
            return

        async with message.channel.typing():
            reply = self._query(message.channel.id, clean, message.author.display_name)
            reply = await self._execute_actions(reply, message)

        chunks = [reply[i:i+1900] for i in range(0, len(reply), 1900)]
        for i, chunk in enumerate(chunks):
            if i == 0:
                await message.reply(chunk, mention_author=False)
            else:
                await message.channel.send(chunk)

    @app_commands.command(name="ask", description="Ask Kronus anything")
    async def ask(self, interaction: discord.Interaction, question: str):
        if not self._rate_check(interaction.user.id):
            await interaction.response.send_message("> _One moment..._", ephemeral=True)
            return
        await interaction.response.defer()
        reply = self._query(interaction.channel_id, question, interaction.user.display_name)
        await interaction.followup.send(reply[:2000])

    @app_commands.command(name="ping", description="Check Kronus status")
    async def ping(self, interaction: discord.Interaction):
        self._reset_daily()
        await interaction.response.send_message(
            f"> **Online** | Calls today: {self.daily_calls}/{self.daily_limit} | "
            f"> Server: Sinister State (Qbox, 102 resources)",
            ephemeral=True
        )

    @app_commands.command(name="chat", description="Start a conversation with Kronus")
    async def chat(self, interaction: discord.Interaction):
        await interaction.response.send_message(
            f"> I'm listening, {interaction.user.mention}. I can help with:\n"
            f"> **FiveM/Qbox** — scripting, config, troubleshooting\n"
            f"> **Server management** — rules, announcements, moderation\n"
            f"> **GTA mechanics** — natives, game systems, vehicle data\n"
            f"> **Discord** — channel editing, role management, pinning\n"
            f"> Or just talk. Use `/ask` for one-off questions."
        )


async def setup(bot: commands.Bot):
    await bot.add_cog(AssistantCog(bot))
