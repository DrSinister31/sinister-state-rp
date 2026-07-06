"""Spell Agent — Generate Solis-Grave spells for a specific level range.
Usage: python spell_agent.py <min_level> <max_level> <output_file>
Example: python spell_agent.py 0 1 spells_0_1.json"""
import json, sys, os, time
from openai import OpenAI

MIN_LVL = int(sys.argv[1]) if len(sys.argv) > 1 else 0
MAX_LVL = int(sys.argv[2]) if len(sys.argv) > 2 else 1
OUTPUT = sys.argv[3] if len(sys.argv) > 3 else f"spells_{MIN_LVL}_{MAX_LVL}.json"

client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

SPELL_CLASSES = "Vanguard-Blank,Strider-Garrison,Archon-Caster,Ordained,Penitent,Sovereign"
SPELL_TEMPLATE = '{"name":"Spell Name","level":0,"school":"School","casting_time":"1 Action","range":"60 feet","components":"V, S, M (component)","duration":"Instantaneous","description":"Detailed mechanical description with exact numbers and Solis-Grave flavor.","higher_levels":"At Higher Levels text","classes":"Class1, Class2","purity_requirement":0,"spell_safety_modifier":0,"source_tags":["solis-grave","element-tag"]}'

WORLD_TONE = """Solis-Grave grimdark tone: Magic = dragon blood purity. Casting spells without sufficient purity causes Aether Burn (internal damage, ignores resistances). Spell Safety DC = 20 - (Purity/5). Blanks (0% purity) cannot cast. Church hunts illegal casters. Void magic is forbidden. Blood magic costs HP. Undead are failed Ascension rituals. Dragons are classified by purity tier."""

def gen_batch(prompt, retries=2):
    for attempt in range(retries):
        try:
            resp = client.chat.completions.create(
                model='deepseek-v4-flash',
                messages=[{'role':'system','content':WORLD_TONE},{'role':'user','content':prompt + f'\n\nOutput ONLY a valid JSON array. No markdown. No explanation. Start with [. End with ]. Each object must exactly match this format:\n{SPELL_TEMPLATE}\nMax 15 objects.'}],
                max_tokens=6000
            )
            text = resp.choices[0].message.content
            s = text.find('['); e = text.rfind(']')+1
            if s >= 0:
                return json.loads(text[s:e])
        except Exception as e:
            if attempt == retries - 1:
                print(f"  FAILED after {retries} attempts: {e}")
            time.sleep(2)
    return []

