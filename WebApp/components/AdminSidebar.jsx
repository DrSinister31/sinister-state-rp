'use client';
import { useState, useEffect } from 'react';
import { Shield, Trash2, Eye, Wifi } from 'lucide-react';

// All admin RCON commands use the COMMAND_REGISTRY format (from main.py)
const ADMIN_ACTIONS = [
  { label: 'Heal Player', cmd: 'HealPlayer', icon: '❤️', target: true },
  { label: 'Spectate', cmd: 'spectate', icon: '👁️', target: true },
  { label: 'Teleport To', cmd: 'teleport', icon: '🌀', target: true },
  { label: 'Kick Player', cmd: 'KickPlayer', icon: '🥾', target: true },
  { label: 'Ban Player', cmd: 'BanPlayer', icon: '🔨', target: true },
  { label: 'Slay Player', cmd: 'slay', icon: '💀', target: true },
  { label: 'Wipe Player', cmd: 'wipe_player', icon: '☢️', target: true },
  { label: 'Set Hunger 100', cmd: 'SetHunger', icon: '🍖', target: true, arg: '100' },
  { label: 'Set Thirst 100', cmd: 'SetThirst', icon: '💧', target: true, arg: '100' },
  { label: 'Set Stamina 100', cmd: 'SetStamina', icon: '⚡', target: true, arg: '100' },
];

const GLOBAL_ACTIONS = [
  { label: 'Wipe Corpses', cmd: 'wipecorpses', icon: '🦴' },
  { label: 'Save Server', cmd: 'save', icon: '💾' },
  { label: 'Player List', cmd: 'playerlist', icon: '📋' },
  { label: 'Announce', cmd: 'ServerAnnounce', icon: '📢', hasMsg: true },
];

export default function AdminSidebar({ isAdmin, userSteamId }) {
  const [targetName, setTargetName] = useState('');
  const [announceMsg, setAnnounceMsg] = useState('');
  const [msg, setMsg] = useState(null);

  if (!isAdmin) return null;

  const executeCommand = async (cmd, target, arg) => {
    const finalTarget = target || targetName;
    if (!finalTarget && ['HealPlayer','KickPlayer','BanPlayer','slay','wipe_player','SetHunger','SetThirst','SetStamina','teleport','spectate'].includes(cmd)) {
      setMsg({ ok: false, text: 'Enter a target player name.' }); return;
    }

    try {
      const { getSupabase } = await import('../lib/supabaseClient');
      const supabase = getSupabase();
      const rconCmd = arg ? `${cmd} ${finalTarget} ${arg}` : `${cmd} ${finalTarget || ''}`;
      await supabase.from('pending_tasks').insert({
        command: rconCmd.trim(),
        target_id: finalTarget || '',
        is_raw_command: true,
        status: 'pending',
      });
      setMsg({ ok: true, text: `Sent: ${rconCmd.trim()}` });
    } catch (e) {
      setMsg({ ok: false, text: e.message });
    }
    setTimeout(() => setMsg(null), 3000);
  };

  return (
    <div className="filter-group">
      <div className="filter-group-header-wrapper">
        <h3 className="filter-group-header" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Shield className="w-3.5 h-3.5 text-yellow-400" /> Admin Panel
        </h3>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '8px' }}>
        {/* Target input */}
        <input
          type="text" placeholder="Target player name..."
          value={targetName} onChange={e => setTargetName(e.target.value)}
          className="syn-input" style={{ width: '100%', padding: '8px', fontSize: '11px', textTransform: 'uppercase' }}
        />

        {/* Player-targeted actions */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4px' }}>
          {ADMIN_ACTIONS.map(a => (
            <button key={a.cmd} onClick={() => executeCommand(a.cmd, undefined, a.arg)}
              className="syn-button" style={{ padding: '6px 8px', fontSize: '10px', display: 'flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}>
              {a.icon} {a.label}
            </button>
          ))}
        </div>

        {/* Announce input */}
        <div style={{ display: 'flex', gap: '4px' }}>
          <input type="text" placeholder="Announce message..."
            value={announceMsg} onChange={e => setAnnounceMsg(e.target.value)}
            className="syn-input" style={{ flex: 1, padding: '8px', fontSize: '11px' }}
          />
          <button onClick={() => { executeCommand('ServerAnnounce', announceMsg); setAnnounceMsg(''); }}
            className="syn-button" style={{ padding: '6px 10px', fontSize: '10px', whiteSpace: 'nowrap' }}>📢 Send</button>
        </div>

        {/* Global actions */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4px' }}>
          {GLOBAL_ACTIONS.filter(a => !a.hasMsg).map(a => (
            <button key={a.cmd} onClick={() => executeCommand(a.cmd, '', '')}
              className="syn-button" style={{ padding: '6px 8px', fontSize: '10px', display: 'flex', alignItems: 'center', gap: '4px' }}>
              {a.icon} {a.label}
            </button>
          ))}
        </div>

        {msg && (
          <div style={{ fontSize: '10px', padding: '4px 8px', borderRadius: '4px', color: msg.ok ? '#4CAF50' : '#f44336', background: msg.ok ? 'rgba(76,175,80,0.1)' : 'rgba(244,67,54,0.1)' }}>
            {msg.text}
          </div>
        )}
      </div>
    </div>
  );
}
