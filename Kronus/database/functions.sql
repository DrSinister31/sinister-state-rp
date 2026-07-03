-- ============================================================================
-- SUPABASE DATABASE FUNCTIONS
-- Run in SQL Editor AFTER creating the schema tables.
-- ============================================================================

-- Add funds to a player's economy account
CREATE OR REPLACE FUNCTION add_funds(p_citizenid TEXT, p_amount BIGINT, p_account TEXT DEFAULT 'bank')
RETURNS void AS $$
BEGIN
    IF p_account = 'bank' THEN
        UPDATE player_economy SET bank = bank + p_amount, updated_at = now()
        WHERE citizenid = p_citizenid;
    ELSIF p_account = 'cash' THEN
        UPDATE player_economy SET cash = cash + p_amount, updated_at = now()
        WHERE citizenid = p_citizenid;
    ELSIF p_account = 'crypto' THEN
        UPDATE player_economy SET crypto = crypto + p_amount, updated_at = now()
        WHERE citizenid = p_citizenid;
    ELSIF p_account = 'dirty_money' THEN
        UPDATE player_economy SET dirty_money = dirty_money + p_amount, updated_at = now()
        WHERE citizenid = p_citizenid;
    END IF;

    IF NOT FOUND THEN
        INSERT INTO player_economy (citizenid, bank, cash, crypto, dirty_money)
        VALUES (p_citizenid,
            CASE WHEN p_account = 'bank' THEN p_amount ELSE 0 END,
            CASE WHEN p_account = 'cash' THEN p_amount ELSE 0 END,
            CASE WHEN p_account = 'crypto' THEN p_amount ELSE 0 END,
            CASE WHEN p_account = 'dirty_money' THEN p_amount ELSE 0 END
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Seed bot configuration defaults
INSERT INTO public.bot_config (key, value) VALUES
    ('ban_strike_threshold', '3'),
    ('inflation_wealth_threshold_pct', '25'),
    ('delinquency_days', '14'),
    ('market_ticker_interval_minutes', '30'),
    ('payroll_interval_hours', '1'),
    ('max_jobs_per_player', '3'),
    ('server_name', 'Sinister State')
ON CONFLICT (key) DO NOTHING;

-- Seed default Deepseek prompt templates
INSERT INTO public.kronus_prompts (purpose, prompt_text, version) VALUES
    ('judge_ruling', 'You are the SYNIX STATE AI judge. Review evidence and render verdicts.', 1),
    ('event_narration', 'You are a news broadcaster for Sinister State.', 1),
    ('economy_audit', 'You are the SYNIX STATE economy auditor.', 1),
    ('policy_review', 'You are the SYNIX STATE policy reviewer.', 1)
ON CONFLICT (purpose) DO NOTHING;
