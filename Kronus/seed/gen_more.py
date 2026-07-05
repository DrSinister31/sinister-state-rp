import json, time
from openai import OpenAI

client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

def generate_spells():
    path = 'compendium_spells_seed.json'
    spells = json.load(open(path))
    template = '{"name":"...","level":0,"school":"Evocation","casting_time":"1 Action","range":"60 feet","components":"V, S","duration":"Instantaneous","description":"...","source_tags":["solis-grave"]}'
    
    batches = [
        'Generate 15 D&D 5e spells levels 0-6 for Solis-Grave grimdark. Include: Aether Missile, Void Shield, Blood Sacrifice, Dragons Breath, Inquisitors Verdict, Cult Prophecy, Flesh Graft, Storm Cloak, Iron Skin, Pyre Forge, Sump Mist, Ash Storm, Drakes Blood, Bone Cage, Crystal Lance.',
        'Generate 15 D&D 5e spells levels 3-8 for Solis-Grave grimdark. Include: Sovereigns Wrath, Tenebris Corruption, Ferrum Stand, Vortex Tornado, Obsidian Gavel, Ignis Inferno, Core Explosion, Aetheric Flood, Blanks Fury, Penitents Gambit, Void Walk, Cycle Break, Crown Shatter, Sleeper Rise, Maw Open.',
    ]
    
    for prompt in batches:
        print(f'Spell batch...')
        full = prompt + f' Output ONLY valid JSON array. No markdown. Each object format: {template}. Max 15 objects.'
        resp = client.chat.completions.create(model='deepseek-chat', messages=[{'role':'user','content':full}], max_tokens=6000)
        text = resp.choices[0].message.content
        s = text.find('[')
        e = text.rfind(']') + 1
        try:
            data = json.loads(text[s:e])
            spells += data
            json.dump(spells, open(path, 'w'), indent=2)
            print(f'  +{len(data)} -> {len(spells)} total')
        except Exception as err:
            print(f'  Skip: {str(err)[:60]}')
        time.sleep(2)
    return len(spells)

def generate_monsters():
    path = 'compendium_monsters_seed.json'
    monsters = json.load(open(path))
    
    batches = [
        'Generate 10 CR 0.25-4 monsters for Solis-Grave grimdark: Giant Spider Aether-touched, Sump-Barrow Ghoul, Cultist Initiate, Vortex Lookout, Ferrum Recruit, Obsidian Clerk, Tenebris Specimen, Pyre Smith Apprentice, Blank Deserter, Ash-Walker Vagrant.',
        'Generate 10 CR 5-10 monsters for Solis-Grave grimdark: Abomination Bloated, Inquisitor Purifier, Vortex Storm-Captain, Ferrum Iron-Sentinel, Tenebris Flesh-Golem, Penitent Firebrand, Adult Wyvern, Sulfur Drake, Crystal Hydra, Pyre Siege-Golem.',
    ]
    
    for prompt in batches:
        print(f'Monster batch...')
        full = prompt + ' Output ONLY valid JSON array. No markdown. Max 10 objects.'
        resp = client.chat.completions.create(model='deepseek-chat', messages=[{'role':'user','content':full}], max_tokens=6000)
        text = resp.choices[0].message.content
        s = text.find('[')
        e = text.rfind(']') + 1
        try:
            data = json.loads(text[s:e])
            monsters += data
            json.dump(monsters, open(path, 'w'), indent=2)
            print(f'  +{len(data)} -> {len(monsters)} total')
        except Exception as err:
            print(f'  Skip: {str(err)[:60]}')
        time.sleep(2)
    return len(monsters)

if __name__ == '__main__':
    m = generate_monsters()
    s = generate_spells()
    print(f'Done: {m} monsters, {s} spells')
