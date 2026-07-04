-- 3 New Business Tables
CREATE TABLE IF NOT EXISTS public.business_licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL,
    business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
    license_number TEXT NOT NULL UNIQUE,
    license_type TEXT NOT NULL,
    business_type TEXT NOT NULL,
    business_name TEXT,
    status TEXT DEFAULT 'pending',
    fee BIGINT DEFAULT 0,
    renewal_fee BIGINT DEFAULT 0,
    issued_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.business_finances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    revenue BIGINT DEFAULT 0,
    expenses BIGINT DEFAULT 0,
    profit BIGINT DEFAULT 0,
    tax_due BIGINT DEFAULT 0,
    tax_paid BIGINT DEFAULT 0,
    employee_count INTEGER DEFAULT 0,
    transaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (business_id, date)
);

CREATE TABLE IF NOT EXISTS public.business_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    quantity INTEGER DEFAULT 0,
    cost_per_unit BIGINT DEFAULT 0,
    last_ordered TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (business_id, item_name)
);

-- Apply Kronus RLS pattern to all 26 tables
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS service_all ON public.%I', tbl);
        EXECUTE format('CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
        EXECUTE format('GRANT ALL ON public.%I TO service_role', tbl);
    END LOOP;
END $$;
