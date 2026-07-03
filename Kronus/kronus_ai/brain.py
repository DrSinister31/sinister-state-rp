import os
import json
import time
from pathlib import Path
from openai import OpenAI
from shared.config import Config


class TokenTracker:
    def __init__(self):
        self.requests_today = 0
        self.tokens_today = 0
        self.last_reset = time.time()
        self.daily_limit = 100
        self.today_date = time.strftime("%Y-%m-%d")

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
        return f"{self.requests_today}/{self.daily_limit} calls | {self.tokens_today} tokens today"


_token_tracker = TokenTracker()


class DeepseekBrain:
    def __init__(self, config: Config):
        self.client = OpenAI(
            api_key=config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self.prompt_dir = Path(__file__).parent / "prompt_templates"

    def _load_prompt(self, name: str) -> str:
        path = self.prompt_dir / f"{name}.txt"
        if path.exists():
            return path.read_text()
        return ""

    def _query(self, system_prompt: str, user_prompt: str, max_tokens: int = 800) -> str:
        if not _token_tracker.can_call():
            print(f"[kronus-ai] Daily limit reached ({_token_tracker.daily_limit}). Skipping.")
            return ""

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=max_tokens,
                temperature=0.7
            )
            usage = response.usage.total_tokens if response.usage else max_tokens
            _token_tracker.record(usage)
            print(f"[kronus-ai] Call #{_token_tracker.requests_today} | {usage}t | {_token_tracker.status()}")
            return response.choices[0].message.content or ""
        except Exception as e:
            print(f"[kronus-ai] Failed: {e}")
            return ""

    def score_event(self, event_type: str, parties: str, location: str, details: str) -> str:
        if not _token_tracker.can_call():
            return ""

        prompt = f"""Score this server event 0-30:
Type: {event_type}
Parties: {parties}
Location: {location}
Details: {details}

Rules:
0-14 = ignore | 15-22 = journal entry | 23-30 = crisis broadcast

Reply ONLY with: SCORE=<number>"""
        return self._query("You score server events 0-30. Output only SCORE=N", prompt, max_tokens=20)

    def judge_ruling(self, case_details: str, evidence: str, attorney_tier: str, jury_results: str) -> str:
        if not _token_tracker.can_call():
            return ""

        template = self._load_prompt("judge_ruling")
        prompt = template.format(
            case_details=case_details,
            evidence=evidence,
            attorney_tier=attorney_tier,
            jury_results=jury_results
        )
        return self._query("You are the SYNIX STATE AI Judge. Be concise.", prompt, max_tokens=500)

    def generate_narration(self, event_type: str, score: int, parties: str, location: str, details: str) -> str:
        if not _token_tracker.can_call():
            return f"BREAKING: {event_type} reported at {location}. Investigation ongoing."

        template = self._load_prompt("event_narration")
        prompt = template.format(
            event_type=event_type,
            score=score,
            parties=parties,
            location=location,
            details=details
        )
        return self._query("You are a news broadcaster. Write 2-4 sentence report.", prompt, max_tokens=400)

    def audit_economy(self, metrics: dict) -> str:
        if not _token_tracker.can_call():
            return ""

        template = self._load_prompt("economy_audit")
        prompt = template.format(
            avg_cash=metrics.get("avg_cash", 0),
            avg_bank=metrics.get("avg_bank", 0),
            wealth_distribution=json.dumps(metrics.get("wealth_distribution", {})),
            tx_volume=metrics.get("tx_volume", 0),
            active_businesses=metrics.get("active_businesses", 0),
            inflation_state=metrics.get("inflation_state", "stable"),
            current_policies=json.dumps(metrics.get("current_policies", {}))
        )
        return self._query("You are the SYNIX STATE economy auditor. Be concise.", prompt, max_tokens=500)

    def review_policy(self, policy_key: str, current_value: str, outcomes: str) -> str:
        if not _token_tracker.can_call():
            return ""

        template = self._load_prompt("policy_review")
        prompt = template.format(
            policy_key=policy_key,
            current_value=current_value,
            outcomes=outcomes
        )
        return self._query("You are the SYNIX STATE policy reviewer. Be concise.", prompt, max_tokens=500)


_brain: DeepseekBrain | None = None


def get_brain(config: Config | None = None) -> DeepseekBrain:
    global _brain
    if _brain is None:
        if config is None:
            config = Config.from_env()
        _brain = DeepseekBrain(config)
    return _brain
