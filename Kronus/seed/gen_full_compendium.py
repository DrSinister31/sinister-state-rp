"""Complete Solis-Grave compendium generator — monsters, spells, backgrounds, traits, items, rules."""
import json, time, os
from openai import OpenAI

BASE = os.path.dirname(__file__)
client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

def batch(table, path, prompts, count, batch_size=10):
    """Run multiple prompts, append results to JSON file."""
    existing = json.load(open(path)) if os.path.exists(path) else []
    for prompt in prompts:
        print(f'  {table} batch...')
        resp = client.chat.completions.create(
            model='deepseek-chat',
            messages=[{'role':'user','content':prompt}],
            max_tokens=6000
        )
        text = resp.choices[0].message.content
        s = text.find('['); e = text.rfind(']') + 1
        try:
            data = json.loads(text[s:e])
            existing += data
            json.dump(existing, open(path, 'w'), indent=2)
            print(f'    +{len(data)} -> {len(existing)} total')
        except Exception as err:
            print(f'    Skip: {str(err)[:60]}')
        time.sleep(2)
    return len(existing)

# 1. MONSTERS — 3 batches of 10 (70->100)
print('=== MONSTERS ===')
batch('monsters', 'compendium_monsters_seed.json', [
    'Generate 10 CR 0-4 D&D 5e monsters for Solis-Grave grimdark: Swarm of Sump-Rats, Draft-Horse (War-Trained), Hunting Hound (Aether-Scent), Citadel Watch-Sergeant, Village Headman, Church Tithe-Collector, Canal Smuggler, House Courier, Stable Boy (Blank), Street Urchin (Sump-Blood). JSON only. No markdown. Max 10 objects.',
    'Generate 10 CR 4-9 D&D 5e monsters for Solis-Grave grimdark: Abomination Screamer, Inquisitor Grand-Justicar, Vortex Hurricane-Rider, Ferrum Bastion-Guardian, Tenebris Flesh-Weaver, Penitent High-Priest, Elder Wyvern, Obsidian Crystal-Warden, Frost Drake (Ancient), Pyre Arsenal-Golem. JSON only. No markdown.',
    'Generate 10 CR 0.5-4 D&D 5e monsters for Solis-Grave grimdark: Giant Centipede (Sump), Stirge (Aether-touched), Thug (Unlicensed Caster), Acolyte (Church of Five Skulls), Scout (House Vortex), Spy (House Obsidian), Priest (Church), Cult Fanatic (Sixth), Knight (House Ferrum), Veteran (Iron-Blaze War). JSON only.',
], 10)

# 2. SPELLS — 4 batches of 15 (56->116)
print('=== SPELLS ===')
batch('spells', 'compendium_spells_seed.json', [
    'Generate 15 D&D 5e spells levels 0-9 for Solis-Grave grimdark. Include cantrips: Void-Touch, Dragon-Spark, Flesh-Knit, Blood-Read, Storm-Snap. Level 1-3: Aether-Ward, Sovereigns-Presence, Inquisitors-Chains, Cultists-Secret, Ferrum-Plate. Level 4-6: Ignis-Cataclysm, Vortex-Rift, Obsidian-Decree, Tenebris-Undo, Flesh-Tide. Level 7-9: Dragons-Awakening, Crown-Shatter, Void-Apocalypse. JSON only. Each: {"name":"...","level":0,"school":"...","casting_time":"...","range":"...","components":"...","duration":"...","description":"...","source_tags":["solis-grave"]}',
    'Generate 15 D&D 5e utility/ritual spells levels 1-5 for Solis-Grave grimdark. Include: Blood-Crystal-Locate, Purify-Aether, Forge-Heat, Storm-Sense, Flesh-Recall, Iron-Anchor, Shadow-Pass, Ash-Breath, Sump-Breathe, Scale-Armor, Bone-Mend, Drake-Speed, Crystal-Sight, Void-Whisper, Crown-Oath. JSON only.',
    'Generate 15 D&D 5e combat spells levels 1-7 for Solis-Grave grimdark. Include damage spells: Ignis-Strike, Vortex-Bolt, Obsidian-Shard, Tenebris-Grasp, Ferrum-Bash, Pyre-Blast, Void-Lance, Flesh-Whip, Storm-Chain, Crystal-Burst, Ash-Scatter, Bone-Spear, Sovereigns-Fury, Inquisitors-Smite, Cultists-Venom. JSON only.',
    'Generate 15 D&D 5e protective/healing spells levels 1-6 for Solis-Grave: Aether-Shell, Blood-Barrier, Dragons-Scale, Inquisitors-Bulwark, Flesh-Knit-Greater, Storm-Wall, Iron-Skin, Crystal-Cage, Ash-Cloak, Bone-Shield, Void-Shroud, Crown-Protection, Purify-Curse, Mend-Soul, Sanctuary-Flame. JSON only.',
], 15)

