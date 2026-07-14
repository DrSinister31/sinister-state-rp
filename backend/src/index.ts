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

async function isAdmin(userId: string): Promise<boolean> {
  console.log(`Checking admin for user ID: ${userId} (Env OWNER_ID: ${OWNER_ID}, ADMIN_IDS: ${JSON.stringify(ADMIN_IDS)})`);
  
  // 1. Env check
  if (OWNER_ID && userId === OWNER_ID) {
    console.log(`  -> Match: OWNER_ID`);
    return true;
  }
  if (ADMIN_IDS.includes(userId)) {
    console.log(`  -> Match: ADMIN_IDS`);
    return true;
  }

  // 2. Database check
  try {
    const { data } = await supabase.from('server_roles').select('is_admin, is_mod').eq('discord_id', userId).maybeSingle();
    if (data?.is_admin || data?.is_mod) {
      console.log(`  -> Match: server_roles database (is_admin: ${data.is_admin}, is_mod: ${data.is_mod})`);
      return true;
    }
  } catch (err) {
    console.error('Error checking server_roles table:', err);
  }

  console.log(`  -> No permission.`);
  return false;
}

// ---------- Target Resolver (Discord tag, SteamID, or Online Player Name) ----------
async function resolveTarget(target: string): Promise<string | null> {
  const clean = target.trim();
  
  // 1. Check if 17-digit SteamID
  if (/^\d{17}$/.test(clean)) {
    return clean;
  }
  
  // 2. Check if Discord mention/tag (<@123456> or 123456)
  const match = clean.match(/^(?:<@!?)?(\d+)>?$/);
  if (match) {
    const discordId = match[1];
    const { data } = await supabase.from('player_links').select('steam_id').eq('discord_id', discordId).maybeSingle();
    if (data?.steam_id) {
      return data.steam_id;
    }
  }
  
  // 3. Check online players by name (case-insensitive)
  const lowerName = clean.toLowerCase();
  for (const pos of Object.values(globalPositions)) {
    if (pos.player_name.toLowerCase().includes(lowerName)) {
      return pos.steam_id;
    }
  }
  
  return null;
}

