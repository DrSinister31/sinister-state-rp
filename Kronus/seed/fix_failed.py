import json, time
from openai import OpenAI
client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

# More monsters
monsters = json.load(open('compendium_monsters_seed.json'))
for prompt in [
    "Generate 10 CR 0.5-3 D&D 5e monsters for Solis-Grave grimdark: Zombie Blank-Laborer, Skeleton Guard, Shadow Aether-Wisp, Mastiff War-Hound, Mule Pack-Beast, Hawk Messenger-Scout, Cat Sump-Stalker, Rat Disease-Carrier, Raven Cult-Watcher, Snake Pit-Viper. JSON array only. No markdown. Max 10 objects.",
    "Generate 10 CR 1-5 D&D 5e monsters for Solis-Grave grimdark: Ghast Tenebris-Experiment, Wight Frozen-Soldier, Specter Failed-Ascension, Ogre Border-Brute, Harpy Vortex-Siren, Merrow Sump-Lurker, Basilisk Stone-Ridge, Cockatrice Sulfur-Hen, Doppelganger Obsidian-Spy, Mimic Treasure-Trap. JSON array only. No markdown. Max 10 objects.",
]:
    print('Monster batch...')
    resp = client.chat.completions.create(model='deepseek-chat', messages=[{'role':'user','content':prompt}], max_tokens=6000)
    text = resp.choices[0].message.content
    s = text.find('['); e = text.rfind(']')+1
    try:
        data = json.loads(text[s:e]); monsters += data
        json.dump(monsters, open('compendium_monsters_seed.json','w'), indent=2)
        print(f'  +{len(data)} -> {len(monsters)} total')
    except Exception as err:
        print(f'  Skip: {str(err)[:60]}')
    time.sleep(2)

# Backgrounds
print('Backgrounds...')
resp = client.chat.completions.create(model='deepseek-chat', messages=[{'role':'user','content':(
    'Generate 8 D&D 5e character backgrounds for Solis-Grave grimdark. '
    'Output JSON array. Each object format: {"name":"Blank-Laborer","skill_proficiencies":"Athletics, Survival",'
    '"tool_proficiencies":"Carpenters tools","languages":"Common","equipment":"Common clothes, shovel, 5 CP",'
    '"feature":"Unseen and Unnoticed","feature_desc":"Nobles ignore you as furniture. Move through noble districts unnoticed.",'
    '"source_tags":["solis-grave"]}. Include: Blank-Laborer, Archon-Noble, Cult-Recruit, Inquisitor-Cadet, Sump-Runner, '
    'House-Retainer, Core-Thief-Apprentice, Ash-Walker-Outcast. JSON only. Max 8 objects.'
)}], max_tokens=4000)
text = resp.choices[0].message.content
s = text.find('['); e = text.rfind(']')+1
try:
    data = json.loads(text[s:e])
    json.dump(data, open('compendium_backgrounds_seed.json','w'), indent=2)
    print(f'  {len(data)} backgrounds')
except Exception as err:
    print(f'  Skip: {str(err)[:60]}')
    open('raw_backgrounds.txt','w').write(text)

# Traits - single alignment + personality object
print('Traits...')
resp = client.chat.completions.create(model='deepseek-chat', messages=[{'role':'user','content':(
    'Generate personality traits, ideals, bonds, flaws, and alignment descriptions for Solis-Grave D&D. '
    'Output a SINGLE JSON object (not array): {"personality_traits":["8 traits here"],"ideals":["6 ideals here"],'
    '"bonds":["6 bonds here"],"flaws":["6 flaws here"],"alignments":{"Lawful Good":"Upholds purity caste as divine order.",'
    '"Neutral Good":"Helps where they can, survival first.","Chaotic Good":"Breaks unjust laws for right causes.",'
    '"Lawful Neutral":"Purity is law. Church is order.","True Neutral":"Stays neutral. Lives day to day.",'
    '"Chaotic Neutral":"Trusts no faction. Own survival above all.",'
    '"Lawful Evil":"Uses purity system to dominate. Archon supremacy.",'
    '"Neutral Evil":"Exploits weakness. Blank or Archon all the same.",'
    '"Chaotic Evil":"Burns it all. The system is a lie."}}. '
    'Solis-Grave flavor: blood purity caste, feudal oppression, Church dogma, House loyalty, Cult hope, Blank despair. '
    'JSON only. No markdown. Single object.'
)}], max_tokens=2000)
text = resp.choices[0].message.content
s = text.find('{')
try:
    data = json.loads(text[s:])
    json.dump(data, open('compendium_traits_seed.json','w'), indent=2)
    print(f'  Traits: {list(data.keys())}')
except Exception as err:
    print(f'  Skip: {str(err)[:60]}')
    open('raw_traits.txt','w').write(text)

# Final
print()
for f in ['compendium_monsters_seed.json','compendium_spells_seed.json','compendium_backgrounds_seed.json','compendium_traits_seed.json','compendium_items_seed.json','compendium_rules_seed.json']:
    import os
    if os.path.exists(f):
        d = json.load(open(f))
        c = len(d) if isinstance(d, list) else ('obj: '+', '.join(list(d.keys())[:4]) if isinstance(d, dict) else 1)
        print(f'{f}: {c}')
