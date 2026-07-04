-- ============================================================================
-- SINISTER STATE TX — PHASE 0 TABLES (Lean Economy)
-- ============================================================================

-- Business Expenses
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

-- Expense Templates
CREATE TABLE IF NOT EXISTS public.expense_templates (
    business_type TEXT NOT NULL,
    expense_type TEXT NOT NULL,
    label TEXT NOT NULL,
    base_amount BIGINT NOT NULL,
    billing_cycle TEXT DEFAULT 'weekly',
    is_required BOOLEAN DEFAULT true,
    effect_description TEXT,
    effect_multiplier FLOAT DEFAULT 1.0,
    PRIMARY KEY (business_type, expense_type)
);

-- Business P&L
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

-- Business bank accounts
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS bank_account BIGINT DEFAULT 0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS tax_rate_percent FLOAT DEFAULT 10.0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS ai_permanent INTEGER DEFAULT 0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS ai_contractors INTEGER DEFAULT 0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS last_payroll TIMESTAMPTZ;

-- Employee AI flag
ALTER TABLE public.business_employees ADD COLUMN IF NOT EXISTS is_ai BOOLEAN DEFAULT false;
ALTER TABLE public.business_employees ADD COLUMN IF NOT EXISTS hourly_wage INTEGER DEFAULT 100;

-- BBB Ratings
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

-- Warehouse Properties
CREATE TABLE IF NOT EXISTS public.warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.businesses(id),
    property_name TEXT NOT NULL,
    location_coords JSONB NOT NULL,
    tier INTEGER DEFAULT 1,
    max_slots INTEGER NOT NULL,
    used_slots INTEGER DEFAULT 0,
    owner_type TEXT DEFAULT 'npc',
    owner_citizenid TEXT,
    buy_price BIGINT,
    per_order_fee BIGINT DEFAULT 0,
    monthly_upkeep BIGINT DEFAULT 0,
    is_front_for UUID REFERENCES public.businesses(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Department Inventory
CREATE TABLE IF NOT EXISTS public.department_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department TEXT NOT NULL,
    item_name TEXT NOT NULL,
    current_stock INTEGER DEFAULT 0,
    min_threshold INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    wholesale_price BIGINT DEFAULT 0,
    retail_price BIGINT DEFAULT 0,
    last_ordered TIMESTAMPTZ,
    UNIQUE (department, item_name)
);

-- Supply Orders
CREATE TABLE IF NOT EXISTS public.supply_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department TEXT,
    business_id UUID REFERENCES public.businesses(id),
    order_type TEXT NOT NULL,
    items JSONB NOT NULL,
    total_cost BIGINT NOT NULL,
    cargo_tier TEXT DEFAULT 'standard',
    required_truck TEXT DEFAULT 'benson',
    status TEXT DEFAULT 'pending',
    assigned_trucker TEXT,
    robbed BOOLEAN DEFAULT false,
    replacement_for UUID,
    insurance_claim BOOLEAN DEFAULT false,
    base_rate BIGINT DEFAULT 0,
    preferred_provider TEXT,
    load_percentage FLOAT DEFAULT 100.0,
    loaded_by TEXT,
    intentional_overload BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    delivered_at TIMESTAMPTZ
);

-- AI Worker Performance
CREATE TABLE IF NOT EXISTS public.ai_worker_performance (
    worker_id TEXT PRIMARY KEY,
    warehouse_id UUID REFERENCES public.warehouses(id),
    total_loads INTEGER DEFAULT 0,
    correct_loads INTEGER DEFAULT 0,
    underloads INTEGER DEFAULT 0,
    overloads INTEGER DEFAULT 0,
    accuracy_score FLOAT DEFAULT 85.0,
    last_incident TIMESTAMPTZ,
    retraining_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active'
);

-- Order Bids
CREATE TABLE IF NOT EXISTS public.order_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.supply_orders(id),
    business_id UUID REFERENCES public.businesses(id),
    bid_amount BIGINT NOT NULL,
    bidder_citizenid TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Robbery Incidents
