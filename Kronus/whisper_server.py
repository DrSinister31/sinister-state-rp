"""Standalone Whisper STT server for Solis-Grave DM bot.
Start locally: python whisper_server.py
Default port 8787. Set WHISPER_PORT env var to change.
Bot connects via WHISPER_SERVER_URL=http://localhost:8787 in .env

Lightweight — uses faster-whisper instead of openai-whisper (~400MB RAM vs ~1GB).
If faster-whisper unavailable, falls back to openai-whisper."""
import os, sys, json, tempfile, wave
from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi

PORT = int(os.getenv("WHISPER_PORT", "8787"))
MODEL = os.getenv("WHISPER_MODEL", "tiny.en")

print(f"Loading Whisper {MODEL}...")

_model = None
try:
    from faster_whisper import WhisperModel
    _model = WhisperModel(MODEL, device="cpu", compute_type="int8")
    print(f"faster-whisper loaded ({MODEL}, cpu/int8)")
    USE_FASTER = True
except ImportError:
    import whisper
    _model = whisper.load_model(MODEL)
    print(f"openai-whisper loaded ({MODEL})")
    USE_FASTER = False


class WhisperHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/transcribe":
            self.send_error(404)
            return

        ctype, _ = cgi.parse_header(self.headers.get("Content-Type", ""))
        if ctype != "multipart/form-data":
            self.send_error(400, "Send multipart/form-data with 'audio' field")
            return

        form = cgi.FieldStorage(
            fp=self.rfile, headers=self.headers,
            environ={"REQUEST_METHOD": "POST", "CONTENT_TYPE": self.headers["Content-Type"]}
        )

        audio_field = form.get("audio")
        if not audio_field:
            self.send_error(400, "Missing 'audio' field")
            return

        wav_bytes = audio_field.file.read()

        try:
            text = self.transcribe(wav_bytes)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"text": text}).encode())
        except Exception as e:
            self.send_error(500, str(e))

    def transcribe(self, wav_bytes: bytes) -> str:
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        try:
            with wave.open(tmp.name, 'wb') as wf:
                wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(16000)
                wf.writeframes(wav_bytes)

            if USE_FASTER:
                segments, _ = _model.transcribe(tmp.name, language="en")
                return " ".join(s.text for s in segments).strip()
            else:
                result = _model.transcribe(tmp.name, language="en", fp16=False)
                return result["text"].strip()
        finally:
            try: os.unlink(tmp.name)
            except OSError: pass

    def log_message(self, format, *args):
        pass  # silent


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), WhisperHandler)
    print(f"Whisper server listening on :{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()
