import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import asyncio
from datetime import datetime, timedelta, timezone
import discord
from discord import app_commands
from discord.ext import commands, tasks
from openai import AsyncOpenAI
from shared.config import Config
from shared.supabase_client import get_supabase


PENDING_TIMEOUT_MINUTES = 5


class ChannelMemory(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self.client = AsyncOpenAI(
            api_key=self.config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self._pending_dms: dict[int, int] = {}
        self._pending_timers: dict[int, asyncio.Task] = {}

    async def cog_load(self):
        self.compaction_loop.start()

    def cog_unload(self):
        self.compaction_loop.cancel()

    @commands.Cog.listener()
    async def on_guild_channel_create(self, channel: discord.abc.GuildChannel):
        if not isinstance(channel, discord.TextChannel):
            return
        await asyncio.sleep(3)

        creator = None
        try:
            async for entry in channel.guild.audit_logs(limit=10, action=discord.AuditLogAction.channel_create):
                if entry.target and entry.target.id == channel.id:
                    creator = entry.user
                    break
        except Exception:
            pass

        if not creator or creator.bot:
            return

        try:
            existing = self.supabase.table("channel_purposes").select("id").eq("channel_id", str(channel.id)).execute()
            if existing.data:
                return
        except Exception:
            pass

        try:
            dm = await creator.create_dm()
            await dm.send(
                f"Howdy! I noticed y'all just created {channel.mention}.\n"
                f"What's this channel for, partner? Give me a quick description and I'll remember it."
            )
            self._pending_dms[creator.id] = channel.id

            async def clear_pending():
                await asyncio.sleep(PENDING_TIMEOUT_MINUTES * 60)
                if creator.id in self._pending_dms:
                    del self._pending_dms[creator.id]
                    try:
                        await dm.send(f"No rush on that channel description for {channel.mention} — y'all can use `/remember` anytime to tell me later.")
                    except Exception:
                        pass

            self._pending_timers[creator.id] = asyncio.create_task(clear_pending())
        except Exception:
            pass

    @commands.Cog.listener()
    async def on_message(self, message: discord.Message):
        if message.author.bot:
            return
        if not isinstance(message.channel, discord.DMChannel):
            return
        if message.author.id not in self._pending_dms:
            return

        channel_id = self._pending_dms.pop(message.author.id, None)
        if not channel_id:
            return

        timer = self._pending_timers.pop(message.author.id, None)
        if timer:
            timer.cancel()

        purpose = message.content.strip()[:500]
        channel = self.bot.get_channel(channel_id)
        channel_name = channel.name if channel else "unknown"

        try:
            self.supabase.table("channel_purposes").upsert({
                "channel_id": str(channel_id),
                "channel_name": channel_name,
                "purpose": purpose,
                "creator_id": str(message.author.id),
                "updated_at": "now()"
            }).execute()
        except Exception as e:
            print(f"[channel_memory] Failed to save purpose: {e}")

        try:
            await message.channel.send(
                f"Got it, partner. I'll remember that {channel.mention if channel else '#' + channel_name} is for: *{purpose[:200]}*\n\n"
                f"Next time, just ask me — `@Kronus create a channel for [purpose]` — and I'll handle the whole rodeo."
            )
        except Exception:
            pass

    @tasks.loop(hours=168)
    async def compaction_loop(self):
        await self._run_compaction()

    @compaction_loop.before_loop
    async def before_compaction(self):
        await self.bot.wait_until_ready()
        await asyncio.sleep(60)

    async def _run_compaction(self):
        try:
            r = self.supabase.table("channel_purposes").select("channel_name,purpose").eq("is_compacted", False).execute()
            if not r.data or len(r.data) == 0:
                return

            entries = r.data
            if len(entries) == 1:
                compacted = f"#{entries[0]['channel_name']}: {entries[0].get('purpose', 'no description')}"
            else:
                channel_list = "\n".join([
                    f"- #{e['channel_name']}: {e.get('purpose', 'no description')[:200]}"
                    for e in entries
                ])
                prompt = f"""You are Kronus, the Texas AI for Sinister State RP. Below is a list of Discord channels and their purposes. Summarize this into a single compact knowledge block. One sentence per channel MAX. Keep only what's useful for answering questions about the server. Discard trivial or redundant info.

{channel_list}

Return ONLY the compacted summary, no preamble."""
                try:
                    resp = await self.client.chat.completions.create(
                        model="deepseek-chat",
                        messages=[{"role": "user", "content": prompt}],
                        max_tokens=500,
                        temperature=0.3
                    )
                    compacted = resp.choices[0].message.content.strip()
                except Exception as e:
                    print(f"[channel_memory] LLM compaction failed: {e}")
                    compacted = channel_list

            self.supabase.table("bot_config").upsert({
                "key": "kronus_channel_knowledge",
                "value": compacted[:4000],
                "updated_at": "now()"
            }).execute()

            channel_ids = [e.get("channel_id") or str(e.get("id")) for e in entries]
            for cid in channel_ids:
                self.supabase.table("channel_purposes").update({"is_compacted": True}).eq("channel_id", cid).execute()

            print(f"[channel_memory] Compaction complete — {len(entries)} channel purposes summarized")
        except Exception as e:
            print(f"[channel_memory] Compaction error: {e}")

    @app_commands.command(name="channel-info", description="See what Kronus knows about a channel")
    @app_commands.default_permissions(manage_channels=True)
    async def channel_info(self, interaction: discord.Interaction, channel: discord.TextChannel):
        try:
            r = self.supabase.table("channel_purposes").select("*").eq("channel_id", str(channel.id)).execute()
            if not r.data:
                await interaction.response.send_message(f"No stored info for {channel.mention}.", ephemeral=True)
                return
            entry = r.data[0]
            embed = discord.Embed(
                title=f"Channel Info: #{entry['channel_name']}",
                color=discord.Color.from_rgb(191, 87, 0)
            )
            embed.add_field(name="Purpose", value=entry.get("purpose", "none")[:1024], inline=False)
            embed.add_field(name="Compacted", value="Yes" if entry.get("is_compacted") else "No", inline=True)
            embed.add_field(name="Added", value=str(entry.get("created_at", "unknown"))[:19], inline=True)
            await interaction.response.send_message(embed=embed, ephemeral=True)
        except Exception as e:
            await interaction.response.send_message(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="forget-channel", description="Make Kronus forget everything about a channel")
    @app_commands.default_permissions(manage_channels=True)
    async def forget_channel(self, interaction: discord.Interaction, channel: discord.TextChannel):
        try:
            self.supabase.table("channel_purposes").delete().eq("channel_id", str(channel.id)).execute()
            await interaction.response.send_message(f"Done. {channel.mention} has been forgotten.", ephemeral=True)

            self.supabase.table("kronus_logs").insert({
                "service": "kronus-core",
                "action": "channel_forgotten",
                "context_json": {"channel_id": str(channel.id), "channel_name": channel.name, "by": str(interaction.user.id)},
                "result": "deleted"
            }).execute()
        except Exception as e:
            await interaction.response.send_message(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="remember", description="Tell Kronus what a channel is for")
    @app_commands.default_permissions(manage_channels=True)
    async def remember(self, interaction: discord.Interaction, channel: discord.TextChannel, purpose: str):
        try:
            self.supabase.table("channel_purposes").upsert({
                "channel_id": str(channel.id),
                "channel_name": channel.name,
                "purpose": purpose[:500],
                "creator_id": str(interaction.user.id),
                "updated_at": "now()"
            }).execute()
            await interaction.response.send_message(
                f"Remembered: {channel.mention} is for *{purpose[:200]}*",
                ephemeral=True
            )
        except Exception as e:
            await interaction.response.send_message(f"Error: {e}", ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(ChannelMemory(bot))
