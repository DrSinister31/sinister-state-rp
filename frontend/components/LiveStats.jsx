'use client';
import { useState, useEffect } from 'react';

export default function LiveStats() {
  const [stats, setStats] = useState({
    marks: 0, pKills: 0, aiKills: 0, dinoCount: 0, 
    eggCount: 0, migZone: 'N/A', patrolZone: 'N/A', dinoAge: 0
  });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await fetch('/api/get_live_stats');
        const data = await res.json();
        if (!data.error) setStats(data);
      } catch (err) { console.error("Stats fetch failed", err); }
    };
    
    fetchStats();
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="bg-syn-charcoal p-4 border border-syn-crimson rounded text-xs space-y-2">
      <h3 className="text-syn-crimson font-bold uppercase">Live Stats</h3>
      <div className="grid grid-cols-2 gap-2">
        <span>Marks: <b id="points">{stats.marks}</b></span>
        <span>AI Kills: <b id="aiKills">{stats.aiKills}</b></span>
        <span>Dino Count: <b id="dinoCount">{stats.dinoCount}</b></span>
        <span>Age: <b id="dino-age">{stats.dinoAge}</b></span>
      </div>
    </div>
  );
}