import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import json
import time
from openai import OpenAI
from shared.config import Config
from kronus_compendium.prompt_loader import load_prompt, load_active_context


class TokenTracker:
    def __init__(self):
        self.requests_today = 0
        self.tokens_today = 0
        self.today_date = time.strftime("%Y-%m-%d")
        self.daily_limit = 100

    def _reset_if_new_day(self):
        today = time.strftime("%Y-%m-%d")
        if today != self.today_date:
            self.today_date = today
            self.requests_today = 0
            self.tokens_today = 0

    def can_call(self) -> bool:
        self._reset_if_new_day()
        return self.requests_today < self.daily_limit

    def record(self, tokens: int):
        self.requests_today += 1
        self.tokens_today += tokens

    def status(self) -> str:
        return f"{self.requests_today}/{self.daily_limit} calls | {self.tokens_today} tokens"


_token_tracker = TokenTracker()


class CompendiumGenerator:
    def __init__(self, config: Config):
        self.client = OpenAI(
            api_key=config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self.system_prompt = load_prompt("monster_compendium_guide")
        if not self.system_prompt:
            raise FileNotFoundError("monster_compendium_guide.md not found in prompts/solis_grave/")

    def _build_context_prompt(self, region: str = None, faction: str = None,
                              cr_min: float = None, cr_max: float = None,
                              monster_type: str = None, count: int = 10) -> str:
        live_context = load_active_context()
        parts = ["Generate EXACTLY the specified monsters below as a JSON array. Each entry must be a complete stat block.\n"]

        if live_context:
            parts.append(f"### CURRENT CAMPAIGN STATE:\n{live_context}\n")

        parts.append(f"### GENERATION PARAMETERS:\n- Count: {count} monsters")
        if region:
            parts.append(f"- Region/Biome: {region}")
        if faction:
            parts.append(f"- Faction affiliation: {faction}")
        if monster_type:
            parts.append(f"- Monster type: {monster_type}")
        if cr_min is not None:
            parts.append(f"- CR minimum: {cr_min}")
        if cr_max is not None:
            parts.append(f"- CR maximum: {cr_max}")

        parts.append("\nReturn ONLY a JSON array of monster objects. No markdown wrapping, no explanation.")
        return "\n".join(parts)

    def generate(self, region: str = None, faction: str = None,
                 cr_min: float = None, cr_max: float = None,
                 monster_type: str = None, count: int = 10) -> list[dict]:
        if not _token_tracker.can_call():
            print(f"[kronus-compendium] Daily limit reached. Skipping generation.")
            return []

        user_prompt = self._build_context_prompt(
            region=region, faction=faction,
            cr_min=cr_min, cr_max=cr_max,
            monster_type=monster_type, count=count
        )

        try:
            response = self.client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=4000,
                temperature=0.8
            )
            usage = response.usage.total_tokens if response.usage else 4000
            _token_tracker.record(usage)
            print(f"[kronus-compendium] Generation #{_token_tracker.requests_today} | {usage}t | {_token_tracker.status()}")

            content = response.choices[0].message.content or ""
            return self._parse_response(content)

        except Exception as e:
            print(f"[kronus-compendium] Generation failed: {e}")
            return []

    def _parse_response(self, content: str) -> list[dict]:
        content = content.strip()
        if content.startswith("```"):
            lines = content.split("\n")
            lines = lines[1:] if lines[0].startswith("```") else lines
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            content = "\n".join(lines)

        try:
            data = json.loads(content)
            if isinstance(data, list):
                return self._validate_monsters(data)
            elif isinstance(data, dict) and "monsters" in data:
                return self._validate_monsters(data["monsters"])
            return []
        except json.JSONDecodeError:
            try:
                start = content.find("[")
                end = content.rfind("]") + 1
                if start >= 0 and end > start:
                    data = json.loads(content[start:end])
                    return self._validate_monsters(data)
            except json.JSONDecodeError:
                pass
            print(f"[kronus-compendium] Could not parse response as JSON")
            return []

    def _validate_monsters(self, monsters: list[dict]) -> list[dict]:
        required = {"name", "size", "type", "cr"}
        valid = []
        for m in monsters:
            if not isinstance(m, dict):
                continue
            if not required.issubset(m.keys()):
                print(f"[kronus-compendium] Skipping invalid monster (missing fields): {m.get('name', 'unknown')}")
                continue
            m.setdefault("alignment", "unaligned")
            m.setdefault("stats", {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10})
            m.setdefault("traits", [])
            m.setdefault("actions", [])
            m.setdefault("legendary_actions", [])
            m.setdefault("lair_actions", [])
            m.setdefault("reactions", [])
            m.setdefault("lore", "")
            m.setdefault("source_tags", ["solis-grave"])
            m.setdefault("biome_tags", [])
            m.setdefault("aether_core", {"tier": "None", "element": "None", "value_gc": 0})
            m.setdefault("public", False)
            m.setdefault("ac", 10)
            m.setdefault("hp", "1 (1d4-1)")
            m.setdefault("speed", "30 ft.")
            m.setdefault("xp", 0)
            m.setdefault("senses", "passive Perception 10")
            m.setdefault("languages", "")
            valid.append(m)
        return valid


_generator: CompendiumGenerator | None = None


def get_generator(config: Config | None = None) -> CompendiumGenerator:
    global _generator
    if _generator is None:
        if config is None:
            config = Config.from_env()
        _generator = CompendiumGenerator(config)
    return _generator
