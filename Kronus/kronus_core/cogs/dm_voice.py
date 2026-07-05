import sys, os, asyncio, subprocess, uuid
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config

DM_VOICE = os.getenv("DM_TTS_VOICE", "en-US-EricNeural")
WHISPER_ENABLED = os.getenv("DM_WHISPER_ENABLED", "0") == "1"
WHISPER_MODEL = os.getenv("DM_WHISPER_MODEL", "tiny.en")

class DMVoiceCog(commands.Cog):
    """Voice: edge-tts narration with voice-switching, Whisper STT, stream detection."""

    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.voice_client: discord.VoiceClient | None = None
        self.narration_queue: asyncio.Queue = asyncio.Queue()
        self.is_speaking = False
        self.streaming_user_ids: set[int] = set()
        self.idle_task: asyncio.Task | None = None
        self.consumer_task: asyncio.Task | None = None
        self.listen_task: asyncio.Task | None = None
        self._listen_enabled = False
        self._whisper_model = None
        self._temp_dir = os.path.join(os.environ.get("TEMP", "/tmp"), "opencode", "narration")
        os.makedirs(self._temp_dir, exist_ok=True)
        if WHISPER_ENABLED:
            self._init_whisper()

    def _init_whisper(self):
        try:
            import whisper
            print(f"[dm-voice] Loading Whisper {WHISPER_MODEL}...")
            self._whisper_model = whisper.load_model(WHISPER_MODEL)
            print("[dm-voice] Whisper ready")
        except Exception as e:
            print(f"[dm-voice] Whisper failed: {e}")

    async def connect(self, channel: discord.VoiceChannel) -> bool:
        if self.voice_client and self.voice_client.is_connected():
            if self.voice_client.channel.id == channel.id: return True
            await self.voice_client.disconnect(); self.voice_client = None
        try:
            self.voice_client = await channel.connect()
            self.consumer_task = asyncio.create_task(self._narration_consumer())
            if WHISPER_ENABLED and self._whisper_model:
                self.listen_task = asyncio.create_task(self._voice_listener_loop())
            if self.idle_task: self.idle_task.cancel(); self.idle_task = None
            return True
        except Exception as e:
            print(f"[dm-voice] Connect failed: {e}")
            return False

    async def disconnect(self):
        if self.consumer_task: self.consumer_task.cancel(); self.consumer_task = None
        if self.listen_task: self.listen_task.cancel(); self.listen_task = None
        self.narration_queue = asyncio.Queue()
        self.is_speaking = False
        if self.voice_client and self.voice_client.is_connected():
            await self.voice_client.disconnect(); self.voice_client = None

    async def narrate(self, text: str):
        if text and text.strip(): await self.narration_queue.put(text.strip())

    async def _narration_consumer(self):
        while self.voice_client and self.voice_client.is_connected():
            try:
                text = await asyncio.wait_for(self.narration_queue.get(), timeout=600)
            except (asyncio.TimeoutError, asyncio.CancelledError):
                continue

            self.is_speaking = True
            segments = self._parse_voice_segments(text)
            for voice, seg_text in segments:
                if not seg_text.strip(): continue
                if not self.voice_client or not self.voice_client.is_connected(): break
                try:
                    path = os.path.join(self._temp_dir, f"n_{uuid.uuid4().hex[:6]}.mp3")
                    loop = asyncio.get_event_loop()
                    await loop.run_in_executor(None, self._tts_edge, seg_text, path, voice)
                    if not os.path.exists(path): continue
                    source = discord.FFmpegPCMAudio(path, options="-loglevel quiet")
                    self.voice_client.play(source)
                    while self.voice_client.is_playing(): await asyncio.sleep(0.3)
                    try: os.remove(path)
                    except OSError: pass
                except Exception as e:
                    print(f"[dm-voice] TTS error: {e}")
            self.is_speaking = False

    def _tts_edge(self, text: str, path: str, voice: str = DM_VOICE):
        subprocess.run(["edge-tts", "--voice", voice, "--text", text, "--write-media", path],
                       check=True, capture_output=True, timeout=30)

    def _parse_voice_segments(self, text: str) -> list[tuple[str, str]]:
        import re
        segments = []
        pattern = r'\[NARRATE(?::([a-z]{2}-[A-Z]{2}-\w+))?\]'
        parts = re.split(pattern, text)
        last_voice = DM_VOICE
        i = 0
        while i < len(parts):
            part = parts[i]
            if part is None: i += 1; continue
            if i + 1 < len(parts) and parts[i + 1] and parts[i + 1].startswith("en-"):
                last_voice = parts[i + 1]; i += 2; continue
            stripped = part.strip()
            if stripped:
                if "[/NARRATE]" in stripped:
                    for sp in stripped.split("[/NARRATE]"):
                        sp = sp.strip()
                        if sp: segments.append((last_voice, sp))
                else:
                    segments.append((last_voice, stripped))
            i += 1
        return segments or [(DM_VOICE, text.strip())]

    async def _voice_listener_loop(self):
        while self._listen_enabled and self.voice_client and self.voice_client.is_connected():
            try:
                import io, wave
                sink = discord.sinks.WaveSink()
                self.voice_client.start_recording(sink, lambda *a: None)
                for user_id, audio in sink.audio_data.items():
                    name = self.bot.get_user(user_id)
                    name_str = name.display_name if name else str(user_id)
                    audio.file.seek(0)
                    wav_bytes = audio.file.read()
                    loop = asyncio.get_event_loop()
                    text = await loop.run_in_executor(None, self._transcribe, wav_bytes)
                    if text:
                        session_cog = self.bot.get_cog("DMSessionCog")
                        if session_cog and session_cog.session_active:
                            session_cog.handle_voice_input(user_id, name_str, text)
                        else:
                            ch = self.bot.get_channel(self.config.dm_text_channel_id)
                            if ch: await ch.send(f"🎙️ **{name_str}**: {text}")
                self.voice_client.stop_recording()
            except Exception as e:
                print(f"[dm-voice] Listen error: {e}")
            await asyncio.sleep(3)

    def _transcribe(self, wav_bytes: bytes) -> str | None:
        if not self._whisper_model: return None
        try:
            import wave, tempfile
            tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
            with wave.open(tmp.name, 'wb') as wf:
                wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(16000)
                wf.writeframes(wav_bytes)
            result = self._whisper_model.transcribe(tmp.name, language="en", fp16=False)
            os.unlink(tmp.name)
            return result["text"].strip() or None
        except Exception as e:
            return None

    @commands.Cog.listener()
    async def on_voice_state_update(self, member: discord.Member, before: discord.VoiceState, after: discord.VoiceState):
        if member.bot: return
        if after.self_stream and not before.self_stream:
            self.streaming_user_ids.add(member.id)
            ch = self.bot.get_channel(self.config.dm_text_channel_id)
            if ch: await ch.send(embed=discord.Embed(title="📺 Stream Detected", description=f"**{member.display_name}** is live!", color=0x8B0000))
            if after.channel and (not self.voice_client or not self.voice_client.is_connected()):
                await self.connect(after.channel)
        elif before.self_stream and not after.self_stream:
            self.streaming_user_ids.discard(member.id)
            if not self.streaming_user_ids: await self._start_idle_timer()

    async def _start_idle_timer(self):
        if self.idle_task: self.idle_task.cancel()
        self.idle_task = asyncio.create_task(self._idle_check())

    async def _idle_check(self):
        await asyncio.sleep(300)
        if not self.streaming_user_ids and not self.is_speaking and self.narration_queue.empty():
            await self.disconnect()

    @app_commands.command(name="dm_join", description="Bot joins your voice channel")
    async def dm_join(self, interaction: discord.Interaction):
        if not interaction.user.voice or not interaction.user.voice.channel:
            await interaction.response.send_message("Join a voice channel first.", ephemeral=True); return
        await interaction.response.defer(ephemeral=True)
        ok = await self.connect(interaction.user.voice.channel)
        await interaction.followup.send(f"✅ Joined **{interaction.user.voice.channel.name}** — I'll listen for narration and streams." if ok else "Failed to join.", ephemeral=True)

    @app_commands.command(name="dm_leave", description="Bot leaves voice channel")
    async def dm_leave(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        await self.disconnect()
        await interaction.followup.send("Disconnected.", ephemeral=True)

    @app_commands.command(name="dm_narrate", description="Queue text for TTS narration")
    async def dm_narrate(self, interaction: discord.Interaction, text: str):
        if not self.voice_client or not self.voice_client.is_connected():
            await interaction.response.send_message("Not in VC. Use /dm_join.", ephemeral=True); return
        await interaction.response.defer(ephemeral=True)
        await self.narrate(text)
        await interaction.followup.send("Queued.", ephemeral=True)

    @app_commands.command(name="dm_listen", description="Enable voice-to-text listening (Whisper)")
    async def dm_listen(self, interaction: discord.Interaction):
        if not WHISPER_ENABLED:
            await interaction.response.send_message("Set DM_WHISPER_ENABLED=1 in .env and restart.", ephemeral=True); return
        if not self._whisper_model:
            await interaction.response.send_message("Whisper model failed to load. Check logs.", ephemeral=True); return
        if not self.voice_client or not self.voice_client.is_connected():
            await interaction.response.send_message("Bot is not in VC. Use /dm_join first.", ephemeral=True); return
        await interaction.response.defer(ephemeral=True)
        self._listen_enabled = True
        if not self.listen_task:
            self.listen_task = asyncio.create_task(self._voice_listener_loop())
        await interaction.followup.send(f"🎙️ Listening enabled (Whisper `{WHISPER_MODEL}`).", ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(DMVoiceCog(bot))
