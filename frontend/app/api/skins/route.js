import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const supabase = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;

export async function POST(request) {
  try {
    const payload = await request.json();

    // 1. Validate Payload Structure
    if (!payload.metadata || !payload.layers) {
      return NextResponse.json(
        { error: 'Invalid payload: Missing metadata or layers.' },
        { status: 400 }
      );
    }

    const { metadata, layers } = payload;

    // Validate metadata keys
    const requiredMetadata = ['species', 'gender', 'pattern', 'variant'];
    for (const key of requiredMetadata) {
      if (metadata[key] === undefined) {
        return NextResponse.json(
          { error: `Invalid payload: Missing metadata.${key}` },
          { status: 400 }
        );
      }
    }

    // 2. Insert into Supabase dino_skins table
    let insertedData = null;
    if (supabase) {
      const { data, error } = await supabase
        .from('dino_skins')
        .insert([
          {
            species: metadata.species,
            gender: metadata.gender,
            pattern: metadata.pattern,
            variant: metadata.variant,
            skin_data: JSON.stringify(payload), // Storing the full JSON structure
            created_at: new Date().toISOString()
          }
        ])
        .select();

      if (error) {
        console.error('Supabase insert error:', error);
        return NextResponse.json(
          { error: 'Failed to save skin to database.', details: error.message },
          { status: 500 }
        );
      }
      insertedData = data;
    } else {
      console.warn('Supabase client not initialized. Skipping database insert.');
    }

    // 3. Trigger Discord Webhook Utility
    const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
    if (webhookUrl) {
      // Build an embed for the new community skin showcase
      const embed = {
        title: '🦕 New Community Skin Showcase!',
        description: `A new skin has been submitted for **${metadata.species}**!`,
        color: 0x3498db,
        fields: [
          { name: 'Species', value: metadata.species, inline: true },
          { name: 'Gender', value: metadata.gender === 1 ? 'Male' : 'Female', inline: true },
          { name: 'Pattern / Variant', value: `${metadata.pattern} / ${metadata.variant}`, inline: true },
          { name: 'Detail Layer', value: layers.detail?.hexUI || 'N/A', inline: true },
          { name: 'Base Tones', value: layers.baseTones?.hexUI || 'N/A', inline: true }
        ],
        footer: {
          text: 'SinisterMap Skin API',
        },
        timestamp: new Date().toISOString()
      };

      try {
        await fetch(webhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            username: 'Skin Showcase Bot',
            embeds: [embed]
          })
        });
      } catch (err) {
        console.error('Discord webhook failed:', err);
        // We don't fail the API request if the webhook fails, but we log it.
      }
    } else {
      console.warn('DISCORD_WEBHOOK_URL not set. Skipping webhook notification.');
    }

    return NextResponse.json(
      { success: true, message: 'Skin saved successfully', data: insertedData },
      { status: 201 }
    );
  } catch (error) {
    console.error('API Error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
