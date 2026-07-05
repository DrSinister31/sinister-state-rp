'use client';
import { useState, useEffect } from 'react';
import { useSession } from 'next-auth/react';
import Link from 'next/link';
import { Search, ShoppingBag, Zap, Shield } from 'lucide-react';

const SPECIES = ['All', 'Tyrannosaurus', 'Carnotaurus', 'Ceratosaurus', 'Deinosuchus', 'Dilophosaurus', 'Herrerasaurus', 'Omniraptor', 'Pteranodon', 'Troodon', 'Allosaurus', 'Diabloceratops', 'Dryosaurus', 'Gallimimus', 'Hypsilophodon', 'Maiasaura', 'Pachycephalosaurus', 'Stegosaurus', 'Tenontosaurus', 'Beipiaosaurus'];

const DEFAULT_COMMANDS = [
  { key: 'heal', effect: 'Full heal (all stats)', cost: 25000, cooldown_minutes: 0 },
  { key: 'buyhealth', effect: 'Health to 100%', cost: 10000, cooldown_minutes: 0 },
  { key: 'buyblood', effect: 'Blood to 100%', cost: 10000, cooldown_minutes: 0 },
  { key: 'buyhunger', effect: 'Hunger to 100%', cost: 15000, cooldown_minutes: 0 },
  { key: 'buythirst', effect: 'Thirst to 100%', cost: 15000, cooldown_minutes: 0 },
  { key: 'buystam', effect: 'Stamina to 100%', cost: 5000, cooldown_minutes: 0 },
  { key: 'buycopout', effect: 'Full diets + heal + 1 tier growth', cost: 75000, cooldown_minutes: 0 },
  { key: 'buygrow', effect: 'Growth 88% + heal (Deino: 100%)', cost: 25000, cooldown_minutes: 5 },
  { key: 'freegrow', effect: 'Growth to 74%', cost: 0, cooldown_minutes: 180 },
  { key: 'unstuck', effect: 'Free teleport to safe zone + clear animations', cost: 0, cooldown_minutes: 0 },
  { key: 'applyskin', effect: 'Apply a saved skin from your presets', cost: 0, cooldown_minutes: 0 },
  { key: 'myskins', effect: 'List all your saved skin presets', cost: 0, cooldown_minutes: 0 },
  { key: 'balance', effect: 'Check your current marks balance', cost: 0, cooldown_minutes: 0 },
  { key: 'daily', effect: 'Claim your daily marks bonus (24h cooldown)', cost: 0, cooldown_minutes: 1440 },
  { key: 'link', effect: 'Link your Discord to your game Steam ID', cost: 0, cooldown_minutes: 0 },
  { key: 'leaderboard', effect: 'View top players by marks, XP, or kills', cost: 0, cooldown_minutes: 0 },
  { key: 'gift', effect: 'Gift marks to another linked player', cost: 'Variable', cooldown_minutes: 0 },
  { key: 'buyskinstorage', effect: 'Buy an extra skin slot (default 5 max)', cost: '25,000 per slot', cooldown_minutes: 0 },
  { key: 'buystorage', effect: 'Buy an extra dino storage slot', cost: '25,000 per slot', cooldown_minutes: 0 },
];

const ADMIN_COMMANDS = [
  { key: 'playerlist', effect: 'List all online players on the server', cost: 0 },
  { key: 'kick <player>', effect: 'Kick a player from the server', cost: 0 },
  { key: 'ban <player> <hours>', effect: 'Ban a player (optional duration)', cost: 0 },
  { key: 'announce <msg>', effect: 'Broadcast a message to all players in-game', cost: 0 },
  { key: 'heal_player <player>', effect: 'Heal a specific player', cost: 0 },
  { key: 'teleport <player>', effect: 'Teleport a player to another location', cost: 0 },
  { key: 'addmarks <player> <amt>', effect: 'Grant marks to a player', cost: 0 },
  { key: 'removemarks <player> <amt>', effect: 'Remove marks from a player', cost: 0 },
  { key: 'wipecorpses', effect: 'Clear all dinosaur carcasses from the map', cost: 0 },
  { key: 'dm <player> <msg>', effect: 'Send a private in-game message to a player', cost: 0 },
  { key: 'spectate <player>', effect: 'Spectate a player from their perspective', cost: 0 },
];

