-- ============================================================================
-- SYNIX STATE: MASTER PHASES 3-6 TABLES
-- All tables needed for remaining features. Run ONCE on Supabase.
-- Sorted by feature area: AI, Medical, Economy, Jobs, Criminal, Aviation, Housing
-- ============================================================================

-- ============================================================================
-- 1. AI / WORLD BALANCING
-- ============================================================================

-- Per-sector AI density tracking (AI_Worth_Ratio spec)
CREATE TABLE IF NOT EXISTS public.ai_sector_density (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sector_name TEXT NOT NULL UNIQUE,
    sector_type TEXT DEFAULT 'urban',
    center_coords JSONB DEFAULT '{"x":0,"y":0,"z":0}',
    radius FLOAT DEFAULT 500.0,
    base_ai_count INTEGER DEFAULT 10,
    current_ai_count INTEGER DEFAULT 0,
    current_player_count INTEGER DEFAULT 0,
    density_multiplier FLOAT DEFAULT 1.0,
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- Police AI fallback state tracking
CREATE TABLE IF NOT EXISTS public.police_ai_fallback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leo_player_count INTEGER DEFAULT 0,
    threshold INTEGER DEFAULT 3,
    vanilla_ai_enabled BOOLEAN DEFAULT false,
    last_checked TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- 2. MEDICAL AI (Spec 1.2)
-- ============================================================================

-- Emergency room treatment records
CREATE TABLE IF NOT EXISTS public.medical_treatments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_citizenid TEXT NOT NULL,
    treatment_type TEXT NOT NULL,
    injury_cause TEXT,
    doctor_citizenid TEXT,
    is_ai_doctor BOOLEAN DEFAULT false,
    treatment_duration_sec INTEGER DEFAULT 60,
    invoice_amount INTEGER DEFAULT 500,
    invoice_paid BOOLEAN DEFAULT false,
    outcome TEXT DEFAULT 'treated',
    hospital_location TEXT,
    treated_at TIMESTAMPTZ DEFAULT now()
);

-- Ambulance billing
CREATE TABLE IF NOT EXISTS public.ambulance_billing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_citizenid TEXT NOT NULL,
    treatment_id UUID REFERENCES public.medical_treatments(id),
    base_cost INTEGER DEFAULT 500,
    distance_charge INTEGER DEFAULT 100,
    severity_multiplier FLOAT DEFAULT 1.0,
    total_amount INTEGER NOT NULL,
    paid BOOLEAN DEFAULT false,
    billed_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- 3. ECONOMY / LUXURY TARIFFS (Spec 2.2, 2.3)
-- ============================================================================

-- Dynamic tariff rates applied during inflation state
CREATE TABLE IF NOT EXISTS public.tariff_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL UNIQUE,
    description TEXT,
    base_rate FLOAT DEFAULT 1.0,
    current_rate FLOAT DEFAULT 1.0,
    inflation_multiplier FLOAT DEFAULT 1.0,
    applies_to TEXT[] DEFAULT '{}',
    active BOOLEAN DEFAULT false,
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- Luxury flash auctions (hypercars, skins, licenses)
CREATE TABLE IF NOT EXISTS public.luxury_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_type TEXT NOT NULL,
    asset_name TEXT NOT NULL,
    asset_properties JSONB DEFAULT '{}',
    starting_bid INTEGER NOT NULL,
    current_bid INTEGER,
    winner_citizenid TEXT,
    auction_location TEXT,
    listed_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours'),
    status TEXT DEFAULT 'active',
    final_amount INTEGER,
    closed_at TIMESTAMPTZ
);

-- Auction bids
CREATE TABLE IF NOT EXISTS public.auction_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES public.luxury_auctions(id),
    bidder_citizenid TEXT NOT NULL,
    amount INTEGER NOT NULL,
    placed_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- 4. JOBS / APPLICATIONS / CLOCK-IN (Spec 3.1, 3.3)
