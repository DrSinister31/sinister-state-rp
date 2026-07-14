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
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ error: 'Database configuration error' }, { status: 500 });
    }
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { steam_id, skin_name, species, skin_data, material_preset, pattern_type, source } = await request.json();
    if (!steam_id || !skin_name || !skin_data) {
      return NextResponse.json({ error: 'steam_id, skin_name, and skin_data are required' }, { status: 400 });
    }
    if (skin_name.length > 64) {
      return NextResponse.json({ error: 'Skin name must be 64 characters or fewer' }, { status: 400 });
    }

    const newHash = hashSkinData(skin_data);

    // Check for duplicate hash across all users
    const { data: dupCheck } = await supabase
      .from('user_skins')
      .select('steam_id, skin_name, passcode')
      .eq('skin_hash', newHash)
      .maybeSingle();

    if (dupCheck) {
      if (dupCheck.steam_id === steam_id) {
        return NextResponse.json({
          error: 'You already have this exact skin saved',
          passcode: dupCheck.passcode,
          skin_name: dupCheck.skin_name,
        }, { status: 409 });
      }
      return NextResponse.json({
        error: 'This exact skin color combination already exists and is owned by another player',
      }, { status: 409 });
    }

    // Check if updating existing by name
    const { data: existing } = await supabase
      .from('user_skins')
      .select('id, passcode')
      .eq('steam_id', steam_id)
      .eq('skin_name', skin_name)
      .maybeSingle();

    let result;
    if (existing) {
      const { data, error } = await supabase
        .from('user_skins')
        .update({
          species: species || 'Unknown',
          skin_data,
          material_preset: material_preset || 'matte',
          pattern_type: pattern_type ?? 0,
          source: source || 'original',
          skin_hash: newHash,
          updated_at: new Date().toISOString(),
        })
        .eq('id', existing.id)
        .select()
        .single();
      if (error) throw error;
      result = data;
    } else {
      const passcode = generatePasscode();

      // Ensure passcode is unique
      const { data: pcCheck } = await supabase.from('user_skins').select('id').eq('passcode', passcode).maybeSingle();
      if (pcCheck) {
        return NextResponse.json({ error: 'Failed to generate unique passcode. Please try again.' }, { status: 500 });
      }

      const { data, error } = await supabase
        .from('user_skins')
        .insert({
          steam_id,
          skin_name,
          species: species || 'Unknown',
          skin_data,
          material_preset: material_preset || 'matte',
          pattern_type: pattern_type ?? 0,
          source: source || 'original',
          passcode,
          skin_hash: newHash,
        })
        .select()
        .single();
      if (error) throw error;
      result = data;
    }

    return NextResponse.json({
      success: true,
      data: result,
      message: `Skin saved! Your apply code is: ${result.passcode}. Use !applyskin ${result.passcode} in Discord.`,
    }, { status: 201 });
  } catch (error) {
    console.error('Save skin error:', error);
    return NextResponse.json({ error: 'Failed to save skin', details: error.message }, { status: 500 });
  }
}
