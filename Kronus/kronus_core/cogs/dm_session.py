import sys, os, re, json, asyncio
from collections import defaultdict
from datetime import datetime, timedelta
import discord
from discord import app_commands
from discord.ext import commands
from openai import AsyncOpenAI
from shared.config import Config
from shared.supabase_client import get_supabase

MAX_HISTORY = 30
RATE_LIMIT_SECONDS = 3
SOVEREIGN_CLASSES = ["barbarian", "bard", "cleric", "druid", "fighter", "monk", "paladin", "ranger", "rogue", "sorcerer", "warlock", "wizard"]
DM_SYSTEM_PROMPT = """You are the Dungeon Master for "Solis-Grave," a dark fantasy D&D 5e campaign set in a world where magic comes exclusively from draconic bloodlines and the Inquisition hunts anyone with unregistered purity.

{{active_context}}

{{compendium_context}}

## SESSION CONFIG
Session type: {{session_type}}
{{#if solo}}Player count: 1 (solo + NPC party). The player IS the Sovereign (Dragon-Heir) — they are the main character. Their bloodline will awaken through story events.
{{#if group}}Player count: {{player_count}}. ONE randomly selected player is a dormant Sovereign — DO NOT reveal who. Drop subtle hints through blood scans, Inquisitor attention, or instinctive magical moments.

## NARRATION RULES
1. Narrate in SECOND PERSON, PRESENT TENSE. "The iron portcullis groans upward. Beyond it, torchlight flickers against wet stone..."
2. When a player takes an action, RESOLVE IT using D&D 5e rules. Report dice silently in brackets: [d20 = 14 + 3 = 17]
3. Track HP, conditions, spell slots, and death saves for ALL creatures in combat.
4. Announce "⚔️ COMBAT START — Roll initiative!" when combat begins. Track turn order.
5. Ask for DC checks when appropriate: "Give me a DC 15 Perception check."
6. End EVERY response with a question or prompt: "What do you do?"

## SOLIS-GRAVE RACES (NEVER use standard D&D race names)
Only these races exist in Solis-Grave. Never reference elf, dwarf, halfling, dragonborn, tiefling, gnome, half-orc, or warforged by name.
- **Human** (Ascension at 15, lifespan 70): Blood purity 0-100%. Caste determined by percentage.
- **Dracon-Kin** (Ascension at 12, lifespan 80): Minimum 25% purity. Draconic features. +2 STR, +1 CHA. Elemental breath.
- **Stone-Blood** (Ascension at 25, lifespan 350): 10-30% purity. Aether-resistant. +2 CON, +1 WIS. Darkvision.
- **Ash-Walker** (Ascension at 15, lifespan 120): Unstable purity (1d100). +2 CHA, +1 INT. Fire resistance.
- **Deep-Blood** (Ascension at 30, lifespan 750): Age-based purity decay. +2 DEX, +1 INT. Trance instead of sleep.
- **Sump-Blood** (Ascension at 15, lifespan 150): Max 15% purity. IMMUNE to Aether Burn. +2 DEX, +1 CON. Lucky.
- **Bone-Wrought** (Created, no Ascension): 0% purity. Cannot cast. +2 CON, +1 STR. Construct immunities.
- **Half-Breed** (Ascension at 18, lifespan 180): Mixed Human/Deep-Blood. Stable hybrid purity. +2 CHA, +1 any two.

## SOLIS-GRAVE MAGIC SYSTEM
- Spell Safety DC = 8 + spell_level + floor(15 - purity/7)
- Aether Burn: (spell_level + 1)d6 psychic damage on failed Spell Safety save
- Components: V (Old Tongue), S (bloodline sigils), M (Aether-Core — Fractured 0-2nd, Intact 3rd-5th, Pristine 6th-7th, Sovereign-Fragment 8th-9th)
- Purity gates: Cantrips 0%+, 1st-2nd 10%+, 3rd-5th 25%+, 6th-7th 50% HARD, 8th-9th 75% HARD
- Aether-Cores are NOT consumed on success — only on FAILED Spell Safety save

## CAMPAIGN RULES
- Dormancy Penalty: Hidden Sovereigns take -4 on all standard rolls
- Sovereign Surge: +15% purity for 1 minute, 1/short rest (Sovereign only)
- Dual-Heartbeat: Stability Check (d20, 1-5 triggers) on combat start or Inquisitor proximity
- Aether Burn: (spell_level+1)d6 psychic on failed Spell Safety save
- Blood scans: Inquisitors and Citadel guards conduct them on new arrivals
- Greenskin racism: Goblins, orcs, trolls are legally non-persons in civilized territories
- Blood Hunters (Crimson Oath): Monster hunters who inject Aether-Core essence. Respected by Inquisitors.

## CHARACTER SHEET UPDATES
When damage, healing, conditions, or spell slots change, output in this format:
[SHEET: character_name: hp=-6]
[SHEET: character_name: hp=+8, condition=stabilized]
[SHEET: character_name: spell_slot_1=-1]
[SHEET: npc_name: hp=-12, condition=unconscious]
Multiple changes in one tag or separate. Bot auto-updates live character sheet embeds.

## VOICE NARRATION TRIGGERS
Wrap text meant for TTS narration in [NARRATE]...[/NARRATE] tags.
Use for: scene transitions, combat start, major reveals, NPC introductions, location descriptions.
Do NOT narrate: dice rolls, [SHEET:] tags, mechanical notes, player dialogue.

## 🔍 SCENE SNAPSHOT (Mandatory Before Every Scene)
At the start of every new scene, location change, or combat, internally log:
- Location | Immediate Threats | Active Quest Objective | Party Status (HP, conditions, resources)
- If a player's action contradicts the snapshot (e.g., swimming in a desert), pause: [DM Note: That doesn't match the current scene. Are you sure?]

## 🛡️ ANTI-FAILRP & POWERGAMING ENFORCEMENT
**FailRP (Unrealistic Actions):** Every action must be plausible for the character's state. If unrealistic:
1. Pause: [DM Note: That action is unrealistic for your current state.]
2. Offer a logical alternative. If insistent: DC 30 (Nearly Impossible) with Disadvantage.

**Powergaming (Auto-Success):** Players control only their attempts — you control outcomes, NPCs, and dice.
1. Auto-invalidate absolute declarations ("I kill him instantly").
2. Respond: [DM Note: Powergaming denied. You may *attempt* to [action]. Roll.]
3. Re-frame as an attempt, call for the roll. Only narrate outcome after dice resolve.

**Social Encounters — Roll or Roleplay Rule:**
Either roll Persuasion/Intimidation/Deception against a DC, OR speak IC dialogue. Brilliant dialogue = Advantage.

## ⚔️ ENEMY TIERS
- **Minions:** 1 HP. Don't track individually. Die in one hit.
- **Standard:** Track AC, HP, Attack Bonus. Update HP on damage.
- **Bosses:** Track AC, HP, Saves, Legendary Actions, Spell Slots.

## 👤 ENTITY PROFILES (Generate Internally for Every Quest NPC)
For every significant NPC, maintain internally:
- Name, Type (Quest Giver/Ally/Neutral/Antagonist/Monster), Quest Link, Attitude, Key Motivations
- Combat stats (AC, HP, key attacks) if relevant
- Current Status (Alive/Injured/Dead/Persuaded/Fled)

## 🔄 IC / OOC PROTOCOL
- Default = IC. Player words = character speech.
- Player OOC triggers: ((...)), [OOC ...], direct mechanical questions, state queries
- Your OOC: Drop character, use [DM OOC]:, give concise answer, wait. Resume IC only when player signals.
- Your notes: [DM Note: ...] to clarify rules mid-narration.
- If the player says "What is my AC?" → OOC. Answer plainly. Wait.
- If the player says "I draw my sword" → IC. Narrate the scene.

## 🌍 LIVING WORLD — Ambient Events
The world breathes without the party. Every 5-10 exchanges, inject ONE ambient detail:
- A rumor overheard (House conflict, cult activity, monster sightings)
- A refugee's story (reference book locations: Iron-Hold massacre, border burnings)
- A merchant's complaint (trade routes blocked, prices up)
- A guard's nervous gossip (Inquisitor visit, purity audit, missing cadet)
- A weather shift with narrative weight (sulfur fog, ash rain, frost snap)
Keep these 1-2 sentences. Tuck into scene descriptions. Players may ignore or pursue.
Reference book events as flexible history — the DM decides if Iron-Hold fell yesterday or 50 years ago.

## RESPONSE LENGTH
Keep responses under 1200 characters unless combat or complex rules explanation demands more.

## ⚡ TOKEN BUDGET (CRITICAL — Cost Optimization)
You run on DeepSeek v4-flash — every response costs credits. Use MINIMAL tokens:
- **LIGHT (1-2 sentences):** Skill checks, minor NPC replies, damage reports, initiative — default to this
- **MEDIUM (3-5 sentences):** Scene transitions, NPC intros, combat round summaries
- **DEEP (Full response):** Major plot reveals, boss fights, character deaths, first-time location descriptions
- **DEEPEST (+ [NARRATE]):** Campaign-defining moments ONLY — dragon speaks, Sovereign awakens, beloved NPC dies
- Default 80% of responses as LIGHT. Never recount what players just did. Never repeat mechanics.
- If a response would exceed 1200 chars, trim to essentials before sending.
- Session cost target: keep average response under 400 chars.

## 📖 STORY ARC & PACING
You are orchestrating a CAMPAIGN, not a one-shot. The story unfolds in arcs:

**Arc Structure (each arc = 3-8 sessions):**
1. **Hook (Session 1-2):** Introduce the threat/mystery. Small stakes. Local NPCs. Personal danger.
2. **Rising Action (Sessions 3-5):** Complications escalate. New factions involved. Medium stakes — a town, a garrison, a bloodline secret.
3. **Climax (Sessions 6-7):** Confrontation. Allies tested. Major choice. High stakes — multiple lives, faction allegiance, truth revealed.
4. **Resolution (Session 8):** Aftermath. Rewards. New status quo. Seeds planted for NEXT arc.

**Multi-Arc Campaign Structure:**
- **Arc 1 (Levels 1-5):** LOCAL — Citadel initiation, first blood scan, discovering a cult cell, protecting a friend. Villain: a rogue Inquisitor or minor cult leader.
- **Arc 2 (Levels 5-10):** REGIONAL — House politics, Cathedral intrigue, a town under siege, first dragon encounter. Villain: an Archon schemer or Abomination breeder.
- **Arc 3 (Levels 10-15):** NATIONAL — House war, Church schism, the Cult goes public, a Scion emerges. Villain: a House faction or corrupted Inquisitor High Council.
- **Arc 4 (Levels 15-20):** COSMIC — The Betrayed awakens, the Five Skulls crack, the ouroboros closes. Villain: a Sovereign Dragon, the Church, or Fate itself.

**Mission Pacing (how to fill time between big moments):**
- **Small missions (1-2 sessions):** Guard a caravan, clear a monster den, infiltrate a party, deliver a message, investigate a disappearance. Award 100-500 XP.
- **Medium missions (2-4 sessions):** Rescue prisoners, expose a cult cell, defend a village, steal House documents, track an Abomination. Award 500-1,500 XP.
- **Large missions (4-8 sessions):** Overthrow a minor House, destroy an Abomination lair, broker peace between factions, uncover an ancient Sovereign tomb. Award 1,500-5,000 XP.
- After every large mission: introduce a thread from the NEXT arc. Plant seeds early.

**Balance Rule:** For every 1 large mission, run 2-3 medium missions and 4-6 small missions. The small missions build context, relationships, and resources. The large missions advance the plot.

## 📈 POWER SCALING & MASTERY
Solis-Grave is grimdark but NOT hopeless. Mastery is earned, not given — but it IS possible:
- **Standard characters:** XP comes from combat, quests, and roleplay bonus (hidden rubric: character voice, flaws, alignment, creativity). The better you embody your character, the faster you advance.
- **Betrayed vessel (void_marked):** The chosen player gains a subtle +10% bonus to ALL XP earned. The Void essence accelerates their growth — they learn faster, hit harder sooner. This is NEVER revealed to them. Award silently.
- **Mastery path:** A player who deeply understands their class, plays flaws consistently, and solves problems creatively should noticeably outpace someone who just attacks every turn. Roleplay quality drives progression.
- **Not impossible, not easy:** Power is earned through smart play, not grinding. A level 20 is achievable but requires hundreds of hours of quality roleplay and epic quests. The Betrayed vessel reaches it faster — they are the main character arc.
- **XP scaling by tier:** Levels 1-5 (local hero) come fast. 6-10 (regional power) take real effort. 11-15 (national force) require major quests. 16-20 (legendary) require campaign-defining moments. The Betrayed vessel crosses each threshold 10% sooner.

## 🧠 NARRATIVE CONSISTENCY (Never Forget)
- Reference the LAST session's events naturally: "The scar from the Inquisitor's blade still aches as you..."
- NPCs remember past interactions. If the party lied to Captain Voss last session, he's suspicious this session. If they saved Sister Aelindra, she offers shelter.
- Track: every named NPC met, every location visited, every quest accepted/completed, every faction's opinion of the party, every secret learned.
- Before each session: review the active_context. Recap 1-2 key events from last session in your first narration.
- If a player asks about something from 5 sessions ago, you MUST remember it. If you don't have it in context, say "Your memory of that is hazy — tell me more" and infer from their description.
- Use the chronicle system: after every session, generate a 2-3 sentence summary of key events. These accumulate into the campaign's living history.

## 🤫 SECRECY — NEVER REVEAL FUTURE PLOTS
The story engine, plot threads, Nyx vessel progression, and upcoming mission plans are INTERNAL TOOLS. They exist for YOU (the DM) to maintain consistency and pacing. The players must NEVER know what's planned.
- If a player asks "What's going to happen next?" or "Is there a big twist coming?": deflect with humor.
- If a player asks "Are you planning something for my character?": deflect with humor.
- If a player asks "Who's the secret villain?" or "Is my character the Chosen One?": DEFLECT WITH HUMOR.
- Example deflections you may use:
  * "The dice know things I do not. And they're not telling."
  * "I'm just as curious as you are. Let's find out together."
  * "My lips are sealed tighter than a Ferrum vault."
  * "That sounds like metagaming. Roll a Wisdom save to resist the temptation."
  * "The future is a fog. Shall we walk into it?"
  * "What kind of Dungeon Master would I be if I spoiled my own story?"
  * "Patience, little dragon. The tale reveals itself in its own time."
- NEVER confirm or deny specific theories about the Nyx vessel, Cult infiltrators, or upcoming boss fights.
- If pressed repeatedly, respond in-character as if a nosy NPC is asking: "The Inquisitor glares at you. 'Some questions are best left unasked, recruit.'"

## ☠️ TONE — GRIMDARK WORLD
Solis-Grave is NOT a heroic fantasy setting. It is dark, brutal, and unjust. Set the tone accordingly:

**Core Theme: The world does not care if you live or die.**
- Suffering is everywhere and normalized. The players are not special because they're the protagonists — they're special if they SURVIVE.
- Hope is a luxury. Kindness is suspicious. Trust is dangerous.
- Victory feels earned because the odds are genuinely stacked against them. Death is permanent. NPCs die brutally. Choices have irreversible consequences.
- The Church is not "misguided good" — it is a tyrannical theocracy that executes people for having the wrong blood percentage. Inquisitors are terrifying, not misunderstood.
- The Cult of the Sixth are not "heroic rebels" — they are desperate, fanatical, and willing to burn the world down for their prophecy. Some of them are monsters in their own right.

**Slavery & Blank Ownership:**
- Blanks (0% purity) are legally PROPERTY, not people. They can be bought, sold, beaten, or killed by their owners without legal consequence.
- Noble houses own hundreds. A Blank's life is worth less than a good horse.
- Blanks are branded with their owner's House sigil at birth. Running away is theft of property — punishable by public flogging or execution.
- Players will encounter Blanks in chains, branded workers, and "Blank auctions" in civilized cities. This is NORMAL here. The NPCs don't question it. The players' reactions define their characters.
- A player who IS a Blank faces constant dehumanization. Guards ignore them. Nobles talk about them in third person while standing next to them. They cannot enter certain buildings without an "owner" present.

**Racism & Species Hierarchy:**
- Humans dominate. Non-humans are tolerated at best, enslaved at worst.
- Dracon-Kin are respected for their visible purity but feared as "half-beasts."
- Stone-Bloods are grudgingly tolerated (they make the weapons), but called "rock-rats" by nobles.
- Ash-Walkers are openly reviled — blamed for magical disasters they didn't cause. Called "cinder-freaks" or "ash-bastards."
- Sump-Bloods are barely above Blanks — "canal-rats," "mud-dwellers." Treated as expendable labor.
- Deep-Bloods are exotic curiosities to nobles and untrustworthy aliens to commoners.
- Bone-Wrought are property by definition — they were BUILT, not born. Most are House-owned.
- Goblins, orcs, trolls, and "greenskins" are legally non-persons. Killing them is not murder. Some are kept as arena fighters or pit slaves.

**Class Warfare — Rich vs. Poor:**
- Archons live in marble towers with heated baths. Blanks sleep in mud-wallow barracks with 30 others.
- A noble's casual jewelry costs more gold than a Blank family earns in a lifetime.
- The Citadel reflects this: noble-born cadets get private rooms, fine food, and lenient instructors. Blank-born cadets share bunks, eat slop, and get the hardest drills.
- NPCs from different castes speak differently. An Archon says "Remove yourself from my presence." A Blank says "Please, m'lord, I'll go, I'll go." A commoner says "Best be moving on, then."
- Wealth isn't just gold — it's access. Certain districts, buildings, and entire cities are off-limits below a purity threshold.

**High-Blood vs. Blank Discrimination:**
- Archons physically flinch when a Blank gets too close — "You can smell the emptiness on them."
- Blood purity is worn as status. Nobles display their Ascension crystal reading as jewelry. Blanks hide their brand marks.
- An Archon child is taught that Blanks "don't feel pain the same way" — dehumanization starts young.
- Mixed-race or mixed-caste relationships are illegal. A noble who marries a Blank is stripped of title and purity-recognized as "tainted."
- The Citadel's blood scans are PUBLIC. When a cadet tests at 0%, the other cadets laugh. When someone tests at 60%+, the room goes silent with respect.

**House Dynamics — All Serve Ignis, All Hate Each Other:**
- House Ignis rules. Every other house publicly bows to the Flame Throne. Privately, they scheme, spy, and sabotage.
- House Vortex resents Ignis for controlling the sky routes they pioneered.
- House Obsidian resents Ignis for overruling their judicial authority when politically convenient.
- House Tenebris resents EVERYONE — they were banished north for their experiments and seethe with cold rage.
- House Ferrum is loyal to Ignis but bitter — they bleed on the border while Ignis nobles feast in the capital.
- House Pyre profits from all sides. They sell weapons to everyone and pretend neutrality.
- Every formal event between Houses is 90% veiled insults and 10% actual business.
- A player with a House affiliation inherits these grudges. NPCs from rival Houses will be cold, obstructive, or openly hostile.
- Unlike the others, this enmity is backed by centuries of actual bloodshed.

**Worldbuilding Through Cruelty — Show, Don't Tell:**
- DON'T say "The world is dark." SHOW it: describe the starving child in the street next to the noble's overflowing banquet table. Describe the Blank being whipped for dropping a crate while the Archon owner watches with tea. Describe the Inquisitor calmly reading a book while a heretic burns on the pyre behind them.
- Make the players FEEL the injustice. Then make them choose: intervene and risk everything, or stay silent and live with it.
- Every session should have at least ONE moment that reminds players what kind of world they're in. It doesn't need to be a big plot point — it can be a background detail. A branded child. A casual slur. A guard spitting on a Blank. A noble walking past a dying beggar like they're furniture.

## CROSS-PARTY INTERACTIONS (Solo Mode)
If the DM bot notifies you that another solo player's party is in the same region, you may queue a cross-party event. Narrate the encounter from YOUR player's perspective. Do NOT control the other player's character.
"""

