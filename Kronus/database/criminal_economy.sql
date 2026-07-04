-- NEW TABLES FOR CRIMINAL ECONOMY

-- Drug Reputation System
CREATE TABLE IF NOT EXISTS public.player_drug_xp (
    citizenid TEXT PRIMARY KEY,
    drug_level INTEGER DEFAULT 0,
    drug_xp INTEGER DEFAULT 0,
    total_sales INTEGER DEFAULT 0,
    lifetime_earnings BIGINT DEFAULT 0,
    last_sale TIMESTAMPTZ
);

-- Arms Dealer Stock (rotating)
CREATE TABLE IF NOT EXISTS public.arms_dealer_stock (
    id SERIAL PRIMARY KEY,
    item TEXT NOT NULL,
    stock INTEGER DEFAULT 0,
    price INTEGER DEFAULT 0,
    tier INTEGER DEFAULT 1,
    active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Apply RLS to new tables
ALTER TABLE public.player_drug_xp ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS service_all ON public.player_drug_xp;
CREATE POLICY service_all ON public.player_drug_xp FOR ALL TO service_role USING (true) WITH CHECK (true);

ALTER TABLE public.arms_dealer_stock ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS service_all ON public.arms_dealer_stock;
CREATE POLICY service_all ON public.arms_dealer_stock FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Seed arms dealer stock (Tier 1-2 weapons available by default)
INSERT INTO public.arms_dealer_stock (item, stock, price, tier, active) VALUES
    ('weapon_knife', 10, 500, 1, true),
    ('weapon_snspistol', 5, 3000, 1, true),
    ('weapon_combatpistol', 3, 8000, 2, true),
    ('weapon_microsmg', 3, 12000, 2, true),
    ('weapon_pumpshotgun', 2, 18000, 3, false),
    ('weapon_assaultrifle', 2, 25000, 3, false),
    ('weapon_carbinerifle', 2, 35000, 3, false),
    ('weapon_heavypistol', 1, 15000, 4, false),
    ('weapon_smg', 1, 28000, 4, false),
    ('weapon_combatmg', 1, 45000, 5, false),
    ('armor', 10, 2000, 1, true),
    ('weapon_suppressor', 3, 5000, 3, false),
    ('lockpick', 10, 100, 1, true),
    ('advancedlockpick', 5, 500, 2, true)
ON CONFLICT DO NOTHING;

-- Seed bot config defaults
INSERT INTO public.bot_config (key, value) VALUES
    ('arms_dealer_rotate_hours', '2'),
    ('arms_dealer_max_tier', '2'),
    ('drug_alert_chance_weed', '15'),
    ('drug_alert_chance_cocaine', '25'),
    ('drug_alert_chance_meth', '35'),
    ('drug_alert_chance_heroin', '40'),
    ('drug_alert_chance_fentanyl', '55')
ON CONFLICT (key) DO NOTHING;