-- ============================================================================

-- Auto-filled job applications (metadata scraping)
CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_citizenid TEXT NOT NULL,
    target_business_id UUID,
    target_job TEXT,
    experience_metrics JSONB DEFAULT '{}',
    approval_status TEXT DEFAULT 'pending',
    reviewer_citizenid TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Clock-in GPS nodes
CREATE TABLE IF NOT EXISTS public.clock_in_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id),
    label TEXT NOT NULL,
    coords JSONB NOT NULL DEFAULT '{"x":0,"y":0,"z":0}',
    radius FLOAT DEFAULT 15.0,
    job_restriction TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Employee shift records
CREATE TABLE IF NOT EXISTS public.employee_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_citizenid TEXT NOT NULL,
    business_id UUID REFERENCES public.businesses(id),
    clock_in_node_id UUID REFERENCES public.clock_in_nodes(id),
    clock_in_time TIMESTAMPTZ DEFAULT now(),
    clock_out_time TIMESTAMPTZ,
    total_hours FLOAT,
    total_pay INTEGER,
    paid BOOLEAN DEFAULT false,
    session_active BOOLEAN DEFAULT true
);

-- Background check records
CREATE TABLE IF NOT EXISTS public.background_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_citizenid TEXT NOT NULL,
    requested_by_citizenid TEXT,
    result JSONB DEFAULT '{}',
    status TEXT DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- 5. CRIMINAL / GANG (Spec 3, Phase 2)
-- ============================================================================

-- Gang roster
CREATE TABLE IF NOT EXISTS public.gang_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL,
    gang_name TEXT NOT NULL,
    rank TEXT DEFAULT 'Member',
    rank_level INTEGER DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT now(),
    active BOOLEAN DEFAULT true,
    UNIQUE(citizenid, gang_name)
);

-- Criminal street reputation scores
CREATE TABLE IF NOT EXISTS public.street_reputation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL UNIQUE,
    rep_score INTEGER DEFAULT 0,
    known_alias TEXT,
    territory_control INTEGER DEFAULT 0,
    street_cred INTEGER DEFAULT 0,
    heat_level INTEGER DEFAULT 0,
    last_active_turf TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Darknet / underworld vetting network (Spec 3 criminal)
CREATE TABLE IF NOT EXISTS public.darknet_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_type TEXT NOT NULL,
    issuer_citizenid TEXT,
    target TEXT,
    payout INTEGER DEFAULT 0,
    requirements JSONB DEFAULT '{}',
    status TEXT DEFAULT 'open',
    accepted_by TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- 6. AVIATION / AIRSPACE (Spec 4.2)
-- ============================================================================

-- Pre-filed flight plans (ATC clearance)
CREATE TABLE IF NOT EXISTS public.flight_clearances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pilot_citizenid TEXT NOT NULL,
    aircraft_model TEXT,
    departure_location TEXT,
    destination_location TEXT,
    filed_altitude INTEGER DEFAULT 100,
    filed_departure TIMESTAMPTZ DEFAULT now(),
    clearance_status TEXT DEFAULT 'pending',
    cleared_by TEXT,
    actual_departure TIMESTAMPTZ,
    actual_landing TIMESTAMPTZ,
    squawk_code TEXT,
    hijacked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- National Guard intercept log (4-stage matrix)
CREATE TABLE IF NOT EXISTS public.intercept_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flight_clearance_id UUID REFERENCES public.flight_clearances(id),
    pilot_citizenid TEXT,
    aircraft_model TEXT,
    stage_1_triggered BOOLEAN DEFAULT false,
    stage_1_at TIMESTAMPTZ,
    stage_2_triggered BOOLEAN DEFAULT false,
    stage_2_at TIMESTAMPTZ,
    stage_3_triggered BOOLEAN DEFAULT false,
    stage_3_at TIMESTAMPTZ,
    stage_4_triggered BOOLEAN DEFAULT false,
    stage_4_at TIMESTAMPTZ,
    aircraft_destroyed BOOLEAN DEFAULT false,
    pilot_ejected BOOLEAN DEFAULT false,
    outcome TEXT,
    started_at TIMESTAMPTZ DEFAULT now()
);

