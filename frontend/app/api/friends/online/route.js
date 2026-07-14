import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

// GET /api/friends/online?steam_id=XXX
// Returns online friends showing display_name (in-game name) — NEVER steam_id
export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const steam_id = searchParams.get('steam_id') || '';

    if (!steam_id) {
      return NextResponse.json({ error: 'steam_id required' }, { status: 400 });
    }

    // 1. Get this player's accepted friends list (both directions)
    const { data: friendRows } = await supabase
      .from('friends')
      .select('user_steam_id, friend_steam_id')
      .or(`user_steam_id.eq.${steam_id},friend_steam_id.eq.${steam_id}`)
      .eq('status', 'accepted');

    if (!friendRows || friendRows.length === 0) {
      return NextResponse.json([], { status: 200 });
    }

    // Build flat set of friend steam_ids (exclude self)
    const friendIds = new Set();
    for (const row of friendRows) {
      if (row.user_steam_id !== steam_id)   friendIds.add(row.user_steam_id);
      if (row.friend_steam_id !== steam_id) friendIds.add(row.friend_steam_id);
    }

    if (friendIds.size === 0) {
      return NextResponse.json([], { status: 200 });
    }

    // 2. Check which friends are currently in live_map_positions
    const { data: positions } = await supabase
      .from('live_map_positions')
      .select('player_name, species, growth, health, last_updated')
      // NOTE: intentionally NOT selecting steam_id — never expose it
      .in('steam_id', [...friendIds]);

    if (!positions || positions.length === 0) {
      return NextResponse.json([], { status: 200 });
    }

    // 3. Only return friends active in last 60 seconds
    const cutoff = new Date(Date.now() - 60_000);
    const online = positions.filter(p => new Date(p.last_updated) > cutoff);

    // Return safe display-only data
    const result = online.map(p => ({
      display_name: p.player_name || 'Unknown',
      species:      p.species     || 'Unknown',
      growth:       p.growth      || 0,
      health:       p.health      || 0,
      last_seen:    p.last_updated,
      is_adult:     (p.growth || 0) >= 1.0
    }));

    return NextResponse.json(result, { status: 200 });

  } catch (err) {
    console.error('friends/online error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
