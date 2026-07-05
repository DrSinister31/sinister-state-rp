import sys, os, asyncio, tempfile, uuid
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config


class DMVoiceCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.voice_client: discord.VoiceClient | None = None
        self.narration_queue: asyncio.Queue = asyncio.Queue()
        self.is_speaking = False
        self.streaming_user_ids: set[int] = set()
        self.idle_task: asyncio.Task | None = None
        self.consumer_task: asyncio.Task | None = None
        self._temp_dir = os.path.join(os.environ.get("TEMP", "/tmp"), "opencode", "narration")
        os.makedirs(self._temp_dir, exist_ok=True)

    def _is_dm(self, interaction: discord.Interaction) -> bool:
        if interaction.user.id == self.config.owner_discord_id:
            return True
        if interaction.user.id in self.config.admin_discord_ids:
            return True
        if self.config.dm_session_role_id:
            role = interaction.guild.get_role(self.config.dm_session_role_id)
            return role is not None and role in interaction.user.roles
        return False

    async def connect(self, channel: discord.VoiceChannel) -> bool:
        if self.voice_client and self.voice_client.is_connected():
            if self.voice_client.channel.id == channel.id:
                return True
            await self.voice_client.disconnect()
            self.voice_client = None

        try:
            self.voice_client = await channel.connect()
            self.consumer_task = asyncio.create_task(self._narration_consumer())
            if self.idle_task:
                self.idle_task.cancel()
                self.idle_task = None
            return True
        except Exception as e:
            print(f"[dm-voice] Failed to connect: {e}")
            return False

    async def disconnect(self):
        if self.consumer_task:
            self.consumer_task.cancel()
            self.consumer_task = None
        self.narration_queue = asyncio.Queue()
        self.is_speaking = False
        if self.voice_client and self.voice_client.is_connected():
            await self.voice_client.disconnect()
            self.voice_client = None

    async def narrate(self, text: str):
        await self.narration_queue.put(text)

    async def _narration_consumer(self):
        while self.voice_client and self.voice_client.is_connected():
            try:
                text = await asyncio.wait_for(self.narration_queue.get(), timeout=600)
            except asyncio.TimeoutError:
                continue
            except asyncio.CancelledError:
                break

            self.is_speaking = True
            try:
                temp_path = os.path.join(self._temp_dir, f"narration_{uuid.uuid4().hex[:8]}.mp3")
                loop = asyncio.get_event_loop()
                await loop.run_in_executor(None, self._generate_tts, text, temp_path)

                if not os.path.exists(temp_path):
                    continue

                source = discord.FFmpegPCMAudio(temp_path)
                self.voice_client.play(source)

                while self.voice_client.is_playing():
                    await asyncio.sleep(0.5)

                try:
                    os.remove(temp_path)
                except OSError:
                    pass
            except Exception as e:
                print(f"[dm-voice] Narration error: {e}")
            finally:
                self.is_speaking = False

    def _generate_tts(self, text: str, path: str):
        from gtts import gTTS
        tts = gTTS(text=text, lang="en", slow=False)
        tts.save(path)

    async def _start_idle_timer(self):
        if self.idle_task:
            self.idle_task.cancel()
        self.idle_task = asyncio.create_task(self._idle_check())

    async def _idle_check(self):
        await asyncio.sleep(300)
        if not self.streaming_user_ids and not self.is_speaking and self.narration_queue.empty():
            await self.disconnect()

    @commands.Cog.listener()
    async def on_voice_state_update(self, member: discord.Member, before: discord.VoiceState,
                                     after: discord.VoiceState):
        if member.bot:
            return

        if after.self_stream and not before.self_stream:
            self.streaming_user_ids.add(member.id)
            text_channel = self.bot.get_channel(self.config.dm_text_channel_id)
            if text_channel:
                embed = discord.Embed(
                    title="Stream Detected",
                    description=f"**{member.display_name}** is now streaming! A session may be in progress.",
                    color=0x8B0000
                )
                await text_channel.send(embed=embed)

            if after.channel and (not self.voice_client or not self.voice_client.is_connected()):
                await self.connect(after.channel)
                if text_channel:
                    await text_channel.send(f"Joined {after.channel.mention}.")

        elif before.self_stream and not after.self_stream:
            self.streaming_user_ids.discard(member.id)
            if not self.streaming_user_ids:
                text_channel = self.bot.get_channel(self.config.dm_text_channel_id)
                if text_channel:
                    await text_channel.send(f"**{member.display_name}** stopped streaming.")
                await self._start_idle_timer()

    @app_commands.command(name="dm_join", description="[DM] Bot joins your voice channel")
    async def dm_join(self, interaction: discord.Interaction):
        if not self._is_dm(interaction):
            await interaction.response.send_message("DM only.", ephemeral=True)
            return
        if not interaction.user.voice or not interaction.user.voice.channel:
            await interaction.response.send_message("You are not in a voice channel.", ephemeral=True)
            return
        await interaction.response.defer(ephemeral=True)
        success = await self.connect(interaction.user.voice.channel)
        if success:
            await interaction.followup.send(f"Joined {interaction.user.voice.channel.name}.", ephemeral=True)
        else:
            await interaction.followup.send("Failed to join voice channel.", ephemeral=True)

    @app_commands.command(name="dm_leave", description="[DM] Bot leaves voice channel")
    async def dm_leave(self, interaction: discord.Interaction):
        if not self._is_dm(interaction):
            await interaction.response.send_message("DM only.", ephemeral=True)
            return
        await interaction.response.defer(ephemeral=True)
        await self.disconnect()
        await interaction.followup.send("Disconnected from voice.", ephemeral=True)

    @app_commands.command(name="dm_narrate", description="[DM] Queue text for TTS narration in voice channel")
    @app_commands.describe(text="Text to narrate aloud")
    async def dm_narrate(self, interaction: discord.Interaction, text: str):
        if not self._is_dm(interaction):
            await interaction.response.send_message("DM only.", ephemeral=True)
            return
        if not self.voice_client or not self.voice_client.is_connected():
            await interaction.response.send_message("Bot is not connected to a voice channel. Use /dm_join first.", ephemeral=True)
            return
        await interaction.response.defer(ephemeral=True)
        await self.narrate(text)
        await interaction.followup.send("Queued for narration.", ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(DMVoiceCog(bot))
