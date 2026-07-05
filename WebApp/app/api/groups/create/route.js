import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { steam_id } = await request.json();
    if (!steam_id) {
      return NextResponse.json({ error: 'steam_id is required' }, { status: 400 });
    }

    // Remove existing membership first (one player = one group)
    await supabase.from('tracker_groups').delete().eq('steam_id', steam_id);

    // Generate a short random share code
    const shareCode = Math.random().toString(36).substring(2, 8).toUpperCase();

    const { data, error } = await supabase
      .from('tracker_groups')
      .insert({ steam_id, share_code: shareCode })
      .select()
      .single();

    if (error) throw error;
    return NextResponse.json({ success: true, share_code: shareCode }, { status: 201 });
  } catch (error) {
    console.error('Create group error:', error);
    return NextResponse.json({ error: 'Failed to create group', details: error.message }, { status: 500 });
  }
}
