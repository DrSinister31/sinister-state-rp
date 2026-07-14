import { Client, GatewayIntentBits, REST, Routes, SlashCommandBuilder, CommandInteraction, ActivityType } from 'discord.js';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { runRcon } from './rcon.js';
import { supabase } from './db.js';

dotenv.config();

const OWNER_ID = process.env.OWNER_ID;
const ADMIN_IDS = (process.env.ADMIN_IDS || '').split(',').map(x => x.trim()).filter(Boolean);
const LOG_CHANNEL_ID = process.env.LOG_CHANNEL_ID;

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

// ---------- Express API Server for Live Map ----------
const app = express();
app.use(cors());
app.use(express.json());

let globalPositions: Record<string, any> = {};

app.get('/api/players', (req, res) => {
  res.json(Object.values(globalPositions));
});

app.post('/api/link', async (req, res) => {
  const { discord_id, steam_id } = req.body;
  if (!discord_id || !steam_id) {
    return res.status(400).json({ error: 'Missing params' });
  }
  try {
    await supabase.from('player_links').upsert({ discord_id, steam_id }).select();
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

const API_PORT = 8080;
app.listen(API_PORT, '0.0.0.0', () => {
  console.log(`🌐 API Server running on port ${API_PORT}`);
});

// ---------- Database Helpers ----------
async function getMarks(steamId: string): Promise<number> {
  const { data } = await supabase.from('player_marks').select('marks').eq('steam_id', steamId).maybeSingle();
  if (data) return data.marks;
  const defaultMarks = 20000;
  await supabase.from('player_marks').upsert({ steam_id: steamId, marks: defaultMarks });
  return defaultMarks;
}

async function addMarks(steamId: string, amount: number): Promise<number> {
  const current = await getMarks(steamId);
  const updated = current + amount;
  await supabase.from('player_marks').upsert({ steam_id: steamId, marks: updated });
  return updated;
}

async function deductMarks(steamId: string, amount: number): Promise<boolean> {
  const current = await getMarks(steamId);
  if (current < amount) return false;
  await supabase.from('player_marks').upsert({ steam_id: steamId, marks: current - amount });
  return true;
}

function isAdmin(userId: string): boolean {
  if (OWNER_ID && userId === OWNER_ID) return true;
  return ADMIN_IDS.includes(userId);
}

// ---------- Slash Commands Registration ----------
const commands = [
  new SlashCommandBuilder()
    .setName('link')
    .setDescription('Link your Discord to Steam ID')
    .addStringOption(opt => opt.setName('steam_id').setDescription('17-digit Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('balance')
    .setDescription('Check your current marks and level'),
  new SlashCommandBuilder()
    .setName('leaderboard')
    .setDescription('View the top 10 richest players'),
  new SlashCommandBuilder()
    .setName('heal_player')
    .setDescription('[Staff] Heal a player in-game')
    .addStringOption(opt => opt.setName('target').setDescription('Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('kick')
    .setDescription('[Staff] Kick a player')
    .addStringOption(opt => opt.setName('target').setDescription('Steam ID or name').setRequired(true))
    .addStringOption(opt => opt.setName('reason').setDescription('Reason for kick')),
  new SlashCommandBuilder()
    .setName('announce')
    .setDescription('[Staff] Server-wide announcement')
    .addStringOption(opt => opt.setName('message').setDescription('Announcement message').setRequired(true)),
];

client.on('ready', async () => {
  console.log(`✅ Bot online as ${client.user?.tag}`);

  // Register commands
  const rest = new REST({ version: '10' }).setToken(process.env.DISCORD_TOKEN!);
  try {
    await rest.put(
      Routes.applicationCommands(client.user!.id),
      { body: commands.map(cmd => cmd.toJSON()) }
    );
    console.log('📋 Slash commands synced');
  } catch (err) {
    console.error('Failed to sync slash commands:', err);
  }

  // Start background tasks
  setInterval(positionUpdater, 10000);
  setInterval(taskWatcher, 5000);
});

// ---------- Slash Commands Handlers ----------
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  const { commandName } = interaction;

  if (commandName === 'link') {
    await interaction.deferReply({ ephemeral: true });
    const steamId = interaction.options.getString('steam_id', true);
    if (!/^\d{17}$/.test(steamId)) {
      return interaction.followUp('❌ Invalid Steam ID.');
    }
    const check = await runRcon(`getplayerdata ${steamId}`);
    if (check.includes('❌') || check.toLowerCase().includes('error')) {
      return interaction.followUp('❌ That Steam ID does not appear to be on the server or is invalid.');
    }
    await supabase.from('player_links').upsert({ discord_id: interaction.user.id, steam_id: steamId });
    return interaction.followUp(`✅ Successfully linked Steam ID: ${steamId}`);
  }

  if (commandName === 'balance') {
    await interaction.deferReply();
    const { data: link } = await supabase.from('player_links').select('steam_id').eq('discord_id', interaction.user.id).maybeSingle();
    if (!link) {
      return interaction.followUp('❌ Please link your Steam ID first using `/link`.');
    }
    const marks = await getMarks(link.steam_id);
    return interaction.followUp(`💰 You currently have **${marks.toLocaleString()}** Marks.`);
  }

  if (commandName === 'leaderboard') {
    await interaction.deferReply();
    const { data: richest } = await supabase.from('player_marks').select('steam_id, marks').order('marks', { ascending: false }).limit(10);
    if (!richest?.length) return interaction.followUp('No data available.');
    let list = richest.map((p, idx) => `${idx + 1}. \`${p.steam_id}\`: **${p.marks.toLocaleString()}** Marks`).join('\n');
    return interaction.followUp(`🏆 **Top Richest Players:**\n\n${list}`);
  }

  if (commandName === 'heal_player') {
    if (!isAdmin(interaction.user.id)) return interaction.reply({ content: '❌ No permission.', ephemeral: true });
    await interaction.deferReply();
    const target = interaction.options.getString('target', true);
    const res = await runRcon(`Set ${target} Health 1.0`);
    return interaction.followUp(`RCON Response: \`${res}\``);
  }

  if (commandName === 'announce') {
    if (!isAdmin(interaction.user.id)) return interaction.reply({ content: '❌ No permission.', ephemeral: true });
    await interaction.deferReply();
    const msg = interaction.options.getString('message', true);
    const res = await runRcon(`announce ${msg}`);
    return interaction.followUp(`RCON Response: \`${res}\``);
  }
});

// ---------- Background Task loops ----------
async function positionUpdater() {
  try {
    const raw = await runRcon('playerdata');
    if (!raw) return;

    const pattern = /Name:\s*(.*?),\s*PlayerID:\s*(\d+),\s*SteamID:\s*(\d+),\s*Location:\s*X=([-\d.]+)\s*Y=([-\d.]+)\s*Z=([-\d.]+),\s*Class:\s*(.*?),\s*Growth:\s*([-\d.]+),\s*Health:\s*([-\d.]+),\s*Stamina:\s*([-\d.]+),\s*Hunger:\s*([-\d.]+),\s*Thirst:\s*([-\d.]+)/g;
    let match;
    const activeSteamIds = new Set<string>();

    while ((match = pattern.exec(raw)) !== null) {
      const name = match[1].trim();
      const steamId = match[3];
      const x = parseFloat(match[4]);
      const y = parseFloat(match[5]);
      const z = parseFloat(match[6]);
      const species = match[7];
      const growth = parseFloat(match[8]);
      const health = parseFloat(match[9]);

      activeSteamIds.add(steamId);

      globalPositions[steamId] = {
        steam_id: steamId,
        player_name: name,
        position_x: x,
        position_y: y,
        position_z: z,
        species,
        growth,
        health,
        last_updated: new Date().toISOString(),
      };

      await supabase.from('live_map_positions').upsert({
        steam_id: steamId,
        position_x: x,
        position_y: y,
        player_name: name,
        species,
        health,
        growth,
        last_updated: new Date().toISOString(),
      });
    }

    // Clean up offline players
    for (const sid of Object.keys(globalPositions)) {
      if (!activeSteamIds.has(sid)) {
        delete globalPositions[sid];
        await supabase.from('live_map_positions').delete().eq('steam_id', sid);
      }
    }
  } catch (err) {
    console.error('Position Updater error:', err);
  }
}

async function taskWatcher() {
  try {
    const { data: tasks } = await supabase.from('pending_tasks').select('*').eq('status', 'pending');
    if (!tasks) return;

    for (const t of tasks) {
      console.log(`Executing pending task: ${t.command}`);
      const res = await runRcon(t.command);
      await supabase.from('pending_tasks').update({ status: 'completed' }).eq('id', t.id);
      if (LOG_CHANNEL_ID) {
        const chan = await client.channels.fetch(LOG_CHANNEL_ID);
        if (chan?.isTextBased()) {
          await (chan as any).send(`⚙️ **Executed Pending Task**: \`${t.command}\` -> \`${res}\``);
        }
      }
    }
  } catch (err) {
    console.error('Task Watcher error:', err);
  }
}

// Log in
client.login(process.env.DISCORD_TOKEN);