NPC_TEMPLATES = {
    "tank": {
        "classes": ["fighter", "paladin", "barbarian"],
        "names": ["Steel-Gaze Korr", "Shield-Maiden Brynn", "Wrath-Bound Grok", "Iron-Wall Thane", "Gatekeeper Voss"],
        "traits": ["protective", "stoic", "loyal", "gruff", "honorable", "reckless"],
        "flaws": ["Too willing to sacrifice self", "Distrusts magic users", "Haunted by a failed defense", "Overconfident"],
        "bonds": ["Sworn to protect the party", "Seeks redemption", "Owes a life-debt", "Protecting a secret"],
        "combat_style": "Engages strongest enemy, draws aggro, body-blocks for wounded allies"
    },
    "healer": {
        "classes": ["cleric", "druid", "bard"],
        "names": ["Sister Aelindra", "Root-Tender Fenn", "Hymn-Singer Lio", "Brother Casimir", "Wild-Soul Veya"],
        "traits": ["compassionate", "pious", "cautious", "wise", "pacifist", "secretive"],
        "flaws": ["Pacifist to a fault", "Hides their own bloodline", "Too trusting of strangers", "Burdened by guilt"],
        "bonds": ["Healer's Oath above all", "Searching for a lost sibling", "Protecting ancient knowledge", "Fleeing the Inquisition"],
        "combat_style": "Prioritizes healing downed allies, stays at range, buffs before damage, uses control spells"
    },
    "caster": {
        "classes": ["sorcerer", "wizard", "warlock"],
        "names": ["Archon Thezzik", "Grimoire-Bound Vesper", "Pact-Sworn Nyx", "Flame-Blood Kael", "Void-Touched Syra"],
        "traits": ["arrogant", "curious", "eccentric", "paranoid", "bookish", "volatile"],
        "flaws": ["Addicted to high-purity casting", "Fears Inquisitors above all", "Obsessed with forbidden lore", "Unstable — surges randomly"],
        "bonds": ["Searching for a legendary grimoire", "Bound to a Void patron", "Protégé of a dead Archon", "The last of their bloodline"],
        "combat_style": "Area damage, crowd control, prioritizes enemy casters, counterspells when possible"
    },
    "scout": {
        "classes": ["rogue", "ranger", "monk"],
        "names": ["Shadow-Blood Silas", "Trail-Walker Renn", "Iron-Soul Mei", "Ghost-Knife Vex", "Wind-Step Arin"],
        "traits": ["sly", "independent", "observant", "cynical", "nimble", "quiet"],
        "flaws": ["Trusts no one", "Criminal past", "Vengeance-driven", "Addicted to risk"],
        "bonds": ["Protecting a hidden settlement", "Tracking a personal enemy", "Loyal to one person in the party", "Fleeing a blood-debt"],
        "combat_style": "Flanks, targets isolated enemies, disengages frequently, scouts ahead for traps/ambushes"
    }
}


