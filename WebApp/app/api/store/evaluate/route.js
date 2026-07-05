import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Color palette evaluation — scores creativity and categorizes rarity
function evaluateSkin(skinData) {
  if (!skinData || typeof skinData !== 'object') return { score: 0, tier: 'common', reasoning: 'No valid skin data' };

  const layers = ['b', 'u', 'm', 'f', 'd1', 'md', 'e'];
  const colors = [];
  let hdrCount = 0;
  let totalBrightness = 0;
  let uniqueHues = new Set();

  for (const key of layers) {
    const val = skinData[key];
    if (!val || typeof val !== 'string') continue;
    const x = parseFloat((val.match(/X=([-\d.]+)/) || [])[1]) || 0;
    const y = parseFloat((val.match(/Y=([-\d.]+)/) || [])[1]) || 0;
    const z = parseFloat((val.match(/Z=([-\d.]+)/) || [])[1]) || 0;

    // HDR detection: values outside [0,1] range = neon/glitch
    if (x > 1.0 || y > 1.0 || z > 1.0 || x < 0 || y < 0 || z < 0) hdrCount++;

    // Brightness (approximate luminance)
    const lum = 0.299 * Math.max(0, x) + 0.587 * Math.max(0, y) + 0.114 * Math.max(0, z);
    totalBrightness += lum;

    // Hue quantization (6 buckets)
    if (Math.max(x, y, z) > 0.01) {
      const hueBucket = Math.round((Math.atan2(y - x, z - x) + Math.PI) / (Math.PI / 3)) % 6;
      uniqueHues.add(hueBucket);
    }

    colors.push({ x, y, z, lum, layer: key });
  }

  const avgBrightness = totalBrightness / layers.length;
  const colorVariety = uniqueHues.size; // 1-6

  // Contrast: difference between brightest and darkest
  const brightValues = colors.map(c => c.lum).filter(l => l > 0);
  const contrast = brightValues.length > 1 ? Math.max(...brightValues) - Math.min(...brightValues) : 0;

  // Scoring (0-100)
  let score = 20; // base
  score += colorVariety * 8;       // hue diversity: up to 48
  score += Math.min(hdrCount * 10, 30); // HDR/neon: up to 30
  score += Math.min(contrast * 25, 20);  // contrast: up to 20
  score = Math.min(100, Math.round(score));

  // Tier classification
  let tier = 'common';
  let reasoning = 'Standard earth-tone palette.';
  if (score >= 70) { tier = 'legendary'; reasoning = 'Exceptional multi-hue design with striking contrast and distinctive character.'; }
  else if (score >= 50) { tier = 'rare'; reasoning = 'Creative use of color variety and brightness. Stands out from typical patterns.'; }
  else if (score >= 35) { tier = 'uncommon'; reasoning = 'Some creative touches beyond the standard palette.'; }
  else { reasoning = 'Standard palette. Clean but common color selection.'; }

  // Rarity price multiplier
  const multipliers = { common: 1.0, uncommon: 1.5, rare: 2.0, legendary: 3.0 };
  const multiplier = multipliers[tier] || 1.0;

  return {
    score,
    tier,
    multiplier,
    details: { colorVariety, hdrCount: hdrCount > 0, contrast: contrast.toFixed(2), avgBrightness: avgBrightness.toFixed(2) },
    reasoning,
    suggestedPrice: Math.round(5000 * multiplier),
  };
}

export async function GET(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { searchParams } = new URL(request.url);
    const productId = searchParams.get('product_id');

    if (productId) {
      // Evaluate existing product
      const { data: product } = await supabase.from('store_products').select('skin_data').eq('id', productId).single();
      if (!product) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
      const evaluation = evaluateSkin(product.skin_data);
      return NextResponse.json({ success: true, evaluation }, { status: 200 });
    }

    // Re-evaluate all approved products and update demand-adjusted prices
    const { data: products } = await supabase.from('store_products').select('*').eq('status', 'approved');
    if (!products?.length) return NextResponse.json({ success: true, updated: 0 }, { status: 200 });

    let updated = 0;
    for (const p of products) {
      const evaluation = evaluateSkin(p.skin_data);
      const demandBonus = p.view_count > 0 ? Math.round((p.sales / Math.max(p.view_count, 1)) * 2000) : 0;
      const newPrice = Math.round(5000 * evaluation.multiplier + demandBonus);

      if (newPrice !== p.price_auto || evaluation.score !== p.rarity_score || evaluation.tier !== p.rarity_tier) {
        await supabase.from('store_products').update({
          rarity_score: evaluation.score,
          rarity_tier: evaluation.tier,
          price_auto: newPrice,
          price: Math.round((p.price + newPrice) / 2), // Blend existing and auto price
          updated_at: new Date().toISOString(),
        }).eq('id', p.id);
        updated++;
      }
    }

    return NextResponse.json({ success: true, updated, message: `Re-evaluated ${updated} products` }, { status: 200 });
  } catch (error) {
    console.error('Evaluation error:', error);
    return NextResponse.json({ error: 'Evaluation failed' }, { status: 500 });
  }
}

export async function POST(request) {
  // Evaluate a skin's creativity without saving
  try {
    const { skin_data } = await request.json();
    if (!skin_data) return NextResponse.json({ error: 'skin_data required' }, { status: 400 });
    const evaluation = evaluateSkin(skin_data);
    return NextResponse.json({ success: true, evaluation }, { status: 200 });
  } catch (error) {
    return NextResponse.json({ error: 'Evaluation failed' }, { status: 500 });
  }
}
