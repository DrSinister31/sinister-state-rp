import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const req_steam_id = searchParams.get('steam_id') || '';
    const share_code = searchParams.get('share_code') || '';
    const is_admin = searchParams.get('is_admin') === 'true';

    // 1. If Admin, fetch all positions
    if (is_admin) {
      const { data } = await supabase.from('live_map_positions').select('*');
      const result = (data || []).map(p => ({ ...p, is_server_admin: p.steam_id === req_steam_id, path: [] }));
      return NextResponse.json(result, { status: 200 });
    }

    // 2. Fetch herd members if sharing code
    let herd_members = [];
    if (share_code) {
      const { data: groupData } = await supabase.from('tracker_groups').select('steam_id').eq('share_code', share_code.toUpperCase());
      if (groupData) {
        herd_members = groupData.map(r => r.steam_id);
      }
    }

    // 3. Fetch all positions, then filter out enemies (fog of war)
    const { data: allPositions } = await supabase.from('live_map_positions').select('*');
    if (!allPositions) return NextResponse.json([], { status: 200 });

    const players = [];
    for (const p of allPositions) {
      const pid = p.steam_id;
      if (pid === req_steam_id || herd_members.includes(pid)) {
        players.push({
          ...p,
          path: [], // Trails are memory-only in the bot right now
          is_server_admin: false
        });
      }
    }

    return NextResponse.json(players, { status: 200 });

  } catch (err) {
    console.error("Error querying Supabase players API:", err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
