import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  const url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_KEY;
  if (!url || !key) return null;
  return createClient(url, key);
}

export async function GET(request, { params }) {
  const supabase = getSupabase();
  if (!supabase) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
  const { data, error } = await supabase.from('store_products').select('*').eq('id', params.id).single();
  if (error || !data) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
  // Track view count
  supabase.from('store_products').update({ view_count: (data.view_count || 0) + 1 }).eq('id', params.id).then(() => {}).catch(() => {});
  return NextResponse.json({ success: true, data }, { status: 200 });
}

export async function PUT(request, { params }) {
  const supabase = getSupabase();
  if (!supabase) return NextResponse.json({ error: 'DB config error' }, { status: 500 });

  const body = await request.json();
  const { steam_id, price, description } = body;
  if (!steam_id) return NextResponse.json({ error: 'steam_id required' }, { status: 400 });

  const { data: existing } = await supabase.from('store_products').select('steam_id, status').eq('id', params.id).single();
  if (!existing) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
  if (existing.steam_id !== steam_id) return NextResponse.json({ error: 'Not authorized' }, { status: 403 });
  if (existing.status === 'nsfw_renamed') return NextResponse.json({ error: 'This product has been flagged and cannot be edited' }, { status: 403 });

  const updates = { updated_at: new Date().toISOString() };
  if (price !== undefined && price >= 100) updates.price = price;
  if (description !== undefined) updates.description = description;

  const { data, error } = await supabase.from('store_products').update(updates).eq('id', params.id).select().single();
  if (error) throw error;
  return NextResponse.json({ success: true, data }, { status: 200 });
}

export async function DELETE(request, { params }) {
  const supabase = getSupabase();
  if (!supabase) return NextResponse.json({ error: 'DB config error' }, { status: 500 });

  const { searchParams } = new URL(request.url);
  const steam_id = searchParams.get('steam_id');
  if (!steam_id) return NextResponse.json({ error: 'steam_id required' }, { status: 400 });

  const { data: existing } = await supabase.from('store_products').select('steam_id').eq('id', params.id).single();
  if (!existing) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
  if (existing.steam_id !== steam_id) return NextResponse.json({ error: 'Not authorized' }, { status: 403 });

  const { error } = await supabase.from('store_products').delete().eq('id', params.id);
  if (error) throw error;
  return NextResponse.json({ success: true }, { status: 200 });
}
