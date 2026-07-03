-- ============================================================================
-- SINISTER STATE: COMPLETE SUPABASE SCHEMA
-- Run in Supabase SQL Editor to initialize all tables.
-- ============================================================================

-- 1. Discord ↔ FiveM Identity Linking
CREATE TABLE IF NOT EXISTS public.discord_players (
    discord_id BIGINT PRIMARY KEY,
    citizenid TEXT NOT NULL UNIQUE,
    discord_username TEXT,
    linked_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_seen TIMESTAMPTZ DEFAULT now(),
    fivem_license TEXT
);

-- 2. Character Data (synced from Qbox via bridge)
CREATE TABLE IF NOT EXISTS public.characters (
    citizenid TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    dob DATE,
    gender TEXT,
    nationality TEXT,
    job_name TEXT,
    job_grade INTEGER DEFAULT 0,
    gang_name TEXT,
    gang_grade INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    last_updated TIMESTAMPTZ DEFAULT now()
);

-- 3. Economy
CREATE TABLE IF NOT EXISTS public.player_economy (
    citizenid TEXT PRIMARY KEY,
    cash BIGINT DEFAULT 0,
    bank BIGINT DEFAULT 0,
    crypto BIGINT DEFAULT 0,
    dirty_money BIGINT DEFAULT 0,
    savings BIGINT DEFAULT 0,
    debt_owed BIGINT DEFAULT 0,
    wealth_bracket TEXT DEFAULT 'Lower',
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_citizenid TEXT,
    to_citizenid TEXT,
    amount BIGINT NOT NULL,
    account_type TEXT NOT NULL,
    reason TEXT,
    channel TEXT,
    business_id UUID,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 4. Businesses
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_citizenid TEXT NOT NULL,
    name TEXT NOT NULL,
    business_type TEXT NOT NULL,
    revenue BIGINT DEFAULT 0,
    employee_count INTEGER DEFAULT 0,
    location JSONB,
    active BOOLEAN DEFAULT true,
    delinquent BOOLEAN DEFAULT false,
    delinquent_since TIMESTAMPTZ,
    ai_placeholder BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    discord_category_id BIGINT,
    discord_owner_channel BIGINT,
    discord_lounge_channel BIGINT,
    discord_logs_channel BIGINT
);

CREATE TABLE IF NOT EXISTS public.business_employees (
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    citizenid TEXT NOT NULL,
    role TEXT DEFAULT 'Employee',
    salary INTEGER DEFAULT 0,
    hired_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (business_id, citizenid)
);

-- 5. Enforcement
CREATE TABLE IF NOT EXISTS public.criminal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL,
    charge TEXT NOT NULL,
    severity TEXT DEFAULT 'Misdemeanor',
    officer_citizenid TEXT,
    report_id TEXT,
    convicted BOOLEAN DEFAULT false,
    fine_amount INTEGER DEFAULT 0,
    jail_time INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.warrants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL,
    reason TEXT NOT NULL,
    issuing_officer TEXT,
    active BOOLEAN DEFAULT true,
    issued_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.mdt_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_citizenid TEXT NOT NULL,
    suspect_citizenid TEXT,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'Open',
    priority TEXT DEFAULT 'Normal',
    assigned_to TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.strikes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT NOT NULL,
    discord_id BIGINT,
    violation TEXT NOT NULL,
    strike_count INTEGER DEFAULT 1,
    fine_amount INTEGER DEFAULT 0,
    moderator_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.bans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    citizenid TEXT,
    discord_id BIGINT,
    reason TEXT NOT NULL,
    moderator_id TEXT,
    duration TEXT,
    active BOOLEAN DEFAULT true,
    issued_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ
);

-- 6. Self-Learning System
CREATE TABLE IF NOT EXISTS public.kronus_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service TEXT NOT NULL,
    action TEXT NOT NULL,
    context_json JSONB DEFAULT '{}',
    result TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.kronus_outcomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_id UUID REFERENCES public.kronus_logs(id) ON DELETE CASCADE,
    outcome_type TEXT NOT NULL,
    data_json JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.kronus_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL,
    confidence FLOAT DEFAULT 0,
    applied BOOLEAN DEFAULT false,
    reviewed_by BIGINT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.kronus_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purpose TEXT NOT NULL UNIQUE,
    prompt_text TEXT NOT NULL,
    version INTEGER DEFAULT 1,
    performance_score FLOAT DEFAULT 0,
    uses INTEGER DEFAULT 0,
    last_used TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.kronus_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name TEXT NOT NULL,
    value FLOAT NOT NULL,
    metadata_json JSONB DEFAULT '{}',
    recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 7. Bot Configuration
CREATE TABLE IF NOT EXISTS public.bot_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. RCON Command Queue (bridge reads this)
CREATE TABLE IF NOT EXISTS public.rcon_commands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    command TEXT NOT NULL,
    source TEXT,
    status TEXT DEFAULT 'pending',
    response TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    executed_at TIMESTAMPTZ
);

-- 9. Discord Channel Mapping (for dynamic faction generation)
CREATE TABLE IF NOT EXISTS public.discord_channels (
    channel_id BIGINT PRIMARY KEY,
    business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
    channel_type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. Chronicles (30-Point Narrative Rubric entries)
CREATE TABLE IF NOT EXISTS public.chronicle_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    score INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    involved_citizenids TEXT[],
    involved_discord_ids BIGINT[],
    embed_style TEXT DEFAULT 'journal',
    volume_index INTEGER,
    event_date TIMESTAMPTZ DEFAULT now(),
    posted_to_discord BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 11. Weazel News (media economy)
CREATE TABLE IF NOT EXISTS public.weazel_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viewership_count INTEGER DEFAULT 0,
    circulation INTEGER DEFAULT 0,
    recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 12. Tebex Purchase Log
CREATE TABLE IF NOT EXISTS public.tebex_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT UNIQUE,
    player_discord_id BIGINT,
    package_name TEXT,
    price REAL,
    currency TEXT,
    delivered BOOLEAN DEFAULT false,
    delivery_command TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.discord_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_economy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.criminal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warrants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mdt_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strikes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kronus_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kronus_outcomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kronus_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kronus_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kronus_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bot_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rcon_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discord_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chronicle_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weazel_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tebex_purchases ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SERVICE ROLE BYPASSES RLS (standard Supabase behavior)
-- Kronus uses the service_role key, so all access is unrestricted.
-- ============================================================================
