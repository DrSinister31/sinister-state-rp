-- ============================================================================
-- Sinister H-Town RP — Tebex Tracking Tables (Worker E)
-- Run this in the Supabase SQL Editor:
--   https://yqfzaugbrwoluhkddcsh.supabase.co → SQL Editor
-- ============================================================================

CREATE TABLE IF NOT EXISTS tebex_purchases (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id TEXT UNIQUE NOT NULL,
    player_citizenid TEXT,
    player_name TEXT,
    package_name TEXT,
    package_id TEXT,
    price DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    items_granted JSONB DEFAULT '[]',
    status TEXT DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tebex_webhook_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type TEXT,
    payload JSONB,
    received_at TIMESTAMPTZ DEFAULT NOW()
);