-- Purchased airspace easements (farming, private airspace)
CREATE TABLE IF NOT EXISTS public.airspace_easements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_citizenid TEXT NOT NULL,
    label TEXT,
    bounds_coords JSONB NOT NULL DEFAULT '{"x":0,"y":0,"z":0}',
    radius FLOAT DEFAULT 100.0,
    altitude_max INTEGER DEFAULT 100,
    purpose TEXT DEFAULT 'crop_dusting',
    whitelisted_pilots TEXT[] DEFAULT '{}',
    purchased_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ,
    active BOOLEAN DEFAULT true
);


-- ============================================================================
-- 7. HOUSING / RP (Phase 6)
-- ============================================================================

-- Real estate property listings
CREATE TABLE IF NOT EXISTS public.property_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL,
    property_type TEXT DEFAULT 'residential',
    address TEXT,
    interior_id INTEGER,
    price INTEGER NOT NULL,
    owner_citizenid TEXT,
    listing_status TEXT DEFAULT 'available',
    bedrooms INTEGER DEFAULT 1,
    bathrooms INTEGER DEFAULT 1,
    garage_spots INTEGER DEFAULT 0,
    square_footage INTEGER DEFAULT 500,
    listed_at TIMESTAMPTZ DEFAULT now(),
    sold_at TIMESTAMPTZ
);

-- Marriage / civil union records
CREATE TABLE IF NOT EXISTS public.marriage_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    spouse1_citizenid TEXT NOT NULL,
    spouse2_citizenid TEXT NOT NULL,
    officiant TEXT,
    ceremony_location TEXT,
    married_at TIMESTAMPTZ DEFAULT now(),
    divorced_at TIMESTAMPTZ,
    status TEXT DEFAULT 'active'
);

-- Player insurance policies
CREATE TABLE IF NOT EXISTS public.insurance_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_holder_citizenid TEXT NOT NULL,
    policy_type TEXT NOT NULL,
    coverage_description TEXT,
    coverage_amount INTEGER NOT NULL,
    monthly_premium INTEGER NOT NULL,
    deductible INTEGER DEFAULT 500,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    next_payment_due TIMESTAMPTZ
);

-- Wills & inheritance
CREATE TABLE IF NOT EXISTS public.wills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    testator_citizenid TEXT NOT NULL,
    beneficiary_citizenid TEXT NOT NULL,
    asset_type TEXT NOT NULL,
    asset_value INTEGER DEFAULT 0,
    asset_description TEXT,
    filed_at TIMESTAMPTZ DEFAULT now(),
    executed_at TIMESTAMPTZ,
    executed BOOLEAN DEFAULT false
);


-- ============================================================================
-- 8. HIJACKING / LOGISTICS (Spec 4.3)
-- ============================================================================

-- Premium trailer hijacking incidents
CREATE TABLE IF NOT EXISTS public.hijack_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perpetrator_citizenid TEXT,
    cargo_tier TEXT NOT NULL,
    cargo_value INTEGER DEFAULT 0,
    alert_level TEXT DEFAULT 'Priority 5',
    fib_notified BOOLEAN DEFAULT false,
    police_responded BOOLEAN DEFAULT false,
    outcome TEXT DEFAULT 'in_progress',
    location_coords JSONB DEFAULT '{}',
    started_at TIMESTAMPTZ DEFAULT now(),
    resolved_at TIMESTAMPTZ
);


