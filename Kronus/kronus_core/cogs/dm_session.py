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
Example:
"Before you, the Citadel of the Dragon-Garrison looms — a spire of obsidian and brass, its walls carved with the sigils of every bloodline the Inquisition has ever catalogued. The gates are guarded by Ordained in white-and-gold plate."
[NARRATE] Before you, the Citadel of the Dragon-Garrison looms — a spire of obsidian and brass, its walls carved with the sigils of every bloodline the Inquisition has ever catalogued. The gates are guarded by Ordained in white-and-gold plate. [/NARRATE]

## RESPONSE LENGTH
Keep responses under 1200 characters unless combat or complex rules explanation demands more.

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
        return prompt

    async def _generate_npc_party(self, owner_id: int, player_level: int) -> list[dict]:
        import random
        npcs = []
        roles = ["tank", "healer", "caster", "scout"]
        for role in roles:
            template = random.choice(NPC_TEMPLATES[role]["names"])
            npc = {
                "name": npc,
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
                "signature_ability_1": f"{role}_ability_1",
                "signature_ability_2": f"{role}_ability_2",
                "signature_ability_3": f"{role}_ability_3",
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
                model="deepseek-chat",
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
                        await user.send(file=discord.File(
                            discord.utils.MISSING,
                            filename="campaign_chronicle.md"
                        ))
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
                if not history:
                    history.append({"role": "system", "content": system_prompt})

                if len(history) > MAX_HISTORY:
                    history = [history[0]] + history[-(MAX_HISTORY - 1):]
                    active_session["history"] = history

                history.append({"role": "user", "content": f"[{message.author.display_name}]: {message.content}"})

                response = await self.ai.chat.completions.create(
                    model="deepseek-chat",
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


async def setup(bot: commands.Bot):
    await bot.add_cog(DMSessionCog(bot))
