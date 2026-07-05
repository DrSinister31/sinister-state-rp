import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import discord
from discord import app_commands
from discord.ext import commands
from shared.config import Config
from kronus_compendium.lookup import CompendiumLookup
from kronus_compendium.generator import CompendiumGenerator


DM_CATEGORY_NAMES = {"staff", "dm", "game-master", "kronus", "admin"}


class CompendiumCog(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        self.config = Config.from_env()
        self.lookup = CompendiumLookup(self.config)
        self.generator = CompendiumGenerator(self.config)

    def _is_dm_channel(self, interaction: discord.Interaction) -> bool:
        if not interaction.channel or not isinstance(interaction.channel, discord.TextChannel):
            return False
        if interaction.channel.category:
            return interaction.channel.category.name.lower() in DM_CATEGORY_NAMES
        return False

    def _is_admin(self, interaction: discord.Interaction) -> bool:
        return interaction.user.id == self.config.owner_discord_id or \
               interaction.user.id in self.config.admin_discord_ids

    def _format_monster_embed(self, monster: dict) -> discord.Embed:
        name = monster.get("name", "Unknown")
        size = monster.get("size", "Medium")
        mtype = monster.get("type", "Unknown")
        cr = monster.get("cr", 0)
        alignment = monster.get("alignment", "unaligned")

        embed = discord.Embed(
            title=f"{name}",
            description=f"*{size} {mtype}, {alignment}*",
            color=0x8B0000
        )

        embed.add_field(name="CR", value=str(cr), inline=True)
        embed.add_field(name="XP", value=str(monster.get("xp", 0)), inline=True)
        embed.add_field(name="AC", value=str(monster.get("ac", 10)), inline=True)
        embed.add_field(name="HP", value=monster.get("hp", "?"), inline=True)
        embed.add_field(name="Speed", value=monster.get("speed", "30 ft."), inline=True)

        stats = monster.get("stats", {})
        stat_line = f"STR {stats.get('str',10)} | DEX {stats.get('dex',10)} | CON {stats.get('con',10)} | INT {stats.get('int',10)} | WIS {stats.get('wis',10)} | CHA {stats.get('cha',10)}"
        embed.add_field(name="Stats", value=stat_line, inline=False)

        saves = monster.get("saving_throws")
        if saves:
            save_parts = [f"{k.upper()} +{v}" for k, v in saves.items()]
            embed.add_field(name="Saving Throws", value=", ".join(save_parts), inline=False)

        skills = monster.get("skills")
        if skills:
            skill_parts = [f"{k.title()} +{v}" for k, v in skills.items()]
            embed.add_field(name="Skills", value=", ".join(skill_parts), inline=False)

        for field_key, field_name in [
            ("damage_vulnerabilities", "Damage Vulnerabilities"),
            ("damage_resistances", "Damage Resistances"),
            ("damage_immunities", "Damage Immunities"),
            ("condition_immunities", "Condition Immunities"),
        ]:
            val = monster.get(field_key)
            if val:
                embed.add_field(name=field_name, value=val, inline=True)

        senses = monster.get("senses", "")
        languages = monster.get("languages", "")
        if senses or languages:
            embed.add_field(name="Senses", value=senses or "passive Perception 10", inline=True)
            if languages:
                embed.add_field(name="Languages", value=languages, inline=True)

        traits = monster.get("traits") or []
        for trait in traits:
            if isinstance(trait, dict):
                embed.add_field(name=f"[Trait] {trait.get('name', '?')}", value=trait.get("desc", "")[:1024], inline=False)

        actions = monster.get("actions") or []
        for action in actions:
            if isinstance(action, dict):
                embed.add_field(name=f"[Action] {action.get('name', '?')}", value=action.get("desc", "")[:1024], inline=False)

        legendary = monster.get("legendary_actions") or []
        for la in legendary:
            if isinstance(la, dict):
                embed.add_field(name=f"[Legendary] {la.get('name', '?')}", value=la.get("desc", "")[:1024], inline=False)

        lair = monster.get("lair_actions") or []
        for la in lair:
            if isinstance(la, dict):
                embed.add_field(name=f"[Lair] {la.get('name', '?')}", value=la.get("desc", "")[:1024], inline=False)

        reactions = monster.get("reactions") or []
        for react in reactions:
            if isinstance(react, dict):
                embed.add_field(name=f"[Reaction] {react.get('name', '?')}", value=react.get("desc", "")[:1024], inline=False)

        lore = monster.get("lore", "")
        aether = monster.get("aether_core", {})
        if aether and aether.get("tier") not in (None, "None", ""):
            lore += f"\n\n**Aether-Core:** {aether.get('tier')} ({aether.get('element','?')}) — {aether.get('value_gc',0)} GC"

        if lore:
            embed.add_field(name="Lore", value=lore[:1024], inline=False)

        tags = monster.get("source_tags") or []
        biomes = monster.get("biome_tags") or []
        footer = []
        if tags:
            footer.append("Tags: " + ", ".join(tags))
        if biomes:
            footer.append("Biomes: " + ", ".join(biomes))
        if footer:
            embed.set_footer(text=" | ".join(footer))

        return embed

    @app_commands.command(name="bestiary", description="Look up a monster from the Solis-Grave compendium")
    @app_commands.describe(
        name="Monster name or partial name",
        cr_min="Minimum Challenge Rating",
        cr_max="Maximum Challenge Rating",
        monster_type="Monster type (e.g. Dragon, Undead, Beast)",
        biome="Native biome (e.g. swamp, mountain, forest)"
    )
    async def bestiary(self, interaction: discord.Interaction, name: str = None,
                       cr_min: float = None, cr_max: float = None,
                       monster_type: str = None, biome: str = None):
        await interaction.response.defer(ephemeral=False)

        try:
            session = self.lookup.supabase.table("compendium_session_state").select("*").eq("id", 1).execute()
            if session.data:
                state = session.data[0]
                if not state.get("player_access_enabled", True):
                    await interaction.followup.send(
                        "The bestiary is currently restricted. Your character doesn't know this information. "
                        "Try recalling from memory or using an appropriate skill check.",
                        ephemeral=True
                    )
                    return

            if name:
                monster = self.lookup.get_by_name(name, public_only=True)
                if monster:
                    embed = self._format_monster_embed(monster)
                    await interaction.followup.send(embed=embed)
                else:
                    await interaction.followup.send(
                        f"No public monster found matching \"{name}\". Try a different name or ask a DM.",
                        ephemeral=True
                    )
                return

            results = self.lookup.search(
                query=name, cr_min=cr_min, cr_max=cr_max,
                monster_type=monster_type, biome=biome,
                public_only=True, limit=5
            )

            if not results:
                await interaction.followup.send("No monsters found matching those filters.", ephemeral=True)
                return

            if len(results) == 1:
                embed = self._format_monster_embed(results[0])
                await interaction.followup.send(embed=embed)
                return

            names = [f"**{m['name']}** (CR {m.get('cr',0)}, {m.get('size','?')} {m.get('type','?')})" for m in results]
            msg = "**Found multiple monsters:**\n" + "\n".join(names)
            msg += "\n\nUse `/bestiary name:<name>` for a specific one."
            await interaction.followup.send(msg)

        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="bestiary_random", description="Get a random monster from the public bestiary")
    async def bestiary_random(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=False)

        try:
            monster = self.lookup.get_random(public_only=True)
            if monster:
                embed = self._format_monster_embed(monster)
                await interaction.followup.send(embed=embed)
            else:
                await interaction.followup.send("No public monsters in the compendium yet.", ephemeral=True)
        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="bestiary_dm", description="[DM] Full compendium lookup including hidden monsters")
    @app_commands.describe(
        name="Monster name or partial name",
        cr_min="Minimum Challenge Rating",
        cr_max="Maximum Challenge Rating",
        monster_type="Monster type",
        biome="Native biome"
    )
    async def bestiary_dm(self, interaction: discord.Interaction, name: str = None,
                          cr_min: float = None, cr_max: float = None,
                          monster_type: str = None, biome: str = None):
        if not (self._is_dm_channel(interaction) or self._is_admin(interaction)):
            await interaction.response.send_message("This command is restricted to DM channels.", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=False)

        try:
            if name:
                monster = self.lookup.get_by_name(name, public_only=False)
                if monster:
                    embed = self._format_monster_embed(monster)
                    await interaction.followup.send(embed=embed)
                else:
                    await interaction.followup.send(f"No monster found matching \"{name}\".", ephemeral=True)
                return

            results = self.lookup.search(
                query=name, cr_min=cr_min, cr_max=cr_max,
                monster_type=monster_type, biome=biome,
                public_only=False, limit=5
            )

            if not results:
                await interaction.followup.send("No monsters found.", ephemeral=True)
                return

            if len(results) == 1:
                embed = self._format_monster_embed(results[0])
                await interaction.followup.send(embed=embed)
                return

            names = [f"**{m['name']}** (CR {m.get('cr',0)}, {m.get('size','?')} {m.get('type','?')}) {'[PUBLIC]' if m.get('public') else '[HIDDEN]'}" for m in results]
            msg = "**Found multiple monsters:**\n" + "\n".join(names)
            msg += "\n\nUse `/bestiary_dm name:<name>` for the full stat block."
            await interaction.followup.send(msg)

        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="bestiary_generate", description="[DM] Generate new monsters via DeepSeek")
    @app_commands.describe(
        count="Number of monsters to generate (max 20)",
        region="Target biome/region",
        faction="Target faction",
        monster_type="Monster type to generate",
        cr_min="Minimum CR",
        cr_max="Maximum CR"
    )
    async def bestiary_generate(self, interaction: discord.Interaction, count: int = 5,
                                region: str = None, faction: str = None,
                                monster_type: str = None, cr_min: float = None, cr_max: float = None):
        if not (self._is_dm_channel(interaction) or self._is_admin(interaction)):
            await interaction.response.send_message("This command is restricted to DM channels.", ephemeral=True)
            return

        if count > 20:
            count = 20
        if count < 1:
            count = 1

        await interaction.response.defer(ephemeral=False)

        try:
            existing = self.lookup.count_monsters()
            await interaction.followup.send(
                f"Generating {count} monster(s)... (Current total: {existing}). This may take a moment."
            )

            monsters = self.generator.generate(
                region=region, faction=faction,
                cr_min=cr_min, cr_max=cr_max,
                monster_type=monster_type, count=count
            )

            if not monsters:
                await interaction.followup.send("Generation failed or daily API limit reached.")
                return

            inserted = self.lookup.insert_monsters(monsters)
            names = [m.get("name", "???") for m in monsters]
            total = self.lookup.count_monsters()

            await interaction.followup.send(
                f"**Generated {inserted}/{len(monsters)} monsters:** {', '.join(names)}\n"
                f"Total compendium: {total} monsters."
            )

        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="bestiary_public", description="[DM] Toggle a monster's public visibility")
    @app_commands.describe(name="Exact monster name", public="Set to publicly visible?")
    async def bestiary_public(self, interaction: discord.Interaction, name: str, public: bool):
        if not (self._is_dm_channel(interaction) or self._is_admin(interaction)):
            await interaction.response.send_message("This command is restricted to DM channels.", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=True)

        success = self.lookup.set_public(name, public)
        status = "public" if public else "hidden"
        if success:
            await interaction.followup.send(f"\"{name}\" is now **{status}**.", ephemeral=True)
        else:
            await interaction.followup.send(f"Could not find \"{name}\".", ephemeral=True)

    @app_commands.command(name="bestiary_toggle", description="[DM] Enable/disable player bestiary access during sessions")
    @app_commands.describe(enabled="Allow players to use /bestiary?")
    async def bestiary_toggle(self, interaction: discord.Interaction, enabled: bool):
        if not (self._is_dm_channel(interaction) or self._is_admin(interaction)):
            await interaction.response.send_message("This command is restricted to DM channels.", ephemeral=True)
            return

        await interaction.response.defer(ephemeral=True)

        try:
            self.lookup.supabase.table("compendium_session_state").update({
                "player_access_enabled": enabled,
                "dm_discord_id": interaction.user.id
            }).eq("id", 1).execute()

            status = "enabled" if enabled else "disabled"
            await interaction.followup.send(f"Player bestiary access **{status}**.", ephemeral=True)
        except Exception as e:
            await interaction.followup.send(f"Error: {e}", ephemeral=True)

    @app_commands.command(name="bestiary_stats", description="Show compendium statistics")
    async def bestiary_stats(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)

        total = self.lookup.count_monsters()
        public = self.lookup.count_public_monsters()
        types = self.lookup.get_distinct_types()
        biomes = self.lookup.get_distinct_biomes()

        msg = (
            f"**Compendium Stats**\n"
            f"Total monsters: **{total}**\n"
            f"Public (player-visible): **{public}**\n"
            f"Hidden (DM-only): **{total - public}**\n"
            f"Monster types: {', '.join(types[:20])}{'...' if len(types) > 20 else ''}\n"
            f"Biomes: {', '.join(biomes[:15])}{'...' if len(biomes) > 15 else ''}"
        )
        await interaction.followup.send(msg, ephemeral=True)


async def setup(bot: commands.Bot):
    await bot.add_cog(CompendiumCog(bot))