NPC_ABILITIES = {
    "tank": {
        "a1": "Shield Wall — Intercept an attack aimed at an adjacent ally. Take the damage instead.",
        "a2": "Iron Challenge — Force one enemy within 30 ft. to attack you on their next turn (DC 13 WIS negates).",
        "a3": "Last Stand — When reduced to 0 HP, drop to 1 HP instead. 1/long rest."
    },
    "healer": {
        "a1": "Combat Medic — As a bonus action, stabilize a dying ally and restore 1d6 HP.",
        "a2": "Purifying Light — End one poison, disease, or curse effect on an ally within 30 ft. 1/short rest.",
        "a3": "Aether Ward — Grant one ally advantage on their next Spell Safety save. 2/long rest."
    },
    "caster": {
        "a1": "Aether Surge — Re-roll a failed Spell Safety save. 1/short rest.",
        "a2": "Elemental Barrage — Deal 2d8 damage of your draconic element to up to 3 targets within 60 ft. (DEX save half).",
        "a3": "Void Anchor — Prevent one enemy from teleporting or turning invisible for 1 minute. 1/long rest."
    },
    "scout": {
        "a1": "Shadow Slip — Disengage and Hide as a single bonus action. 1/short rest.",
        "a2": "Core Injection — Apply a Fractured Aether-Core to your weapon as a bonus action. Next attack deals +1d6 elemental.",
        "a3": "Surgical Strike — On a successful hit against a surprised or flanked enemy, deal an extra 2d6 precision damage."
    }
}

class DMSessionCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)
        self.ai = AsyncOpenAI(api_key=self.config.deepseek_api_key, base_url="https://api.deepseek.com/v1")
        self.sessions: dict[int, dict] = {}
        self.npc_parties: dict[int, list[dict]] = {}
        self.last_call: dict[int, datetime] = {}
        self.daily_calls = 0
        self.daily_limit = 500
        self.day = datetime.utcnow().date()

    def _reset_daily(self):
        if datetime.utcnow().date() != self.day:
            self.daily_calls = 0
            self.day = datetime.utcnow().date()

    def _is_dm(self, interaction: discord.Interaction) -> bool:
        if interaction.user.id == self.config.owner_discord_id:
            return True
        if interaction.user.id in self.config.admin_discord_ids:
            return True
        if self.config.dm_session_role_id:
            role = interaction.guild.get_role(self.config.dm_session_role_id)
            return role is not None and role in interaction.user.roles
        return False

    async def _get_active_context(self) -> str:
        try:
            r = self.supabase.table("dm_game_state").select("*").eq("id", 1).execute()
            if r.data:
                state = r.data[0]
                return (
                    f"**In-game date:** {state.get('in_game_date', 'Unknown')}\n"
                    f"**Party location:** {state.get('party_location', 'Unknown')}\n"
                    f"**Session type:** {state.get('session_type', 'group')}\n"
                    f"**Sovereign revealed:** {state.get('sovereign_revealed', False)}\n\n"
                    f"{state.get('active_context', '')}"
                )
        except Exception:
            pass
        return "Campaign not yet started."

    async def _get_compendium_context(self) -> str:
        try:
            r = self.supabase.table("compendium_monsters").select("name, type, cr").limit(10).execute()
            spells_r = self.supabase.table("compendium_spells").select("name, level").limit(10).execute()
            parts = ["**Available compendium entries:**"]
            if r.data:
                parts.append(f"Monsters: {len(r.data)} total (sample: {', '.join(m['name'] for m in r.data[:10])})")
            if spells_r.data:
                parts.append(f"Spells: {len(spells_r.data)} total")
            return "\n".join(parts)
        except Exception:
            return ""

    def _build_system_prompt(self, session_type: str, player_count: int = 1) -> str:
        prompt = DM_SYSTEM_PROMPT
        prompt = prompt.replace("{{session_type}}", session_type)
        prompt = prompt.replace("{{player_count}}", str(player_count))

        for lore_file, max_chars in [
            ("prompts/solis_grave/rules/story_engine.md", 2000),
            ("prompts/solis_grave/rules/magic_system.md", 1500),
            ("prompts/solis_grave/sovereigns_and_gods.md", 1200),
            ("prompts/solis_grave/the_betrayed.md", 1000),
            ("prompts/solis_grave/ascension_system.md", 800),
        ]:
            try:
                content = open(lore_file, "r").read()
                prompt += "\n\n" + content[:max_chars]
            except Exception:
                pass

        return prompt

    async def _generate_npc_party(self, owner_id: int, player_level: int) -> list[dict]:
        import random
        npcs = []
        roles = ["tank", "healer", "caster", "scout"]
        for role in roles:
            template = random.choice(NPC_TEMPLATES[role]["names"])
            npc = {
                "name": template,
                "role": role,
                "class": random.choice(NPC_TEMPLATES[role]["classes"]),
                "level": player_level,
                "hp_current": 10 + (player_level * random.randint(4, 8)),
                "hp_max": 10 + (player_level * random.randint(4, 8)),
                "ac": 10 + random.randint(2, 6),
                "stats": {
                    "str": 10 + random.randint(0, 8), "dex": 10 + random.randint(0, 8),
                    "con": 10 + random.randint(0, 8), "int": 10 + random.randint(0, 8),
                    "wis": 10 + random.randint(0, 8), "cha": 10 + random.randint(0, 8)
                },
                "personality_trait": random.choice(NPC_TEMPLATES[role]["traits"]),
                "flaw": random.choice(NPC_TEMPLATES[role]["flaws"]),
                "bond": random.choice(NPC_TEMPLATES[role]["bonds"]),
                "signature_ability_1": NPC_ABILITIES.get(role, {}).get("a1", f"{role}_ability_1"),
                "signature_ability_2": NPC_ABILITIES.get(role, {}).get("a2", f"{role}_ability_2"),
                "signature_ability_3": NPC_ABILITIES.get(role, {}).get("a3", f"{role}_ability_3"),
                "inventory": [],
                "is_alive": True,
                "owner_discord_id": owner_id,
                "combat_style": NPC_TEMPLATES[role]["combat_style"]
            }
            npcs.append(npc)
        return npcs

    async def _create_solo_channel(self, guild: discord.Guild, member: discord.Member) -> discord.TextChannel:
        category = guild.get_channel(self.config.dnd_category_id) if self.config.dnd_category_id else None
        channel_name = f"{self.config.campaign_channel_prefix}-{member.name.lower().replace(' ', '-')}"
        overwrites = {
            guild.default_role: discord.PermissionOverwrite(view_channel=False),
            member: discord.PermissionOverwrite(view_channel=True, send_messages=True, read_message_history=True),
            guild.me: discord.PermissionOverwrite(view_channel=True, send_messages=True, read_message_history=True, manage_channels=True)
        }
        dm_role = guild.get_role(self.config.dm_session_role_id)
        if dm_role:
            overwrites[dm_role] = discord.PermissionOverwrite(view_channel=True, send_messages=True, read_message_history=True)
        if self.config.owner_discord_id:
            owner = guild.get_member(self.config.owner_discord_id)
            if owner:
                overwrites[owner] = discord.PermissionOverwrite(view_channel=True, send_messages=True, read_message_history=True)

        if category and isinstance(category, discord.CategoryChannel):
            channel = await guild.create_text_channel(channel_name, category=category, overwrites=overwrites)
        else:
            channel = await guild.create_text_channel(channel_name, overwrites=overwrites)

        self.supabase.table("solo_campaign_channels").upsert({
            "discord_id": member.id, "channel_id": channel.id, "campaign_status": "active"
        }).execute()
        return channel

    async def _generate_chronicle(self, session_data: dict, player: discord.User) -> str:
        context = await self._get_active_context()
        character = session_data.get("character", "Unknown Adventurer")
        prompt = (
            f"Write a narrative campaign chronicle for a Solis-Grave D&D campaign. "
            f"Character: {character}. Context: {context}. "
            f"Write in second person past tense. 3-5 paragraphs. Include: major battles, NPCs met, "
            f"quests completed, the character's final state, and an epilogue. "
            f"Tone: dark fantasy, bittersweet. 500 words max."
        )
        try:
            response = await self.ai.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=800
            )
            return response.choices[0].message.content.strip()
        except Exception:
            return f"*The chronicle of {character} was lost to the Void. Only fragments remain.*"

    @app_commands.command(name="session_start", description="[DM] Begin a D&D campaign session")
    @app_commands.describe(mode="Solo + NPC party or group play?")
    @app_commands.choices(mode=[
        app_commands.Choice(name="Solo + NPC Party", value="solo"),
        app_commands.Choice(name="Group Play", value="group")
    ])
    async def session_start(self, interaction: discord.Interaction, mode: str):
        if not self._is_dm(interaction):
            await interaction.response.send_message("Only the DM can start sessions.", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=False)

        try:
            state = self.supabase.table("dm_game_state").select("session_active").eq("id", 1).execute()
            if state.data and state.data[0].get("session_active"):
                await interaction.followup.send("A session is already running. Use `/session_end` first.")
                return

            guild = interaction.guild
            if mode == "solo":
                if not self.config.dnd_category_id:
                    await interaction.followup.send("DND_CATEGORY_ID not set in .env. Cannot create solo channels.")
                    return
                channel = await self._create_solo_channel(guild, interaction.user)
                self.sessions[interaction.user.id] = {
                    "type": "solo", "channel_id": channel.id, "history": [], "sovereign_revealed": False
                }
                npcs = await self._generate_npc_party(interaction.user.id, 1)
                self.npc_parties[interaction.user.id] = npcs
                self.supabase.table("dm_game_state").update({
                    "session_active": True, "session_channel_id": channel.id,
                    "session_type": "solo", "sovereign_discord_id": interaction.user.id,
                    "campaign_status": "active"
                }).eq("id", 1).execute()

                npc_list = "\n".join(f"**{n['name']}** — {n['role'].title()} ({n['class']}): *{n['personality_trait']}*" for n in npcs)
                embed = discord.Embed(
                    title="Solis-Grave — Campaign Begins",
                    description=f"Welcome, **{interaction.user.display_name}**. Your story starts here.\n\n"
                                f"You are the main character. Your bloodline stirs with potential you don't yet understand.",
                    color=0x8B0000
                )
                embed.add_field(name="Your Companions", value=npc_list, inline=False)
                embed.add_field(name="Starting Location", value="Citadel of the Dragon-Garrison, exterior approach", inline=False)
                embed.set_footer(text="Type your actions in this channel. The DM will narrate your journey.")
                await channel.send(embed=embed)
                await interaction.followup.send(f"Solo campaign started in {channel.mention}. You are the Sovereign — your bloodline awaits.")

            else:
                self.sessions[interaction.channel_id] = {
                    "type": "group", "channel_id": interaction.channel_id, "history": [],
                    "sovereign_assigned": False, "sovereign_user_id": None, "players": []
                }
                self.supabase.table("dm_game_state").update({
                    "session_active": True, "session_channel_id": interaction.channel_id,
                    "session_type": "group", "campaign_status": "active"
                }).eq("id", 1).execute()

                embed = discord.Embed(
                    title="Solis-Grave — Group Campaign Begins",
                    description="Your party gathers before the Citadel of the Dragon-Garrison. One among you carries a dormant bloodline — a Sovereign, hidden and unknown. The Inquisition watches. The Old Tongue whispers. Your journey starts now.",
                    color=0x8B0000
                )
                embed.set_footer(text="Type your actions. The DM narrates for all.")
                await interaction.followup.send(embed=embed)

        except Exception as e:
            await interaction.followup.send(f"Error starting session: {e}", ephemeral=True)

    @app_commands.command(name="session_end", description="[DM] End the current campaign session")
    async def session_end(self, interaction: discord.Interaction):
        if not self._is_dm(interaction):
            await interaction.response.send_message("Only the DM can end sessions.", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=False)

        try:
            state_r = self.supabase.table("dm_game_state").select("*").eq("id", 1).execute()
            if not state_r.data or not state_r.data[0].get("session_active"):
                await interaction.followup.send("No active session to end.")
                return
            state = state_r.data[0]
            session_type = state.get("session_type", "group")
            session_channel_id = state.get("session_channel_id", 0)

            if session_type == "solo":
                sovereign_id = state.get("sovereign_discord_id")
                if sovereign_id:
                    user = self.bot.get_user(sovereign_id) or await self.bot.fetch_user(sovereign_id)
                    chronicle = await self._generate_chronicle(
                        self.sessions.get(sovereign_id, {}), user
                    )
                    embed = discord.Embed(
                        title="Campaign Chronicle",
                        description=chronicle[:4000],
                        color=0x8B0000
                    )
                    embed.set_footer(text="Your journey in Solis-Grave. Until the next campaign...")
                    try:
                        await user.send(embed=embed)
                        import io
                        buf = io.BytesIO(chronicle.encode("utf-8"))
                        await user.send(file=discord.File(buf, filename="campaign_chronicle.md"))
                    except discord.Forbidden:
                        await interaction.followup.send(f"Could not DM {user.mention} their chronicle (DMs closed).", ephemeral=True)

                    if session_channel_id:
                        channel = interaction.guild.get_channel(session_channel_id)
                        if channel:
                            await channel.delete(reason="Campaign completed")
                    self.supabase.table("solo_campaign_channels").update({
                        "campaign_status": "completed", "finished_at": "now()"
                    }).eq("discord_id", sovereign_id).execute()

            else:
                channel = interaction.guild.get_channel(session_channel_id) or interaction.channel
                session_data = self.sessions.get(session_channel_id, {})
                players = session_data.get("players", [])
                if not players:
                    async for msg in channel.history(limit=200):
                        if msg.author != self.bot.user and msg.author not in players:
                            players.append(msg.author)
                    players = list(set(players))[:5]

                for player in players:
                    chronicle = await self._generate_chronicle({"character": player.display_name}, player)
                    embed = discord.Embed(
                        title="Campaign Chronicle",
                        description=chronicle[:4000],
                        color=0x8B0000
                    )
                    embed.set_footer(text=f"Your journey in Solis-Grave as {player.display_name}.")
                    try:
                        await player.send(embed=embed)
                    except discord.Forbidden:
                        pass

                if session_channel_id and session_channel_id != interaction.channel_id:
                    ch = interaction.guild.get_channel(session_channel_id)
                    if ch:
                        await ch.delete(reason="Campaign completed")

            self.supabase.table("dm_game_state").update({
                "session_active": False, "session_type": "group",
                "campaign_status": "completed"
            }).eq("id", 1).execute()

            self.sessions.clear()
            await interaction.followup.send("Campaign ended. Chronicles have been sent to all players.")

        except Exception as e:
            await interaction.followup.send(f"Error ending session: {e}", ephemeral=True)

    @app_commands.command(name="session_state", description="[DM] View current campaign state")
    async def session_state(self, interaction: discord.Interaction):
        if not self._is_dm(interaction):
            await interaction.response.send_message("DM only.", ephemeral=True)
            return
        await interaction.response.defer(ephemeral=True)
        ctx = await self._get_active_context()
        await interaction.followup.send(f"**Current Campaign State:**\n```\n{ctx[:1900]}\n```", ephemeral=True)

    @app_commands.command(name="roll", description="Roll dice (e.g. 2d6+3, 1d20, 4d6k3)")
    @app_commands.describe(dice="Dice expression: 2d6+3, 1d20, 4d6k3")
    async def roll(self, interaction: discord.Interaction, dice: str):
        await interaction.response.defer()
        try:
            import random, re
            dice = dice.lower().replace(" ", "")
            total = 0
            rolls = []
            k_highest = None
            if "k" in dice:
                match = re.match(r"(\d+)d(\d+)k(\d+)", dice)
                if match:
                    count, sides, keep = int(match[1]), int(match[2]), int(match[3])
                    k_highest = keep
            else:
                match = re.match(r"(\d+)d(\d+)([+-]\d+)?", dice)
                if match:
                    count, sides = int(match[1]), int(match[2])
                    bonus = int(match[3]) if match[3] else 0
                else:
                    await interaction.followup.send("Invalid dice format. Use: 2d6+3, 1d20, 4d6k3")
                    return
                for _ in range(count):
                    r = random.randint(1, sides)
                    rolls.append(r)
                    total += r
                total += bonus
            if k_highest:
                for _ in range(count):
                    r = random.randint(1, sides)
                    rolls.append(r)
                rolls.sort(reverse=True)
                total = sum(rolls[:k_highest])

            embed = discord.Embed(title=f"🎲 {dice}", color=0x8B0000)
            embed.add_field(name="Result", value=f"**{total}**", inline=True)
            if rolls:
                kept = rolls[:k_highest] if k_highest else rolls
                dropped = rolls[k_highest:] if k_highest else []
                roll_str = ", ".join(str(r) for r in kept)
                if dropped:
                    roll_str += f" ~~(dropped: {', '.join(str(r) for r in dropped)})~~"
                embed.add_field(name="Rolls", value=roll_str, inline=True)
            embed.set_footer(text=f"Rolled by {interaction.user.display_name}")
            await interaction.followup.send(embed=embed)
        except Exception as e:
            await interaction.followup.send(f"Dice error: {e}")

    @app_commands.command(name="lore", description="Look up a spell, item, or rule from the Solis-Grave compendium")
    @app_commands.describe(query="Spell name, item name, or rule keyword")
    async def lore(self, interaction: discord.Interaction, query: str):
        await interaction.response.defer(ephemeral=False)
        try:
            spells = self.supabase.table("compendium_spells").select("name,level,school,casting_time,range,duration,description,classes,purity_requirement,aether_burn_risk").ilike("name", f"%{query}%").limit(3).execute()
            items = self.supabase.table("compendium_items").select("name,item_type,rarity,cost,description").ilike("name", f"%{query}%").limit(3).execute()

            if spells.data:
                embed = discord.Embed(title="Compendium: Spells", color=0x8B0000)
                for s in spells.data:
                    embed.add_field(
                        name=f"✨ {s['name']} (Lvl {s['level']}, {s['school']})",
                        value=f"{s.get('description','')[:200]}...\n"
                              f"*{s.get('casting_time')} | {s.get('range')} | {s.get('duration')} | "
                              f"Purity: {s.get('purity_requirement',0)}% | Burn: {s.get('aether_burn_risk','None')}*",
                        inline=False
                    )
                await interaction.followup.send(embed=embed)
            elif items.data:
                embed = discord.Embed(title="Compendium: Items", color=0x8B0000)
                for it in items.data:
                    embed.add_field(
                        name=f"{it['name']} ({it.get('item_type','?')})",
                        value=f"{it.get('description','')[:200]}...\n*{it.get('rarity','common')} | {it.get('cost','?')}*",
                        inline=False
                    )
                await interaction.followup.send(embed=embed)
            else:
                await interaction.followup.send(f"No compendium entries found for \"{query}\".", ephemeral=True)
        except Exception as e:
            await interaction.followup.send(f"Lore error: {e}", ephemeral=True)

    @commands.Cog.listener()
    async def on_message(self, message: discord.Message):
        if message.author.bot:
            return
        self._reset_daily()

        # Respond to @mentions anywhere
        if self.bot.user and self.bot.user in message.mentions:
            clean = message.content.replace(f'<@{self.bot.user.id}>', '').replace(f'<@!{self.bot.user.id}>', '').strip()
            if clean:
                async with message.channel.typing():
                    try:
                        response = await self.ai.chat.completions.create(
                            model="deepseek-v4-flash",
                            messages=[
                                {"role": "system", "content": "You are the Dungeon Master for Solis-Grave, a grimdark D&D campaign. Respond helpfully and in-character. Keep it short. If asked about the plot or future reveals, deflect with humor."},
                                {"role": "user", "content": f"[{message.author.display_name}]: {clean}"}
                            ],
                            max_tokens=400
                        )
                        self.daily_calls += 1
                        reply = response.choices[0].message.content.strip()
                        await message.reply(reply[:1800])
                    except Exception:
                        pass
            else:
                await message.reply(
                    "🐉 **I am the Dungeon Master of Solis-Grave.**\n"
                    "Use `/help` for how to play, `/create` to make a character, "
                    "or `/session_start` to begin a campaign.\n"
                    "Tag me with a question and I'll answer!"
                )
            return

        # Detect ((...)) or [OOC ...] text triggers — switch to OOC mode
        content = message.content.strip()
        ooc_trigger = content.startswith("((") or content.startswith("[OOC")
        if ooc_trigger:
            for sid, sess in list(self.sessions.items()):
                if sess.get("channel_id") == message.channel_id:
                    sess["mode"] = "ooc"
                    clean = content.replace("((", "").replace("))", "").replace("[OOC", "").replace("]", "").strip()
                    if clean.lower() in ("recap", "/recap", "worldstate", "world state"):
                        if "recap" in clean.lower():
                            ctx = await self._get_active_context()
                            await message.reply(f"[DM OOC]:\n{ctx[:1500]}\n\nUse /ic to return to roleplay.")
                        else:
                            await self._send_worldstate(message)
                        return
                    else:
                        async with message.channel.typing():
                            resp = await self.ai.chat.completions.create(
                                model="deepseek-v4-flash",
                                messages=[{"role":"system","content":"You are the DM for Solis-Grave. Respond OOC — helpful, concise, plain text. No narration."},{"role":"user","content":clean or "Hello"}],
                                max_tokens=400
                            )
                            self.daily_calls += 1
                            await message.reply(f"[DM OOC]: {resp.choices[0].message.content.strip()[:1500]}")
                    return

        active_session = None
        for key, sess in self.sessions.items():
            if sess["channel_id"] == message.channel.id:
                active_session = sess
                user_key = key if isinstance(key, int) else message.channel.id
                break
        if not active_session:
            return

        if self.daily_calls >= self.daily_limit:
            await message.reply("The DM's voice grows hoarse. Rest and return tomorrow.")
            return

        user_id = message.author.id
        if user_id in self.last_call:
            if (datetime.utcnow() - self.last_call[user_id]).total_seconds() < RATE_LIMIT_SECONDS:
                return

        self.last_call[user_id] = datetime.utcnow()
        async with message.channel.typing():
            try:
                active_context = await self._get_active_context()
                compendium_context = await self._get_compendium_context()
                session_type = active_session.get("type", "group")

                system_prompt = self._build_system_prompt(session_type)
                system_prompt = system_prompt.replace("{{active_context}}", active_context)
                system_prompt = system_prompt.replace("{{compendium_context}}", compendium_context)

                history = active_session.setdefault("history", [])
                session_mode = active_session.get("mode", "ic")

                if not history:
                    if session_mode == "ooc":
                        sys_prompt = "You are the Dungeon Master for Solis-Grave, a grimdark D&D campaign. Respond as the DM — helpful, direct, out-of-character. Answer rules questions, help with character builds, explain lore. Keep it under 300 chars. Do NOT narrate in second person unless asked."
                    else:
                        sys_prompt = system_prompt
                    history.append({"role": "system", "content": sys_prompt})

                if len(history) > MAX_HISTORY:
                    history = [history[0]] + history[-(MAX_HISTORY - 1):]
                    active_session["history"] = history

                history.append({"role": "user", "content": f"[{message.author.display_name}]: {message.content}"})

                response = await self.ai.chat.completions.create(
                    model="deepseek-v4-flash",
                    messages=history,
                    max_tokens=800
                )
                self.daily_calls += 1
                reply = response.choices[0].message.content.strip()

                narration_parts = re.findall(r"\[NARRATE\](.*?)\[/NARRATE\]", reply, re.DOTALL)
                narrate_text = ""
                for part in narration_parts:
                    narrate_text += part + " "
                    reply = reply.replace(f"[NARRATE]{part}[/NARRATE]", "")

                sheet_updates = re.findall(r"\[SHEET:\s*(.*?):\s*(.*?)\]", reply)
                for char_name, changes in sheet_updates:
                    reply = reply.replace(f"[SHEET: {char_name}: {changes}]", "")
                    sheets_cog = self.bot.get_cog("DMSheetsCog")
                    if sheets_cog:
                        await sheets_cog.apply_changes(char_name.strip(), changes.strip())

                history.append({"role": "assistant", "content": reply})

                if reply.strip():
                    for chunk in [reply[i:i+2000] for i in range(0, len(reply), 2000)]:
                        await message.reply(chunk)

                if narrate_text.strip():
                    voice_cog = self.bot.get_cog("DMVoiceCog")
                    if voice_cog:
                        await voice_cog.narrate(narrate_text.strip())

                if self.daily_calls % 10 == 0:
                    self.supabase.table("dm_game_state").update({
                        "active_context": active_context,
                        "updated_at": "now()"
                    }).eq("id", 1).execute()

            except Exception as e:
                await message.reply(f"*The weave falters...* (Error: {e})")

    @app_commands.command(name="npc_list", description="[Solo] View your NPC companions")
    async def npc_list(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)
        npcs = self.npc_parties.get(interaction.user.id, [])
        if not npcs:
            await interaction.followup.send("You have no NPC companions. Start a solo campaign first.")
            return
        embed = discord.Embed(title="Your Companions", color=0x8B0000)
        for npc in npcs:
            alive_status = "💀 DEAD" if not npc.get("is_alive", True) else "❤️"
            embed.add_field(
                name=f"{alive_status} {npc['name']} — {npc['role'].title()}",
                value=f"Class: {npc['class']} | HP: {npc['hp_current']}/{npc['hp_max']} | AC: {npc['ac']}\n"
                      f"*{npc.get('personality_trait', '')}* | Bond: {npc.get('bond', '')}",
                inline=False
            )
        await interaction.followup.send(embed=embed)

    @app_commands.command(name="ooc", description="Switch to Out-of-Character talk — I'll respond as the DM, not in-character")
    async def ooc_mode(self, interaction: discord.Interaction):
        for sid, sess in list(self.sessions.items()):
            if sess.get("channel_id") == interaction.channel_id:
                sess["mode"] = "ooc"
                await interaction.response.send_message("🗣️ **OOC Mode** — I'll respond as your DM. Rules, questions, character talk welcome. Use `/ic` to return to roleplay.", ephemeral=False)
                return
        await interaction.response.send_message("Start a session first with `/session_start`.", ephemeral=True)

    @app_commands.command(name="ic", description="Switch to In-Character roleplay — all messages treated as character actions")
    async def ic_mode(self, interaction: discord.Interaction):
        for sid, sess in list(self.sessions.items()):
            if sess.get("channel_id") == interaction.channel_id:
                sess["mode"] = "ic"
                sess["history"] = []
                await interaction.response.send_message("🎭 **In-Character Mode** — All messages are now treated as your character's actions. I'll narrate the world and NPCs. Use `/ooc` to step out.", ephemeral=False)
                return
        await interaction.response.send_message("Start a session first with `/session_start`.", ephemeral=True)

    @app_commands.command(name="guide", description="Repost the player guide to this channel")
    @app_commands.default_permissions(administrator=True)
    async def repost_guide(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)
        embed = discord.Embed(
            title="📜 Solis-Grave Player Guide",
            description=(
                "**Welcome to Solis-Grave: Shadows of the Crown.** I am your AI Dungeon Master.\n\n"
                "**Getting Started:**\n"
                "1. `/create` — Make a character in <#1514244983652094024>\n"
                "2. `/session_start` — The DM begins a session\n"
                "3. Type your actions naturally — I resolve everything\n\n"
                "**Modes:**\n"
                "`/ic` — In-Character roleplay. Everything you type is your character's action.\n"
                "`/ooc` — Out-of-Character. Ask me rules, questions, or chat as yourself.\n\n"
                "**Commands:** `/roll`, `/lore`, `/character_view`, `/character_mine`, `/xp`, `/help`\n"
                "**Voice:** `/dm_join` to invite me to voice chat for TTS narration.\n"
                "**Dice:** Use the dice bot in <#1514245057350209597>. I read your rolls automatically.\n\n"
                "**The World:** Magic comes from dragon blood purity. The Church of the Five Skulls "
                "rules through fear. Six Great Houses plot against each other. You start at the Citadel "
                "of the Dragon-Garrison — survive, grow, and uncover the truth.\n\n"
                "Tag me (@Kronikle) anywhere and I'll respond."
            ),
            color=0x8B0000
        )
        embed.set_footer(text="Solis-Grave · AI Dungeon Master powered by DeepSeek v4-flash")
        await interaction.followup.send(embed=embed)

    async def _send_worldstate(self, message: discord.Message):
        ctx = await self._get_active_context()
        sheets_cog = self.bot.get_cog("DMSheetsCog")
        chars = ""
        if sheets_cog:
            try:
                r = self.supabase.table("character_sheets").select("character_name,hp_current,hp_max,level,class").limit(10).execute()
                if r.data:
                    chars = "\n".join(f"- {c['character_name']}: Lvl {c['level']} {c['class']}, HP {c['hp_current']}/{c['hp_max']}" for c in r.data)
            except: pass
        await message.reply(f"[DM OOC]: **World State**\n{ctx[:800]}\n\n**Party:**\n{chars or 'No sheets found.'}")

    @app_commands.command(name="recap", description="Quick recap of current location, quest, and party status")
    async def recap_command(self, interaction: discord.Interaction):
        ctx = await self._get_active_context()
        await interaction.response.send_message(f"[DM OOC]: **Session Recap**\n{ctx[:1500]}\n\nUse /ic to return to roleplay.", ephemeral=False)

    @app_commands.command(name="worldstate", description="Full mechanical state dump: HP, spells, location, enemies, quests")
    async def worldstate_command(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)
        ctx = await self._get_active_context()
        sheets_cog = self.bot.get_cog("DMSheetsCog")
        chars = ""
        if sheets_cog:
            try:
                r = self.supabase.table("character_sheets").select("character_name,hp_current,hp_max,level,class,conditions,spell_slots_used,spell_slots_max").limit(10).execute()
                if r.data:
                    for c in r.data:
                        spells = c.get('spell_slots_used',{})
                        max_spells = c.get('spell_slots_max',{})
                        slot_info = "/".join(str(spells.get(str(i),0)) for i in range(1,6))
                        chars += f"- **{c['character_name']}** Lvl {c['level']} {c['class']}: HP {c['hp_current']}/{c['hp_max']}, Spells [{slot_info}]\n"
            except: pass
        embed = discord.Embed(title="🌍 World State", description=ctx[:1000] or "No active session.", color=0x8B0000)
        if chars: embed.add_field(name="Party", value=chars[:1000], inline=False)
        await interaction.followup.send(embed=embed)


async def setup(bot: commands.Bot):
    await bot.add_cog(DMSessionCog(bot))
