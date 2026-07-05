"""Fill compendium gaps v2 — simpler prompts, direct calls."""
import json, time
from openai import OpenAI

client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

def gen_batch(prompt, path, label):
    existing = json.load(open(path))
    print(f'  {label}...')
    resp = client.chat.completions.create(
        model='deepseek-v4-flash',
        messages=[{'role':'user','content': prompt + ' Output valid JSON array only. Start with [ end with ]. No markdown. No explanation.'}],
        max_tokens=6000
    )
    text = resp.choices[0].message.content
    if not text or len(text) < 10:
        print(f'    Empty response')
        return
    s = text.find('['); e = text.rfind(']')+1
    if s < 0:
        print(f'    No JSON found: {text[:100]}')
        return
    try:
        data = json.loads(text[s:e])
        existing += data
        json.dump(existing, open(path,'w'), indent=2)
        print(f'    +{len(data)} -> {len(existing)} total')
    except Exception as err:
        print(f'    Parse error: {str(err)[:80]}')
        open(f'_err_{label}.txt','w').write(text[s:e])
    time.sleep(1.5)

# HIGH CR MONSTERS
monster_batches = [
("Generate 5 D&D 5e monsters CR 8-12 for Solis-Grave grimdark: Abomination Dissolving, Inquisitor Grand-Justicar, Vortex Sky-Admiral, Ferrum Bastion-Guardian, Tenebris Abyss-Walker. Use standard 5e stat block format.", 'CR8-12'),
("Generate 5 D&D 5e monsters CR 10-16 for Solis-Grave grimdark: Penitent High-Priest, Elder Wyvern, Crystal-Infused Hydra, Church Purifier Golem, Tenebris Flesh-Weaver. Standard 5e stat block format.", 'CR10-16'),
("Generate 5 D&D 5e monsters CR 14-20 for Solis-Grave grimdark: Scion Eclipse-Born, Obsidian Law-Golem, Sovereign Flame Whelp, Bone Colossus, Void-Touched Horror. Standard 5e stat block format.", 'CR14-20'),
("Generate 5 D&D 5e monsters CR 8-14 for Solis-Grave: Obsidian Crystal-Warden, Frost Drake Ancient, Sulfur Drake Adult, Pyre Arsenal-Golem, Storm Archon Dragon. Standard 5e stat block format.", 'CR8-14'),
]

for prompt, label in monster_batches:
    gen_batch(prompt, 'compendium_monsters_seed.json', label)

# HIGH LEVEL SPELLS
spell_batches = [
("Generate 8 D&D 5e spells levels 5-7 for Solis-Grave grimdark: Aether Storm, Dragons Awakening, Crown Shatter, Void Walk, Flesh Tide, Inquisitors Final Smite, Cult Prophecy Fulfilled, Pyre Cataclysm. Standard spell format.", 'spells-L5-7'),
("Generate 7 D&D 5e spells levels 7-9 for Solis-Grave grimdark: Void Apocalypse, Sovereigns Awakening, Cycle Break, Tenebris Undoing, Ignis Inferno World, Ferrum Final Stand, Obsidian Final Verdict. Standard spell format.", 'spells-L7-9'),
]

for prompt, label in spell_batches:
    gen_batch(prompt, 'compendium_spells_seed.json', label)

# Check final counts
print()
for f in ['compendium_monsters_seed.json','compendium_spells_seed.json']:
    d = json.load(open(f))
    print(f'{f}: {len(d)} entries')
