'use client';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useSession, signIn } from 'next-auth/react';
import dynamic from 'next/dynamic';
import { ShoppingCart, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

const SkinViewer3D = dynamic(() => import('../../../components/SkinViewer3D'), { ssr: false });

export default function ProductDetailPage() {
  const { id } = useParams();
  const { data: session } = useSession();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [steamId, setSteamId] = useState(null);
  const [balance, setBalance] = useState(null);
  const [buyState, setBuyState] = useState('idle');

  useEffect(() => {
    fetch(`/api/store/products/${id}`).then(r => r.json()).then(d => {
      if (d.success) setProduct(d.data);
    }).catch(console.error).finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`).then(r => r.json()).then(d => {
        if (d.steam_id) setSteamId(d.steam_id);
      }).catch(() => {});
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

  const handleBuy = async () => {
    if (!steamId) { alert('Connect Discord first.'); return; }
    setBuyState('confirm');
  };

  const confirmBuy = async () => {
    setBuyState('buying');
    try {
      const res = await fetch('/api/store/purchases', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ buyer_steam_id: steamId, product_id: id }),
      });
      const d = await res.json();
      if (d.success) { setBuyState('done'); }
      else { alert(d.error); setBuyState('idle'); }
    } catch (e) { alert('Purchase failed'); setBuyState('idle'); }
  };

  if (loading) return <div className="min-h-full bg-[#0a0a0a] flex items-center justify-center text-neutral-500">Loading...</div>;
  if (!product) return <div className="min-h-full bg-[#0a0a0a] flex items-center justify-center text-neutral-500">Product not found</div>;

  return (
    <div className="min-h-full bg-[#0a0a0a] text-gray-300 overflow-y-auto">
      <div className="max-w-6xl mx-auto px-6 py-8">
        <Link href="/store" className="inline-flex items-center gap-2 text-neutral-500 hover:text-white text-sm mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to Store
        </Link>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* 3D Preview */}
          <div className="h-[500px] bg-[#141414] rounded-xl border border-neutral-800 overflow-hidden">
            {product.skin_data ? (
              <SkinViewer3D skin={product.skin_data} dinoModel={product.species} materialPreset={product.material_preset || 'matte'} />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-neutral-600">
                <ShoppingCart className="w-16 h-16" />
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex flex-col gap-6">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <span className={`text-xs font-bold uppercase px-2 py-0.5 rounded ${product.status === 'approved' ? 'bg-green-900/30 text-green-400 border border-green-900/50' : 'bg-yellow-900/30 text-yellow-400 border border-yellow-900/50'}`}>
                  {product.status}
                </span>
                <span className="text-xs text-neutral-500">{product.sales || 0} sold</span>
              </div>
              <h1 className="text-3xl font-['Orbitron'] font-bold text-white">{product.skin_name}</h1>
              <p className="text-neutral-400 mt-1">{product.species}</p>
            </div>

            <div className="text-4xl font-bold text-red-400 font-['Orbitron']">
              {product.price.toLocaleString()} <span className="text-lg">Ⓜ marks</span>
            </div>

            {session && balance !== null && (
              <div className={`flex items-center gap-2 text-sm font-bold ${
                balance >= product.price ? 'text-green-400' : 'text-red-400'
              }`}>
                <span>Your Balance: {balance.toLocaleString()} Ⓜ</span>
                {balance >= product.price ? (
                  <span className="text-green-500">&#10003; Enough</span>
                ) : (
                  <span className="text-red-500">Need {(product.price - balance).toLocaleString()} more</span>
                )}
              </div>
            )}

            {product.description && (
              <div className="bg-[#141414] border border-neutral-800 rounded-lg p-4">
                <h3 className="text-xs font-bold text-neutral-500 uppercase tracking-wider mb-2">Description</h3>
                <p className="text-sm text-neutral-300">{product.description}</p>
              </div>
            )}

            <div className="bg-[#141414] border border-neutral-800 rounded-lg p-4 text-xs text-neutral-500">
              Material: <span className="text-white capitalize">{product.material_preset || 'matte'}</span>
              <span className="mx-3">|</span>
              Pattern: <span className="text-white">PT:{product.pattern_type ?? 0}</span>
            </div>

            {!session ? (
              <button onClick={() => signIn('discord')} className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white py-3.5 rounded-lg font-bold text-sm uppercase tracking-wider transition-all flex items-center justify-center gap-2">
                Connect Discord to Buy
              </button>
            ) : buyState === 'done' ? (
              <div className="w-full bg-green-900/30 border border-green-900/50 text-green-400 p-4 rounded-lg text-center">
                <p className="font-bold text-sm">Purchase Complete!</p>
                <p className="text-xs mt-1">Skin added to your presets. Use <code className="bg-black/30 px-1 rounded">!applyskin &quot;{product.skin_name} (Store)&quot;</code> in Discord.</p>
              </div>
            ) : buyState === 'confirm' ? (
              <div className="w-full bg-yellow-900/20 border border-yellow-900/50 rounded-lg p-4">
                <p className="text-sm text-yellow-400 mb-3">Confirm purchase of <strong>{product.skin_name}</strong> for <strong>{product.price.toLocaleString()} marks</strong>?</p>
                <div className="flex gap-3">
                  <button onClick={confirmBuy} className="flex-1 bg-red-700 hover:bg-red-600 text-white py-2.5 rounded font-bold text-sm uppercase tracking-wider transition-all">Yes, Buy Now</button>
                  <button onClick={() => setBuyState('idle')} className="px-4 py-2.5 bg-neutral-800 hover:bg-neutral-700 text-neutral-400 rounded text-sm transition-colors">Cancel</button>
                </div>
              </div>
            ) : (
              <button onClick={handleBuy} disabled={!steamId} className="w-full bg-red-700 hover:bg-red-600 disabled:bg-neutral-800 disabled:text-neutral-600 text-white py-3.5 rounded-lg font-bold text-sm uppercase tracking-wider transition-all flex items-center justify-center gap-2">
                <ShoppingCart className="w-4 h-4" /> Buy for {product.price.toLocaleString()} Marks
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
