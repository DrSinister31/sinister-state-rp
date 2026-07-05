'use client';
import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useSession, signIn } from 'next-auth/react';
import { ArrowLeft, Upload } from 'lucide-react';
import Link from 'next/link';

function SubmitForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session } = useSession();
  const [steamId, setSteamId] = useState(null);
  const [skinName, setSkinName] = useState('');
  const [species, setSpecies] = useState('');
  const [price, setPrice] = useState(5000);
  const [description, setDescription] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [skinData, setSkinData] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [msg, setMsg] = useState(null);

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`).then(r => r.json())
        .then(d => { if (d.steam_id) setSteamId(d.steam_id); }).catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    const name = searchParams.get('skin_name');
    const spec = searchParams.get('species');
    const data = searchParams.get('skin_data');
    if (name) setSkinName(name);
    if (spec) setSpecies(spec);
    if (data) {
      try { setSkinData(JSON.parse(decodeURIComponent(data))); } catch {}
    }
    const thumb = searchParams.get('thumbnail');
    if (thumb) setThumbnailUrl(decodeURIComponent(thumb));
  }, [searchParams]);

  const handleSubmit = async () => {
    if (!steamId) { alert('Connect Discord first.'); return; }
    if (!skinName.trim()) { alert('Enter a skin name.'); return; }
    if (!skinData) { alert('No skin data provided. Create a skin in the editor first.'); return; }
    if (price < 100) { alert('Minimum price is 100 marks.'); return; }
    setSubmitting(true);
    try {
      const res = await fetch('/api/store/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          steam_id: steamId, skin_name: skinName.trim(), species: species || 'Unknown',
          skin_data: skinData, price, description: description.trim(), thumbnail_url: thumbnailUrl,
        }),
      });
      const d = await res.json();
      if (d.success) {
        setMsg({ ok: true, text: 'Product submitted for approval!' });
        setTimeout(() => router.push('/store/my-skins'), 1500);
      } else {
        setMsg({ ok: false, text: d.error || 'Submit failed' });
      }
    } catch (e) {
      setMsg({ ok: false, text: 'Submit failed' });
    }
    setSubmitting(false);
  };

  return (
    <div className="min-h-full bg-[#0a0a0a] text-gray-300 overflow-y-auto">
      <div className="max-w-2xl mx-auto px-6 py-8">
        <Link href="/store" className="inline-flex items-center gap-2 text-neutral-500 hover:text-white text-sm mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to Store
        </Link>

        <h1 className="text-2xl font-['Orbitron'] font-bold text-white mb-1">Submit Skin to Store</h1>
        <p className="text-sm text-neutral-500 mb-8">Skins require admin approval before appearing in the store.</p>

        {!session ? (
          <button onClick={() => signIn('discord')} className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white py-3 rounded-lg font-bold text-sm">
            Connect Discord to Submit
          </button>
        ) : skinData ? (
          <div className="space-y-5">
            <div>
              <label className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Skin Name *</label>
              <input value={skinName} onChange={e => setSkinName(e.target.value.slice(0, 64))}
                className="w-full bg-[#141414] border border-neutral-800 rounded-lg p-3 text-sm text-white mt-1.5 outline-none focus:border-red-700" placeholder="e.g. Nightscale Rex" />
            </div>
            <div>
              <label className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Species</label>
              <input value={species} onChange={e => setSpecies(e.target.value)}
                className="w-full bg-[#141414] border border-neutral-800 rounded-lg p-3 text-sm text-white mt-1.5 outline-none focus:border-red-700" placeholder="e.g. Tyrannosaurus" />
            </div>
            <div>
              <label className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Price (marks) *</label>
              <input type="number" min="100" value={price} onChange={e => setPrice(parseInt(e.target.value) || 0)}
                className="w-full bg-[#141414] border border-neutral-800 rounded-lg p-3 text-sm text-white mt-1.5 outline-none focus:border-red-700" />
            </div>
            <div>
              <label className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Description</label>
              <textarea value={description} onChange={e => setDescription(e.target.value)}
                className="w-full bg-[#141414] border border-neutral-800 rounded-lg p-3 text-sm text-white mt-1.5 outline-none focus:border-red-700 h-24 resize-none" placeholder="Describe your skin..." />
            </div>
            <div>
              <label className="text-xs font-bold text-neutral-500 uppercase tracking-wider">Thumbnail {thumbnailUrl && '(Auto-captured)'}</label>
              {thumbnailUrl && thumbnailUrl.startsWith('data:image') && (
                <img src={thumbnailUrl} alt="Preview" className="w-full h-24 object-cover rounded-lg border border-neutral-700 mt-1.5 mb-2" />
              )}
              <input value={thumbnailUrl} onChange={e => setThumbnailUrl(e.target.value)}
                className="w-full bg-[#141414] border border-neutral-800 rounded-lg p-3 text-sm text-white mt-1.5 outline-none focus:border-red-700" placeholder="Auto-captured from skin editor" />
            </div>
            {msg && (
              <div className={`p-3 rounded-lg text-sm font-bold ${msg.ok ? 'bg-green-900/30 text-green-400 border border-green-900/50' : 'bg-red-900/30 text-red-400 border border-red-900/50'}`}>
                {msg.text}
              </div>
            )}
            <button onClick={handleSubmit} disabled={submitting}
              className="w-full bg-red-700 hover:bg-red-600 disabled:opacity-50 text-white py-3 rounded-lg font-bold text-sm uppercase tracking-wider transition-all">
              {submitting ? 'Submitting...' : 'Submit for Approval'}
            </button>
          </div>
        ) : (
          <div className="bg-[#141414] border border-neutral-800 rounded-xl p-10 text-center">
            <Upload className="w-12 h-12 mx-auto mb-4 text-neutral-700" />
            <p className="text-neutral-400 mb-4">No skin data provided. Create a skin in the editor first, then click "Submit to Store."</p>
            <Link href="/skin-creator" className="inline-block bg-red-700 hover:bg-red-600 text-white px-6 py-2.5 rounded text-sm font-bold uppercase tracking-wider transition-all">
              Go to Skin Creator
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}

export default function SubmitPage() {
  return (
    <Suspense fallback={<div className="min-h-full bg-[#0a0a0a] flex items-center justify-center text-neutral-500">Loading...</div>}>
      <SubmitForm />
    </Suspense>
  );
}
