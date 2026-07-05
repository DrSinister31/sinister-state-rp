"use client";

import React, { useState, useEffect, useCallback, useRef } from 'react';
import dynamic from 'next/dynamic';
import { HexColorPicker } from 'react-colorful';
import { vectorStringToHex, hexToVectorString, parseEvrimaSkinCode } from '../../utils/color';
import { useSession, signIn } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { Send, Upload, Download, Trash2, AlertTriangle, Plus, Image, X, Store } from 'lucide-react';

const SkinViewer3D = dynamic(() => import('../../components/SkinViewer3D'), { ssr: false });

const LAYER_DEFINITIONS = [
  { id: 'b', name: 'Base Layer' },
  { id: 'u', name: 'Underbelly' },
  { id: 'm', name: 'Markings' },
  { id: 'md', name: 'Detail Accent' },
  { id: 'f', name: 'Feature (Spots)' },
  { id: 'd1', name: 'Detail 1' },
  { id: 'e', name: 'Eye Color' },
];

const MATERIAL_PRESETS = [
  { id: 'matte', name: 'Matte (Standard)' },
  { id: 'glossy', name: 'Glossy (Wet)' },
  { id: 'metallic', name: 'Metallic' },
  { id: 'chrome', name: 'Chrome (Mirror)' },
  { id: 'neon', name: 'Neon (Emissive)' }
];

const PATTERN_TYPES = [
  { id: 0, name: 'PT:A (Standard)' },
  { id: 1, name: 'PT:B (Striped)' },
  { id: 2, name: 'Custom: Leopard Spots' },
  { id: 3, name: 'Custom: Cybernetic' },
];

const DEFAULT_VECTORS = {
  sv: 0,
  pi: 1,
  md: 'X=0,Y=0,Z=0',
  m: 'X=0,Y=0,Z=0',
  b: 'X=0.03,Y=0.03,Z=0.03',
  f: 'X=0,Y=0,Z=0',
  u: 'X=0.8,Y=0.8,Z=0.8',
  d1: 'X=0,Y=0,Z=0',
  e: 'X=1,Y=1,Z=1'
};

function extractColorsFromImage(imageData, width, height) {
  const colorMap = {};
  const step = Math.max(1, Math.floor((width * height) / 4000));
  const sampleCount = Math.floor((width * height) / step);

  for (let i = 0; i < imageData.length; i += step * 4) {
    const r = imageData[i];
    const g = imageData[i + 1];
    const b = imageData[i + 2];
    const a = imageData[i + 3];
    if (a < 128) continue;

    const qr = Math.round(r / 32) * 32;
    const qg = Math.round(g / 32) * 32;
    const qb = Math.round(b / 32) * 32;
    const key = `${qr},${qg},${qb}`;
    colorMap[key] = (colorMap[key] || 0) + 1;
  }

  const sorted = Object.entries(colorMap)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6);

  const distinct = [sorted[0]];
  for (let i = 1; i < sorted.length && distinct.length < 4; i++) {
    const [key] = sorted[i];
    const [r1, g1, b1] = key.split(',').map(Number);
    let tooClose = false;
    for (const d of distinct) {
      const [r2, g2, b2] = d[0].split(',').map(Number);
      const diff = Math.abs(r1 - r2) + Math.abs(g1 - g2) + Math.abs(b1 - b2);
      if (diff < 64) { tooClose = true; break; }
    }
    if (!tooClose) distinct.push(sorted[i]);
  }

  return distinct.map(([key]) => {
    const [r, g, b] = key.split(',').map(Number);
    const hex = '#' + [r, g, b].map(c => c.toString(16).padStart(2, '0')).join('');
    return hexToVectorString(hex);
  });
}

