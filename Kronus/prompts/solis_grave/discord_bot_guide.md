# Kronus DM Bot — Discord Guide

## What the Bot Does

Kronus is an AI Dungeon Master that runs Solis-Grave D&D campaigns entirely within Discord. It narrates the story, runs combat, tracks character sheets, speaks in voice channels via TTS, and manages solo or group campaigns.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Command Reference](#command-reference)
3. [Session Lifecycle](#session-lifecycle)
4. [Character Sheets](#character-sheets)
5. [Voice & Narration](#voice--narration)
6. [Solo Campaign](#solo-campaign)
7. [Group Campaign](#group-campaign)
8. [Stream Detection](#stream-detection)
9. [Server Setup](#server-setup)
10. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- You must have the **@DM** role to start/end sessions
- The bot must be invited with `7720000` permissions
- A `Dungeons & Dragons` category must exist (for solo channels)
- FFmpeg must be installed on the bot's host (for voice/TTS)

### First Session

1. DM types `/session_start mode:solo` or `/session_start mode:group`
2. For solo: a private channel `#solo-yourname` is created automatically
3. For group: the session runs in the current channel
4. Players create characters with `/character_create`
5. Start typing actions — the DM narrates everything

---

## Command Reference

### Session Commands

| Command | Who | What |
|---------|:--:|------|
| `/session_start mode:solo` | DM | Start a solo campaign. Creates private channel. |
| `/session_start mode:group` | DM | Start a group campaign in the current channel. |
| `/session_end` | DM | End the campaign. Generates chronicles, sends to player DMs, deletes solo channels. |
| `/session_state` | DM | View in-game date, party location, campaign status. |

### Character Commands

| Command | Who | What |
|---------|:--:|------|
| `/character_create name: class: race: level:` | All | Create your D&D character. Posts public embed. DMs you the full private sheet. |
| `/character_view name:` | All | View a character's public embed. Private sheets return "This sheet is private." unless you're the owner or DM. |
| `/character_mine` | All | Bot sends your FULL private sheet to your DMs. |
| `/character_list` | All | List all campaign characters with HP, class, level, conditions. Private sheets show `[PRIVATE]` tag. |
| `/character_edit name: field: value:` | DM | Adjust any field. Examples: `/character_edit Bob hp_current 45`, `/character_edit Bob conditions poisoned,blinded` |
| `/character_longrest` | All | Full HP restore, all spell slots reset, conditions cleared, death saves reset. |
| `/character_shortrest` | All | Roll hit dice, recover HP. |

### Dice & Mechanics

| Command | Who | What |
|---------|:--:|------|
| `/roll dice:` | All | Roll any dice expression. Examples: `1d20+5`, `2d6+3`, `4d6k3`, `1d20` |
| `/initiative name: roll:` | All | Add yourself to the initiative tracker. The DM bot tracks turn order. |
| `/lore query:` | All | Search the Solis-Grave compendium for spells, items, or monsters. |
| `/npc_list` | Solo | View your NPC companions' stats, HP, and personalities. |

### Voice Commands

| Command | Who | What |
|---------|:--:|------|
| `/dm_join` | DM | Bot joins your current voice channel. |
| `/dm_leave` | DM | Bot disconnects from voice. |
| `/dm_narrate text:` | DM | Queue text for TTS narration in voice. |

### Admin Commands (existing Kronus bot)

| Command | Who | What |
|---------|:--:|------|
| `/warn user: reason:` | Staff | Warn a user. |
| `/strike user: reason:` | Staff | Issue a strike. |
| `/ban user: reason:` | Staff | Ban a user. |
| `/announce message:` | Staff | Announce to the server. |
| `/ticket` | All | Open a support ticket. |
| `/bestiary name:` | All | Look up a monster. |
| `/bestiary_random` | All | Get a random monster stat block. |
| `/bestiary_dm name:` | DM | Full (hidden) monster lookup. |
| `/bestiary_generate count:` | DM | Generate new monsters via DeepSeek. |
| `/channel-info` | All | See a channel's stored purpose. |
| `/remember purpose:` | DM | Set a channel's purpose for AI context. |

---

## Session Lifecycle

### Starting (DM)

```
/session_start mode:solo
/session_start mode:group
```

**Solo mode** automatically:
1. Creates `#solo-yourname` under the `Dungeons & Dragons` category
2. Sets permissions: only you + bot + DM can see it
3. Generates 4 NPC companions (tank, healer, caster, scout)
4. Marks YOU as the Sovereign (Dragon-Heir)
5. Posts welcome embed with companion details

**Group mode** automatically:
1. Activates DM AI in the current channel
2. Randomly selects one player as the dormant Sovereign (hidden)
3. Posts welcome embed

### During Play

Just type what your character does. The DM bot:
- Narrates the world in second person present tense
- Rolls dice for attacks, saves, and checks
- Tracks HP, conditions, spell slots automatically
- Updates your character sheet embed in real-time
- Routes dramatic narration to voice (if connected)

**Examples of what to type:**
- "I approach the Citadel gates."
- "I draw my sword and charge the nearest goblin."
- "I ask the guard about the blood scan procedure."
- "I cast Cinder Bolt at the troll."
- "I search the room for hidden doors."
- "Tell Kolgrim to hold the line while I flank left."
- "I try to hide my bloodline during the scan."

**The bot responds within 1-3 seconds.** Response includes:
- Narration of what happens
- Dice results in brackets: `[d20 = 14 + 5 = 19]`
- A follow-up question: *"What do you do?"*

### Ending (DM)

```
/session_end
```

The bot will:
1. **Solo mode:** Generate a "Campaign Chronicle" — a narrative summary of your entire journey. Send it as a DM embed + markdown file. **Delete your solo channel.**
2. **Group mode:** Generate individual chronicles for each player. Send to DMs. Delete session channel if it was a dedicated campaign channel.
3. Archive all state to Supabase.

**This is permanent.** Make sure everyone is ready to end.

---

## Character Sheets

### Creating

```
/character_create name:"Bob the Barbarian" class:Barbarian race:Human level:1
```

The bot:
1. Creates your sheet in the database
2. Posts a **public embed** in the session channel (compact: HP, AC, conditions, spell slots)
3. DMs you a **private embed** with full details (stats, saves, skills, inventory, spells known)

### Live Updates

During combat and roleplay, the DM bot automatically parses `[SHEET:]` tags and updates your embed:
- `[SHEET: Bob: hp=-6]` → HP bar drops
- `[SHEET: Bob: hp=+8, condition=stabilized]` → HP up, condition added
- `[SHEET: Goblin Scout: hp=-12, condition=unconscious]` → Goblin tracked

Your embed in the channel **edits itself live** — no new messages needed.

### Public vs Private

| Setting | Public Sheet | Private Sheet |
|---------|:--:|:--:|
| `/character_view` by another player | Shows compact embed | "This sheet is private." |
| `/character_view` by owner | Shows compact embed | Shows compact embed |
| `/character_view` by DM | Shows compact embed | Shows compact embed |
| `/character_list` | Appears in list | Shows `[PRIVATE]` tag only |
| Auto-update via DM bot | Edits public embed | Edits DM embed only |
| `/character_mine` | Shows full sheet in DM | Shows full sheet in DM |

To toggle privacy: DM asks a DM to `/character_edit Bob is_public false`.

---

## Voice & Narration

### How It Works

1. DM connects bot to voice with `/dm_join`
2. During the session, the AI DM generates narration text wrapped in `[NARRATE]` tags:
   ```
   [NARRATE] The iron portcullis groans upward. Beyond it, torchlight flickers against wet stone. [/NARRATE]
   ```
3. The bot strips the tags from the text reply
4. The narration text enters a FIFO TTS queue
5. gTTS converts text → MP3
6. FFmpeg streams the audio into the voice channel
7. The bot speaks the narration aloud to all VC members

### What Gets Narrated

The AI DM wraps these moments in `[NARRATE]`:
- Scene transitions (entering a new area)
- Combat start ("The goblins burst from the shadows!")
- Major NPC introductions
- Dramatic reveals (the Sovereign bloodline awakening)
- Location descriptions (first time entering a city/dungeon)
- Combat kills / critical moments

**Not narrated:** dice rolls, `[SHEET:]` tags, mechanical notes, player dialogue.

### Manual Narration

The DM can queue any text for TTS:
```
/dm_narrate text:The ground trembles as the Ancient Dragon stirs beneath the mountain.
```

### Stream Detection

When a player starts **streaming** in a voice channel:
1. Bot detects it automatically (via `on_voice_state_update`)
2. Posts an embed in the DM text channel: "**Player is now live!**"
3. If the bot isn't connected to VC, it auto-joins that channel
4. DM narration continues alongside the stream

When streaming stops:
- Bot announces "Stream ended"
- If no one else is streaming and no active narration, bot disconnects after **5 minutes**

No extra setup needed — works out of the box with the `PRESENCE INTENT` enabled.

---

## Solo Campaign

### Channel

Your solo campaign lives in `#solo-yourname` under the `Dungeons & Dragons` category. Only you, the bot, and users with @DM role can see it.

### Your NPC Party

View them anytime: `/npc_list`

| Role | Names | Combat Style |
|------|-------|-------------|
| **Tank** | Steel-Gaze Korr, Shield-Maiden Brynn, Wrath-Bound Grok | Engages strongest enemy, body-blocks for you |
| **Healer** | Sister Aelindra, Root-Tender Fenn, Hymn-Singer Lio | Heals downed allies, stays at range |
| **Caster** | Archon Thezzik, Grimoire-Bound Vesper, Pact-Sworn Nyx | AoE damage, crowd control, targets enemy casters |
| **Scout** | Shadow-Blood Silas, Trail-Walker Renn, Iron-Soul Mei | Flanks, scouts ahead, disengages frequently |

### Commanding NPCs

Use natural language:
- "Tell the healer to heal me"
- "Kolgrim, draw their attention while I flank"
- "Vex, check for traps ahead"
- "Everyone, fall back to the doorway"
- "Nyx, use your fire spell on the troll"

The DM bot interprets your command and controls the NPC accordingly.

### NPC Death

NPCs can **die permanently**. If one falls in combat:
- They get death saves like any character
- If they fail 3, they're dead
- The DM bot generates a replacement NPC at the next town, camp, or safe location
- The replacement has a different name, personality, and backstory

### You Are the Sovereign

In solo mode, you don't need to be randomly selected — **you ARE the Sovereign.** Your bloodline will awaken through the story. When it does, you gain all Sovereign class features alongside your existing class.

### Cross-Play

If another solo player's party is in the same region as yours, the DM bot may trigger a **cross-party event**. This is announced in both channels. You'll see:
> "Through the trees, you spot another party approaching — a warrior flanked by a cleric and a ranger. They see you too."

Combat between parties is **possible** but requires both players to consent. Shared loot is mediated by the DM bot. Parties separate after the shared event.

---

## Group Campaign

### Setup

1. Have all players in the session channel
2. DM types `/session_start mode:group`
3. Everyone creates characters with `/character_create`
4. Start roleplaying

### The Sovereign

One player is secretly the **Sovereign**. Nobody knows who — not even that player. The DM bot tracks it internally. The bloodline awakens through story events:
- A failed blood scan at the Citadel
- A critical combat moment
- Touching a Sovereign-Fragment core
- An Inquisitor "sensing something wrong"

When it happens, the bot reveals it narratively to everyone.

### Player Count

2-5 players recommended. More than 5 slows down combat.

### Ending

`/session_end` sends each player a personalized Campaign Chronicle to their DMs.

---

## Server Setup

### Required Channels/Roles

| Name | Type | Purpose |
|------|------|---------|
| `@DM` | Role | Who can start/end DM sessions |
| `Dungeons & Dragons` | Category | Houses all solo player channels |
| `#rp-table` | Text | Group campaign channel (optional — sessions can run anywhere) |
| `RP Voice` | Voice | Voice channel for TTS narration (optional) |

### .env Configuration

```
DISCORD_GUILD_ID=<your server id>
DM_SESSION_ROLE_ID=<@DM role id>
DND_CATEGORY_ID=<Dungeons & Dragons category id>
DM_VOICE_CHANNEL_ID=<voice channel id, optional>
DM_TEXT_CHANNEL_ID=<#rp-table channel id, optional>
CAMPAIGN_CHANNEL_PREFIX=solo
CHARACTER_SHEETS_CHANNEL_ID=<sheets display channel, optional>
```

### Permissions

The bot role should have:
- `View Channel`, `Send Messages`, `Embed Links`, `Read Message History`, `Add Reactions`, `Attach Files`, `Use External Emojis` in the `Dungeons & Dragons` category
- `Connect`, `Speak`, `Use Voice Activity` in the voice channel
- **Denied** at server level (except the above)

This locks the bot to only D&D channels.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| **Bot doesn't respond** | Check daily API limit (500 calls/day). Wait until next day. Cooldown per user: 3 seconds. |
| **TTS not working** | Ensure FFmpeg is installed on the host system. Ensure bot is connected to VC with `/dm_join`. |
| **Character sheet not updating** | Bot might not have `Manage Messages` in the channel. The edit might be rate-limited. Check that the embed message wasn't deleted. |
| **Solo channel not created** | Check `DND_CATEGORY_ID` in `.env`. Bot needs `Manage Channels` in the category. |
| **Cross-play not triggering** | It's an 85+ on a d100 per in-game day. It's intentionally rare. Both players must be in the same region. |
| **Spell Safety DC seems wrong** | Reminder: it's `8 + spell_level + (15 - purity/7)`. Higher purity = lower DC. Also add the spell's `aether_burn_risk` modifier (+0 to +5). |
| **Bot lagging in combat** | Group combat with many NPCs is intensive. Use `/roll` manually for your own attacks to reduce bot load. |
| **`/lore` returns nothing** | The `compendium_spells` table might be empty. Run `seed_spells.sql` in Supabase. |
| **Campaign chronicle not sent** | Check your DM privacy settings. The bot needs to be able to send you direct messages. |

---

## Quick Reference Card

```
DM COMMANDS:
  /session_start mode:solo|group   Start campaign
  /session_end                     End campaign (generates chronicles)
  /session_state                   View campaign state
  /dm_join                         Bot joins VC
  /dm_leave                        Bot leaves VC
  /dm_narrate text:...             Manual TTS narration
  /character_edit name: field: value:  Adjust any stat

PLAYER COMMANDS:
  /character_create name: class: race: level:   Create character
  /character_view name:             View public sheet
  /character_mine                   DM full private sheet
  /character_list                   All characters
  /character_longrest / character_shortrest    Rest
  /roll dice:                       Roll (1d20, 2d6+3, 4d6k3)
  /lore query:                      Search compendium
  /npc_list (solo only)            View companions

AUTO-FEATURES:
  [SHEET: name: hp=-X]             Auto-updates character embeds
  [NARRATE]...[/NARRATE]           Auto-TTS in voice
  Stream detection                  Auto-join VC when stream starts
  Cross-party events                d100 roll each in-game day
```
