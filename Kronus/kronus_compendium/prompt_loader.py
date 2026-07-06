import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from pathlib import Path

PROMPT_DIR = Path(__file__).resolve().parent.parent / "prompts" / "solis_grave"


def load_prompt(name: str) -> str:
    path = PROMPT_DIR / f"{name}.md"
    if path.exists():
        return path.read_text(encoding="utf-8")
    alt_path = PROMPT_DIR / name
    if alt_path.exists():
        return alt_path.read_text(encoding="utf-8")
    return ""


def load_active_context() -> str:
    ctx = load_prompt("active_context")
    if not ctx:
        return ""
    eplog_path = PROMPT_DIR / "episodes" / "latest.md"
    if eplog_path.exists():
        ctx += "\n\n---\n\n## Latest Episode Log\n\n" + eplog_path.read_text(encoding="utf-8")
    return ctx
