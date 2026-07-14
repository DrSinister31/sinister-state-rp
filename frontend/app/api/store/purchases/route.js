import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { createHash, randomBytes } from 'crypto';

function generatePasscode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  const bytes = randomBytes(6);
  for (let i = 0; i < 4; i++) result += chars[bytes[i] % chars.length];
  result += '-';
  for (let i = 4; i < 6; i++) result += chars[bytes[i] % chars.length];
  return result;
}

function hashSkinData(skinData) {
  const sorted = {};
  Object.keys(skinData).sort().forEach(k => { sorted[k] = skinData[k]; });
  return createHash('sha256').update(JSON.stringify(sorted)).digest('hex').slice(0, 12);
}

export async function POST(request) {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { buyer_steam_id, product_id } = await request.json();
    if (!buyer_steam_id || !product_id) {
      return NextResponse.json({ error: 'buyer_steam_id and product_id required' }, { status: 400 });
    }

    // Fetch product
    const { data: product, error: productError } = await supabase.from('store_products').select('*').eq('id', product_id).single();
    if (productError || !product) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
    if (product.status !== 'approved') return NextResponse.json({ error: 'Product is not available for purchase' }, { status: 400 });
    if (product.steam_id === buyer_steam_id) return NextResponse.json({ error: 'Cannot buy your own product' }, { status: 400 });

    // Check buyer balance
    const { data: buyerMarks } = await supabase.from('player_marks').select('marks').eq('steam_id', buyer_steam_id).maybeSingle();
    const balance = buyerMarks?.marks ?? 0;
    if (balance < product.price) {
      return NextResponse.json({ error: `Insufficient marks. You have ${balance}, need ${product.price}` }, { status: 400 });
    }

    // Deduct from buyer
    const { error: deductError } = await supabase.from('player_marks').update({ marks: balance - product.price }).eq('steam_id', buyer_steam_id);
    if (deductError) throw deductError;

    // Credit seller
    const { data: sellerMarks } = await supabase.from('player_marks').select('marks').eq('steam_id', product.steam_id).maybeSingle();
    const sellerBalance = sellerMarks?.marks ?? 0;
    await supabase.from('player_marks').update({ marks: sellerBalance + product.price }).eq('steam_id', product.steam_id);

    // Insert purchase record
    await supabase.from('store_purchases').insert({
      buyer_steam_id,
      product_id,
      seller_steam_id: product.steam_id,
      price_paid: product.price,
    });

    // Increment sales
    await supabase.from('store_products').update({ sales: (product.sales || 0) + 1 }).eq('id', product_id);

    // Check for duplicate skin hash (buyer already owns this exact skin)
    const newHash = hashSkinData(product.skin_data);
    const { data: dupCheck } = await supabase.from('user_skins').select('passcode, skin_name').eq('steam_id', buyer_steam_id).eq('skin_hash', newHash).maybeSingle();

    let buyerPasscode;
    if (dupCheck) {
      buyerPasscode = dupCheck.passcode;
    } else {
      buyerPasscode = generatePasscode();

      // Copy skin to buyer's user_skins with new passcode
      await supabase.from('user_skins').insert({
        steam_id: buyer_steam_id,
        skin_name: `${product.skin_name} (Store)`,
        species: product.species,
        skin_data: product.skin_data,
        material_preset: product.material_preset || 'matte',
        pattern_type: product.pattern_type ?? 0,
        source: 'store',
        passcode: buyerPasscode,
        skin_hash: newHash,
      });
    }

    // Auto-queue skin injection via pending_tasks
    await supabase.from('pending_tasks').insert({
      command: `injectskin ${buyer_steam_id} ${buyerPasscode}`,
      target_id: buyer_steam_id,
      is_raw_command: false,
      status: 'pending',
    });

    return NextResponse.json({
      success: true,
      message: `Purchased "${product.skin_name}" for ${product.price} marks! Use !applyskin ${buyerPasscode} to apply it.`,
      passcode: buyerPasscode,
      remaining_balance: balance - product.price,
    }, { status: 200 });
  } catch (error) {
    console.error('Purchase error:', error);
    return NextResponse.json({ error: 'Purchase failed', details: error.message }, { status: 500 });
  }
}
