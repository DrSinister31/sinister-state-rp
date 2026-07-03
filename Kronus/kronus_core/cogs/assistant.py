import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

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
RATE_LIMIT_SECONDS = 5


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
        self.daily_limit = 100
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
        cutoff = datetime.utcnow() - timedelta(hours=1)
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
            reply = f"_Having trouble thinking right now. Try again in a moment._\n||error: {str(e)[:100]}||"

        now = datetime.utcnow()
        self.history[channel_id].append({
            "role": "user", "content": f"{username}: {user_msg}",
            "_time": now
        })
        self.history[channel_id].append({
            "role": "assistant", "content": reply,
            "_time": now
        })
        self.history[channel_id] = self.history[channel_id][-MAX_HISTORY:]

        self.daily_calls += 1
        self.last_call[user_id or channel_id] = now
        return reply

    @commands.Cog.listener()
    async def on_message(self, message: discord.Message):
        if message.author.bot:
            return
        if not message.guild:
            return

        should_respond = False
        trigger = ""

        if self.bot.user in message.mentions:
            should_respond = True
            trigger = message.content.replace(f"<@{self.bot.user.id}>", "").strip()
            if not trigger:
                trigger = "Hello Kronus!"

        if message.channel.name == "general-chat" and self.bot.user.mentioned_in(message):
            should_respond = True

        if not should_respond:
            return

        user_id = message.author.id
        if not self._rate_check(user_id):
            await message.reply("_Give me a moment to process..._", mention_author=False)
            return

        async with message.channel.typing():
            reply = self._query(message.channel.id, trigger or message.content, message.author.display_name)

        chunks = [reply[i:i+1900] for i in range(0, len(reply), 1900)]
        for i, chunk in enumerate(chunks):
            if i == 0:
                await message.reply(chunk, mention_author=False)
            else:
                await message.channel.send(chunk)

    @app_commands.command(name="ask", description="Ask Kronus anything about FiveM or Sinister State")
    @app_commands.describe(question="What do you want to know?")
    async def ask(self, interaction: discord.Interaction, question: str):
        if not self._rate_check(interaction.user.id):
            await interaction.response.send_message("_One moment, processing another request..._", ephemeral=True)
            return

        await interaction.response.defer()
        reply = self._query(interaction.channel_id, question, interaction.user.display_name)
        await interaction.followup.send(reply)

    @app_commands.command(name="chat", description="Start a conversation with Kronus in this channel")
    async def chat(self, interaction: discord.Interaction):
        await interaction.response.send_message(
            f"> Hey {interaction.user.mention}, I'm listening. Ask me anything about FiveM, GTA, Qbox, txAdmin, or Sinister State. "
            f"I'm also just here to chat.\n\n"
            f"**Quick commands:**\n"
            f"`/ask` — one-off question\n"
            f"`/ping` — check if I'm online\n"
            f"`@Kronus` — mention me in any message",
            ephemeral=False
        )

    @app_commands.command(name="ping", description="Check if Kronus is online")
    async def ping(self, interaction: discord.Interaction):
        self._reset_daily()
        await interaction.response.send_message(
            f"> Online and operational. **#general-chat** is open for conversation.\n"
            f"> Daily Deepseek calls: {self.daily_calls}/{self.daily_limit}",
            ephemeral=True
        )


async def setup(bot: commands.Bot):
    await bot.add_cog(AssistantCog(bot))
