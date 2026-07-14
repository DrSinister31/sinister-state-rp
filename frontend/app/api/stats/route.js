import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseKey);

    const [{ data: marksData }, { data: xpData }, { data: killsData }, { data: links }] = await Promise.all([
      supabase.from('player_marks').select('steam_id, marks').order('marks', { ascending: false }).limit(10),
      supabase.from('player_marks').select('steam_id, level, xp').order('level', { ascending: false }).order('xp', { ascending: false }).limit(10),
      supabase.from('player_marks').select('steam_id, kills').order('kills', { ascending: false }).limit(10),
      supabase.from('player_links').select('steam_id, discord_id, discord_username'),
    ]);

    const discordMap = {};
    if (links) for (const l of links) {
      discordMap[l.steam_id] = { discord_id: l.discord_id, discord_name: l.discord_username || null };
    }

    function attachDiscord(rows) {
      return (rows || []).map(r => {
        const link = discordMap[r.steam_id];
        const did = link?.discord_id;
        const dname = link?.discord_name;
        const shortId = did ? 'Player #' + String(did).slice(-4) : null;
        return {
          ...r,
          discord_id: did || null,
          discord_name: dname || null,
          display_name: dname || shortId || r.steam_id,
        };
      });
    }

    return NextResponse.json({
      leaderboard_marks: attachDiscord(marksData),
      leaderboard_xp: attachDiscord(xpData),
      leaderboard_kills_alltime: attachDiscord(killsData),
      leaderboard_msgs: [],
      leaderboard_kills_session: [],
      recent_kills: [],
    }, { status: 200 });
  } catch (err) {
    console.error("Error fetching stats:", err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
