import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_KEY;
    if (!supabaseUrl || !supabaseKey) return NextResponse.json({ error: 'DB config error' }, { status: 500 });
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data, error } = await supabase.from('dino_tiers').select('*').neq('tier', 3).order('sort_order', { ascending: true });
    if (error) throw error;

    const carnivores = [];
    const herbivores = [];
    const tier2 = [];

    for (const d of data || []) {
      const entry = { id: d.dino_id, name: d.display_name || d.dino_id, tier: d.tier, diet: d.diet };
      if (d.tier === 2) tier2.push(entry);
      else if (d.diet === 'carnivore') carnivores.push(entry);
      else if (d.diet === 'herbivore') herbivores.push(entry);
    }

    return NextResponse.json({ success: true, carnivores, herbivores, tier2 }, { status: 200 });
  } catch (err) {
    console.error('Dino tiers error:', err);
    return NextResponse.json({ error: 'Failed to load dinosaur tiers' }, { status: 500 });
  }
}
