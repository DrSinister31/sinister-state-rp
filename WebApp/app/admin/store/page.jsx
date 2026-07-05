'use client';
import { useState, useEffect } from 'react';
import { useSession, signIn } from 'next-auth/react';
import Link from 'next/link';
import { ArrowLeft, Check, X, AlertTriangle, Trash2, RefreshCw, Store, Clock } from 'lucide-react';

const STATUS_COLORS = { pending: 'bg-yellow-900/30 text-yellow-400 border-yellow-900/50', approved: 'bg-green-900/30 text-green-400 border-green-900/50', rejected: 'bg-red-900/30 text-red-400 border-red-900/50', nsfw_renamed: 'bg-purple-900/30 text-purple-400 border-purple-900/50' };

export default function AdminStorePage() {
  const { data: session } = useSession();
  const [steamId, setSteamId] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [pendingProducts, setPendingProducts] = useState([]);
  const [approvedProducts, setApprovedProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('pending');
  const [rejectReason, setRejectReason] = useState({});
  const [renameName, setRenameName] = useState({});
  const [newPrices, setNewPrices] = useState({});
  const [msg, setMsg] = useState(null);

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`).then(r => r.json())
        .then(d => { if (d.steam_id) setSteamId(d.steam_id); }).catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    if (!steamId) return;
    setLoading(true);
    Promise.all([
      fetch(`/api/store/pending?admin_steam_id=${steamId}`).then(r => r.json()),
      fetch(`/api/store/products?limit=100&sort=newest`).then(r => r.json()),
    ]).then(([pending, approved]) => {
      if (pending.success) { setPendingProducts(pending.data); setIsAdmin(true); }
      else if (pending.error === 'Admin access required') setIsAdmin(false);
      if (approved.success) setApprovedProducts(approved.data.filter(p => p.status === 'approved'));
    }).catch(() => {}).finally(() => setLoading(false));
  }, [steamId]);

  const updateStatus = async (productId, status, admin_notes = null) => {
    const res = await fetch(`/api/store/products/${productId}/status`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ admin_steam_id: steamId, status, admin_notes }),
    });
    const d = await res.json();
    if (d.success) setPendingProducts(prev => prev.filter(p => p.id !== productId));
    else alert(d.error);
  };

  const removeProduct = async (productId) => {
    if (!confirm('Permanently delete this product?')) return;
    await fetch(`/api/store/products/${productId}?steam_id=${steamId}`, { method: 'DELETE' });
    setApprovedProducts(prev => prev.filter(p => p.id !== productId));
    setMsg({ ok: true, text: 'Product removed' }); setTimeout(() => setMsg(null), 3000);
  };

  const updatePrice = async (productId, newPrice) => {
    const res = await fetch(`/api/store/products/${productId}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ steam_id: steamId, price: parseInt(newPrice) }),
    });
    const d = await res.json();
    if (d.success) {
      setApprovedProducts(prev => prev.map(p => p.id === productId ? { ...p, price: parseInt(newPrice) } : p));
      setMsg({ ok: true, text: 'Price updated' }); setTimeout(() => setMsg(null), 3000);
    } else alert(d.error);
  };

  const reEvaluate = async () => {
    setMsg({ ok: true, text: 'Re-evaluating...' });
    const res = await fetch('/api/store/evaluate');
    const d = await res.json();
    if (d.success) {
      // Refresh approved products
      const r = await fetch('/api/store/products?limit=100').then(r => r.json());
      if (r.success) setApprovedProducts(r.data.filter(p => p.status === 'approved'));
      setMsg({ ok: true, text: `Re-evaluated ${d.updated} products` });
    }
    setTimeout(() => setMsg(null), 4000);
  };

  if (!session) {
    return (<div className="min-h-full bg-[#0a0a0a] flex items-center justify-center">
      <button onClick={() => signIn('discord')} className="bg-[#5865F2] hover:bg-[#4752C4] text-white px-6 py-3 rounded-lg font-bold text-sm uppercase">Connect Discord</button>
    </div>);
  }
  if (loading) return <div className="min-h-full bg-[#0a0a0a] flex items-center justify-center text-neutral-500">Checking permissions...</div>;
  if (!isAdmin) return <div className="min-h-full bg-[#0a0a0a] flex items-center justify-center text-red-400 font-bold">Access Denied</div>;

  return (
    <div className="min-h-full bg-[#0a0a0a] text-gray-300 overflow-y-auto admin-page">
      <div className="max-w-6xl mx-auto px-6 py-8">
        <Link href="/store" className="inline-flex items-center gap-2 text-neutral-500 hover:text-white text-sm mb-4 transition-colors"><ArrowLeft className="w-4 h-4" /> Back to Store</Link>

        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-['Orbitron'] font-bold text-white">Store Admin</h1>
          <div className="flex gap-1 bg-[#141414] rounded-lg border border-neutral-800 p-0.5">
            <button onClick={() => setTab('pending')} className={`px-4 py-1.5 rounded-md text-xs font-bold uppercase tracking-wider transition-all ${tab==='pending'?'bg-red-900/40 text-white':'text-neutral-500 hover:text-neutral-300'}`}>
              <Clock className="w-3.5 h-3.5 inline mr-1.5" /> Pending ({pendingProducts.length})
            </button>
            <button onClick={() => setTab('manage')} className={`px-4 py-1.5 rounded-md text-xs font-bold uppercase tracking-wider transition-all ${tab==='manage'?'bg-red-900/40 text-white':'text-neutral-500 hover:text-neutral-300'}`}>
              <Store className="w-3.5 h-3.5 inline mr-1.5" /> Manage Live ({approvedProducts.length})
            </button>
          </div>
        </div>

        {msg && <div className={`mb-4 p-3 rounded-lg text-sm font-bold ${msg.ok?'bg-green-900/30 text-green-400 border border-green-900/50':'bg-red-900/30 text-red-400 border border-red-900/50'}`}>{msg.text}</div>}

        {tab === 'pending' && (
          pendingProducts.length === 0 ? (
            <div className="bg-[#141414] border border-neutral-800 rounded-xl p-10 text-center"><p className="text-neutral-400">No products pending review.</p></div>
          ) : (
            <div className="space-y-5">
              {pendingProducts.map(p => (
                <div key={p.id} className="bg-[#141414] border border-neutral-800 rounded-xl p-5">
                  <div className="flex gap-5 items-start">
                    <div className="w-20 h-20 bg-[#0a0a0a] rounded-lg shrink-0 flex items-center justify-center text-neutral-600 text-xs">{p.thumbnail_url ? <img src={p.thumbnail_url} alt="" className="w-full h-full object-cover rounded-lg" /> : p.species}</div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-bold text-white text-lg">{p.skin_name}</h3>
                      <p className="text-sm text-neutral-400">{p.species} · {p.price?.toLocaleString()} marks · Seller: {p.steam_id}</p>
                      {p.description && <p className="text-xs text-neutral-500 mt-1">{p.description}</p>}
                    </div>
                  </div>
                  <div className="flex gap-3 mt-4 pt-4 border-t border-neutral-800 flex-wrap">
                    <button onClick={() => updateStatus(p.id, 'approved')} className="flex items-center gap-1.5 bg-green-700 hover:bg-green-600 text-white px-4 py-2 rounded-lg text-xs font-bold uppercase tracking-wider"><Check className="w-3.5 h-3.5" /> Approve</button>
                    <div className="flex items-center gap-2 flex-1 min-w-[200px]">
                      <input placeholder="Rejection reason..." value={rejectReason[p.id] || ''} onChange={e => setRejectReason(prev => ({...prev,[p.id]:e.target.value}))} className="flex-1 bg-[#0a0a0a] border border-neutral-800 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-red-700" />
                      <button onClick={() => updateStatus(p.id, 'rejected', rejectReason[p.id] || null)} className="flex items-center gap-1.5 bg-red-900/50 hover:bg-red-800 text-red-300 px-4 py-2 rounded-lg text-xs font-bold uppercase"><X className="w-3.5 h-3.5" /> Reject</button>
                    </div>
                    <div className="flex items-center gap-2">
                      <input placeholder="New name..." value={renameName[p.id] || ''} onChange={e => setRenameName(prev => ({...prev,[p.id]:e.target.value}))} className="bg-[#0a0a0a] border border-neutral-800 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-purple-700 w-36" />
                      <button onClick={() => renameName[p.id] && updateStatus(p.id, 'nsfw_renamed', renameName[p.id])} className="flex items-center gap-1.5 bg-purple-900/50 hover:bg-purple-800 text-purple-300 px-4 py-2 rounded-lg text-xs font-bold uppercase"><AlertTriangle className="w-3.5 h-3.5" /> Rename</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )
        )}

        {tab === 'manage' && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <p className="text-sm text-neutral-500">{approvedProducts.length} approved products</p>
              <button onClick={reEvaluate} className="flex items-center gap-1.5 bg-yellow-700 hover:bg-yellow-600 text-white px-4 py-2 rounded-lg text-xs font-bold uppercase tracking-wider"><RefreshCw className="w-3.5 h-3.5" /> Re-Evaluate All Prices</button>
            </div>
            <div className="space-y-3">
              {approvedProducts.map(p => (
                <div key={p.id} className="bg-[#141414] border border-neutral-800 rounded-xl p-4 flex items-center gap-4">
                  <div className="w-14 h-14 bg-[#0a0a0a] rounded-lg shrink-0 flex items-center justify-center text-neutral-600 text-[10px]">{p.species}</div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-bold text-white text-sm truncate">{p.skin_name}</h3>
                    <div className="flex items-center gap-3 mt-0.5 text-xs">
                      <span className="text-neutral-500">{p.species}</span>
                      {p.rarity_tier && p.rarity_tier !== 'common' && <span className={`px-1.5 py-0.5 rounded border text-[10px] font-bold uppercase ${p.rarity_tier==='legendary'?'bg-yellow-900/30 text-yellow-400 border-yellow-700':p.rarity_tier==='rare'?'bg-purple-900/30 text-purple-400 border-purple-700':'bg-blue-900/30 text-blue-400 border-blue-700'}`}>{p.rarity_tier}</span>}
                      <span className="text-neutral-600">{p.sales||0} sold · {p.view_count||0} views</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <input type="number" min="100" value={newPrices[p.id] ?? p.price} onChange={e => setNewPrices(prev => ({...prev,[p.id]:e.target.value}))} className="w-24 bg-[#0a0a0a] border border-neutral-800 rounded px-2 py-1.5 text-xs text-white text-center outline-none focus:border-red-700" />
                    <button onClick={() => updatePrice(p.id, newPrices[p.id] ?? p.price)} className="bg-red-900/40 hover:bg-red-800 text-red-300 px-3 py-1.5 rounded text-[10px] font-bold uppercase">Update</button>
                    <button onClick={() => removeProduct(p.id)} className="p-1.5 bg-neutral-800 hover:bg-red-900/50 rounded text-neutral-400 hover:text-red-400 transition-colors"><Trash2 className="w-4 h-4" /></button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
