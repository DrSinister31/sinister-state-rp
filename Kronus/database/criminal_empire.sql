-- ============================================================================
-- CRIMINAL EMPIRE SYSTEM — Organizations, Territories, Drug Spots, Witnesses
-- ============================================================================

-- Organization registry
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    archetype TEXT NOT NULL CHECK (archetype IN ('cartel','mafia','gang','biker','syndicate')),
    color TEXT DEFAULT '#ff0000',
    founder_citizenid TEXT NOT NULL,
    hq_territory TEXT,
    initiation_fee INTEGER DEFAULT 0,
    is_ai BOOLEAN DEFAULT false,
    member_count INTEGER DEFAULT 1,
    total_rep INTEGER DEFAULT 0,
    founded_at TIMESTAMPTZ DEFAULT now(),
    active BOOLEAN DEFAULT true
);

-- Organization members
CREATE TABLE IF NOT EXISTS public.org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    citizenid TEXT NOT NULL,
    rank INTEGER DEFAULT 0,
    rank_title TEXT DEFAULT 'Member',
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(org_id, citizenid)
);

-- Territory claims
CREATE TABLE IF NOT EXISTS public.org_territories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    zone_name TEXT NOT NULL,
    contested_by UUID REFERENCES public.organizations(id),
    controlled_since TIMESTAMPTZ DEFAULT now(),
    UNIQUE(zone_name)
);

-- Archetype slot caps per player count
CREATE TABLE IF NOT EXISTS public.criminal_slots (
    archetype TEXT PRIMARY KEY,
    min_players INTEGER DEFAULT 0,
    max_slots INTEGER DEFAULT 1,
    current_slots INTEGER DEFAULT 0,
    ai_filled INTEGER DEFAULT 0
);

-- Drug dealing spots
CREATE TABLE IF NOT EXISTS public.drug_spots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_name TEXT NOT NULL,
    label TEXT NOT NULL,
    coords JSONB NOT NULL DEFAULT '{"x":0,"y":0,"z":0}',
    buyer_density INTEGER DEFAULT 3,
    best_time TEXT DEFAULT 'night',
    org_id UUID REFERENCES public.organizations(id),
    controlled_by TEXT,
    active BOOLEAN DEFAULT true
);

-- Crime witnesses
CREATE TABLE IF NOT EXISTS public.crime_witnesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crime_type TEXT NOT NULL,
    location TEXT NOT NULL,
    zone_name TEXT,
    perpetrator_citizenid TEXT,
    witness_type TEXT DEFAULT 'civilian',
    reported_to_police BOOLEAN DEFAULT false,
    caught_on_camera BOOLEAN DEFAULT false,
    ps_mdt_alerted BOOLEAN DEFAULT false,
    occurred_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
DO $$
DECLARE tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'organizations','org_members','org_territories','criminal_slots','drug_spots','crime_witnesses'
    ]) LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename=tbl AND policyname='service_all') THEN
            EXECUTE format('CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
        END IF;
    END LOOP;
END $$;

-- Seed slot caps
INSERT INTO public.criminal_slots (archetype, min_players, max_slots) VALUES
    ('cartel', 0, 1), ('mafia', 0, 1), ('gang', 0, 1), ('biker', 0, 1), ('syndicate', 0, 1)
ON CONFLICT (archetype) DO NOTHING;

-- Seed 25 drug spots across Texas neighborhoods
INSERT INTO public.drug_spots (zone_name, label, coords, buyer_density, best_time) VALUES
    ('Loma Vista', 'Route 68 Gas Station', '{"x":1175,"y":2642,"z":38}', 5, 'night'),
    ('Loma Vista', 'Harmony Motel', '{"x":1180,"y":2630,"z":38}', 4, 'night'),
    ('Loma Vista', 'Abandoned Barn', '{"x":1165,"y":2650,"z":38}', 5, 'night'),
    ('Loma Vista', 'Trailer Park Corner', '{"x":1170,"y":2645,"z":38}', 4, 'night'),
    ('Loma Vista', 'Desert Crossroads', '{"x":1178,"y":2635,"z":38}', 3, 'all_day'),
    ('Loma Vista', 'Behind the Diner', '{"x":1182,"y":2648,"z":38}', 4, 'night'),
    ('Third Ward', 'Davis Ave Alley', '{"x":85,"y":-1430,"z":29}', 4, 'night'),
    ('Third Ward', 'Grove St Corner', '{"x":90,"y":-1950,"z":21}', 5, 'night'),
    ('Third Ward', 'Project Stairwell', '{"x":95,"y":-1425,"z":29}', 4, 'all_day'),
    ('Third Ward', 'Liquor Store Back', '{"x":88,"y":-1435,"z":29}', 3, 'evening'),
    ('Third Ward', 'Abandoned House', '{"x":82,"y":-1945,"z":21}', 5, 'night'),
    ('Sunnyside', 'Davis Apartments', '{"x":155,"y":-1305,"z":29}', 4, 'all_day'),
    ('Sunnyside', 'Corner Store Lot', '{"x":145,"y":-1295,"z":29}', 3, 'evening'),
    ('Sunnyside', 'Industrial Alley', '{"x":160,"y":-1310,"z":29}', 4, 'night'),
    ('Sunnyside', 'Park Bench', '{"x":150,"y":-1300,"z":29}', 3, 'all_day'),
    ('Sunnyside', 'Under the Bridge', '{"x":140,"y":-1290,"z":29}', 5, 'night'),
    ('Rancier Ave', 'Trailer Park Rd', '{"x":130,"y":3710,"z":40}', 3, 'night'),
    ('Rancier Ave', 'Biker Hangout', '{"x":120,"y":3705,"z":40}', 4, 'night'),
    ('East End', 'Dock Worker Alley', '{"x":805,"y":-1505,"z":30}', 3, 'afternoon'),
    ('East End', 'Warehouse Loading', '{"x":795,"y":-1495,"z":30}', 4, 'afternoon'),
    ('East End', 'Rail Yard Back', '{"x":810,"y":-1510,"z":30}', 3, 'evening'),
    ('East End', 'Truck Stop', '{"x":800,"y":-1500,"z":30}', 4, 'all_day'),
    ('Channelview', 'Refinery Lot', '{"x":905,"y":-2305,"z":30}', 3, 'afternoon'),
    ('Channelview', 'Shipping Container', '{"x":895,"y":-2295,"z":30}', 3, 'evening'),
    ('The Heights', 'Mirror Park Path', '{"x":1100,"y":-705,"z":57}', 2, 'late_night')
ON CONFLICT DO NOTHING;

-- Feature toggles
INSERT INTO public.bot_config (key, value) VALUES
    ('criminal_empire_enabled', 'true'),
    ('ai_organizations_enabled', 'true'),
    ('gang_wars_enabled', 'true'),
    ('police_witness_enabled', 'true'),
    ('drug_spots_enabled', 'true')
ON CONFLICT (key) DO NOTHING;
