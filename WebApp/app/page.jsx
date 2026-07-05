'use client';
import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import { useSession, signIn, signOut } from 'next-auth/react';
import { getSupabase } from '../lib/supabaseClient';
const Map = dynamic(() => import('../components/Map'), { ssr: false });
const FILTER_GROUPS = [
  {
    title: 'Locations',
    items: ['heat_activity', 'sanctuaries', 'salt_licks', 'wallows', 'caves', 'water', 'spawns', 'tp_points']
  },
  {
    title: 'Zones & Environment',
    items: ['migrations', 'patrol_zones', 'areas', 'mountains', 'landmarks', 'mud_pools', 'air_currents']
  },
  {
    title: 'Prey Foods',
    items: ['boar', 'chicken', 'crab', 'deer', 'fish', 'frog', 'gallimimus', 'gastropod', 'goat', 'rabbit', 'taco', 'turtle'].map(f => `food_${f}`)
  },
  {
    title: 'Plant Foods',
    items: ['agave', 'ash', 'banana', 'brazilnuts', 'cashew', 'chanterelle', 'coconut', 'dulse', 'fiddlehead', 'fireweed', 'jackfruit', 'mango', 'marigold', 'melon', 'orange', 'papaya', 'potato', 'potatovine', 'pumpkin', 'radish', 'redcurrant', 'russula', 'sumac', 'sunchoke', 'trillium'].map(f => `food_${f}`)
  }
];
export default function Home() {
  const [, setSelectedPlayer] = useState(null);
  const [shareCode, setShareCode] = useState("");
  const [inputCode, setInputCode] = useState("");
  const [herdMembers, setHerdMembers] = useState([]);
  const [onlineFriends, setOnlineFriends] = useState([]);
  const [trackerEnabled, setTrackerEnabled] = useState(false);
  const [teleportTarget, setTeleportTarget] = useState("south_plains");
  const TELEPORT_LOCATIONS = {
    south_plains: { name: "South Plains", x: 229000, y: -176000, z: 20000 },
    swamp: { name: "Swamp", x: 282000, y: 28000, z: 20000 },
    delta: { name: "Delta", x: -18000, y: 228000, z: 20000 },
    verdant_forest: { name: "Verdant Forest", x: -241000, y: 171000, z: 20000 },
    mudflats: { name: "Mudflats", x: 171000, y: -329000, z: 20000 },
    highlands: { name: "Highlands (NW Plains Lake)", x: -125000, y: -245000, z: 20000 },
    east_lake: { name: "East Lake", x: -173000, y: 436000, z: 20000 },
    center: { name: "Center Map", x: 0, y: 0, z: 20000 },
    northern_plains: { name: "Northern Plains", x: -185000, y: -420000, z: 20000 },
    west_rail: { name: "West Rail", x: -380000, y: -65000, z: 20000 },
    pit: { name: "The Pit", x: 87000, y: 83000, z: 20000 }
  };
  const [leaderboardMarks, setLeaderboardMarks] = useState([]);
  const [leaderboardXp, setLeaderboardXp] = useState([]);
  const [leaderboardMsgs, setLeaderboardMsgs] = useState([]);
  const [leaderboardKillsSession, setLeaderboardKillsSession] = useState([]);
  const [leaderboardKillsAllTime, setLeaderboardKillsAllTime] = useState([]);
  const [leaderboardCategory, setLeaderboardCategory] = useState('marks');
  const [recentKills, setRecentKills] = useState([]);
  const [activeFilters, setActiveFilters] = useState({
    sanctuaries: false,
    water: false,
    spawns: false,
    tp_points: false,
    migrations: false,
    patrol_zones: false,
    areas: true,
    mountains: false,
    landmarks: false,
    mud_pools: false,
    air_currents: false,
    roads: false,
    heat_activity: false,
    salt_licks: false,
    wallows: false,
    caves: false
  });
  // Load from localStorage on mount
  useEffect(() => {
    const saved = localStorage.getItem('sinisterMapFilters');
    if (saved) {
      try {
        setActiveFilters(JSON.parse(saved));
      } catch (e) {}
    }
  }, []);
  // Save to localStorage when changed
  useEffect(() => {
    localStorage.setItem('sinisterMapFilters', JSON.stringify(activeFilters));
  }, [activeFilters]);
  const [expandedSections, setExpandedSections] = useState({ 'Tracker Hub': true, 'System Controls': true, 'Locations': true, 'Online Friends': true});
  // Auth & Link state
  const { data: session, status } = useSession();
  const [userSteamId, setUserSteamId] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [adminMode, setAdminMode] = useState(false);
  const [showAllPlayers, setShowAllPlayers] = useState(false);
  const [leftOpen, setLeftOpen] = useState(false);
  const [rightOpen, setRightOpen] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setAdminMode(localStorage.getItem('sinisterAdminMode') === 'true');
      const onStorage = () => setAdminMode(localStorage.getItem('sinisterAdminMode') === 'true');
      window.addEventListener('storage', onStorage);
      return () => window.removeEventListener('storage', onStorage);
    }
  }, []);

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`)
        .then(r => r.json())
        .then(data => {
          if (data.steam_id) setUserSteamId(data.steam_id);
          if (data.is_admin || data.is_mod) setIsAdmin(true);
        })
        .catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    if (adminMode && isAdmin) setShowAllPlayers(true);
    else setShowAllPlayers(false);
  }, [adminMode, isAdmin]);
  const toggleFilter = (cat) => {
    setActiveFilters(prev => ({ ...prev, [cat]: !prev[cat] }));
  };
  useEffect(() => {
    // Only fetch stats if authenticated to save requests
    if (status !== 'authenticated') return;
    
    const fetchStats = async () => {
      try {
        const res = await fetch('/api/stats');
        const data = await res.json();
        if (data.leaderboard_marks) setLeaderboardMarks(data.leaderboard_marks);
        if (data.leaderboard_xp) setLeaderboardXp(data.leaderboard_xp);
        if (data.leaderboard_msgs) setLeaderboardMsgs(data.leaderboard_msgs);
        if (data.leaderboard_kills_session) setLeaderboardKillsSession(data.leaderboard_kills_session);
        if (data.leaderboard_kills_alltime) setLeaderboardKillsAllTime(data.leaderboard_kills_alltime);
        if (data.recent_kills) setRecentKills(data.recent_kills);
      } catch (e) {
        console.error('Error fetching stats:', e);
      }
    };
    fetchStats();
    const intv = setInterval(fetchStats, 5000);
    return () => clearInterval(intv);
  }, [status]);
  useEffect(() => {
    if (!userSteamId) return;
    const fetchPersonal = async () => {
      try {
        if (shareCode) {
          const res = await fetch(`/api/groups/members?share_code=${shareCode}`);
          setHerdMembers(await res.json());
        } else {
          setHerdMembers([]);
        }
        
        const fres = await fetch(`/api/friends/online?steam_id=${userSteamId}`);
        setOnlineFriends(await fres.json());
      } catch(e) {}
    };
    fetchPersonal();
    const iv = setInterval(fetchPersonal, 5000);
    return () => clearInterval(iv);
  }, [userSteamId, shareCode]);
  const handleAddFriend = async (friendSteamId) => {
    try {
      await fetch('/api/friends/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_steam_id: userSteamId, friend_steam_id: friendSteamId })
      });
      alert('Friend Added!');
    } catch(e) { alert('Failed to add friend'); }
  };
  const toggleSection = (title) => {
    setExpandedSections(prev => ({ ...prev, [title]: !prev[title] }));
  };
  const handleTeleportSelf = async () => {
    if (!userSteamId) return alert('You must log in and link your Discord to use this feature.');
    const loc = TELEPORT_LOCATIONS[teleportTarget];
    const sure = confirm(`Teleport your character to ${loc.name}? (Note: Teleport costs or conditions may apply in-game)`);
    if (sure) {
      try {
        const supabase = getSupabase();
        await supabase.from('pending_tasks').insert({
          command: `TeleportTo ${userSteamId} ${loc.x} ${loc.y} ${loc.z}`,
          target_id: userSteamId,
          is_raw_command: true,
          status: 'pending'
        });
        alert(`Teleport command sent to ${loc.name}! Check in-game.`);
      } catch (err) {
        console.error(err);
        alert('Failed to send teleport request.');
      }
    }
  };
  return (
    <div className="gamer-container relative w-full h-full overflow-hidden bg-black selection:bg-red-900 selection:text-white" style={{ height: '100%' }}>
      
      {/* Sidebar with Gamer Glassmorphism */}
      <div className={`gamer-sidebar ${leftOpen ? 'mobile-open' : ''}`} onClick={() => setLeftOpen(!leftOpen)}>
        
        <div className="gamer-header">
          <div>
            <h1 className="gamer-title" style={{ fontSize: '18px' }}>Sinister's Park</h1>
            <p className="gamer-subtitle mt-1">Live Tracker</p>
          </div>
        </div>
        {/* Filter Scroll Area */}
        <div className="gamer-scroll-area">
          

          {/* Tracker Toggle */}
          <div className="filter-group">
            <div className="filter-group-header-wrapper" onClick={() => toggleSection('System Controls')}>
              <h3 className="filter-group-header">System Controls</h3>
              <span className="collapse-icon">{expandedSections['System Controls'] ? '▲' : '▼'}</span>
            </div>
            {expandedSections['System Controls'] && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '12px' }}>
                <label className="gamer-checkbox-label">
                  <input 
                    type="checkbox" 
                    className="syn-checkbox"
                    checked={trackerEnabled} 
                    onChange={(e) => setTrackerEnabled(e.target.checked)} 
                  />
                  <span className="checkbox-text">Enable Target Tracking</span>
                </label>
                {isAdmin && (
                <label className="gamer-checkbox-label" style={{ borderLeft: '2px solid gold', paddingLeft: '10px' }}>
                  <input
                    type="checkbox"
                    className="syn-checkbox"
                    checked={showAllPlayers}
                    onChange={(e) => setShowAllPlayers(e.target.checked)}
                  />
                  <span className="checkbox-text" style={{ color: '#FFD700' }}>Admin: Show All Players</span>
                </label>
                )}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span className="checkbox-text" style={{ fontSize: '11px', textTransform: 'uppercase' }}>Teleport:</span>
                  <select 
                    value={teleportTarget} 
                    onChange={(e) => setTeleportTarget(e.target.value)}
                    className="syn-select"
                  >
                    {Object.entries(TELEPORT_LOCATIONS).map(([k, v]) => (
                      <option key={k} value={k}>{v.name}</option>
                    ))}
                  </select>
                </div>
                <button 
                  onClick={handleTeleportSelf}
                  className="syn-button w-full mt-1 hover-glitch"
                  style={{ padding: '12px' }}
                >
                  Teleport
                </button>
              </div>
            )}
          </div>
          {/* Map Layers / Filters */}
          {FILTER_GROUPS.map((group) => (
            <div key={group.title} className="filter-group">
              <div className="filter-group-header-wrapper" onClick={() => toggleSection(group.title)}>
                <h3 className="filter-group-header">{group.title}</h3>
                <div className="filter-group-actions" onClick={e => e.stopPropagation()}>
                  <button className="filter-group-action-btn" onClick={() => {
                    const next = { ...activeFilters };
                    group.items.forEach(item => { next[item] = true; });
                    setActiveFilters(next);
                  }}>All</button>
                  <button className="filter-group-action-btn" onClick={() => {
                    const next = { ...activeFilters };
                    group.items.forEach(item => { next[item] = false; });
                    setActiveFilters(next);
                  }}>None</button>
                  <span className="collapse-icon">{expandedSections[group.title] ? '▲' : '▼'}</span>
                </div>
              </div>
              {expandedSections[group.title] && (
                <div className="filter-list">
                  {group.items.map(cat => (
                    <label key={cat} className="gamer-checkbox-label">
                      <input 
                        type="checkbox" 
                        className="syn-checkbox"
                        id={cat} 
                        checked={activeFilters[cat] || false}
                        onChange={() => toggleFilter(cat)}
                      />
                      <span className="checkbox-text">{cat.replace(/^food_/, '').replace(/_/g, ' ')}</span>
                    </label>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
        
        {/* Discord Auth Widget at Bottom */}
        <div className="flex flex-col items-center justify-center py-4 mt-auto w-full relative border-t-2 border-red-900/30 bg-black shadow-[0_-15px_30px_rgba(0,0,0,0.8)] z-50">
          {/* Subtle animated background glow */}
          <div className="absolute inset-0 bg-gradient-to-t from-red-900/20 to-transparent pointer-events-none animate-pulse"></div>
          {status !== 'authenticated' ? (
            <button 
              onClick={() => signIn('discord')}
              disabled={status === 'loading'}
              className="relative z-10 flex flex-col items-center justify-center gap-3 group transition-all duration-300 bg-transparent border-none outline-none cursor-pointer p-2 w-full"
            >
              <span className="text-red-500 font-bold uppercase tracking-[0.3em] animate-pulse drop-shadow-[0_0_15px_rgba(255,0,0,0.9)] text-lg group-hover:text-red-400 group-hover:scale-105 transition-all duration-300" style={{ fontFamily: "'Orbitron', sans-serif" }}>
                {status === 'loading' ? 'Authenticating...' : 'Sign In'}
              </span>
              <img 
                src="/assets/discordicon.png" 
                alt="Discord" 
                className="w-16 h-16 object-contain filter drop-shadow-[0_0_15px_rgba(220,38,38,0.8)] group-hover:drop-shadow-[0_0_25px_rgba(255,50,50,1)] group-hover:scale-110 transition-transform duration-300"
              />
            </button>
          ) : (
            <div className="relative z-10 flex flex-row items-center justify-center gap-4 w-full p-2 cursor-pointer hover:bg-white/5 transition-colors duration-300" onClick={() => signOut()}>
              <img 
                src="/sinister_park_logo.png" 
                alt="Sinister Park" 
                className="w-12 h-12 object-contain filter drop-shadow-[0_0_12px_rgba(255,0,0,0.7)]"
              />
              <div className="flex flex-col text-left">
                <span className="text-[10px] text-gray-400 uppercase tracking-widest leading-none mb-1">Connected</span>
                <span className="text-md font-bold text-white drop-shadow-[0_0_8px_rgba(255,0,0,0.8)] leading-tight font-[Orbitron] tracking-wider">{session?.user?.name || 'Discord User'}</span>
              </div>
            </div>
          )}
        </div>
      </div>  
        <div className="map-wrapper">
          <Map 
            isAdmin={isAdmin && showAllPlayers} 
            userSteamId={userSteamId}
            shareCode={shareCode}
            herdMembers={herdMembers}
            onSelectPlayer={setSelectedPlayer} 
            trackerEnabled={trackerEnabled} 
            activeFilters={activeFilters}
            recentKills={recentKills}
          />
        </div>
      {/* Right Sidebar - Leaderboard & Activity */}
      <div className={`gamer-sidebar-right ${rightOpen ? 'mobile-open' : ''}`} onClick={() => setRightOpen(!rightOpen)}>
        
        {/* Header */}
        <div className="gamer-header" style={{ justifyContent: 'flex-end' }}>
          <div>
            <h1 className="gamer-title" style={{ textAlign: 'right', fontSize: '18px' }}>Live Stats</h1>
            <p className="gamer-subtitle" style={{ textAlign: 'right' }}>Server Activity</p>
          </div>
        </div>
        <div className="gamer-scroll-area">
          
          {/* Tracker Hub */}
          <div className="filter-group">
            <div className="filter-group-header-wrapper" onClick={() => toggleSection('Tracker Hub')}>
              <h3 className="filter-group-header">Tracker Hub</h3>
              <span className="collapse-icon">{expandedSections['Tracker Hub'] ? '▲' : '▼'}</span>
            </div>
            {expandedSections['Tracker Hub'] && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '12px' }}>
                <div style={{ fontSize: '11px', color: 'var(--syn-text-muted)' }}>Create a herd or join an existing one to share map locations.</div>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'stretch' }}>
                  <input 
                    type="text" 
                    placeholder="HERD CODE" 
                    value={inputCode}
                    onChange={(e) => setInputCode(e.target.value)}
                    className="syn-input"
                    style={{ flex: 1, textTransform: 'uppercase', minWidth: 0, height: '40px' }}
                  />
                  <button 
                    onClick={async () => {
                      if (!userSteamId) return alert('You must log in to join a herd.');
                      const code = inputCode.toUpperCase();
                      try {
                        const res = await fetch('/api/groups/join', {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ steam_id: userSteamId, share_code: code })
                        });
                        const data = await res.json();
                        if (data.error) return alert(data.error);
                        setShareCode(code);
                      } catch(e) { alert('Failed to join herd.'); }
                    }}
                    className="syn-button"
                    style={{ padding: '0 16px', fontSize: '12px', height: '40px', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                  >
                    JOIN
                  </button>
                </div>
                <button
                  onClick={async () => {
                    if (!userSteamId) return alert('You must log in first.');
                    try {
                      const res = await fetch('/api/groups/create', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ steam_id: userSteamId })
                      });
                      const data = await res.json();
                      if (data.error) return alert(data.error);
                      setShareCode(data.share_code);
                      setInputCode('');
                      navigator.clipboard.writeText(data.share_code).catch(() => {});
                    } catch(e) { alert('Failed to create herd.'); }
                  }}
                  className="syn-button"
                  style={{ width: '100%', padding: '10px 16px', fontSize: '12px', height: '40px', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #4CAF50, #2E7D32)', borderColor: '#4CAF50' }}
                >
                  + CREATE HERD ID
                </button>
                {shareCode && (
                  <div style={{ fontSize: '12px', color: '#4CAF50', fontWeight: 'bold' }}>
                    Active Herd: {shareCode}
                    <button onClick={async () => { 
                      await fetch('/api/groups/leave', { method: 'POST', body: JSON.stringify({ steam_id: userSteamId }) });
                      setShareCode(""); setInputCode(""); 
                    }} className="hover-glitch" style={{ marginLeft: '10px', background: 'transparent', border: 'none', color: 'var(--syn-crimson-bright)', cursor: 'pointer', fontWeight: 'bold' }}>[LEAVE]</button>
                  </div>
                )}
                {herdMembers.length > 0 && (
                  <div className="filter-list">
                    <div style={{ fontSize: '10px', color: 'var(--syn-text-muted)', textTransform: 'uppercase', marginBottom: '4px' }}>Herd Roster ({herdMembers.length})</div>
                    {herdMembers.map(m => (
                      <div key={m.steam_id} className="leaderboard-entry" style={{ padding: '8px 12px' }}>
                        <span style={{ fontSize: '11px', color: 'white', fontWeight: 'bold' }}>
                          {m.is_leader && <span title="Herd Leader">👑 </span>}
                          {m.player_name || m.steam_id}
                        </span>
                        {m.steam_id !== userSteamId && (
                          <button onClick={() => handleAddFriend(m.steam_id)} title="Add Permanent Friend" style={{ background: 'transparent', border: 'none', cursor: 'pointer', filter: 'drop-shadow(0 0 5px rgba(255,255,255,0.5))' }}>➕</button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
          
          {/* Online Friends */}
          <div className="filter-group">
            <div className="filter-group-header-wrapper" onClick={() => toggleSection('Online Friends')}>
              <h3 className="filter-group-header">Online Friends</h3>
              <span className="collapse-icon">{expandedSections['Online Friends'] ? '▲' : '▼'}</span>
            </div>
            {expandedSections['Online Friends'] && (
              <div className="filter-list" style={{ maxHeight: '120px', overflowY: 'auto' }}>
                {onlineFriends.length === 0 ? (
                  <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>No friends currently online.</span>
                ) : (
                  onlineFriends.map(f => (
                    <div key={f.steam_id} className="leaderboard-entry" style={{ borderLeftColor: '#4CAF50' }}>
                      <span style={{ fontSize: '11px', color: 'white', fontWeight: 'bold' }}>{f.player_name || f.steam_id}</span>
                      <span style={{ fontSize: '10px', color: '#4CAF50', textShadow: '0 0 5px rgba(76,175,80,0.5)' }}>{f.species || 'Playing'}</span>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>
          {/* Top Marks Leaderboard */}
          <div className="filter-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
              <h3 className="filter-group-header" style={{ margin: 0 }}>Leaderboard</h3>
              <select 
                value={leaderboardCategory}
                onChange={(e) => setLeaderboardCategory(e.target.value)}
                className="syn-select"
                style={{ padding: '6px 8px', fontSize: '10px' }}
              >
                <option value="marks">Top Marks</option>
                <option value="xp">Top XP</option>
                <option value="msgs">Most Active</option>
                <option value="kills_session">Top Kills (Session)</option>
                <option value="kills_alltime">Top Kills (All-Time)</option>
              </select>
            </div>
            
            <div className="filter-list">
              {leaderboardCategory === 'marks' && (leaderboardMarks.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>Loading...</span>
              ) : (
                leaderboardMarks.map((user, idx) => (
                  <div key={user.steam_id} className="leaderboard-entry">
                    <span style={{ fontWeight: 'bold', fontSize: '12px', color: idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'var(--syn-text)' }}>
                      #{idx + 1} {user.display_name || (user.discord_id ? `<@${user.discord_id}>` : user.steam_id)}
                    </span>
                    <span style={{ color: 'var(--syn-crimson)', textShadow: '0 0 8px rgba(255,42,75,0.8)', fontWeight: 'bold', fontSize: '12px' }}>{user.marks} Ⓜ️</span>
                  </div>
                ))
              ))}
              {leaderboardCategory === 'xp' && (leaderboardXp.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>Loading...</span>
              ) : (
                leaderboardXp.map((user, idx) => (
                  <div key={user.steam_id} className="leaderboard-entry">
                    <span style={{ fontWeight: 'bold', fontSize: '12px', color: idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'var(--syn-text)' }}>
                      #{idx + 1} {user.display_name || (user.discord_id ? `<@${user.discord_id}>` : user.steam_id)}
                    </span>
                    <span style={{ color: '#4CAF50', textShadow: '0 0 8px rgba(76,175,80,0.8)', fontWeight: 'bold', fontSize: '12px' }}>Lvl {user.level}</span>
                  </div>
                ))
              ))}
              {leaderboardCategory === 'msgs' && (leaderboardMsgs.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>Loading...</span>
              ) : (
                leaderboardMsgs.map((user, idx) => (
                  <div key={user.steam_id} className="leaderboard-entry">
                    <span style={{ fontWeight: 'bold', fontSize: '12px', color: idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'var(--syn-text)' }}>
                      #{idx + 1} {user.display_name || (user.discord_id ? `<@${user.discord_id}>` : user.steam_id)}
                    </span>
                    <span style={{ color: '#2196F3', textShadow: '0 0 8px rgba(33,150,243,0.8)', fontWeight: 'bold', fontSize: '12px' }}>{user.message_count} 💬</span>
                  </div>
                ))
              ))}
              {leaderboardCategory === 'kills_session' && (leaderboardKillsSession.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>No kills yet this session!</span>
              ) : (
                leaderboardKillsSession.map((user, idx) => (
                  <div key={user.steam_id} className="leaderboard-entry">
                    <span style={{ fontWeight: 'bold', fontSize: '12px', color: idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'var(--syn-text)' }}>
                      #{idx + 1} {user.display_name || (user.discord_id ? `<@${user.discord_id}>` : user.steam_id)}
                    </span>
                    <span style={{ color: 'var(--syn-crimson)', textShadow: '0 0 8px rgba(255,42,75,0.8)', fontWeight: 'bold', fontSize: '12px' }}>{user.kills} ☠️</span>
                  </div>
                ))
              ))}
              {leaderboardCategory === 'kills_alltime' && (leaderboardKillsAllTime.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>Loading... (Check if 'kills' column is in Supabase)</span>
              ) : (
                leaderboardKillsAllTime.map((user, idx) => (
                  <div key={user.steam_id} className="leaderboard-entry">
                    <span style={{ fontWeight: 'bold', fontSize: '12px', color: idx === 0 ? '#FFD700' : idx === 1 ? '#C0C0C0' : idx === 2 ? '#CD7F32' : 'var(--syn-text)' }}>
                      #{idx + 1} {user.display_name || (user.discord_id ? `<@${user.discord_id}>` : user.steam_id)}
                    </span>
                    <span style={{ color: 'var(--syn-crimson)', textShadow: '0 0 8px rgba(255,42,75,0.8)', fontWeight: 'bold', fontSize: '12px' }}>{user.kills} ☠️</span>
                  </div>
                ))
              ))}
            </div>
          </div>
          {/* Recent Kills Feed */}
          <div className="filter-group">
            <h3 className="filter-group-header">Recent Kills</h3>
            <div className="filter-list">
              {recentKills.length === 0 ? (
                <span className="checkbox-text" style={{ color: 'var(--syn-text-muted)' }}>No recent activity.</span>
              ) : (
                [...recentKills].reverse().slice(0, 15).map((kill, idx) => (
                  <div key={idx} className="kill-entry">
                    <div style={{ color: 'var(--syn-text-muted)', fontSize: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                      {new Date(kill.timestamp * 1000).toLocaleTimeString()}
                    </div>
                    <div>
                      <span style={{ color: 'var(--syn-text)', fontWeight: 'bold' }}>{kill.killer_name}</span> 
                      <span style={{ color: 'var(--syn-crimson)', margin: '0 4px', textShadow: '0 0 5px rgba(255,0,0,0.5)' }}>killed</span>
                      <span style={{ color: 'var(--syn-text)', fontStyle: 'italic', fontWeight: 'bold' }}>{kill.victim}</span>
                      {kill.type === 'ai' && <span style={{ marginLeft: '6px', fontSize: '9px', background: 'rgba(255,255,255,0.1)', padding: '2px 6px', borderRadius: '4px', border: '1px solid rgba(255,255,255,0.2)' }}>AI</span>}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
      {/* Mobile bottom tab bar */}
      <div className="flex md:hidden fixed bottom-0 left-0 right-0 z-[1999] bg-[rgba(20,20,20,0.95)] backdrop-blur-md border-t border-red-900/30">
        <button className={`flex-1 text-center py-2 text-[10px] font-bold uppercase tracking-wider cursor-pointer border-none bg-transparent transition-colors ${leftOpen ? 'text-red-400' : 'text-neutral-500'}`} onClick={() => { setLeftOpen(!leftOpen); setRightOpen(false); }}>
          <span className="block text-lg mb-0.5">📋</span> Filters
        </button>
        <button className={`flex-1 text-center py-2 text-[10px] font-bold uppercase tracking-wider cursor-pointer border-none bg-transparent transition-colors ${rightOpen ? 'text-red-400' : 'text-neutral-500'}`} onClick={() => { setRightOpen(!rightOpen); setLeftOpen(false); }}>
          <span className="block text-lg mb-0.5">🏆</span> Leaderboard
        </button>
      </div>
    </div>
  );
}
