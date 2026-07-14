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
    const steam_id = searchParams.get('steam_id');
    if (!steam_id) return NextResponse.json({ error: 'steam_id required' }, { status: 400 });

    const { data, error } = await supabase.from('store_products').select('*').eq('steam_id', steam_id).order('created_at', { ascending: false });
    if (error) throw error;
    return NextResponse.json({ success: true, data: data || [] }, { status: 200 });
  } catch (error) {
    console.error('My products error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}
