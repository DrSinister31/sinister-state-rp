"""Solis-Grave Spell Generator — loads world rules from prompt files, generates 400 spells."""
import json, os, time
from openai import OpenAI

BASE = os.path.dirname(os.path.abspath(__file__))
PROMPTS = os.path.join(os.path.dirname(BASE), "prompts", "solis_grave")

# Load world rules for context
def load_context():
    contexts = []
    for f in [
        "rules/magic_system.md",
        "sovereigns_and_gods.md",
        "ascension_system.md",
    ]:
        try:
            path = os.path.join(PROMPTS, f)
            text = open(path).read()
            contexts.append(text[:2000])  # Cap per file
        except:
            pass
    return "\n\n".join(contexts) if contexts else "Solis-Grave grimdark world. Magic = dragon blood purity."

WORLD_CONTEXT = load_context()
print(f"Loaded {len(WORLD_CONTEXT)} chars of world context")

client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

def gen(prompt, retries=3):
    for attempt in range(retries):
        try:
            resp = client.chat.completions.create(
                model='deepseek-v4-flash',
                messages=[
                    {'role': 'system', 'content': WORLD_CONTEXT + "\n\nGenerate Solis-Grave D&D 5e spells. Output ONLY a valid JSON array. No markdown. Each spell: {\"name\":\"...\",\"level\":0,\"school\":\"...\",\"casting_time\":\"...\",\"range\":\"...\",\"components\":\"...\",\"duration\":\"...\",\"description\":\"...\",\"higher_levels\":\"...\",\"classes\":\"...\",\"source_tags\":[\"solis-grave\"]}. Include purity_requirement and spell_safety_modifier where relevant. Spells should fit grimdark tone — blood, void, dragon fire, aether, church, cult."},
                    {'role': 'user', 'content': prompt}
                ],
                max_tokens=6000
            )
            text = resp.choices[0].message.content
            s = text.find('['); e = text.rfind(']')+1
            if s >= 0 and e > s:
                return json.loads(text[s:e])
        except Exception as e:
            if attempt == retries - 1:
                print(f"  FAILED: {str(e)[:80]}")
            time.sleep(2)
    return []

def generate_range(lvl_min, lvl_max, filename, batch_prompts):
    path = os.path.join(BASE, filename)
    existing = json.load(open(path)) if os.path.exists(path) else []

    for i, prompt in enumerate(batch_prompts):
        lvl_range = f"levels {lvl_min}-{lvl_max}" if lvl_min != lvl_max else f"level {lvl_min}"
        data = gen(prompt, retries=2 if i > 0 else 3)
        if data:
            existing += data
            json.dump(existing, open(path, 'w'), indent=2)
            print(f"  {filename} batch {i+1}: +{len(data)} -> {len(existing)} total")
        else:
            print(f"  {filename} batch {i+1}: empty")
        time.sleep(1.5)
    return len(existing)

print("\n=== CANTRIPS + LEVEL 1 ===")
generate_range(0, 1, "spells_0_1.json", [
    "Generate 15 Solis-Grave cantrips (level 0). Utility, combat, flavor. Include: Void-Spark, Blood-Sense, Dragon-Whisper, Aether-Touch, Forge-Heat, Storm-Snap, Flesh-Knit, Bone-Rattle, Ash-Cloud, Crystal-Glint, Sump-Mist, Iron-Rust, Obsidian-Shard, Cult-Chant, Blanks-Resolve. Grimdark tone.",
    "Generate 15 more Solis-Grave cantrips. Unique utility cantrips. Grimdark tone.",
    "Generate 15 Solis-Grave level 1 spells. Grimdark tone. Combat and utility.",
    "Generate 15 more Solis-Grave level 1 spells. Healing, protection, debuffs. Grimdark tone.",
])

print("\n=== LEVELS 2-3 ===")
generate_range(2, 3, "spells_2_3.json", [
    "Generate 15 Solis-Grave level 2 spells. Grimdark. Combat, utility, ritual.",
    "Generate 15 more Solis-Grave level 2 spells. Grimdark.",
    "Generate 15 Solis-Grave level 3 spells. Grimdark. Powerful combat.",
    "Generate 15 more Solis-Grave level 3 spells. Grimdark.",
])

print("\n=== LEVELS 4-5 ===")
generate_range(4, 5, "spells_4_5.json", [
    "Generate 15 Solis-Grave level 4 spells. Grimdark. Major combat spells.",
    "Generate 15 more Solis-Grave level 4 spells. Grimdark.",
    "Generate 15 Solis-Grave level 5 spells. Grimdark. Epic spells, mass combat, transformation.",
    "Generate 10 more Solis-Grave level 5 spells. Grimdark.",
])

print("\n=== LEVELS 6-7 ===")
generate_range(6, 7, "spells_6_7.json", [
    "Generate 15 Solis-Grave level 6 spells. Grimdark. Near-legendary spells.",
    "Generate 15 Solis-Grave level 7 spells. Grimdark. Legendary spells — reality warping, mass destruction, divine intervention.",
])

print("\n=== LEVELS 8-9 ===")
generate_range(8, 9, "spells_8_9.json", [
    "Generate 12 Solis-Grave level 8 spells. Grimdark. God-tier spells.",
    "Generate 12 Solis-Grave level 9 spells. Grimdark. Reality-warping, world-changing ultimate spells.",
])

# Final counts
total = 0
for f in os.listdir(BASE):
    if f.startswith("spells_") and f.endswith(".json"):
        d = json.load(open(os.path.join(BASE, f)))
        print(f"  {f}: {len(d)} spells")
        total += len(d)
print(f"\n=== TOTAL: {total} spells ===")
