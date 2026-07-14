import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { searchParams } = new URL(request.url);
    const steam_id = searchParams.get('steam_id');
    if (!steam_id) {
      return NextResponse.json({ error: 'steam_id is required' }, { status: 400 });
    }

    const [{ count, error: countError }, { data: limits }] = await Promise.all([
      supabase.from('user_skins').select('*', { count: 'exact', head: true }).eq('steam_id', steam_id),
      supabase.from('player_storage_limits').select('max_skin_slots').eq('steam_id', steam_id).maybeSingle(),
    ]);

    if (countError) throw countError;

    const maxSlots = limits?.max_skin_slots ?? 5;
    const used = count ?? 0;

    return NextResponse.json({
      success: true,
      used,
      max: maxSlots,
      available: Math.max(0, maxSlots - used),
    }, { status: 200 });
  } catch (error) {
    console.error('Skin count error:', error);
    return NextResponse.json({ error: 'Failed to check skin count' }, { status: 500 });
  }
}
