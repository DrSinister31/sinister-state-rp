import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data, error } = await supabase.from('economy_rates').select('*').order('cost', { ascending: false });
    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [] }, { status: 200 });
  } catch (error) {
    console.error('Economy rates error:', error);
    return NextResponse.json({ error: 'Failed to fetch rates' }, { status: 500 });
  }
}
