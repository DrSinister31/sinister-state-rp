import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function DELETE(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { searchParams } = new URL(request.url);
    const passcode = searchParams.get('passcode');
    const steam_id = searchParams.get('steam_id');
    const is_admin = searchParams.get('is_admin') === 'true';

    if (!passcode || !steam_id) {
      return NextResponse.json({ error: 'passcode and steam_id query parameters are required' }, { status: 400 });
    }

    // Look up by passcode
    let query = supabase.from('user_skins').select('id, steam_id, skin_name').eq('passcode', passcode.toUpperCase());

    // If not admin, verify ownership
    if (!is_admin) {
      query = query.eq('steam_id', steam_id);
    }

    const { data: existing } = await query.maybeSingle();

    if (!existing) {
      return NextResponse.json({ error: 'Skin not found with that passcode, or you do not own it' }, { status: 404 });
    }

    const { error } = await supabase
      .from('user_skins')
      .delete()
      .eq('id', existing.id);

    if (error) throw error;
    return NextResponse.json({ success: true, deleted: existing.skin_name }, { status: 200 });
  } catch (error) {
    console.error('Delete skin error:', error);
    return NextResponse.json({ error: 'Failed to delete skin', details: error.message }, { status: 500 });
  }
}