CREATE TABLE IF NOT EXISTS public.robbery_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.supply_orders(id),
    cargo_tier TEXT NOT NULL,
    estimated_value BIGINT,
    police_responded BOOLEAN DEFAULT false,
    suspects_escaped BOOLEAN DEFAULT true,
    rubric_score INTEGER,
    occurred_at TIMESTAMPTZ DEFAULT now()
);

-- City Treasury
CREATE TABLE IF NOT EXISTS public.city_treasury (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fund_name TEXT NOT NULL UNIQUE,
    balance BIGINT DEFAULT 0,
    monthly_allocation BIGINT DEFAULT 0,
    monthly_actual BIGINT DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- Tax Transactions
CREATE TABLE IF NOT EXISTS public.tax_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT,
    business_id UUID,
    tax_type TEXT NOT NULL,
    amount BIGINT NOT NULL,
    fund_name TEXT NOT NULL,
    collected_at TIMESTAMPTZ DEFAULT now()
);

-- City Budget Allocations
CREATE TABLE IF NOT EXISTS public.city_budget_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fund_name TEXT NOT NULL UNIQUE,
    mayor_set_percentage FLOAT DEFAULT 0,
    kronus_default_percentage FLOAT NOT NULL,
    last_modified_by TEXT,
    modified_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- APPLY RLS TO ALL NEW TABLES
-- ============================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        AND tablename IN (
            'business_expenses','expense_templates','business_pnl',
            'business_ratings','warehouses','department_inventory',
            'supply_orders','ai_worker_performance','order_bids',
            'robbery_incidents','city_treasury','tax_transactions',
            'city_budget_allocations'
        )
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS service_all ON public.%I', tbl);
        EXECUTE format('CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);
    END LOOP;
END $$;

-- ============================================================================
-- SEED PHASE 0 CONFIGURATION
-- ============================================================================
INSERT INTO public.bot_config (key, value) VALUES
    ('ai_police_enabled', 'true'),
    ('ai_ems_enabled', 'true'),
    ('ai_criminals_enabled', 'true'),
    ('ai_civilians_enabled', 'true'),
    ('ai_workers_enabled', 'true'),
    ('tax_income_enabled', 'false'),
    ('tax_business_enabled', 'false'),
    ('tax_sales_enabled', 'false'),
    ('city_budget_enabled', 'false'),
    ('mayor_system_enabled', 'false'),
    ('mayor_budget_powers', 'false'),
    ('public_works_enabled', 'false'),
    ('treasury_report_enabled', 'false'),
    ('dynamic_events_enabled', 'false'),
    ('police_missions_enabled', 'false'),
    ('ems_missions_enabled', 'false'),
    ('trucking_missions_enabled', 'false'),
    ('criminal_missions_enabled', 'false'),
    ('smuggler_runs_enabled', 'false'),
    ('forgery_enabled', 'false'),
    ('gangs_enabled', 'false'),
    ('marriage_enabled', 'false'),
    ('licensing_enabled', 'false'),
    ('insurance_enabled', 'false'),
    ('inheritance_enabled', 'false'),
    ('civilian_events_enabled', 'false'),
    ('ai_employee_pay_ratio', '0.33'),
    ('max_ai_permanent', '5'),
    ('player_remove_ai_ratio', '2'),
    ('arms_dealer_rotate_hours', '2'),
    ('arms_dealer_max_tier', '2')
ON CONFLICT (key) DO NOTHING;

-- Seed city treasury funds
INSERT INTO public.city_treasury (fund_name, balance, kronus_default_percentage) VALUES
    ('general_fund', 0),
    ('police_fund', 0),
    ('ems_fund', 0),
    ('fire_fund', 0),
    ('infrastructure_fund', 0),
    ('social_services_fund', 0),
    ('environmental_fund', 0),
    ('insurance_pool', 50000),
    ('mayor_discretionary', 0)
ON CONFLICT (fund_name) DO NOTHING;

INSERT INTO public.city_budget_allocations (fund_name, kronus_default_percentage) VALUES
    ('police_fund', 35),
    ('ems_fund', 25),
    ('infrastructure_fund', 20),
    ('social_services_fund', 10),
    ('environmental_fund', 5),
    ('mayor_discretionary', 5)
ON CONFLICT (fund_name) DO NOTHING;
