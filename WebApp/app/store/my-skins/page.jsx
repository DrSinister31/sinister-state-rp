'use client';
import { useState, useEffect } from 'react';
import { useSession, signIn } from 'next-auth/react';
import Link from 'next/link';
import { ArrowLeft, Edit, Trash2 } from 'lucide-react';

const STATUS_COLORS = {
  pending: 'bg-yellow-900/30 text-yellow-400 border-yellow-900/50',
  approved: 'bg-green-900/30 text-green-400 border-green-900/50',
  rejected: 'bg-red-900/30 text-red-400 border-red-900/50',
  nsfw_renamed: 'bg-purple-900/30 text-purple-400 border-purple-900/50',
};

export default function MySkinsPage() {
  const { data: session } = useSession();
  const [steamId, setSteamId] = useState(null);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`).then(r => r.json())
        .then(d => { if (d.steam_id) setSteamId(d.steam_id); }).catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    if (!steamId) return;
    setLoading(true);
    fetch(`/api/store/my-products?steam_id=${steamId}`).then(r => r.json())
      .then(d => { if (d.success) setProducts(d.data); }).catch(console.error)
      .finally(() => setLoading(false));
  }, [steamId]);

  const handleDelete = async (id) => {
    if (!confirm('Delete this product?')) return;
    await fetch(`/api/store/products/${id}?steam_id=${steamId}`, { method: 'DELETE' });
    setProducts(prev => prev.filter(p => p.id !== id));
  };

  if (!session) {
    return (
      <div className="min-h-full bg-[#0a0a0a] flex items-center justify-center">
        <button onClick={() => signIn('discord')} className="bg-[#5865F2] hover:bg-[#4752C4] text-white px-6 py-3 rounded-lg font-bold text-sm uppercase tracking-wider">
          Connect Discord
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-full bg-[#0a0a0a] text-gray-300 overflow-y-auto">
      <div className="max-w-4xl mx-auto px-6 py-8">
        <Link href="/store" className="inline-flex items-center gap-2 text-neutral-500 hover:text-white text-sm mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to Store
        </Link>

        <h1 className="text-2xl font-['Orbitron'] font-bold text-white mb-6">My Store Products</h1>

        {loading ? <p className="text-neutral-500">Loading...</p> : products.length === 0 ? (
          <div className="bg-[#141414] border border-neutral-800 rounded-xl p-10 text-center">
            <p className="text-neutral-400 mb-4">You haven't submitted any products yet.</p>
            <Link href="/store/submit" className="inline-block bg-red-700 hover:bg-red-600 text-white px-6 py-2.5 rounded text-sm font-bold uppercase tracking-wider transition-all">
              Submit a Skin
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {products.map(p => (
              <div key={p.id} className="bg-[#141414] border border-neutral-800 rounded-xl p-5 flex gap-5 items-start">
                <div className="w-24 h-24 bg-[#0a0a0a] rounded-lg shrink-0 flex items-center justify-center overflow-hidden">
                  {p.thumbnail_url ? (
                    <img src={p.thumbnail_url} alt={p.skin_name} className="w-full h-full object-cover" />
                  ) : (
                    <span className="text-xs text-neutral-600">{p.species}</span>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-bold text-white truncate">{p.skin_name}</h3>
                    <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded border ${STATUS_COLORS[p.status] || ''}`}>
                      {p.status === 'nsfw_renamed' ? 'Flagged' : p.status}
                    </span>
                  </div>
                  <p className="text-xs text-neutral-500">{p.species} · {p.price.toLocaleString()} marks · {p.sales || 0} sold</p>
                  {p.admin_notes && <p className="text-xs text-yellow-400 mt-1">Admin note: {p.admin_notes}</p>}
                  {p.status === 'nsfw_renamed' && <p className="text-xs text-purple-400 mt-1">This product has been flagged. Editing is locked.</p>}
                  <p className="text-[10px] text-neutral-600 mt-1">{new Date(p.created_at).toLocaleDateString()}</p>
                </div>
                <div className="flex gap-2 shrink-0">
                  {p.status !== 'nsfw_renamed' && (
                    <Link href={`/store/submit?skin_name=${encodeURIComponent(p.skin_name)}&species=${encodeURIComponent(p.species)}&edit=${p.id}`}
                      className="p-2 bg-neutral-800 hover:bg-neutral-700 rounded-lg text-neutral-400 hover:text-white transition-colors" title="Edit">
                      <Edit className="w-4 h-4" />
                    </Link>
                  )}
                  <button onClick={() => handleDelete(p.id)}
                    className="p-2 bg-neutral-800 hover:bg-red-900/50 rounded-lg text-neutral-400 hover:text-red-400 transition-colors" title="Delete">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
