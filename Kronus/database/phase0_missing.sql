-- Missing Phase 0 tables — run individually if phase0_tables.sql didn't complete
CREATE TABLE IF NOT EXISTS public.business_pnl (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    gross_income BIGINT DEFAULT 0,
    total_expenses BIGINT DEFAULT 0,
    net_profit BIGINT DEFAULT 0,
    tax_due BIGINT DEFAULT 0,
    tax_paid BIGINT DEFAULT 0,
    employee_count INTEGER DEFAULT 0,
    ai_employee_count INTEGER DEFAULT 0,
    revenue_breakdown JSONB DEFAULT '{}',
    expense_breakdown JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (business_id, period_start)
);

CREATE TABLE IF NOT EXISTS public.business_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    expense_type TEXT NOT NULL,
    label TEXT NOT NULL,
    amount BIGINT NOT NULL,
    billing_cycle TEXT DEFAULT 'weekly',
    is_required BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    effect_multiplier FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.business_ratings (
    business_id UUID REFERENCES public.businesses(id) PRIMARY KEY,
    on_time_pct FLOAT DEFAULT 100.0,
    completion_pct FLOAT DEFAULT 100.0,
    dispute_resolution_pct FLOAT DEFAULT 100.0,
    longevity_days INTEGER DEFAULT 0,
    review_avg FLOAT DEFAULT 5.0,
    overall_stars FLOAT DEFAULT 5.0,
    star_tier TEXT DEFAULT 'Platinum',
    total_deliveries INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.city_treasury (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fund_name TEXT NOT NULL UNIQUE,
    balance BIGINT DEFAULT 0,
    monthly_allocation BIGINT DEFAULT 0,
    monthly_actual BIGINT DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- Apply RLS
DO $$
DECLARE tbl TEXT;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        AND tablename IN ('business_pnl','business_expenses','business_ratings','city_treasury')
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS service_all ON public.%I', tbl);
        EXECUTE format('CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
    END LOOP;
END $$;