-- ============================================================================
-- 9. RLS POLICIES — Apply service_role access to ALL new tables
-- ============================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename IN (
            'ai_sector_density','police_ai_fallback','medical_treatments','ambulance_billing',
            'tariff_rates','luxury_auctions','auction_bids','job_applications','clock_in_nodes',
            'employee_shifts','background_checks','gang_memberships','street_reputation',
            'darknet_contracts','flight_clearances','intercept_logs','airspace_easements',
            'property_listings','marriage_records','insurance_policies','wills','hijack_incidents'
        )
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies WHERE tablename = tbl AND policyname = 'service_all'
        ) THEN
            EXECUTE format('CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
        END IF;
    END LOOP;
END $$;


-- ============================================================================
-- 10. SEED DEFAULT DATA
-- ============================================================================

-- Default AI sectors (Texas-themed)
INSERT INTO public.ai_sector_density (sector_name, sector_type, center_coords, radius, base_ai_count) VALUES
    ('Downtown Houston', 'urban', '{"x":-540,"y":-212,"z":30}', 800, 20),
    ('Davis Ave', 'urban', '{"x":150,"y":-1300,"z":29}', 600, 15),
    ('Cypress Flats', 'industrial', '{"x":900,"y":-2300,"z":30}', 700, 10),
    ('Mirror Park', 'suburban', '{"x":1100,"y":-700,"z":57}', 500, 8),
    ('Sandy Shores (Killeen)', 'rural', '{"x":2400,"y":3100,"z":48}', 1000, 5),
    ('Paleto Bay (Ft. Worth)', 'rural', '{"x":-440,"y":6000,"z":31}', 600, 5),
    ('Houston Intl', 'industrial', '{"x":-1050,"y":-2800,"z":15}', 500, 6),
    ('Fort Zancudo', 'military', '{"x":-2200,"y":3250,"z":30}', 400, 4),
    ('Vespucci Beach', 'coastal', '{"x":-1300,"y":-1400,"z":4}', 500, 7),
    ('Grapeseed', 'rural', '{"x":1700,"y":4900,"z":44}', 600, 4)
ON CONFLICT (sector_name) DO NOTHING;

-- Police AI fallback default
INSERT INTO public.police_ai_fallback (leo_player_count, threshold, vanilla_ai_enabled) VALUES
    (0, 3, false)
ON CONFLICT DO NOTHING;

-- Default tariff rates (neutral — no inflation)
INSERT INTO public.tariff_rates (category, description, base_rate, current_rate, applies_to) VALUES
    ('fuel', 'Fuel price multiplier', 1.0, 1.0, ARRAY['gasoline','diesel']),
    ('ammunition', 'Ammo price multiplier', 1.0, 1.0, ARRAY['pistol_ammo','rifle_ammo','shotgun_ammo','smg_ammo']),
    ('property_tax', 'Property tax multiplier for multi-owners', 1.0, 1.0, ARRAY['residential','commercial']),
    ('licensing', 'City Hall licensing fee multiplier', 1.0, 1.0, ARRAY['business_license','weapon_license','drivers_license']),
    ('luxury_goods', 'Luxury item price multiplier', 1.0, 1.0, ARRAY['luxury_vehicles','designer_clothing','jewelry'])
ON CONFLICT (category) DO NOTHING;

-- Feature toggles for new systems
INSERT INTO public.bot_config (key, value) VALUES
    ('ai_sector_throttle_enabled', 'true'),
    ('medical_ai_enabled', 'true'),
    ('vanilla_cop_fallback_enabled', 'true'),
    ('luxury_tariffs_enabled', 'true'),
    ('luxury_auctions_enabled', 'true'),
    ('job_auto_apply_enabled', 'true'),
    ('clock_in_nodes_enabled', 'true'),
    ('gang_system_enabled', 'true'),
    ('street_reputation_enabled', 'true'),
    ('flight_intercept_enabled', 'true'),
    ('airspace_easements_enabled', 'true'),
    ('hijack_alerts_enabled', 'true'),
    ('marriage_system_enabled', 'true'),
    ('insurance_system_enabled', 'true'),
    ('will_system_enabled', 'true')
ON CONFLICT (key) DO NOTHING;