// ---------- Slash Commands Registration ----------
const commands = [
  // --- Core / Economy (All Players) ---
  new SlashCommandBuilder()
    .setName('link')
    .setDescription('Link your Discord to your 17-digit Steam ID')
    .addStringOption(opt => opt.setName('steam_id').setDescription('17-digit Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('unlink')
    .setDescription('Unlink your Discord from your Steam ID'),
  new SlashCommandBuilder()
    .setName('balance')
    .setDescription('Check your current marks and level'),
  new SlashCommandBuilder()
    .setName('daily')
    .setDescription('Claim your daily marks bonus'),
  new SlashCommandBuilder()
    .setName('shop')
    .setDescription('View the available shop items'),
  new SlashCommandBuilder()
    .setName('buy')
    .setDescription('Buy an item from the shop')
    .addStringOption(opt => opt.setName('item').setDescription('Item name to buy').setRequired(true)),
  new SlashCommandBuilder()
    .setName('inventory')
    .setDescription('Check your purchased items and inventory'),
  new SlashCommandBuilder()
    .setName('use')
    .setDescription('Use an item from your inventory')
    .addStringOption(opt => opt.setName('item').setDescription('Item name to use').setRequired(true)),
  new SlashCommandBuilder()
    .setName('leaderboard')
    .setDescription('View the top 10 richest players'),

  // --- Admin / Moderation (Staff Only) ---
  new SlashCommandBuilder()
    .setName('kick')
    .setDescription('[Staff] Kick a player')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addStringOption(opt => opt.setName('reason').setDescription('Reason for kick')),
  new SlashCommandBuilder()
    .setName('ban')
    .setDescription('[Staff] Ban a player')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addStringOption(opt => opt.setName('reason').setDescription('Reason for ban').setRequired(true)),
  new SlashCommandBuilder()
    .setName('unban')
    .setDescription('[Staff] Unban a player')
    .addStringOption(opt => opt.setName('steam_id').setDescription('17-digit Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('announce')
    .setDescription('[Staff] Server-wide announcement')
    .addStringOption(opt => opt.setName('message').setDescription('Announcement message').setRequired(true)),
  new SlashCommandBuilder()
    .setName('save')
    .setDescription('[Staff] Force save the server game state'),
  new SlashCommandBuilder()
    .setName('pause')
    .setDescription('[Staff] Pause/Resume the server game thread'),
  new SlashCommandBuilder()
    .setName('toggleai')
    .setDescription('[Staff] Toggle AI spawning on the server'),
  new SlashCommandBuilder()
    .setName('aidensity')
    .setDescription('[Staff] Set AI density multiplier')
    .addNumberOption(opt => opt.setName('value').setDescription('AI Density multiplier value').setRequired(true)),
  new SlashCommandBuilder()
    .setName('disableaiclasses')
    .setDescription('[Staff] Disable specific AI classes')
    .addStringOption(opt => opt.setName('classes').setDescription('Comma-separated class names').setRequired(true)),
  new SlashCommandBuilder()
    .setName('wipecorpses')
    .setDescription('[Staff] Wipe all corpses from the map'),
  new SlashCommandBuilder()
    .setName('togglegrowthmultiplier')
    .setDescription('[Staff] Toggle growth multiplier state'),
  new SlashCommandBuilder()
    .setName('setgrowthmultiplier')
    .setDescription('[Staff] Set growth multiplier')
    .addNumberOption(opt => opt.setName('value').setDescription('Growth multiplier').setRequired(true)),
  new SlashCommandBuilder()
    .setName('updateplayables')
    .setDescription('[Staff] Update playables cache from config'),
  new SlashCommandBuilder()
    .setName('togglewhitelist')
    .setDescription('[Staff] Toggle server whitelist mode'),
  new SlashCommandBuilder()
    .setName('addwhitelist')
    .setDescription('[Staff] Add a Steam ID to the whitelist')
    .addStringOption(opt => opt.setName('steam_id').setDescription('17-digit Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('removewhitelist')
    .setDescription('[Staff] Remove a Steam ID from the whitelist')
    .addStringOption(opt => opt.setName('steam_id').setDescription('17-digit Steam ID').setRequired(true)),
  new SlashCommandBuilder()
    .setName('playerlist')
    .setDescription('[Staff] List all online players'),
  new SlashCommandBuilder()
    .setName('getplayerdata')
    .setDescription('[Staff] Fetch player details')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('dm')
    .setDescription('[Staff] Direct message a player in-game')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addStringOption(opt => opt.setName('message').setDescription('Message payload').setRequired(true)),
  new SlashCommandBuilder()
    .setName('teleport')
    .setDescription('[Staff] Teleport player to coordinates')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addNumberOption(opt => opt.setName('x').setDescription('X coordinate').setRequired(true))
    .addNumberOption(opt => opt.setName('y').setDescription('Y coordinate').setRequired(true))
    .addNumberOption(opt => opt.setName('z').setDescription('Z coordinate').setRequired(true)),
  new SlashCommandBuilder()
    .setName('bringcorpse')
    .setDescription('[Staff] Teleport target player corpse to self location')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('species')
    .setDescription('[Staff] Modify target player dino species')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addStringOption(opt => opt.setName('species_id').setDescription('Species Class name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('skin')
    .setDescription('[Staff] Force skin reload')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('skincreator')
    .setDescription('[Staff] Grant target player Skin Creator access')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('heal')
    .setDescription('[Staff] Heal target player stats in-game')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('setgrowth')
    .setDescription('[Staff] Adjust target growth value')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addNumberOption(opt => opt.setName('value').setDescription('Growth value (e.g. 0.88)').setRequired(true)),
  new SlashCommandBuilder()
    .setName('pausegrowth')
    .setDescription('[Staff] Pause target player growth')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('resumegrowth')
    .setDescription('[Staff] Resume target player growth')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true)),
  new SlashCommandBuilder()
    .setName('setstat')
    .setDescription('[Staff] Set target player stat value')
    .addStringOption(opt => opt.setName('target').setDescription('Discord tag, SteamID, or name').setRequired(true))
    .addStringOption(opt => {
      return opt.setName('stat')
        .setDescription('Stat to adjust')
        .setRequired(true)
        .addChoices(
          { name: 'Health', value: 'Health' },
          { name: 'Stamina', value: 'Stamina' },
          { name: 'Hunger', value: 'Hunger' },
          { name: 'Thirst', value: 'Thirst' },
          { name: 'Bleed', value: 'Bleed' },
          { name: 'Blood', value: 'Blood' },
          { name: 'Carbs', value: 'Carbs' },
          { name: 'Lipids', value: 'Lipids' },
          { name: 'Protein', value: 'Protein' }
        );
    })
    .addNumberOption(opt => opt.setName('value').setDescription('Stat value (e.g. 100)').setRequired(true)),
  new SlashCommandBuilder()
    .setName('console')
    .setDescription('[Staff] Direct Console Passthrough')
    .addStringOption(opt => opt.setName('command').setDescription('Raw console command string').setRequired(true)),
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

  // --- Economy/Core Commands (Check linking for players) ---
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

  if (commandName === 'unlink') {
    await interaction.deferReply({ ephemeral: true });
    await supabase.from('player_links').delete().eq('discord_id', interaction.user.id);
    return interaction.followUp('✅ Successfully unlinked your Steam ID.');
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

  if (commandName === 'daily') {
    await interaction.deferReply();
    const { data: link } = await supabase.from('player_links').select('steam_id').eq('discord_id', interaction.user.id).maybeSingle();
    if (!link) {
      return interaction.followUp('❌ Please link your Steam ID first using `/link`.');
    }
    
    // Check daily reward cooldown (24 hours)
    const { data: marksRow } = await supabase.from('player_marks').select('last_daily, marks').eq('steam_id', link.steam_id).maybeSingle();
    const now = new Date();
    if (marksRow?.last_daily) {
      const last = new Date(marksRow.last_daily);
      const diff = now.getTime() - last.getTime();
      if (diff < 24 * 60 * 60 * 1000) {
        const remaining = 24 * 60 * 60 * 1000 - diff;
        const hours = Math.floor(remaining / (60 * 60 * 1000));
        const minutes = Math.floor((remaining % (60 * 60 * 1000)) / (60 * 1000));
        return interaction.followUp(`⏳ Cooldown active. You can claim your daily marks again in **${hours}h ${minutes}m**.`);
      }
    }
    
    const reward = 5000;
    await addMarks(link.steam_id, reward);
    await supabase.from('player_marks').update({ last_daily: now.toISOString() }).eq('steam_id', link.steam_id);
    return interaction.followUp(`🎉 Claimed daily bonus of **${reward.toLocaleString()}** Marks!`);
  }

  if (commandName === 'shop') {
    return interaction.reply({
      content: `🛒 **SinisterPark Shop Items:**\n\n- \`heal\` (Full health, hunger, thirst refill) — **25,000 Marks**\n- \`growth\` (Instant growth to 88%) — **25,000 Marks**\n- \`stamina\` (Full stamina refill) — **5,000 Marks**\n\n*Use \`/buy [item]\` to purchase.*`,
      ephemeral: true
    });
  }

  if (commandName === 'buy') {
    await interaction.deferReply();
    const item = interaction.options.getString('item', true).toLowerCase();
    const { data: link } = await supabase.from('player_links').select('steam_id').eq('discord_id', interaction.user.id).maybeSingle();
    if (!link) {
      return interaction.followUp('❌ Please link your Steam ID first using `/link`.');
    }

    let cost = 0;
    let cmd = '';
    if (item === 'heal') {
      cost = 25000;
      cmd = `heal ${link.steam_id}`;
    } else if (item === 'growth') {
      cost = 25000;
      cmd = `setgrowth ${link.steam_id} 0.88`;
    } else if (item === 'stamina') {
      cost = 5000;
      cmd = `setstat ${link.steam_id} Stamina 100`;
    } else {
      return interaction.followUp('❌ Unknown item name. Type `/shop` to view available items.');
    }

    const ok = await deductMarks(link.steam_id, cost);
    if (!ok) {
      return interaction.followUp(`❌ Insufficient marks. This item costs **${cost.toLocaleString()}** Marks.`);
    }

    const res = await runRcon(cmd);
    return interaction.followUp(`🛒 Purchased **${item}** for **${cost.toLocaleString()}** Marks! RCON: \`${res}\``);
  }

  if (commandName === 'leaderboard') {
    await interaction.deferReply();
    const { data: richest } = await supabase.from('player_marks').select('steam_id, marks').order('marks', { ascending: false }).limit(10);
    if (!richest?.length) return interaction.followUp('No data available.');
    let list = richest.map((p, idx) => `${idx + 1}. \`${p.steam_id}\`: **${p.marks.toLocaleString()}** Marks`).join('\n');
    return interaction.followUp(`🏆 **Top Richest Players:**\n\n${list}`);
  }

  // --- Staff Commands (Check permissions) ---
  const isStaff = await isAdmin(interaction.user.id);
  if (!isStaff) {
    return interaction.reply({ content: '❌ You do not have permission to run staff commands.', ephemeral: true });
  }

  await interaction.deferReply();

  try {
    // 1. Kick
    if (commandName === 'kick') {
      const targetInput = interaction.options.getString('target', true);
      const reason = interaction.options.getString('reason') || 'Kicked by administrator';
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`. Ensure they have linked their SteamID or are currently online.`);
      const res = await runRcon(`kick ${steamId}`);
      return interaction.followUp(`RCON: \`kick ${steamId}\` -> \`${res}\` (Reason: ${reason})`);
    }

    // 2. Ban
    if (commandName === 'ban') {
      const targetInput = interaction.options.getString('target', true);
      const reason = interaction.options.getString('reason', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`ban ${steamId} ${reason}`);
      return interaction.followUp(`RCON: \`ban ${steamId} ${reason}\` -> \`${res}\``);
    }

    // 3. Unban
    if (commandName === 'unban') {
      const steamId = interaction.options.getString('steam_id', true);
      const res = await runRcon(`unban ${steamId}`);
      return interaction.followUp(`RCON: \`unban ${steamId}\` -> \`${res}\``);
    }

    // 4. Announce
    if (commandName === 'announce') {
      const message = interaction.options.getString('message', true);
      const res = await runRcon(`announce ${message}`);
      return interaction.followUp(`RCON: \`announce ${message}\` -> \`${res}\``);
    }

    // 5. Save
    if (commandName === 'save') {
      const res = await runRcon('save');
      return interaction.followUp(`RCON: \`save\` -> \`${res}\``);
    }

    // 6. Pause
    if (commandName === 'pause') {
      const res = await runRcon('pause');
      return interaction.followUp(`RCON: \`pause\` -> \`${res}\``);
    }

    // 7. Toggle AI
    if (commandName === 'toggleai') {
      const res = await runRcon('toggleai');
      return interaction.followUp(`RCON: \`toggleai\` -> \`${res}\``);
    }

    // 8. AI Density
    if (commandName === 'aidensity') {
      const val = interaction.options.getNumber('value', true);
      const res = await runRcon(`aidensity ${val}`);
      return interaction.followUp(`RCON: \`aidensity ${val}\` -> \`${res}\``);
    }

    // 9. Disable AI classes
    if (commandName === 'disableaiclasses') {
      const cls = interaction.options.getString('classes', true);
      const res = await runRcon(`disableaiclasses ${cls}`);
      return interaction.followUp(`RCON: \`disableaiclasses ${cls}\` -> \`${res}\``);
    }

    // 10. Wipe corpses
    if (commandName === 'wipecorpses') {
      const res = await runRcon('wipecorpses');
      return interaction.followUp(`RCON: \`wipecorpses\` -> \`${res}\``);
    }

    // 11. Toggle growth multiplier
    if (commandName === 'togglegrowthmultiplier') {
      const res = await runRcon('togglegrowthmultiplier');
      return interaction.followUp(`RCON: \`togglegrowthmultiplier\` -> \`${res}\``);
    }

    // 12. Set growth multiplier
    if (commandName === 'setgrowthmultiplier') {
      const val = interaction.options.getNumber('value', true);
      const res = await runRcon(`setgrowthmultiplier ${val}`);
      return interaction.followUp(`RCON: \`setgrowthmultiplier ${val}\` -> \`${res}\``);
    }

    // 13. Update playables
    if (commandName === 'updateplayables') {
      const res = await runRcon('updateplayables');
      return interaction.followUp(`RCON: \`updateplayables\` -> \`${res}\``);
    }

    // 14. Toggle whitelist
    if (commandName === 'togglewhitelist') {
      const res = await runRcon('togglewhitelist');
      return interaction.followUp(`RCON: \`togglewhitelist\` -> \`${res}\``);
    }

    // 15. Add whitelist
    if (commandName === 'addwhitelist') {
      const steamId = interaction.options.getString('steam_id', true);
      const res = await runRcon(`addwhitelist ${steamId}`);
      return interaction.followUp(`RCON: \`addwhitelist ${steamId}\` -> \`${res}\``);
    }

    // 16. Remove whitelist
    if (commandName === 'removewhitelist') {
      const steamId = interaction.options.getString('steam_id', true);
      const res = await runRcon(`removewhitelist ${steamId}`);
      return interaction.followUp(`RCON: \`removewhitelist ${steamId}\` -> \`${res}\``);
    }

    // 17. Player list
    if (commandName === 'playerlist') {
      const res = await runRcon('playerlist');
      return interaction.followUp(`RCON: \`playerlist\` -> \n\`\`\`\n${res}\n\`\`\``);
    }

    // 18. Get player data
    if (commandName === 'getplayerdata') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`getplayerdata ${steamId}`);
      return interaction.followUp(`RCON: \`getplayerdata ${steamId}\` -> \n\`\`\`\n${res}\n\`\`\ miniature stats`);
    }

    // 19. DM in-game
    if (commandName === 'dm') {
      const targetInput = interaction.options.getString('target', true);
      const message = interaction.options.getString('message', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`directmessage ${steamId},${message}`);
      return interaction.followUp(`RCON: \`directmessage ${steamId},${message}\` -> \`${res}\``);
    }

    // 20. Teleport
    if (commandName === 'teleport') {
      const targetInput = interaction.options.getString('target', true);
      const x = interaction.options.getNumber('x', true);
      const y = interaction.options.getNumber('y', true);
      const z = interaction.options.getNumber('z', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`teleport ${steamId} ${x} ${y} ${z}`);
      return interaction.followUp(`RCON: \`teleport ${steamId} ${x} ${y} ${z}\` -> \`${res}\``);
    }

    // 21. Bring Corpse
    if (commandName === 'bringcorpse') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`bringcorpse ${steamId}`);
      return interaction.followUp(`RCON: \`bringcorpse ${steamId}\` -> \`${res}\``);
    }

    // 22. Species
    if (commandName === 'species') {
      const targetInput = interaction.options.getString('target', true);
      const speciesId = interaction.options.getString('species_id', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`species ${steamId} ${speciesId}`);
      return interaction.followUp(`RCON: \`species ${steamId} ${speciesId}\` -> \`${res}\``);
    }

    // 23. Skin reload
    if (commandName === 'skin') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`skin ${steamId}`);
      return interaction.followUp(`RCON: \`skin ${steamId}\` -> \`${res}\``);
    }

    // 24. Skin Creator
    if (commandName === 'skincreator') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`skincreator ${steamId}`);
      return interaction.followUp(`RCON: \`skincreator ${steamId}\` -> \`${res}\``);
    }

    // 25. Heal
    if (commandName === 'heal') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`heal ${steamId}`);
      return interaction.followUp(`RCON: \`heal ${steamId}\` -> \`${res}\``);
    }

    // 26. Set Growth
    if (commandName === 'setgrowth') {
      const targetInput = interaction.options.getString('target', true);
      const val = interaction.options.getNumber('value', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`setgrowth ${steamId} ${val}`);
      return interaction.followUp(`RCON: \`setgrowth ${steamId} ${val}\` -> \`${res}\``);
    }

    // 27. Pause Growth
    if (commandName === 'pausegrowth') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`pausegrowth ${steamId}`);
      return interaction.followUp(`RCON: \`pausegrowth ${steamId}\` -> \`${res}\``);
    }

    // 28. Resume Growth
    if (commandName === 'resumegrowth') {
      const targetInput = interaction.options.getString('target', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`resumegrowth ${steamId}`);
      return interaction.followUp(`RCON: \`resumegrowth ${steamId}\` -> \`${res}\``);
    }

    // 29. Set Stat
    if (commandName === 'setstat') {
      const targetInput = interaction.options.getString('target', true);
      const stat = interaction.options.getString('stat', true);
      const val = interaction.options.getNumber('value', true);
      const steamId = await resolveTarget(targetInput);
      if (!steamId) return interaction.followUp(`❌ Could not resolve target: \`${targetInput}\`.`);
      const res = await runRcon(`setstat ${steamId} ${stat} ${val}`);
      return interaction.followUp(`RCON: \`setstat ${steamId} ${stat} ${val}\` -> \`${res}\``);
    }

    // 30. Direct Console Passthrough
    if (commandName === 'console') {
      const rawCmd = interaction.options.getString('command', true);
      const res = await runRcon(rawCmd);
      return interaction.followUp(`RCON (Raw): \`${rawCmd}\` -> \n\`\`\`\n${res}\n\`\`\``);
    }

  } catch (err: any) {
    console.error(`Command execution error for ${commandName}:`, err);
    return interaction.followUp(`❌ Error executing command: \`${err.message}\``);
  }
});

// ---------- Background Task loops ----------
async function positionUpdater() {
  try {
    const raw = await runRcon('playerdata');
    if (!raw || raw.includes('❌') || raw.toLowerCase().includes('error')) return;

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
