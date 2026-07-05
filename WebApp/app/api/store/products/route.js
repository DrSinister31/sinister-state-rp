import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

function evaluateSkin(skinData) {
  if (!skinData || typeof skinData !== 'object') return { score: 0, tier: 'common', multiplier: 1.0, suggestedPrice: 5000 };
  const layers = ['b', 'u', 'm', 'f', 'd1', 'md', 'e'];
  let hdrCount = 0;
  let totalBrightness = 0;
  const uniqueHues = new Set();
  for (const key of layers) {
    const val = skinData[key];
    if (!val || typeof val !== 'string') continue;
    const x = parseFloat((val.match(/X=([-\d.]+)/) || [])[1]) || 0;
    const y = parseFloat((val.match(/Y=([-\d.]+)/) || [])[1]) || 0;
    const z = parseFloat((val.match(/Z=([-\d.]+)/) || [])[1]) || 0;
    if (x > 1.0 || y > 1.0 || z > 1.0 || x < 0 || y < 0 || z < 0) hdrCount++;
    totalBrightness += 0.299 * Math.max(0, x) + 0.587 * Math.max(0, y) + 0.114 * Math.max(0, z);
    if (Math.max(x, y, z) > 0.01) uniqueHues.add(Math.round((Math.atan2(y - x, z - x) + Math.PI) / (Math.PI / 3)) % 6);
  }
  const colorVariety = uniqueHues.size;
  let score = 20 + colorVariety * 8 + Math.min(hdrCount * 10, 30) + Math.min(Math.abs(totalBrightness / layers.length - 0.5) * 40, 20);
  score = Math.min(100, Math.round(score));
  let tier = 'common';
  if (score >= 70) tier = 'legendary';
  else if (score >= 50) tier = 'rare';
  else if (score >= 35) tier = 'uncommon';
  const multipliers = { common: 1.0, uncommon: 1.5, rare: 2.0, legendary: 3.0 };
  return { score, tier, multiplier: multipliers[tier] || 1.0, suggestedPrice: Math.round(5000 * (multipliers[tier] || 1.0)), details: { colorVariety, hdr: hdrCount > 0 } };
}

export const dynamic = 'force-dynamic';

export async function GET(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = Math.min(parseInt(searchParams.get('limit') || '12'), 50);
    const species = searchParams.get('species');
    const sort = searchParams.get('sort') || 'newest';
    const search = searchParams.get('search');

    let query = supabase.from('store_products').select('*', { count: 'exact' }).eq('status', 'approved');

    if (species && species !== 'All') query = query.eq('species', species);
    if (search) query = query.ilike('skin_name', `%${search}%`);

    switch (sort) {
      case 'popular': query = query.order('sales', { ascending: false }); break;
      case 'cheapest': query = query.order('price', { ascending: true }); break;
      default: query = query.order('created_at', { ascending: false });
    }

    const from = (page - 1) * limit;
    const { data, count, error } = await query.range(from, from + limit - 1);
    if (error) throw error;

    return NextResponse.json({ success: true, data: data || [], total: count || 0, page, limit }, { status: 200 });
  } catch (error) {
    console.error('Store products list error:', error);
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const body = await request.json();
    const { steam_id, skin_name, species, skin_data, material_preset, pattern_type, price, description, thumbnail_url } = body;

    if (!steam_id || !skin_name || !skin_data) {
      return NextResponse.json({ error: 'steam_id, skin_name, and skin_data are required' }, { status: 400 });
    }
    if (price < 100) {
      return NextResponse.json({ error: 'Price must be at least 100 marks' }, { status: 400 });
    }
    if (skin_name.length > 64) {
      return NextResponse.json({ error: 'Skin name must be 64 characters or fewer' }, { status: 400 });
    }

    // Auto-evaluate rarity and suggest price
    const evaluation = evaluateSkin(skin_data);
    const autoPrice = Math.round(evaluation.suggestedPrice);
    const finalPrice = Math.round((price + autoPrice) / 2); // Blend creator price with auto price

    const { data, error } = await supabase.from('store_products').insert({
      steam_id,
      skin_name: skin_name.trim(),
      species: species || 'Unknown',
      skin_data,
      material_preset: material_preset || 'matte',
      pattern_type: pattern_type ?? 0,
      price: finalPrice,
      price_auto: autoPrice,
      description: description || '',
      thumbnail_url: thumbnail_url || '',
      status: 'pending',
      rarity_score: evaluation.score,
      rarity_tier: evaluation.tier,
    }).select().single();

    if (error) throw error;

    // Notify admins via Discord (uses existing bot token, no webhook needed)
    const token = process.env.DISCORD_TOKEN;
    const logChannel = process.env.LOG_CHANNEL_ID;
    if (token && logChannel) {
      const frontendUrl = process.env.FRONTEND_URL || 'https://sinistersparkmap.vercel.app';
      fetch(`https://discord.com/api/v10/channels/${logChannel}/messages`, {
        method: 'POST',
        headers: { 'Authorization': `Bot ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          embeds: [{
            title: '🛒 New Store Submission — Needs Approval',
            description: `**${skin_name.trim()}** — ${species || 'Unknown'} — ${finalPrice.toLocaleString()} marks`,
            color: 0xF5A623,
            fields: [
              { name: 'Rarity', value: `${evaluation.tier} (score: ${evaluation.score})`, inline: true },
              { name: 'Auto Price', value: `${autoPrice.toLocaleString()} marks`, inline: true },
              { name: 'Approve Now', value: `${frontendUrl}/admin/store`, inline: false },
            ],
            timestamp: new Date().toISOString(),
          }],
        }),
      }).catch(() => {});
    }

    return NextResponse.json({ success: true, data }, { status: 201 });
  } catch (error) {
    console.error('Store product create error:', error);
    return NextResponse.json({ error: 'Failed to create product', details: error.message }, { status: 500 });
  }
}
