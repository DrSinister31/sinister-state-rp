import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { searchParams } = new URL(request.url);
    const admin_steam_id = searchParams.get('admin_steam_id');
    if (!admin_steam_id) return NextResponse.json({ error: 'admin_steam_id required' }, { status: 400 });

    const { data: role } = await supabase.from('server_roles').select('is_admin').eq('steam_id', admin_steam_id).maybeSingle();
    if (!role?.is_admin) return NextResponse.json({ error: 'Admin access required' }, { status: 403 });

    const { data, error } = await supabase.from('store_products').select('*').or('status.eq.pending,status.eq.nsfw_renamed').order('created_at', { ascending: false });
    if (error) throw error;
    return NextResponse.json({ success: true, data: data || [] }, { status: 200 });
  } catch (error) {
    console.error('Pending products error:', error);
    return NextResponse.json({ error: 'Failed to fetch pending products' }, { status: 500 });
  }
}