# 3. BACKGROUNDS — 1 batch of 15
print('=== BACKGROUNDS ===')
batch('backgrounds', 'compendium_backgrounds_seed.json', [
    'Generate 15 D&D 5e character backgrounds for Solis-Grave grimdark. Include: Blank-Laborer, Archon-Noble, Cult-Recruit, Inquisitor-Cadet, Sump-Runner, House-Retainer, Core-Thief-Apprentice, Ash-Walker-Outcast, Citadel-Scholar, Veterans-Orphan, Caravan-Guard, Church-Acolyte, Underground-Smuggler, Fallen-Noble, Wild-Hunter. Each: {"name":"...","skill_proficiencies":"...","tool_proficiencies":"...","languages":"...","equipment":"...","feature":"...","feature_desc":"...","personality_traits":"table of 8","ideals":"table of 6","bonds":"table of 6","flaws":"table of 6","source_tags":["solis-grave"]}. JSON only.',
], 15)

# 4. TRAITS — personality, ideals, bonds, flaws tables per background
print('=== TRAITS ===')
batch('traits', 'compendium_traits_seed.json', [
    'Generate tables of personality traits, ideals, bonds, and flaws for Solis-Grave grimdark D&D characters. Output: {"personality_traits":["...8 items..."],"ideals":["...6 items..."],"bonds":["...6 items..."],"flaws":["...6 items..."],"alignments":{"lawful_good":"...","neutral_good":"...","chaotic_good":"...","lawful_neutral":"...","true_neutral":"...","chaotic_neutral":"...","lawful_evil":"...","neutral_evil":"...","chaotic_evil":"..."}}. Solis-Grave flavor: purity caste, dragon blood, feudal oppression, Church dogma, Cult hope, House loyalty. JSON only. Single object.',
], 1, batch_size=1)

# 5. ITEMS — 2 batches of 10
print('=== ITEMS ===')
batch('items', 'compendium_items_seed.json', [
    'Generate 10 Solis-Grave equipment items: health potion (Aether Purifier Greater), scaling weapon (+1 Sword), scaling armor (+1 Shield), ring of spell safety, cloak of sump camouflage, boots of the ridge, amulet of void resistance, gauntlets of forge strength, circlet of purity sight, bag of holding (Aether-Sack). Each: {"name":"...","type":"potion|weapon|armor|wondrous","rarity":"common|uncommon|rare","cost":"...","weight":"...","description":"...","source_tags":["solis-grave"]}. JSON only.',
    'Generate 10 Solis-Grave adventuring gear: 50ft-hemp-rope, crowbar, hammer, pitons(10), rations(10-days), waterskin, tinderbox, torch(10), backpack, bedroll. Re-flavor each item description for Solis-Grave grimdark world. Each: {"name":"...","type":"gear","rarity":"common","cost":"...","weight":"...","description":"...","source_tags":["solis-grave"]}. JSON only.',
], 10)

# 6. RULES — standard 5e + Solis-Grave specific
print('=== RULES ===')
batch('rules', 'compendium_rules_seed.json', [
    'Generate standard D&D 5e combat rules as compendium entries for Solis-Grave: Actions-in-Combat, Bonus-Actions, Reactions, Opportunity-Attacks, Two-Weapon-Fighting, Grappling, Shoving, Cover (half, three-quarters, full), Difficult-Terrain, Surprise, Initiative, Damage-Types (bludgeoning, piercing, slashing, fire, cold, lightning, acid, poison, necrotic, radiant, psychic, force, thunder), Death-Saving-Throws, Stabilizing, Short-Rest, Long-Rest. Each: {"category":"combat","name":"...","description":"...","source_tags":["solis-grave","5e"]}. JSON only. No markdown.',
    'Generate standard D&D 5e conditions as compendium entries for Solis-Grave: Blinded, Charmed, Deafened, Frightened, Grappled, Incapacitated, Invisible, Paralyzed, Petrified, Poisoned, Prone, Restrained, Stunned, Unconscious, Exhaustion (levels 1-6), Concentrating. Each: {"category":"conditions","name":"...","description":"...","source_tags":["solis-grave","5e"]}. JSON only.',
], 15)

print('\n=== DONE ===')
for f in ['compendium_monsters_seed.json','compendium_spells_seed.json','compendium_backgrounds_seed.json','compendium_traits_seed.json','compendium_items_seed.json','compendium_rules_seed.json']:
    if os.path.exists(f):
        d = json.load(open(f))
        c = len(d) if isinstance(d, list) else 1
        print(f'  {f}: {c}')
