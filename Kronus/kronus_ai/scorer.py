import random
from datetime import datetime
from shared.supabase_client import get_supabase
from shared.config import Config
from brain import get_brain

config = Config.from_env()
supabase = get_supabase(config)
brain = get_brain(config)

SEVERITY_KEYWORDS = {
    "explosion": 25, "bomb": 28, "terror": 30, "hijack": 26, "assassination": 27,
    "martial": 30, "siege": 28, "massacre": 29, "riot": 22, "coup": 30,
}


async def evaluate_event(event_type: str, parties: str, location: str, details: str,
                         involved_citizenids: list, involved_discord_ids: list) -> dict:
    combined = f"{event_type} {details}".lower()
    score = 0
    for keyword, value in SEVERITY_KEYWORDS.items():
        if keyword in combined:
            score = max(score, value)

    if score >= 20:
        ai_score = brain.score_event(event_type, parties, location, details)
        if ai_score:
            try:
                score = int(''.join(c for c in ai_score.split("SCORE=")[-1] if c.isdigit()))
                score = min(max(score, 0), 30)
            except ValueError:
                pass

    if score == 0:
        word_count = len(details.split())
        score = min(word_count // 5, 10)

    narration = ""
    if score >= 15:
        narration = brain.generate_narration(event_type, score, parties, location, details)

    result = {
        "score": score,
        "narration": narration,
        "tier": "filtered" if score < 15 else ("journal" if score < 23 else "crisis")
    }

    supabase.table("kronus_logs").insert({
        "service": "kronus-ai",
        "action": "score_event",
        "context_json": {
            "event_type": event_type,
            "score": score,
            "parties": parties,
            "location": location
        },
        "result": result["tier"]
    }).execute()

    return result


def run_courtroom(citizenid: str, charges: list, officer_citizenid: str) -> dict:
    attorney_tier = _roll_attorney_tier()
    tier_names = {0: "Incompetent", 1: "Standard", 2: "Hotshot"}
    tier_label = tier_names[attorney_tier]

    total_jurors = 12
    guilty_votes = _run_jury_deliberation(charges, attorney_tier, total_jurors)
    verdict = "Guilty" if guilty_votes > total_jurors // 2 else "Not Guilty"

    case_details = f"Defendant: {citizenid}\nCharges: {[c.get('charge', '') for c in charges]}"
    evidence = "\n".join(f"- {c.get('charge', 'Unknown')} ({c.get('severity', 'Misd')})" for c in charges)
    jury_str = f"{guilty_votes}/{total_jurors} guilty"

    ai_reasoning = brain.judge_ruling(case_details, evidence, tier_label, jury_str)

    modifier = 1.0
    if attorney_tier == 0:
        modifier = 1.15
    elif attorney_tier == 2:
        modifier = 0.5

    severity_map = {
        "Felony": {"fine": 5000, "time": 6},
        "Misdemeanor": {"fine": 500, "time": 0},
        "Infraction": {"fine": 100, "time": 0},
    }
    base_fine = sum(severity_map.get(c.get("severity", "Misdemeanor"), {}).get("fine", 500) for c in charges)
    base_time = sum(severity_map.get(c.get("severity", "Misdemeanor"), {}).get("time", 0) for c in charges)

    final_fine = int(base_fine * modifier) if verdict == "Guilty" else 0
    final_time = int(base_time * modifier) if verdict == "Guilty" else 0

    result = {
        "citizenid": citizenid,
        "verdict": verdict,
        "attorney_tier": tier_label,
        "jury_guilty_votes": guilty_votes,
        "jury_total": total_jurors,
        "fine": final_fine,
        "jail_months": final_time,
        "sentence_modifier": modifier,
        "ai_reasoning": ai_reasoning or "Standard statutory ruling applied.",
    }

    supabase.table("kronus_logs").insert({
        "service": "kronus-ai",
        "action": "courtroom",
        "context_json": result,
        "result": verdict
    }).execute()

    return result


def _roll_attorney_tier() -> int:
    roll = random.random()
    if roll < 0.25:
        return 0
    elif roll < 0.75:
        return 1
    else:
        return 2


def _run_jury_deliberation(charges: list, attorney_tier: int, total: int) -> int:
    base = 0.55
    modifiers = {0: -0.10, 1: 0.0, 2: 0.20}
    guilty_chance = base + modifiers.get(attorney_tier, 0) + (len(charges) * 0.03)
    guilty_chance = min(max(guilty_chance, 0.1), 0.95)
    return sum(1 for _ in range(total) if random.random() < guilty_chance)