export default function StorePage() {
  const { data: session } = useSession();
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [species, setSpecies] = useState('All');
  const [sort, setSort] = useState('newest');
  const [search, setSearch] = useState('');
  const [tab, setTab] = useState('skins');
  const [commands, setCommands] = useState(DEFAULT_COMMANDS);
  const [cmdPage, setCmdPage] = useState(0);
  const [adminPage, setAdminPage] = useState(0);
  const [isAdmin, setIsAdmin] = useState(false);
  const [balance, setBalance] = useState(null);
  const [steamId, setSteamId] = useState(null);
  const perPage = 10;
  const limit = 12;

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`).then(r => r.json())
        .then(d => {
          if (d.steam_id) setSteamId(d.steam_id);
          if (d.is_admin || d.is_mod) setIsAdmin(true);
        })
        .catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    if (steamId) {
      fetch(`/api/players/balance?steam_id=${steamId}`)
        .then(r => r.json())
        .then(d => { if (d.marks !== undefined) setBalance(d.marks); })
        .catch(() => {});
    }
  }, [steamId]);

  useEffect(() => {
    fetch('/api/economy/rates')
      .then(r => r.json())
      .then(d => { if (d.success && d.data.length) setCommands(d.data.filter(c => c.cost > 0 || c.key === 'freegrow' || c.key === 'unstuck')); })
      .catch(() => {});
  }, []);

  useEffect(() => {
    setLoading(true);
    const params = new URLSearchParams({ page, limit, sort });
    if (species !== 'All') params.set('species', species);
    if (search) params.set('search', search);
    fetch(`/api/store/products?${params}`)
      .then(r => r.json())
      .then(d => { if (d.success) { setProducts(d.data); setTotal(d.total); } })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [page, species, sort, search]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="min-h-full bg-[#0a0a0a] text-gray-300 overflow-y-auto store-page">
      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between mb-4 md:mb-6 gap-3">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl md:text-3xl font-['Orbitron'] font-bold text-white tracking-wider">SKIN STORE</h1>
            {session && balance !== null && (
              <span className="flex items-center gap-1 text-xs bg-red-900/20 border border-red-900/30 px-2 py-1 rounded">
                <span className="text-neutral-500 uppercase tracking-wider">Balance:</span>
                <span className="text-red-400 font-bold font-['Orbitron']">{balance.toLocaleString()} Ⓜ</span>
              </span>
            )}
          </div>
          <div className="flex gap-1 bg-[#141414] rounded-lg border border-neutral-800 p-0.5 self-start md:self-auto">
            <button onClick={() => setTab('skins')} className={`px-3 md:px-4 py-1.5 rounded-md text-xs font-bold uppercase tracking-wider transition-all ${tab === 'skins' ? 'bg-red-900/40 text-white' : 'text-neutral-500 hover:text-neutral-300'}`}>
              <ShoppingBag className="w-3.5 h-3.5 inline mr-1.5" /><span className="hidden sm:inline">Skins</span>
            </button>
            <button onClick={() => setTab('commands')} className={`px-3 md:px-4 py-1.5 rounded-md text-xs font-bold uppercase tracking-wider transition-all ${tab === 'commands' ? 'bg-red-900/40 text-white' : 'text-neutral-500 hover:text-neutral-300'}`}>
              <Zap className="w-3.5 h-3.5 inline mr-1.5" /><span className="hidden sm:inline">Commands</span>
            </button>
          </div>
          <Link href="/store/submit" className="bg-red-700 hover:bg-red-600 text-white px-4 md:px-5 py-2 md:py-2.5 rounded text-xs font-bold uppercase tracking-wider transition-all self-start md:self-auto">
            Submit
          </Link>
        </div>

        {tab === 'skins' && (
          <div>
            <p className="text-sm text-neutral-500 mb-6">{total} approved products</p>
            <div className="flex flex-col sm:flex-row gap-3 mb-6">
              <div className="relative flex-1 min-w-[200px]">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-500" />
                <input type="text" placeholder="Search skins..." value={search}
                  onChange={e => { setSearch(e.target.value); setPage(1); }}
                  className="w-full bg-[#141414] border border-neutral-800 rounded-lg pl-10 pr-4 py-2.5 text-sm text-white focus:border-red-700 outline-none" />
              </div>
          <select value={species} onChange={e => { setSpecies(e.target.value); setPage(1); }}
            className="bg-[#141414] border border-neutral-800 rounded-lg px-3 py-2.5 text-sm text-white outline-none focus:border-red-700">
            {SPECIES.map(s => <option key={s} value={s} className="bg-[#141414]">{s}</option>)}
          </select>
          <select value={sort} onChange={e => setSort(e.target.value)}
            className="bg-[#141414] border border-neutral-800 rounded-lg px-3 py-2.5 text-sm text-white outline-none focus:border-red-700">
                <option value="newest">Newest</option>
                <option value="popular">Most Popular</option>
                <option value="cheapest">Cheapest</option>
              </select>
            </div>
            {loading ? (
              <div className="text-center py-20 text-neutral-500">Loading...</div>
            ) : products.length === 0 ? (
              <div className="text-center py-20">
                <ShoppingBag className="w-12 h-12 mx-auto mb-4 text-neutral-700" />
                <p className="text-neutral-500">No products found. Be the first to submit!</p>
                <Link href="/store/submit" className="inline-block mt-4 text-red-400 hover:text-red-300 text-sm font-bold">Submit a Skin →</Link>
              </div>
            ) : (
              <div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-5">
                  {products.map(product => (
                    <Link key={product.id} href={`/store/${product.id}`} className="group bg-[#141414] border border-neutral-800/60 rounded-xl overflow-hidden hover:border-red-900/50 hover:shadow-[0_0_20px_rgba(220,38,38,0.1)] transition-all">
                      <div className="aspect-[4/3] bg-[#0a0a0a] flex items-center justify-center overflow-hidden">
                        {product.thumbnail_url ? (
                          <img src={product.thumbnail_url} alt={product.skin_name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                        ) : (
                          <div className="text-center p-4">
                            <ShoppingBag className="w-10 h-10 mx-auto mb-2 text-neutral-700" />
                            <p className="text-xs text-neutral-600">{product.species}</p>
                          </div>
                        )}
                      </div>
                      <div className="p-4">
                        <h3 className="font-bold text-white text-sm truncate">{product.skin_name}</h3>
                        <div className="flex items-center justify-between mt-2">
                          <span className="text-xs text-neutral-400">{product.species}</span>
                          <span className="text-sm font-bold text-red-400">{product.price.toLocaleString()} Ⓜ</span>
                        </div>
                        <div className="flex items-center justify-between mt-1">
                          <span className="text-[10px] text-neutral-600">{product.sales || 0} sold · {product.view_count || 0} views</span>
                          {product.rarity_tier && product.rarity_tier !== 'common' && (
                            <span className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded border ${
                              product.rarity_tier === 'legendary' ? 'bg-yellow-900/30 text-yellow-400 border-yellow-700' :
                              product.rarity_tier === 'rare' ? 'bg-purple-900/30 text-purple-400 border-purple-700' :
                              'bg-blue-900/30 text-blue-400 border-blue-700'
                            }`}>{product.rarity_tier}</span>
                          )}
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
                {totalPages > 1 && (
                  <div className="flex justify-center gap-2 mt-8">
                    {Array.from({ length: totalPages }, (_, i) => (
                      <button key={i} onClick={() => setPage(i + 1)}
                        className={`w-9 h-9 rounded text-xs font-bold ${page === i + 1 ? 'bg-red-700 text-white' : 'bg-[#141414] text-neutral-400 hover:text-white border border-neutral-800'}`}>
                        {i + 1}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {tab === 'commands' && (
          <div className="space-y-3">
            <p className="text-sm text-neutral-500 mb-4">Available commands — use on Discord with Sinister Park Services or type them in-game.</p>
            <div className="overflow-x-auto max-h-[60vh] overflow-y-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="border-b border-neutral-800 text-xs text-neutral-500 uppercase tracking-wider sticky top-0 bg-[#0a0a0a]">
                    <th className="py-3 px-4">Command</th>
                    <th className="py-3 px-4">Effect</th>
                    <th className="py-3 px-4 text-right">Cost</th>
                    <th className="py-3 px-4 text-right">Cooldown</th>
                  </tr>
                </thead>
                <tbody>
                  {commands.slice(cmdPage * perPage, (cmdPage + 1) * perPage).map((cmd, i) => (
                    <tr key={i} className="border-b border-neutral-800/50 text-sm hover:bg-[#141414] transition-colors">
                      <td className="py-3 px-4 font-mono text-red-400 font-bold">/{cmd.key}</td>
                      <td className="py-3 px-4 text-neutral-300">{cmd.effect}</td>
                      <td className="py-3 px-4 text-right text-white font-bold">{cmd.cost === 0 ? <span className="text-green-400">FREE</span> : `${cmd.cost.toLocaleString()} Ⓜ`}</td>
                      <td className="py-3 px-4 text-right text-neutral-500">{cmd.cooldown_minutes === 0 ? 'None' : cmd.cooldown_minutes >= 60 ? `${cmd.cooldown_minutes / 60}h` : `${cmd.cooldown_minutes}m`}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="flex items-center justify-between mt-2">
              <span className="text-[10px] text-neutral-500">{cmdPage * perPage + 1}-{Math.min((cmdPage + 1) * perPage, commands.length)} of {commands.length}</span>
              <div className="flex gap-1">
                <button onClick={() => setCmdPage(Math.max(0, cmdPage - 1))} disabled={cmdPage === 0} className="px-2 py-1 rounded text-[10px] font-bold bg-[#141414] border border-neutral-800 disabled:opacity-30 text-neutral-400 hover:text-white">← Prev</button>
                <button onClick={() => setCmdPage(Math.min(Math.ceil(commands.length / perPage) - 1, cmdPage + 1))} disabled={(cmdPage + 1) * perPage >= commands.length} className="px-2 py-1 rounded text-[10px] font-bold bg-[#141414] border border-neutral-800 disabled:opacity-30 text-neutral-400 hover:text-white">Next →</button>
              </div>
            </div>
            <div className="bg-[#141414] border border-neutral-800 rounded-lg p-4 mt-6">
              <p className="text-xs text-neutral-400">
                <span className="text-red-400 font-bold">Tip:</span> On Discord, say <code className="bg-black/30 px-1 rounded text-red-300">"hey sin i need stamina"</code> — Sinister Park Services understands natural language.
              </p>
            </div>

            {isAdmin && (
              <div className="mt-6">
                <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                  <Shield className="w-4 h-4 text-red-400" /> Admin Commands
                </h3>
                <div className="overflow-x-auto max-h-[40vh] overflow-y-auto">
                  <table className="w-full text-left">
                    <thead>
                      <tr className="border-b border-neutral-800 text-xs text-neutral-500 uppercase tracking-wider sticky top-0 bg-[#0a0a0a]">
                        <th className="py-3 px-4">Command</th>
                        <th className="py-3 px-4">Effect</th>
                        <th className="py-3 px-4 text-right">Cost</th>
                      </tr>
                    </thead>
                    <tbody>
                      {ADMIN_COMMANDS.slice(adminPage * perPage, (adminPage + 1) * perPage).map((cmd, i) => (
                        <tr key={i} className="border-b border-neutral-800/50 text-sm hover:bg-[#141414] transition-colors">
                          <td className="py-3 px-4 font-mono text-yellow-400 font-bold">/{cmd.key}</td>
                          <td className="py-3 px-4 text-neutral-300">{cmd.effect}</td>
                          <td className="py-3 px-4 text-right text-green-400 font-bold text-xs">ADMIN</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-[10px] text-neutral-500">{adminPage * perPage + 1}-{Math.min((adminPage + 1) * perPage, ADMIN_COMMANDS.length)} of {ADMIN_COMMANDS.length}</span>
                  <div className="flex gap-1">
                    <button onClick={() => setAdminPage(Math.max(0, adminPage - 1))} disabled={adminPage === 0} className="px-2 py-1 rounded text-[10px] font-bold bg-[#141414] border border-neutral-800 disabled:opacity-30 text-neutral-400 hover:text-white">← Prev</button>
                    <button onClick={() => setAdminPage(Math.min(Math.ceil(ADMIN_COMMANDS.length / perPage) - 1, adminPage + 1))} disabled={(adminPage + 1) * perPage >= ADMIN_COMMANDS.length} className="px-2 py-1 rounded text-[10px] font-bold bg-[#141414] border border-neutral-800 disabled:opacity-30 text-neutral-400 hover:text-white">Next →</button>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