export default function SkinCreatorPage() {
  const { data: session } = useSession();
  const router = useRouter();
  const [steamId, setSteamId] = useState(null);
  const [authLoading, setAuthLoading] = useState(false);

  const [activeLayer, setActiveLayer] = useState('b');
  const [materialPreset, setMaterialPreset] = useState('matte');
  const [patternType, setPatternType] = useState(0);
  const [activeDino, setActiveDino] = useState('Tyrannosaurus');
  const [importText, setImportText] = useState('');
  const [source, setSource] = useState('original');

  const [skinVectors, setSkinVectors] = useState({ ...DEFAULT_VECTORS });

  const [saveModal, setSaveModal] = useState(false);
  const [skinNameInput, setSkinNameInput] = useState('');
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState(null);

  const [savedPresets, setSavedPresets] = useState([]);
  const [presetsLoading, setPresetsLoading] = useState(false);
  const [confirmedDelete, setConfirmedDelete] = useState(null);
  const [skinSlots, setSkinSlots] = useState({ used: 0, max: 5, available: 5 });

  const [dragOver, setDragOver] = useState(false);
  const [extractingColors, setExtractingColors] = useState(false);
  const [extractedPreview, setExtractedPreview] = useState(null);

  const fileInputRef = useRef(null);

  // Dynamic dino roster from API
  const [dinoRoster, setDinoRoster] = useState({ carnivores: [], herbivores: [], tier2: [] });
  const [selectedTier, setSelectedTier] = useState(1);

  useEffect(() => {
    fetch('/api/dino-tiers')
      .then(r => r.json())
      .then(d => { if (d.success) setDinoRoster({ carnivores: d.carnivores || [], herbivores: d.herbivores || [], tier2: d.tier2 || [] }); })
      .catch(() => {});
  }, []);

  // Resolve Steam ID from Discord session
  useEffect(() => {
    async function resolve() {
      if (!session?.user?.id || steamId) return;
      setAuthLoading(true);
      try {
        const res = await fetch(`/api/discord_link/${session.user.id}`);
        if (res.ok) {
          const data = await res.json();
          setSteamId(data.steam_id);
        }
      } catch (e) {
        console.error('Failed to resolve Steam ID:', e);
      }
      setAuthLoading(false);
    }
    resolve();
  }, [session, steamId]);

  // Load saved presets when Steam ID is known
  useEffect(() => {
    if (!steamId) return;
    setPresetsLoading(true);
    fetch(`/api/skins/load?steam_id=${steamId}`)
      .then(r => r.json())
      .then(d => {
        if (d.success) setSavedPresets(d.data || []);
      })
      .catch(console.error)
      .finally(() => setPresetsLoading(false));
    fetch(`/api/skins/count?steam_id=${steamId}`)
      .then(r => r.json())
      .then(d => { if (d.success) setSkinSlots({ used: d.used, max: d.max, available: d.available }); })
      .catch(() => {});
  }, [steamId]);

  const handleColorChange = useCallback((hex) => {
    const vectorStr = hexToVectorString(hex);
    setSkinVectors(prev => ({ ...prev, [activeLayer]: vectorStr }));
  }, [activeLayer]);

  const handleImport = () => {
    if (!importText.trim()) return;
    const parsed = parseEvrimaSkinCode(importText);
    if (parsed && typeof parsed === 'object') {
      const newVectors = { ...skinVectors };
      for (const key of Object.keys(skinVectors)) {
        if (parsed[key] !== undefined) {
          newVectors[key] = parsed[key];
        }
      }
      setSkinVectors(newVectors);
      setSource('imported');
      alert('Skin Code Imported! (Marked as imported — cannot submit to marketplace)');
      setImportText('');
    } else {
      alert('Invalid Skin Code Format. Please check the syntax.');
    }
  };

  const handleExport = () => {
    const exportStr = JSON.stringify(skinVectors, null, 2).replace(/"/g, "'");
    navigator.clipboard.writeText(exportStr);
    alert('Skin Code copied to clipboard!');
  };

  const handleSave = async () => {
    if (!steamId) { alert('Connect Discord to save presets.'); return; }
    if (!skinNameInput.trim()) { alert('Enter a name for this preset.'); return; }
    const isUpdate = savedPresets.some(p => p.skin_name.toLowerCase() === skinNameInput.trim().toLowerCase());
    if (!isUpdate && skinSlots.available <= 0) {
      setSaveMsg({ ok: false, text: `Your ${skinSlots.max} skin slots are full! Purchase more with /buyskinstorage (costs marks per additional slot).` });
      setTimeout(() => setSaveMsg(null), 8000);
      return;
    }
    setSaving(true);
    setSaveMsg(null);
    try {
      const res = await fetch('/api/skins/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          steam_id: steamId,
          skin_name: skinNameInput.trim(),
          species: activeDino,
          skin_data: skinVectors,
          material_preset: materialPreset,
          pattern_type: patternType,
          source,
        }),
      });
      const d = await res.json();
      if (d.success) {
        setSaveMsg({ ok: true, text: `Saved "${skinNameInput.trim()}"` });
        setSaveModal(false);
        setSkinNameInput('');
        // Refresh presets
        const r = await fetch(`/api/skins/load?steam_id=${steamId}`);
        const ld = await r.json();
        if (ld.success) setSavedPresets(ld.data || []);
      } else {
        setSaveMsg({ ok: false, text: d.error || 'Save failed', detail: d.details || '' });
      }
    } catch (e) {
      setSaveMsg({ ok: false, text: 'Network error', detail: e.message });
    }
    setSaving(false);
    setTimeout(() => setSaveMsg(null), 3000);
  };

  const handleLoadPreset = (preset) => {
    if (preset.skin_data && typeof preset.skin_data === 'object') {
      setSkinVectors({ ...DEFAULT_VECTORS, ...preset.skin_data });
    }
    if (preset.species) setActiveDino(preset.species);
    if (preset.material_preset) setMaterialPreset(preset.material_preset);
    if (preset.pattern_type !== undefined) setPatternType(preset.pattern_type);
    setSource(preset.source || 'original');
  };

  const handleDeletePreset = async (id) => {
    if (!steamId) return;
    try {
      await fetch(`/api/skins/delete?id=${id}&steam_id=${steamId}`, { method: 'DELETE' });
      setSavedPresets(prev => prev.filter(p => p.id !== id));
    } catch (e) {
      console.error('Delete failed:', e);
    }
    setConfirmedDelete(null);
  };

  const handleNewPreset = () => {
    setSkinVectors({ ...DEFAULT_VECTORS });
    setSource('original');
    setSkinNameInput('');
    setActiveDino('Tyrannosaurus');
    setMaterialPreset('matte');
    setPatternType(0);
  };

  // Drag-drop image color extraction
  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(true);
  };
  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(false);
  };
  const handleDrop = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragOver(false);
    const file = e.dataTransfer?.files?.[0];
    if (!file || !file.type.startsWith('image/')) return;

    setExtractingColors(true);
    try {
      const img = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = (ev) => {
          const image = new window.Image();
          image.onload = () => resolve(image);
          image.onerror = reject;
          image.src = ev.target.result;
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });

      const canvas = document.createElement('canvas');
      const maxDim = 200;
      const scale = Math.min(maxDim / img.width, maxDim / img.height);
      canvas.width = Math.floor(img.width * scale);
      canvas.height = Math.floor(img.height * scale);
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

      const vectors = extractColorsFromImage(imageData.data, canvas.width, canvas.height);

      const layers = ['b', 'u', 'm', 'f'];
      const newVectors = { ...skinVectors };
      for (let i = 0; i < Math.min(vectors.length, layers.length); i++) {
        newVectors[layers[i]] = vectors[i];
      }
      setSkinVectors(newVectors);
      setSource('imported');

      const previewColors = vectors.map(v => vectorStringToHex(v));
      setExtractedPreview(previewColors);
      setTimeout(() => setExtractedPreview(null), 5000);
    } catch (err) {
      console.error('Image extraction failed:', err);
      alert('Failed to extract colors from image. Try a different file.');
    }
    setExtractingColors(false);
  };

  const currentHex = vectorStringToHex(skinVectors[activeLayer]);

  return (
    <div
      className="flex flex-col md:flex-row w-full h-full bg-[#0a0a0a] text-gray-300 font-sans overflow-hidden border-t-2 border-red-900/50 select-none skin-creator-page"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Drag overlay */}
      {dragOver && (
        <div className="absolute inset-0 z-50 bg-black/70 flex items-center justify-center pointer-events-none">
          <div className="text-center">
            <Image className="w-16 h-16 mx-auto mb-3 text-red-400 animate-pulse" />
            <p className="text-2xl font-bold text-white">Drop image to extract colors</p>
            <p className="text-sm text-gray-400 mt-2">Extracted colors will map to skin layers</p>
          </div>
        </div>
      )}

      {/* Left Panel - Species List */}
      <aside className="w-full md:w-72 bg-[#141414] border-b md:border-r md:border-b-0 border-neutral-800/80 flex flex-col shadow-2xl z-10 shrink-0 max-h-[30vh] md:max-h-full">
        <div className="p-3 bg-[#1a1a1a] border-b border-neutral-800 flex items-center justify-between">
          <h2 className="text-xs font-bold uppercase tracking-widest text-neutral-400">Content Outliner</h2>
          <div className="w-2 h-2 rounded-full bg-red-600 shadow-[0_0_8px_rgba(220,38,38,0.8)] animate-pulse"></div>
        </div>
        <div className="flex-grow overflow-y-auto custom-scrollbar p-2">
          {/* Carnivores */}
          <div className="mb-4">
            <div className="flex items-center gap-2 mb-2 px-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-red-500">▼ Carnivores</span>
            </div>
            <div className="flex flex-col gap-1 pl-4 border-l border-neutral-800 ml-3">
              {dinoRoster.carnivores.map(dino => (
                <button key={dino.id}
                  onClick={() => { setActiveDino(dino.id); setSelectedTier(dino.tier); }}
                  className={`text-left px-3 py-1.5 rounded-md text-xs font-medium transition-all ${
                    activeDino === dino.id
                      ? 'bg-red-900/40 text-red-100 border border-red-900/50 shadow-[0_0_10px_rgba(220,38,38,0.1)]'
                      : 'text-neutral-400 hover:bg-neutral-800/50 hover:text-neutral-200 border border-transparent'
                  }`}>
                  {dino.name}
                </button>
              ))}
            </div>
          </div>

          {/* Herbivores */}
          <div className="mb-4">
            <div className="flex items-center gap-2 mb-2 px-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-green-500">▼ Herbivores</span>
            </div>
            <div className="flex flex-col gap-1 pl-4 border-l border-neutral-800 ml-3">
              {dinoRoster.herbivores.map(dino => (
                <button key={dino.id}
                  onClick={() => { setActiveDino(dino.id); setSelectedTier(dino.tier); }}
                  className={`text-left px-3 py-1.5 rounded-md text-xs font-medium transition-all ${
                    activeDino === dino.id
                      ? 'bg-red-900/40 text-red-100 border border-red-900/50 shadow-[0_0_10px_rgba(220,38,38,0.1)]'
                      : 'text-neutral-400 hover:bg-neutral-800/50 hover:text-neutral-200 border border-transparent'
                  }`}>
                  {dino.name}
                </button>
              ))}
            </div>
          </div>

          {/* Tier 2 — Upcoming (greyed out, preview only) */}
          {dinoRoster.tier2.length > 0 && (
          <div className="mb-4">
            <div className="flex items-center gap-2 mb-2 px-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-yellow-500">▼ Upcoming (Preview Only)</span>
            </div>
            <div className="flex flex-col gap-1 pl-4 border-l border-neutral-800 ml-3">
              {dinoRoster.tier2.map(dino => (
                <button key={dino.id}
                  onClick={() => { setActiveDino(dino.id); setSelectedTier(dino.tier); }}
                  className={`text-left px-3 py-1.5 rounded-md text-xs font-medium transition-all opacity-50 grayscale cursor-not-allowed ${
                    activeDino === dino.id
                      ? 'bg-red-900/40 text-red-100 border border-red-900/50 shadow-[0_0_10px_rgba(220,38,38,0.1)]'
                      : 'text-neutral-400 hover:bg-neutral-800/50 hover:text-neutral-200 border border-transparent'
                  }`}>
                  {dino.name} <span className="text-[9px] text-yellow-500">(Locked)</span>
                </button>
              ))}
            </div>
          </div>
          )}
        </div>
      </aside>

      {/* Center - Viewport & Console */}
      <main className="flex-grow flex flex-col relative bg-[#0f0f0f] bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]">
        <div className="h-10 bg-[#141414] border-b border-neutral-800 flex items-center px-4 justify-between shadow-sm">
          <div className="flex gap-4">
            <span className="text-[10px] uppercase tracking-widest text-neutral-500 font-bold">Viewport</span>
            <span className="text-[10px] uppercase tracking-widest text-red-500 font-bold bg-red-900/20 px-2 rounded">Perspective / Lit</span>
          </div>
          <div className="flex items-center gap-3">
            {source === 'imported' && (
              <span className="text-[9px] bg-yellow-900/40 text-yellow-500 px-2 py-0.5 rounded border border-yellow-900/50 font-bold uppercase tracking-wider">
                Imported
              </span>
            )}
            <div className="text-[10px] font-mono text-neutral-600">FPS: 60 | Tris: 85k</div>
          </div>
        </div>

        <div className="flex-grow relative overflow-hidden">
          <SkinViewer3D skin={skinVectors} materialPreset={materialPreset} dinoModel={activeDino} />
        </div>

        {/* Bottom Console - Import/Export */}
        <div className="h-40 bg-[#141414] border-t border-neutral-800 flex flex-col shadow-[0_-10px_20px_rgba(0,0,0,0.3)] z-10">
          <div className="p-2 bg-[#1a1a1a] border-b border-neutral-800 flex items-center">
            <h2 className="text-[10px] font-bold uppercase tracking-widest text-neutral-400 px-2">Data Console</h2>
          </div>
          <div className="flex-grow p-3 flex gap-4">
            <div className="flex-grow relative">
              <span className="absolute top-2 left-2 text-green-500 font-mono text-xs select-none">{'>'}</span>
              <textarea
                className="w-full h-full bg-[#0a0a0a] border border-neutral-800 rounded-md p-2 pl-6 text-xs font-mono text-green-400 focus:outline-none focus:border-red-900/50 transition-colors resize-none shadow-inner custom-scrollbar"
                placeholder="Paste Evrima JSON Code here..."
                value={importText}
                onChange={(e) => setImportText(e.target.value)}
              />
            </div>
            <div className="w-48 flex flex-col gap-1.5">
              <button
                onClick={handleImport}
                className="bg-neutral-800 hover:bg-neutral-700 text-neutral-300 px-4 py-2 rounded text-[11px] font-bold uppercase tracking-wider transition-colors border border-neutral-700 hover:border-neutral-500"
              >
                Compile Import
              </button>
              <button
                onClick={handleExport}
                className="bg-red-900/30 hover:bg-red-900/50 text-red-300 px-4 py-2 rounded text-[11px] font-bold uppercase tracking-wider transition-colors border border-red-900 hover:border-red-500"
              >
                Export JSON Code
              </button>
              {/* Image upload button */}
              <button
                onClick={() => fileInputRef.current?.click()}
                disabled={extractingColors}
                className="bg-neutral-800 hover:bg-neutral-700 text-neutral-300 px-4 py-2 rounded text-[10px] font-bold uppercase tracking-wider transition-colors border border-neutral-700 hover:border-neutral-500 disabled:opacity-50 flex items-center justify-center gap-1"
              >
                <Upload className="w-3 h-3" />
                {extractingColors ? 'Extracting...' : 'Upload Image'}
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/png,image/jpeg,image/webp"
                className="hidden"
                onChange={(e) => {
                  if (e.target.files?.[0]) {
                    const dt = new DataTransfer();
                    dt.items.add(e.target.files[0]);
                    const fakeEvent = { preventDefault: () => {}, stopPropagation: () => {}, dataTransfer: dt };
                    handleDrop(fakeEvent);
                  }
                }}
              />
            </div>
          </div>
          {/* Extracted colors preview */}
          {extractedPreview && (
            <div className="bg-[#1a1a1a] border-t border-neutral-700 px-3 py-1.5 flex items-center gap-2">
              <span className="text-[9px] text-neutral-500 uppercase tracking-wider">Extracted:</span>
              {extractedPreview.map((hex, i) => (
                <div key={i} className="w-4 h-4 rounded-sm border border-neutral-600" style={{ backgroundColor: hex }} title={hex} />
              ))}
              <span className="text-[9px] text-yellow-500 ml-auto">Marked as imported</span>
            </div>
          )}
        </div>
      </main>

      {/* Right Panel - Inspector, Presets, Save */}
      <aside className="w-full md:w-80 bg-[#141414] border-t md:border-l md:border-t-0 border-neutral-800/80 flex flex-col shadow-2xl z-10 shrink-0 max-h-[35vh] md:max-h-full">
        <div className="p-3 bg-[#1a1a1a] border-b border-neutral-800">
          <h2 className="text-xs font-bold uppercase tracking-widest text-neutral-400">Details Inspector</h2>
        </div>

        {selectedTier === 2 && (
          <div className="px-3 py-2 bg-yellow-900/20 border-b border-yellow-900/30 text-[10px] text-yellow-400 text-center font-bold uppercase tracking-wider">
            This dinosaur has not been officially released yet — customization and saving are disabled.
          </div>
        )}

        <div className="flex-grow overflow-y-auto custom-scrollbar p-4 flex flex-col gap-5">

          {/* Layer System */}
          <section>
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-neutral-500 mb-3 border-b border-neutral-800 pb-1">Skin Layers</h3>
            <div className="flex flex-col gap-1.5">
              {LAYER_DEFINITIONS.map(layer => {
                const isActive = activeLayer === layer.id;
                const layerHex = vectorStringToHex(skinVectors[layer.id]);
                return (
                  <button
                    key={layer.id}
                    onClick={() => setActiveLayer(layer.id)}
                    className={`flex items-center justify-between p-2 rounded transition-all border ${
                      isActive
                        ? 'bg-red-900/20 border-red-900/50 shadow-inner'
                        : 'bg-[#0a0a0a] border-neutral-800/50 hover:border-neutral-700'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-4 h-4 rounded-sm border border-neutral-700 shadow-sm" style={{ backgroundColor: layerHex }} />
                      <span className={`text-[11px] font-medium ${isActive ? 'text-red-300' : 'text-neutral-400'}`}>{layer.name}</span>
                    </div>
                    {isActive && <div className="w-1.5 h-1.5 rounded-full bg-red-500"></div>}
                  </button>
                );
              })}
            </div>
          </section>

          {/* Color Wheel */}
          <section className="flex flex-col items-center">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-neutral-500 mb-3 border-b border-neutral-800 pb-1 w-full">Albedo Picker</h3>
            <div className="bg-[#0a0a0a] p-3 rounded-lg border border-neutral-800 shadow-inner">
              <HexColorPicker color={currentHex} onChange={handleColorChange} className="!w-48 !h-48" />
            </div>
            <div className="w-full mt-3 bg-[#0a0a0a] rounded border border-neutral-800 p-2 font-mono text-[10px] flex flex-col gap-1">
              <div className="flex justify-between"><span className="text-neutral-500">HEX</span><span className="text-neutral-300">{currentHex.toUpperCase()}</span></div>
              <div className="flex justify-between"><span className="text-neutral-500">VEC3</span><span className="text-red-400 truncate max-w-[150px]">{skinVectors[activeLayer]}</span></div>
            </div>
          </section>

          {/* Pattern Type */}
          <section>
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-neutral-500 mb-3 border-b border-neutral-800 pb-1">Pattern Type</h3>
            <select
              value={patternType}
              onChange={(e) => setPatternType(parseInt(e.target.value))}
              className="w-full bg-[#0a0a0a] border border-neutral-800 rounded p-2 text-xs text-neutral-300 outline-none focus:border-red-900/50"
            >
              {PATTERN_TYPES.map(pt => (
                <option key={pt.id} value={pt.id} className="bg-[#0a0a0a]">{pt.name}</option>
              ))}
            </select>
          </section>

          {/* Material Presets */}
          <section>
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-neutral-500 mb-3 border-b border-neutral-800 pb-1">Shader Preset</h3>
            <div className="grid grid-cols-2 gap-2">
              {MATERIAL_PRESETS.map(mat => (
                <button
                  key={mat.id}
                  onClick={() => setMaterialPreset(mat.id)}
                  className={`text-center p-2 rounded text-[10px] font-bold uppercase tracking-wider transition-all border ${
                    materialPreset === mat.id ? 'bg-neutral-800 text-white border-neutral-600 shadow-inner' : 'bg-[#0a0a0a] text-neutral-500 border-neutral-800/50 hover:border-neutral-700'
                  }`}
                >
                  {mat.name}
                </button>
              ))}
            </div>
          </section>

          {/* Saved Presets */}
          <section className="border-t border-neutral-800 pt-3">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-[10px] font-bold uppercase tracking-widest text-neutral-400">Saved Presets</h3>
              <button onClick={handleNewPreset} className="text-[9px] text-red-400 hover:text-red-300 border border-red-900/50 px-2 py-0.5 rounded hover:bg-red-900/20 transition-colors flex items-center gap-1">
                <Plus className="w-3 h-3" /> New
              </button>
            </div>
            {!session && presetsLoading === false && (
              <button onClick={() => signIn('discord')} className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white font-bold py-1.5 rounded text-xs flex justify-center items-center gap-1.5 transition mb-2">
                Connect Discord
              </button>
            )}
            {authLoading && <p className="text-[10px] text-neutral-500 italic">Resolving account...</p>}
            {presetsLoading && <p className="text-[10px] text-neutral-500 italic">Loading presets...</p>}
            {!presetsLoading && savedPresets.length === 0 && session && (
              <p className="text-[10px] text-neutral-500 italic">No presets saved yet.</p>
            )}
            <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto custom-scrollbar">
              {savedPresets.map(p => (
                <div key={p.id} className="flex items-center bg-[#0a0a0a] rounded border border-neutral-800/50 hover:border-neutral-700 transition-colors">
                  <button
                    onClick={() => handleLoadPreset(p)}
                    className="flex-grow text-left px-3 py-1.5 text-xs"
                  >
                    <div className="text-neutral-300 truncate max-w-[140px]">{p.skin_name}</div>
                    <div className="text-[9px] text-neutral-500">{p.species || '-'} · {p.source === 'imported' ? 'Imported' : 'Original'}</div>
                  </button>
                  {confirmedDelete === p.id ? (
                    <div className="flex items-center gap-1 px-2">
                      <button onClick={() => handleDeletePreset(p.id)} className="text-red-500 hover:text-red-300 text-[9px] font-bold">Yes</button>
                      <button onClick={() => setConfirmedDelete(null)} className="text-neutral-500 hover:text-neutral-300 text-[9px]">No</button>
                    </div>
                  ) : (
                    <button onClick={() => setConfirmedDelete(p.id)} className="px-2 py-1 text-neutral-600 hover:text-red-400 transition-colors">
                      <Trash2 className="w-3 h-3" />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Bottom Actions */}
        <div className="p-4 bg-[#1a1a1a] border-t border-neutral-800 flex flex-col gap-2">
          {saveMsg && (
            <div className={`text-[10px] font-bold text-center px-2 py-2 rounded ${saveMsg.ok ? 'bg-green-900/30 text-green-400 border border-green-900/50' : 'bg-red-900/30 text-red-400 border border-red-900/50'}`}>
              {saveMsg.text}
              {saveMsg.detail && <div className="text-[9px] mt-1 opacity-70">{saveMsg.detail}</div>}
            </div>
          )}
          {!session ? (
            <button onClick={() => signIn('discord')} className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white px-4 py-3 rounded text-xs font-bold uppercase tracking-wider transition-all">
              Connect Discord to Save
            </button>
          ) : (
            <>
            <button
              onClick={() => setSaveModal(true)}
              disabled={!steamId || selectedTier === 2}
              className="w-full bg-red-700 hover:bg-red-600 text-white px-4 py-3 rounded text-xs font-bold uppercase tracking-wider transition-all shadow-[0_0_15px_rgba(220,38,38,0.3)] disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {selectedTier === 2 ? 'Locked — Preview Only' : 'Commit To Database'}
            </button>
            {steamId && source === 'original' && selectedTier !== 2 && (
              <button
                onClick={() => {
                  const canvas = document.querySelector('canvas');
                  const thumb = canvas ? canvas.toDataURL('image/webp', 0.7) : '';
                  const data = encodeURIComponent(JSON.stringify(skinVectors));
                  router.push(`/store/submit?skin_name=${encodeURIComponent(skinNameInput || activeDino)}&species=${encodeURIComponent(activeDino)}&skin_data=${data}&thumbnail=${encodeURIComponent(thumb)}`);
                }}
                className="w-full bg-green-800 hover:bg-green-700 text-green-200 px-4 py-2.5 rounded text-xs font-bold uppercase tracking-wider transition-all border border-green-900/50 mt-2 flex items-center justify-center gap-1.5"
              >
                <Store className="w-3 h-3" /> Submit to Store
              </button>
            )}
            </>
          )}
          <div className="text-[8px] text-neutral-600 text-center uppercase tracking-wider">
            {steamId ? `${skinSlots.used}/${skinSlots.max} skin slots used` : authLoading ? 'Linking...' : 'Login to save presets'}
          </div>
        </div>
      </aside>

      {/* Save Modal */}
      {saveModal && (
        <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center" onClick={() => setSaveModal(false)}>
          <div className="bg-[#1a1a1a] border border-neutral-700 rounded-lg p-6 w-80 shadow-2xl" onClick={e => e.stopPropagation()}>
            <h3 className="text-sm font-bold text-white mb-4 uppercase tracking-wider">Save Preset</h3>
            <input
              autoFocus
              type="text"
              placeholder="Preset name (max 64 chars)"
              value={skinNameInput}
              onChange={e => setSkinNameInput(e.target.value.slice(0, 64))}
              onKeyDown={e => e.key === 'Enter' && handleSave()}
              className="w-full bg-[#0a0a0a] border border-neutral-700 rounded p-2 text-sm text-white outline-none focus:border-red-700 mb-2"
            />
            <div className="text-[10px] text-neutral-500 mb-1">Species: {activeDino} · Slots: {skinSlots.used}/{skinSlots.max} used</div>
            <div className="text-[10px] text-neutral-500 mb-1">Source: {source === 'imported' ? 'Imported (cannot submit to marketplace)' : 'Original'}</div>
            {skinSlots.available <= 0 && !savedPresets.some(p => p.skin_name.toLowerCase() === skinNameInput.trim().toLowerCase()) && (
              <div className="text-[10px] text-yellow-500 bg-yellow-900/20 border border-yellow-900/40 rounded p-2 mb-2">
                All {skinSlots.max} skin slots are full. Save will overwrite an existing preset, or purchase more slots with <span className="text-white font-bold">/buyskinstorage</span> (costs marks).
              </div>
            )}
            <div className="flex gap-2">
              <button onClick={handleSave} disabled={saving} className="flex-1 bg-red-700 hover:bg-red-600 text-white py-2 rounded text-xs font-bold uppercase tracking-wider transition-all disabled:opacity-50">
                {saving ? 'Saving...' : 'Save'}
              </button>
              <button onClick={() => setSaveModal(false)} className="px-4 py-2 bg-neutral-800 hover:bg-neutral-700 text-neutral-400 rounded text-xs transition-colors">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Custom Scrollbar Styles */}
      <style dangerouslySetInnerHTML={{__html: `
        .custom-scrollbar::-webkit-scrollbar { width: 6px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: #0a0a0a; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #555; }
      `}} />
    </div>
  );
}