def main():
    batch_prompts = {
        (0,1): [
            f"Generate 15 Solis-Grave cantrips (level 0). Include utility, combat, and flavor cantrips. Classes: {SPELL_CLASSES}. Dark fantasy flavor — void sparks, blood reading, draconic whispers, aether touch, forge heat, storm snap, flesh knit, bone rattle, ash cloud, crystal glint, sump mist, iron rust, obsidian shard, cult chant, blanks resolve.",
            f"Generate 15 Solis-Grave cantrips (level 0). Include more utility and unique cantrips. Classes: {SPELL_CLASSES}. Dark fantasy flavor.",
            f"Generate 10 Solis-Grave level 1 spells. Combat and utility. Classes: {SPELL_CLASSES}. Include: Aether Missile, Void Shield, Blood Boil, Dragons Breath, Inquisitors Mark, Cult Whispers, Flesh Mend, Storm Step, Iron Skin, Pyre Spark.",
            f"Generate 10 Solis-Grave level 1 spells. More combat and utility. Classes: {SPELL_CLASSES}. Include: Sump Fog, Ash Cloud, Drakes Fury, Bone Armor, Crystal Shard, Aetheric Ward, Blanks Endurance, Penitents Sacrifice, Core Drain, Sovereigns Whisper.",
            f"Generate 10 Solis-Grave level 1 spells. Healing, buffs, debuffs. Classes: {SPELL_CLASSES}. Include: Purify Blood, Mend Flesh, Iron Resolve, Void Touch, Storm Blessing, Forge Strength, Obsidian Verdict, Tenebris Grasp, Ferrum Stand, Pyre Warmth.",
        ],
        (2,3): [
            f"Generate 15 Solis-Grave level 2 spells. Combat, utility, rituals. Classes: {SPELL_CLASSES}. Include: Aether Storm, Void Step, Blood Pact, Dragons Roar, Inquisitors Chains, Cult Prophecy, Flesh Graft, Storm Cloak, Iron Wall, Pyre Blast, Sump Breath, Ash Storm, Drakes Fury II, Bone Cage, Crystal Lance.",
            f"Generate 15 Solis-Grave level 2 spells. More variety. Classes: {SPELL_CLASSES}.",
            f"Generate 10 Solis-Grave level 3 spells. Powerful combat and utility. Classes: {SPELL_CLASSES}. Include: Aetheric Chain, Void Walk, Blood Sacrifice, Dragons Wrath, Inquisitors Smite, Cult Ritual, Flesh Tide, Storm Call, Iron Fortress, Pyre Cataclysm, Sump Drown, Ash Burial, Drakes Breath, Bone Wall, Crystal Prison.",
            f"Generate 10 Solis-Grave level 3 spells. More level 3 variety. Classes: {SPELL_CLASSES}.",
        ],
        (4,5): [
            f"Generate 15 Solis-Grave level 4 spells. Classes: {SPELL_CLASSES}. Include powerful combat, utility, and ritual spells.",
            f"Generate 10 Solis-Grave level 4 spells. More variety. Classes: {SPELL_CLASSES}.",
            f"Generate 15 Solis-Grave level 5 spells. Major combat and utility. Classes: {SPELL_CLASSES}. Include: Aether Storm (mass), Void Apocalypse (lesser), Blood Tide, Dragons Awakening (lesser), Inquisitors Final Smite, Cult Mass Fervor, Flesh Horde, Storm Legion, Iron Battalion, Pyre Inferno.",
            f"Generate 10 Solis-Grave level 5 spells. More variety. Classes: {SPELL_CLASSES}.",
        ],
        (6,7): [
            f"Generate 10 Solis-Grave level 6 spells. Epic combat and utility. Classes: {SPELL_CLASSES}. Include: Void Cataclysm, Blood Moon, Dragons Transformation, Inquisitors Excommunication, Cult Mass Prophecy, Flesh Army, Storm Apocalypse, Iron Citadel, Pyre World-Fire, Sovereigns Decree, Core Explosion.",
            f"Generate 10 Solis-Grave level 6 spells. More variety. Classes: {SPELL_CLASSES}.",
            f"Generate 10 Solis-Grave level 7 spells. Legendary spells. Classes: {SPELL_CLASSES}. Include: Void Rift, Blood Eclipse, Dragons True Form, Inquisitors Divine Judgment, Cult Sixth Coming, Flesh God, Storm God, Iron God, Pyre God, Sovereigns Command, Crown Shatter, Cycle Break, Maw Open, Tail Strike, Sleeper Rise.",
            f"Generate 5 Solis-Grave level 7 spells. More legendary spells. Classes: {SPELL_CLASSES}.",
        ],
        (8,9): [
            f"Generate 10 Solis-Grave level 8 spells. Near-god tier. Classes: {SPELL_CLASSES}. Include: Void Annihilation, Blood Apocalypse, Dragons Ascension, Inquisitors Gods Wrath, Cult Fulfillment, Flesh Cataclysm, Storm Ragnarok, Iron Apocalypse, Pyre Extinction, Sovereigns Awakening, Crown Shatter True, Cycle End, Maw Consume, Tail Coil, Sleeper Awake.",
            f"Generate 10 Solis-Grave level 9 spells. God-tier reality warping. Classes: {SPELL_CLASSES}. Include: Void Unmake, Blood God, Dragons God, Inquisitors Armageddon, Cult Sixth Rises, Flesh World, Storm World-Ender, Iron World-Wall, Pyre World-Ash, Sovereigns Return, Crown Breaker, Cycle Reset, Maw Devour, Tail Strike True, Sleeper Walk.",
        ],
    }

    key = (MIN_LVL, MAX_LVL)
    if key not in batch_prompts:
        print(f"No prompts for range {MIN_LVL}-{MAX_LVL}")
        return

    existing = json.load(open(OUTPUT)) if os.path.exists(OUTPUT) else []
    prompts = batch_prompts[key]

    for i, prompt in enumerate(prompts):
        print(f"  Batch {i+1}/{len(prompts)}...")
        data = gen_batch(prompt)
        if data:
            existing += data
            json.dump(existing, open(OUTPUT, 'w'), indent=2)
            print(f"    +{len(data)} -> {len(existing)} total")
        else:
            print(f"    No valid output")
        time.sleep(1.5)

    print(f"\nDone! {OUTPUT}: {len(existing)} spells for levels {MIN_LVL}-{MAX_LVL}")

if __name__ == '__main__':
    main()
