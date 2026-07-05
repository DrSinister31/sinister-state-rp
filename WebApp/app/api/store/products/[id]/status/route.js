import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function PUT(request, { params }) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const body = await request.json();
    const { admin_steam_id, status, admin_notes } = body;
    if (!admin_steam_id) return NextResponse.json({ error: 'admin_steam_id required' }, { status: 400 });

    // Verify admin
    const { data: role } = await supabase.from('server_roles').select('is_admin').eq('steam_id', admin_steam_id).maybeSingle();
    if (!role?.is_admin) return NextResponse.json({ error: 'Admin access required' }, { status: 403 });

    const validStatuses = ['approved', 'rejected', 'nsfw_renamed'];
    if (!validStatuses.includes(status)) {
      return NextResponse.json({ error: 'Invalid status. Must be: approved, rejected, or nsfw_renamed' }, { status: 400 });
    }

    const { data, error } = await supabase.from('store_products').update({
      status,
      admin_notes: admin_notes || null,
      updated_at: new Date().toISOString(),
    }).eq('id', params.id).select().single();

    if (error) throw error;
    return NextResponse.json({ success: true, data }, { status: 200 });
  } catch (error) {
    console.error('Product status error:', error);
    return NextResponse.json({ error: 'Failed to update status' }, { status: 500 });
  }
}
