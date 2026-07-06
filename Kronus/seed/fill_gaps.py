"""Fill compendium gaps: high-CR monsters + high-level spells."""
import json, time
from openai import OpenAI

client = OpenAI(api_key='sk-a80259455b0646ef997c55742da5f532', base_url='https://api.deepseek.com/v1')

def gen(prompts, path, max_tokens=6000):
    existing = json.load(open(path))
    for prompt in prompts:
        print(f'  Generating...')
        resp = client.chat.completions.create(
            model='deepseek-v4-flash',
            messages=[{'role':'user','content':prompt + ' JSON array only. No markdown. Max objects: ' + prompt.split('|')[0] if '|' in prompt else '10'}],
            max_tokens=max_tokens
        )
        text = resp.choices[0].message.content
        s = text.find('['); e = text.rfind(']')+1
        try:
            data = json.loads(text[s:e])
            existing += data
            json.dump(existing, open(path,'w'), indent=2)
            print(f'    +{len(data)} -> {len(existing)} total')
        except Exception as err:
            print(f'    Skip: {str(err)[:60]}')
        time.sleep(1.5)
    return len(existing)

# HIGH CR MONSTERS (CR 8-20)
print('=== HIGH CR MONSTERS ===')
gen([
    "Generate 5 D&D 5e monsters CR 8-12 for Solis-Grave grimdark: Abomination Dissolving (CR 9, unstable, acid aura), Inquisitor Grand-Justicar (CR 10, legendary actions, purging smite), Vortex Sky-Admiral (CR 8, flying, lightning lance), Ferrum Bastion-Guardian (CR 11, shield-wall, immune to push), Tenebris Abyss-Walker (CR 10, teleporting, necrotic touch). JSON array only. No markdown.",
    "Generate 5 D&D 5e monsters CR 10-15 for Solis-Grave grimdark: Penitent High-Priest (CR 12, legendary, mass fervor), Elder Wyvern (CR 11, legendary, acid breath), Crystal-Infused Hydra (CR 13, multi-head regen, crystal reflect spell), Church Purifier Golem (CR 14, anti-magic field, construct), Tenebris Flesh-Weaver (CR 10, summon abominations, flesh control). JSON array only.",
    "Generate 5 D&D 5e monsters CR 14-20 for Solis-Grave grimdark: Scion Eclipse-Born Advanced (CR 16, cataclysmic aura, double heartbeat legendary), Obsidian Law-Golem (CR 15, immune to nonmagical, pronounce sentence legendary), Sovereign Flame Whelp (CR 18, young sovereign dragon, fire breath legendary, purity sight), Bone Colossus (CR 17, dragon-bone construct, multi-attack legendary, fear aura), Void-Touched Horror (CR 16, tentacles, void step teleport, madness aura). JSON array only.",
    "Generate 5 D&D 5e monsters CR 8-14 for Solis-Grave grimdark: Obsidian Crystal-Warden (CR 9, crystal prison, psychic blast), Frost Drake Ancient (CR 12, cold breath legendary, ice wall lair), Sulfur Drake Adult (CR 8, sulfur breath poison, burrow), Pyre Arsenal-Golem (CR 10, multi-weapon, flamethrower, self-destruct), Storm Archon Dragon (CR 14, lightning breath, wind control, lightning immunity). JSON array only.",
], 'compendium_monsters_seed.json')

# HIGH LEVEL SPELLS (level 5-9)
print('=== HIGH LEVEL SPELLS ===')
gen([
    'Generate 8 D&D 5e spells levels 5-7 for Solis-Grave grimdark: Aether Storm (5th, large AoE, wild surge risk), Dragons Awakening (6th, temporary draconic transformation), Crown Shatter (7th, anti-monarch, breaks enchantments), Void Walk (6th, teleport through void space), Flesh Tide (5th, AoE necrotic wave, heal allies), Inquisitors Final Smite (6th, single target massive radiant), Cult Prophecy Fulfilled (5th, party buff, fervor risk cost), Pyre Cataclysm (7th, massive fire AoE, leaves burning terrain). JSON array only.',
    'Generate 7 D&D 5e spells levels 7-9 for Solis-Grave grimdark: Void Apocalypse (9th, reality warps, wild surge table), Sovereigns Awakening (9th, true draconic form, exhaustion after), Cycle Break (8th, reverse time 1 round, extreme cost), Tenebris Undoing (8th, flesh manipulation mass, permanent scars), Ignis Inferno World (9th, fire storm legendary, terrain changes), Ferrum Final Stand (7th, party invulnerable 1 round, user drops to 0 HP), Obsidian Final Verdict (7th, mass banishment, Lawful only). JSON array only.',
], 'compendium_spells_seed.json')

print('\nDone!')
