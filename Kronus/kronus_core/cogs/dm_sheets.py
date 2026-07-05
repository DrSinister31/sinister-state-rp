import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config
from shared.supabase_client import get_supabase

STAT_ORDER = ["str", "dex", "con", "int", "wis", "cha"]
STAT_EMOJI = {"str": "💪", "dex": "🏃", "con": "❤️", "int": "🧠", "wis": "🦉", "cha": "👑"}


class DMSheetsCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.supabase = get_supabase(self.config)

    def _hp_bar(self, current: int, max_hp: int, length: int = 12) -> str:
        if max_hp <= 0:
            return "░░░░░░░░░░░░"
        ratio = min(current / max_hp, 1.0)
        filled = max(0, int(ratio * length))
        empty = length - filled
        return "█" * filled + "░" * empty

    def _conditions_emoji(self, conditions: list) -> str:
        if not conditions:
            return ""
        emoji_map = {
            "blinded": "👁️", "charmed": "💕", "deafened": "🔇", "frightened": "😱",
            "grappled": "🪢", "incapacitated": "💤", "invisible": "👻", "paralyzed": "⚡",
            "petrified": "🗿", "poisoned": "☠️", "prone": "⬇️", "restrained": "⛓️",
            "stunned": "💫", "unconscious": "🩸", "exhausted": "😩", "stabilized": "🩹",
            "concentrating": "🔮"
        }
        parts = []
        for c in conditions:
            c_lower = c.lower().strip()
            parts.append(f"{emoji_map.get(c_lower, '❓')} {c_lower}")
        return " | ".join(parts)

    def _build_public_embed(self, sheet: dict) -> discord.Embed:
        name = sheet.get("character_name", "Unknown")
        cls = sheet.get("class", "?")
        race = sheet.get("race", "?")
        level = sheet.get("level", 1)
        hp_c = sheet.get("hp_current", 0)
        hp_m = sheet.get("hp_max", 10)
        ac = sheet.get("ac", 10)
        speed = sheet.get("speed", 30)
        purity = sheet.get("blood_purity", 10)
        conditions = sheet.get("conditions", [])
        is_sovereign = sheet.get("is_sovereign", False)
        is_alive = sheet.get("is_alive", True)

        status = "💀 DEAD" if not is_alive else "❤️"
        sovereign_tag = " 👑 SOVEREIGN" if is_sovereign else ""

        embed = discord.Embed(
            title=f"{status}{sovereign_tag} {name}",
            description=f"*{race} {cls} — Level {level}*",
            color=0xFFD700 if is_sovereign else 0x8B0000
        )
        embed.add_field(
            name="HP",
            value=f"{self._hp_bar(hp_c, hp_m)} {hp_c}/{hp_m}",
            inline=True
        )
        embed.add_field(name="AC", value=str(ac), inline=True)
        embed.add_field(name="Speed", value=f"{speed} ft.", inline=True)
        embed.add_field(name="Blood Purity", value=f"{purity}%", inline=True)

        if conditions:
            embed.add_field(name="Conditions", value=self._conditions_emoji(conditions), inline=False)

        spell_slots_max = sheet.get("spell_slots_max", {})
        spell_slots_used = sheet.get("spell_slots_used", {})
        slot_parts = []
        for lvl_key in ["1", "2", "3", "4", "5"]:
            max_s = spell_slots_max.get(lvl_key, 0) if isinstance(spell_slots_max, dict) else 0
            used = spell_slots_used.get(lvl_key, 0) if isinstance(spell_slots_used, dict) else 0
            if max_s > 0:
                remaining = max_s - used
                bar = "█" * max(0, remaining) + "░" * max(0, used)
                slot_parts.append(f"Lvl{lvl_key}: {bar} {remaining}/{max_s}")
        for lvl_key in ["6", "7", "8", "9"]:
            max_s = spell_slots_max.get(lvl_key, 0) if isinstance(spell_slots_max, dict) else 0
            used = spell_slots_used.get(lvl_key, 0) if isinstance(spell_slots_used, dict) else 0
            if max_s > 0:
                slot_parts.append(f"Lvl{lvl_key}: {max_s - used}/{max_s}")
        if slot_parts:
            embed.add_field(name="Spell Slots", value="\n".join(slot_parts), inline=False)

        embed.set_footer(text=f"Blood Purity {purity}%{' | Hidden Sovereign' if is_sovereign else ''}")

        return embed

    def _build_private_embed(self, sheet: dict) -> discord.Embed:
        embed = self._build_public_embed(sheet)

        stats = sheet.get("stats", {})
        if isinstance(stats, str):
            stats = json.loads(stats)
        stat_line = "  ".join(f"{STAT_EMOJI.get(s,'')} **{s.upper()} {stats.get(s,10)}**" for s in STAT_ORDER)
        embed.add_field(name="Stats", value=stat_line, inline=False)

        saves = sheet.get("saving_throws", {})
        if isinstance(saves, str):
            saves = json.loads(saves)
        if saves:
            save_parts = [f"{k.upper()}: +{v}" for k, v in saves.items()]
            embed.add_field(name="Saving Throws", value=", ".join(save_parts), inline=False)

        skills = sheet.get("skill_proficiencies", {})
        if isinstance(skills, str):
            skills = json.loads(skills)
        if skills:
            skill_parts = [f"{k.title()}: +{v}" for k, v in skills.items()]
            embed.add_field(name="Skills", value=", ".join(skill_parts), inline=False)

        spells_known = sheet.get("spells_known", [])
        if isinstance(spells_known, str):
            spells_known = json.loads(spells_known)
        if spells_known:
            embed.add_field(name="Spells Known", value=", ".join(spells_known[:20]), inline=False)

        inventory = sheet.get("inventory", [])
        if isinstance(inventory, str):
            inventory = json.loads(inventory)
        if inventory:
            embed.add_field(name="Inventory", value=", ".join(str(i) for i in inventory[:15]), inline=False)

        notes = sheet.get("notes", "")
        if notes:
            embed.add_field(name="Notes", value=notes[:1024], inline=False)

        death_saves = f"✅ {sheet.get('death_saves_success', 0)}/3 | ❌ {sheet.get('death_saves_fail', 0)}/3"
        embed.add_field(name="Death Saves", value=death_saves, inline=True)

        return embed

    async def get_sheet(self, character_name: str, discord_id: int = None) -> dict | None:
        try:
            query = self.supabase.table("character_sheets").select("*")
            if discord_id:
                query = query.eq("discord_id", discord_id)
            query = query.ilike("character_name", f"%{character_name}%").limit(1)
            r = query.execute()
            if r.data:
                return r.data[0]
        except Exception:
            pass
        try:
            r = self.supabase.table("character_sheets").select("*").ilike("character_name", f"%{character_name}%").limit(1).execute()
            if r.data:
                return r.data[0]
        except Exception:
            pass
        return None

    async def refresh_sheet(self, character_name: str, discord_id: int = None):
        sheet = await self.get_sheet(character_name, discord_id)
        if not sheet:
            return
        public_id = sheet.get("public_message_id")
        private_id = sheet.get("private_message_id")
        public_ch = sheet.get("public_channel_id")
        private_ch = sheet.get("private_channel_id")
        is_public = sheet.get("is_public", True)

        if public_id and public_ch and is_public:
            try:
                ch = self.bot.get_channel(public_ch) or await self.bot.fetch_channel(public_ch)
                msg = await ch.fetch_message(public_id)
                await msg.edit(embed=self._build_public_embed(sheet))
            except Exception:
                pass

        if private_id and private_ch:
            try:
                ch = self.bot.get_channel(private_ch) or await self.bot.fetch_channel(private_ch)
                msg = await ch.fetch_message(private_id)
                await msg.edit(embed=self._build_private_embed(sheet))
            except Exception:
                pass

    async def apply_changes(self, character_name: str, changes_str: str):
        sheet = await self.get_sheet(character_name)
        if not sheet:
            return
        updates = {}
        for change in changes_str.split(","):
            change = change.strip()
            if "=" not in change:
                continue
            key, val = change.split("=", 1)
            key = key.strip()
            val = val.strip()
            if key == "hp":
                updates["hp_current"] = max(0, sheet.get("hp_current", 0) + int(val))
            elif key == "condition":
                conditions = list(sheet.get("conditions", []) or [])
                if val.startswith("-"):
                    c = val[1:].strip()
                    if c in conditions:
                        conditions.remove(c)
                else:
                    if val not in conditions:
                        conditions.append(val)
                updates["conditions"] = conditions
            elif key.startswith("spell_slot_"):
                slot_lvl = key.replace("spell_slot_", "")
                key_path = f"spell_slots_used:{slot_lvl}"
                current_used = json.loads(json.dumps(sheet.get("spell_slots_used", {}))) if isinstance(sheet.get("spell_slots_used"), str) else dict(sheet.get("spell_slots_used", {}))
                max_slots = json.loads(json.dumps(sheet.get("spell_slots_max", {}))) if isinstance(sheet.get("spell_slots_max"), str) else dict(sheet.get("spell_slots_max", {}))
                current = int(current_used.get(slot_lvl, 0))
                new_val = max(0, min(int(max_slots.get(slot_lvl, 0)), current + int(val)))
                current_used[slot_lvl] = new_val
                updates["spell_slots_used"] = current_used
            elif key == "temp_hp":
                updates["temp_hp"] = max(0, sheet.get("temp_hp", 0) + int(val))
        if updates:
            updates["updated_at"] = "now()"
            self.supabase.table("character_sheets").update(updates).eq("id", sheet["id"]).execute()
            await self.refresh_sheet(character_name)

    @app_commands.command(name="character_create", description="Create your D&D character sheet")
    @app_commands.describe(name="Character name", char_class="Class (Barbarian, Wizard, etc.)", race="Race (Human, Elf, etc.)", level="Starting level")
    async def character_create(self, interaction: discord.Interaction, name: str, char_class: str, race: str = "Human", level: int = 1):
        await interaction.response.defer(ephemeral=True)
        try:
            existing = self.supabase.table("character_sheets").select("id").eq("discord_id", interaction.user.id).eq("character_name", name).execute()
            if existing.data:
                await interaction.followup.send(f"Character \"{name}\" already exists. Use `/character_view {name}`.", ephemeral=True)
                return

            sheet = {
                "discord_id": interaction.user.id,
                "character_name": name,
                "class": char_class,
                "race": race,
                "level": level,
                "hp_current": 10 + (level * 5),
                "hp_max": 10 + (level * 5),
                "ac": 10,
                "speed": 30,
                "is_public": True,
                "is_alive": True
            }

            r = self.supabase.table("character_sheets").insert(sheet).execute()
            if r.data:
                sheet = r.data[0]
                embed = self._build_public_embed(sheet)
                msg = await interaction.followup.send(embed=embed, ephemeral=False, wait=True)
                self.supabase.table("character_sheets").update({
                    "public_message_id": msg.id,
                    "public_channel_id": interaction.channel_id
                }).eq("id", sheet["id"]).execute()

                try:
                    dm_channel = await interaction.user.create_dm()
                    private_embed = self._build_private_embed(sheet)
                    dm_msg = await dm_channel.send(embed=private_embed)
                    self.supabase.table("character_sheets").update({
                        "private_message_id": dm_msg.id,
                        "private_channel_id": dm_channel.id
                    }).eq("id", sheet["id"]).execute()
                except discord.Forbidden:
                    pass

            await interaction.followup.send(f"Character **{name}** created!", ephemeral=True)
        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="character_view", description="View a character sheet")
    @app_commands.describe(name="Character name")
    async def character_view(self, interaction: discord.Interaction, name: str):
        await interaction.response.defer(ephemeral=False)
        sheet = await self.get_sheet(name)
        if not sheet:
            await interaction.followup.send(f"Character \"{name}\" not found.", ephemeral=True)
            return

        is_owner = sheet.get("discord_id") == interaction.user.id
        is_dm = (interaction.user.id == self.config.owner_discord_id or
                 interaction.user.id in self.config.admin_discord_ids)
        is_public = sheet.get("is_public", True)

        if not is_owner and not is_dm and not is_public:
            await interaction.followup.send("This character's sheet is private.", ephemeral=True)
            return

        embed = self._build_public_embed(sheet)
        await interaction.followup.send(embed=embed)

    @app_commands.command(name="character_mine", description="View your full private character sheet (sent to DMs)")
    async def character_mine(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        r = self.supabase.table("character_sheets").select("*").eq("discord_id", interaction.user.id).order("created_at", desc=True).limit(1).execute()
        if not r.data:
            await interaction.followup.send("You have no characters. Use `/character_create`.", ephemeral=True)
            return
        sheet = r.data[0]
        try:
            embed = self._build_private_embed(sheet)
            await interaction.user.send(embed=embed)
            await interaction.followup.send("Full sheet sent to your DMs.", ephemeral=True)
        except discord.Forbidden:
            await interaction.followup.send("I can't DM you — check your privacy settings.", ephemeral=True)

    @app_commands.command(name="character_edit", description="[DM] Edit a character sheet")
    @app_commands.describe(name="Character name", field="Field to edit (hp_current, hp_max, ac, level, blood_purity, conditions)", value="New value (or +/- for hp)")
    async def character_edit(self, interaction: discord.Interaction, name: str, field: str, value: str):
        if interaction.user.id != self.config.owner_discord_id and interaction.user.id not in self.config.admin_discord_ids:
            await interaction.response.send_message("DM only.", ephemeral=True)
            return
        await interaction.response.defer(ephemeral=True)
        sheet = await self.get_sheet(name)
        if not sheet:
            await interaction.followup.send(f"Character \"{name}\" not found.", ephemeral=True)
            return
        try:
            if value.startswith("+") or value.startswith("-"):
                current = sheet.get(field, 0)
                new_val = current + int(value)
            else:
                new_val = int(value) if field not in ("conditions",) else value.split(",")
            update = {field: new_val, "updated_at": "now()"}
            self.supabase.table("character_sheets").update(update).eq("id", sheet["id"]).execute()
            await self.refresh_sheet(name)
            await interaction.followup.send(f"Updated **{name}** — {field} = {new_val}", ephemeral=True)
        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="character_list", description="List all characters in the campaign")
    async def character_list(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)
        r = self.supabase.table("character_sheets").select("character_name,class,race,level,hp_current,hp_max,is_alive,is_public,is_sovereign,blood_purity,conditions").eq("is_npc", False).execute()
        if not r.data:
            await interaction.followup.send("No characters created yet.")
            return
        embed = discord.Embed(title="Campaign Characters", color=0x8B0000)
        for c in r.data:
            hp_bar = self._hp_bar(c["hp_current"], c["hp_max"], 8)
            status = "💀" if not c["is_alive"] else "❤️"
            privacy = "🔒" if not c["is_public"] else ""
            sovereign = " 👑" if c.get("is_sovereign") else ""
            conditions_str = self._conditions_emoji(c.get("conditions", []))
            embed.add_field(
                name=f"{status}{privacy}{sovereign} {c['character_name']}",
                value=f"{c.get('race','?')} {c['class']} Lvl {c['level']} | {hp_bar} {c['hp_current']}/{c['hp_max']} | Purity {c.get('blood_purity',0)}%{(' ' + conditions_str) if conditions_str else ''}",
                inline=False
            )
        await interaction.followup.send(embed=embed)

    @app_commands.command(name="character_longrest", description="Reset HP/spell slots to max (long rest)")
    async def character_longrest(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        r = self.supabase.table("character_sheets").select("id,hp_max,spell_slots_max").eq("discord_id", interaction.user.id).eq("is_alive", True).execute()
        if not r.data:
            await interaction.followup.send("You have no living characters.", ephemeral=True)
            return
        for sheet in r.data:
            self.supabase.table("character_sheets").update({
                "hp_current": sheet["hp_max"],
                "temp_hp": 0,
                "spell_slots_used": sheet.get("spell_slots_max", {}),
                "conditions": [],
                "death_saves_success": 0,
                "death_saves_fail": 0,
                "updated_at": "now()"
            }).eq("id", sheet["id"]).execute()
        await interaction.followup.send("Long rest complete. HP restored, spell slots refreshed, conditions cleared.", ephemeral=True)

    @app_commands.command(name="character_shortrest", description="Short rest — roll hit dice to recover HP")
    async def character_shortrest(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)
        import random
        r = self.supabase.table("character_sheets").select("id,character_name,hp_current,hp_max,level").eq("discord_id", interaction.user.id).eq("is_alive", True).execute()
        if not r.data:
            await interaction.followup.send("You have no living characters.", ephemeral=True)
            return
        results = []
        for sheet in r.data:
            hd_count = min(sheet["level"], 5)
            healing = sum(random.randint(1, 8) + 2 for _ in range(hd_count))
            new_hp = min(sheet["hp_max"], sheet["hp_current"] + healing)
            self.supabase.table("character_sheets").update({
                "hp_current": new_hp,
                "updated_at": "now()"
            }).eq("id", sheet["id"]).execute()
            results.append(f"{sheet['character_name']}: +{healing} HP ({new_hp}/{sheet['hp_max']})")
        await interaction.followup.send("Short rest:\n" + "\n".join(results), ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(DMSheetsCog(bot))
