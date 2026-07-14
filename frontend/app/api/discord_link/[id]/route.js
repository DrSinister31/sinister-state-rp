import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export async function GET(request, { params }) {
  const discordId = params.id;

  if (!discordId) {
    return NextResponse.json({ error: 'Discord ID is required' }, { status: 400 });
  }

  // Use the service key to bypass Row Level Security since this is a server-side trusted API
  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing Supabase environment variables");
    return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    // Query the player_links table using the discord_id
    const { data, error } = await supabase
      .from('player_links')
      .select('steam_id')
      .eq('discord_id', discordId)
      .single();

    if (error || !data) {
      return NextResponse.json({ error: 'Account not linked' }, { status: 404 });
    }

    const { data: role } = await supabase
      .from('server_roles')
      .select('is_admin, is_mod')
      .eq('steam_id', data.steam_id)
      .maybeSingle();

    return NextResponse.json({
      steam_id: data.steam_id,
      is_admin: role?.is_admin || false,
      is_mod: role?.is_mod || false,
    }, { status: 200 });

  } catch (err) {
    console.error("Error fetching discord link:", err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
