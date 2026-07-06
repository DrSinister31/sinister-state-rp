import sys, os, asyncio, subprocess, uuid, time, wave, io, struct, threading, tempfile
from collections import defaultdict
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config

DM_VOICE = os.getenv("DM_TTS_VOICE", "en-US-EricNeural")
WHISPER_ENABLED = os.getenv("DM_WHISPER_ENABLED", "1") == "1"
WHISPER_MODEL = os.getenv("DM_WHISPER_MODEL", "tiny.en")
WHISPER_SERVER = os.getenv("WHISPER_SERVER_URL", "")  # e.g. http://localhost:8787
SILENCE_THRESHOLD = 2.0      # seconds of silence to end utterance
MAX_UTTERANCE_SECS = 45       # max seconds before forcing a cut
SPEECH_RMS_FLOOR = 200        # RMS below this = silence
SPEECH_CONFIDENCE_WINDOW = 3  # consecutive loud chunks to confirm speech started
CHUNK_SECS = 0.5              # audio chunk duration in seconds


class DMVoiceCog(commands.Cog):
    """Voice: edge-tts narration with voice-switching, dynamic Whisper STT, stream detection."""

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
        self._user_buffers: dict[int, list[bytes]] = defaultdict(list)
        self._user_silence: dict[int, float] = defaultdict(float)
        self._user_speaking: dict[int, bool] = defaultdict(bool)
        self._user_names: dict[int, str] = {}
        if WHISPER_ENABLED:
            self._init_whisper()

    def _init_whisper(self):
        if WHISPER_SERVER:
            print(f"[dm-voice] Using Whisper server: {WHISPER_SERVER}")
            return
        try:
            import whisper
            print(f"[dm-voice] Loading Whisper {WHISPER_MODEL}...")
            self._whisper_model = whisper.load_model(WHISPER_MODEL)
            print("[dm-voice] Whisper ready")
        except Exception as e:
            print(f"[dm-voice] Whisper failed: {e}")
            self._whisper_model = None

    async def connect(self, channel: discord.VoiceChannel) -> bool:
        if self.voice_client and self.voice_client.is_connected():
            if self.voice_client.channel.id == channel.id: return True
            await self.voice_client.disconnect(); self.voice_client = None
        try:
            self.voice_client = await channel.connect()
            self.consumer_task = asyncio.create_task(self._narration_consumer())
            if WHISPER_ENABLED and (self._whisper_model or WHISPER_SERVER):
                self._listen_enabled = True
                self.listen_task = asyncio.create_task(self._voice_listener_loop())
            if self.idle_task: self.idle_task.cancel(); self.idle_task = None
            return True
        except Exception as e:
            print(f"[dm-voice] Connect failed: {e}")
            return False

    async def disconnect(self):
        self._listen_enabled = False
        if self.consumer_task: self.consumer_task.cancel(); self.consumer_task = None
        if self.listen_task: self.listen_task.cancel(); self.listen_task = None
        self.narration_queue = asyncio.Queue()
        self.is_speaking = False
        self._user_buffers.clear()
        self._user_silence.clear()
        self._user_speaking.clear()
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

    # ──────────────── DYNAMIC VOICE LISTENING ────────────────

    async def _voice_listener_loop(self):
        """Dynamically capture speech utterances, not fixed chunks.
        Listens continuously, buffers while someone speaks, sends to Whisper
        when they finish their thought (pause >= SILENCE_THRESHOLD seconds)."""
        while self._listen_enabled and self.voice_client and self.voice_client.is_connected():
            try:
                sink = discord.sinks.WaveSink()
                self.voice_client.start_recording(sink, lambda *a: None)

                await asyncio.sleep(CHUNK_SECS)
                self.voice_client.stop_recording()

                now = time.time()
                for user_id, audio in sink.audio_data.items():
                    if not audio.file: continue
                    audio.file.seek(0)
                    if audio.file.getbuffer().nbytes < 500: continue  # skip tiny chunks

                    wav_bytes = audio.file.read()

                    name = self.bot.get_user(user_id)
                    self._user_names[user_id] = name.display_name if name else str(user_id)

                    rms = self._calc_rms(wav_bytes)

                    if rms > SPEECH_RMS_FLOOR:
                        self._user_speaking[user_id] = True
                        self._user_silence[user_id] = 0.0
                        self._user_buffers[user_id].append(wav_bytes)
                    elif self._user_speaking.get(user_id, False):
                        self._user_silence[user_id] = self._user_silence.get(user_id, 0.0) + CHUNK_SECS
                        self._user_buffers[user_id].append(wav_bytes)

                # Check for completed utterances (silence after speech)
                for user_id in list(self._user_speaking.keys()):
                    silence_dur = self._user_silence.get(user_id, 0.0)
                    utterance_len = len(self._user_buffers.get(user_id, [])) * CHUNK_SECS

                    if self._user_speaking.get(user_id) and (
                        silence_dur >= SILENCE_THRESHOLD or utterance_len >= MAX_UTTERANCE_SECS
                    ):
                        chunks = self._user_buffers.pop(user_id, [])
                        self._user_silence.pop(user_id, 0.0)
                        self._user_speaking[user_id] = False

                        if chunks and utterance_len >= 0.8:  # minimum 0.8 sec utterance
                            combined = b"".join(chunks)
                            name = self._user_names.get(user_id, "Unknown")
                            text = await self._transcribe_async(combined)
                            if text and len(text.strip()) > 1:
                                print(f"[dm-voice] 🎤 {name}: {text}")
                                session_cog = self.bot.get_cog("DMSessionCog")
                                if session_cog and session_cog.session_active:
                                    session_cog.handle_voice_input(user_id, name, text)
                                else:
                                    ch = self.bot.get_channel(self.config.dm_text_channel_id)
                                    if ch: await ch.send(f"🎙️ **{name}**: {text}")

            except Exception as e:
                print(f"[dm-voice] Listen error: {e}")
                await asyncio.sleep(0.5)

    async def _transcribe_async(self, wav_bytes: bytes) -> str | None:
        if WHISPER_SERVER:
            return await self._transcribe_http(wav_bytes)
        if not self._whisper_model: return None
        try:
            tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
            with wave.open(tmp.name, 'wb') as wf:
                wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(16000)
                wf.writeframes(wav_bytes)
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, self._whisper_model.transcribe, tmp.name, dict(language="en", fp16=False))
            os.unlink(tmp.name)
            return result["text"].strip() or None
        except Exception as e:
            return None

    async def _transcribe_http(self, wav_bytes: bytes) -> str | None:
        try:
            import aiohttp
            async with aiohttp.ClientSession() as session:
                data = aiohttp.FormData()
                data.add_field('audio', wav_bytes, filename='audio.wav', content_type='audio/wav')
                async with session.post(f"{WHISPER_SERVER}/transcribe", data=data, timeout=15) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        return result.get("text", "").strip() or None
        except Exception as e:
            print(f"[dm-voice] Whisper server error: {e}")
        return None

    @staticmethod
    def _calc_rms(data: bytes) -> float:
        count = len(data) // 2
        if count < 10: return 0
        try:
            samples = struct.unpack(f"<{count}h", data[:count * 2])
            return (sum(s * s for s in samples) / count) ** 0.5
        except Exception:
            return 0

    # ──────────────── STREAM DETECTION ────────────────

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

    # ──────────────── COMMANDS ────────────────

    @app_commands.command(name="dm_join", description="Bot joins your voice channel")
    async def dm_join(self, interaction: discord.Interaction):
        if not interaction.user.voice or not interaction.user.voice.channel:
            await interaction.response.send_message("Join a voice channel first.", ephemeral=True); return
        await interaction.response.defer(ephemeral=True)
        ok = await self.connect(interaction.user.voice.channel)
        await interaction.followup.send(f"✅ Joined **{interaction.user.voice.channel.name}** — listening for speech." if ok else "Failed to join.", ephemeral=True)

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

    @app_commands.command(name="dm_listen", description="Toggle voice-to-text listening")
    async def dm_listen(self, interaction: discord.Interaction):
        if not WHISPER_ENABLED:
            await interaction.response.send_message("Set DM_WHISPER_ENABLED=1 in env.", ephemeral=True); return
        if not self._whisper_model and not WHISPER_SERVER:
            await interaction.response.send_message("Whisper model not loaded and no WHISPER_SERVER_URL set. Check logs.", ephemeral=True); return
        if not self.voice_client or not self.voice_client.is_connected():
            await interaction.response.send_message("Not in VC. Use /dm_join first.", ephemeral=True); return
        self._listen_enabled = not self._listen_enabled
        if self._listen_enabled:
            if not self.listen_task:
                self.listen_task = asyncio.create_task(self._voice_listener_loop())
        else:
            if self.listen_task: self.listen_task.cancel(); self.listen_task = None
        mode = "server" if WHISPER_SERVER else "local"
        await interaction.response.send_message(f"🎙️ Voice listening: **{'ON' if self._listen_enabled else 'OFF'}** ({mode} Whisper)", ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(DMVoiceCog(bot))
