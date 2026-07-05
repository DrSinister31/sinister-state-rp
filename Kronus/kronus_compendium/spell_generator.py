import sys, os, json, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from pathlib import Path
from openai import OpenAI
from shared.config import Config
from shared.supabase_client import get_supabase

PROMPT_DIR = Path(__file__).resolve().parent.parent.parent / "prompts" / "solis_grave" / "rules"
SPELL_SYSTEM_PROMPT = (PROMPT_DIR / "magic_system.md").read_text(encoding="utf-8")
CLASSES_DATA = json.loads((PROMPT_DIR / "classes.json").read_text(encoding="utf-8"))
OUTPUT_DIR = Path(__file__).resolve().parent.parent.parent / "prompts" / "solis_grave" / "spells"


class SpellGenerator:
    """Generate Solis-Grave spells using DeepSeek AI, matching the existing CompendiumGenerator pattern."""

    def __init__(self, config: Config):
        self.config = config
        self.client = OpenAI(
            api_key=config.deepseek_api_key,
            base_url="https://api.deepseek.com/v1"
        )
        self.supabase = get_supabase(config)
        self.daily_calls = 0
        self.daily_limit = 100

    def _build_prompt(self, level_range: tuple[int, int], classes_target: list[str],
                      spell_count: int, style: str = "reflavor") -> str:
        """Build the generation prompt for a batch of spells."""
        min_lvl, max_lvl = level_range
        class_names = ", ".join(classes_target)
        level_str = f"level {min_lvl} to {max_lvl}" if min_lvl != max_lvl else f"level {min_lvl}"

        srd_context = ""
        if style == "reflavor":
            srd_context = """
You are provided with a list of D&D 5e SRD spells that need to be RE-FLAVORED for the Solis-Grave setting. For each spell:
1. Keep the same mechanical function (damage dice, range, duration, saving throws, effects)
2. REWRITE the name if it references non-draconic concepts (e.g. "Fireball" → "Cinder Burst", "Cure Wounds" → "Blood-Mend", "Magic Missile" → "Sigil Dart")
3. REWRITE the description to use Solis-Grave terminology: magic is bloodline-based, components use Aether-Cores not bat guano, verbal components are the Old Tongue, somatic components trace bloodline sigils
4. ASSIGN classes from the class list below. A spell may belong to multiple classes.
5. ADD purity_requirement (0-100) matching the hybrid gating rules in magic_system.md
6. ADD aether_burn_risk tag: None/Low/Moderate/Severe/Catastrophic
7. ADD spell_safety_modifier (0 to 5) — higher for more volatile spells
8. SET source_tags: ["solis-grave", "srd-ref", original_srd_name]
"""
        else:
            srd_context = """
You are creating ENTIRELY NEW homebrew spells for the Solis-Grave setting. These spells must:
1. Be thematically appropriate for the target class(es)
2. Fill gaps in the spell list (e.g. martial cantrips for non-casters, unique bloodline spells for Sovereign, blood curses for Blood Hunter, gadget-spells for Artificer)
3. Follow the same mechanical balance as standard D&D 5e spells of the same level
4. Use Solis-Grave magic system rules for components, purity, aether burn
5. ASSIGN to appropriate classes
"""

        return f"""You are the "Solis-Grave Grimoire Architect." Generate {spell_count} D&D 5e-compatible spells for levels {level_str}, targeting these classes: {class_names}.

{srd_context}

## SOLIS-GRAVE MAGIC SYSTEM (FULL RULES)
{SPELL_SYSTEM_PROMPT}

## TARGET CLASSES
{json.dumps(CLASSES_DATA["classes"], indent=2)[:3000]}

## CLASS SPELL LISTS
{json.dumps(CLASSES_DATA["class_spell_lists"], indent=2)}

## OUTPUT FORMAT
Return ONLY a valid JSON array. No markdown, no explanation, no code blocks. Each spell object:

{{
  "name": "Cinder Burst",
  "level": 3,
  "school": "Evocation",
  "casting_time": "1 action",
  "range": "150 feet",
  "components": "V, S, M (Intact Aether-Core — Fire)",
  "duration": "Instantaneous",
  "description": "You trace the sigil of your bloodline in a sweeping arc, then speak the Old Tongue word for 'ignition'. A bead of compressed draconic flame streaks from your fingertip...",
  "higher_level": "When you cast this spell using a spell slot of 4th level or higher, the damage increases by 1d6 for each slot level above 3rd.",
  "classes": ["sorcerer", "wizard"],
  "subclass": null,
  "ritual": false,
  "concentration": false,
  "purity_requirement": 25,
  "aether_burn_risk": "Moderate",
  "spell_safety_modifier": 2,
  "source_tags": ["solis-grave", "srd-ref", "fireball"]
}}

## CONSTRAINTS
- Every spell MUST have a valid purity_requirement matching the gating rules (cantrip=0, 1st-2nd>=10, 3rd-5th>=25, 6th-7th>=50, 8th-9th>=75)
- Every spell MUST be assigned to at least one class that CAN cast at that level
- Paladin/Ranger/Artificer/Blood Hunter max spell level is 5
- Fighter (Eldritch Knight)/Rogue (Arcane Trickster) max spell level is 4
- Cantrips must exist for ALL classes including non-casters (for Blood Awakening)
- aether_burn_risk must be one of: None, Low, Moderate, Severe, Catastrophic
- spell_safety_modifier must be integer 0-5
- Do NOT include spells above level 9 or below level 0 (cantrip=0)
- Write original descriptions — do not copy SRD text verbatim

## OUTPUT
Valid JSON array of {spell_count} spell objects:"""

    def generate(self, level_range: tuple[int, int], classes_target: list[str],
                 spell_count: int = 10, style: str = "reflavor",
                 srd_names: list[str] | None = None) -> list[dict]:
        """Generate spells via DeepSeek. Returns list of spell dicts."""
        if self.daily_calls >= self.daily_limit:
            print(f"[spell-generator] Daily limit of {self.daily_limit} reached.")
            return []

        prompt = self._build_prompt(level_range, classes_target, spell_count, style)
        if srd_names:
            prompt += f"\n\nSRD spells to reflavor:\n" + "\n".join(f"- {n}" for n in srd_names)

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=8192,
                temperature=0.7
            )
            self.daily_calls += 1

            content = response.choices[0].message.content
            content = content.strip()
            if content.startswith("```"):
                content = content.split("\n", 1)[1]
                if content.endswith("```"):
                    content = content[:-3]
            if content.startswith("json"):
                content = content[4:]

            spells = json.loads(content)
            if not isinstance(spells, list):
                spells = [spells]
            print(f"[spell-generator] Generated {len(spells)} spells. Daily calls: {self.daily_calls}/{self.daily_limit}")
            return spells
        except json.JSONDecodeError as e:
            print(f"[spell-generator] JSON parse error: {e}")
            print(f"[spell-generator] Raw response: {content[:500]}...")
            return []
        except Exception as e:
            print(f"[spell-generator] API error: {e}")
            return []

    def insert_spells(self, spells: list[dict]) -> int:
        """Upsert spells into supabase compendium_spells table. Returns count inserted."""
        inserted = 0
        for spell in spells:
            try:
                existing = self.supabase.table("compendium_spells").select("id").eq("name", spell["name"]).execute()
                if existing.data:
                    self.supabase.table("compendium_spells").update(spell).eq("name", spell["name"]).execute()
                else:
                    self.supabase.table("compendium_spells").insert(spell).execute()
                inserted += 1
            except Exception as e:
                print(f"[spell-generator] DB error for {spell.get('name')}: {e}")
        return inserted

    def save_to_file(self, spells: list[dict], filename: str) -> str:
        """Save generated spells to a JSON file. Returns file path."""
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        path = OUTPUT_DIR / filename
        path.write_text(json.dumps(spells, indent=2), encoding="utf-8")
        return str(path)

    def count_spells(self) -> int:
        """Count total spells in the database."""
        try:
            r = self.supabase.table("compendium_spells").select("id", count="exact").execute()
            return r.count or 0
        except:
            return 0


if __name__ == "__main__":
    config = Config.from_env()
    gen = SpellGenerator(config)
    print(f"[spell-generator] Current compendium: {gen.count_spells()} spells")
    print(f"[spell-generator] Daily limit: {gen.daily_limit}")
    print(f"[spell-generator] Output dir: {OUTPUT_DIR}")
    print("[spell-generator] Ready. Use generate() + insert_spells() or save_to_file().")
