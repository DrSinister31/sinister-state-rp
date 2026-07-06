-- ============================================================================
-- KRONUS: SHARED SUPABASE SCHEMA + RLS
-- Run FIRST before any domain-specific schemas.
-- ============================================================================

-- 0. Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- 1. Self-Learning System
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

-- 2. Bot Configuration (shared across all services)
CREATE TABLE IF NOT EXISTS public.bot_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Chronicles (30-Point Narrative Rubric entries)
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

-- 4. Discord Ticket System
CREATE TABLE IF NOT EXISTS public.tickets (
    id SERIAL PRIMARY KEY,
    channel_id TEXT NOT NULL,
    creator_id TEXT NOT NULL,
    ticket_type TEXT NOT NULL,
    status TEXT DEFAULT 'open',
    claimed_by TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    closed_at TIMESTAMPTZ
);

-- ============================================================================
-- ROW LEVEL SECURITY (shared tables only)
-- ============================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        AND tablename IN (
            'kronus_logs','kronus_outcomes',
            'kronus_policies','kronus_prompts','kronus_metrics','bot_config',
            'chronicle_entries','tickets'
        )
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS service_all ON public.%I', tbl);
        EXECUTE format(
            'CREATE POLICY service_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)',
            tbl
        );
    END LOOP;
END $$;
