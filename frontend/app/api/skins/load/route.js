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
    const passcode = searchParams.get('passcode');
    if (!steam_id && !passcode) {
      return NextResponse.json({ error: 'steam_id or passcode query parameter is required' }, { status: 400 });
    }

    let query = supabase.from('user_skins').select('*').order('updated_at', { ascending: false });

    if (passcode) {
      query = query.eq('passcode', passcode.toUpperCase());
    }
    if (steam_id) {
      query = query.eq('steam_id', steam_id);
    }

    const { data, error } = await query;
    if (error) throw error;
    return NextResponse.json({ success: true, data: data || [] }, { status: 200 });
  } catch (error) {
    console.error('Load skins error:', error);
    return NextResponse.json({ error: 'Failed to load skins', details: error.message }, { status: 500 });
  }
}
