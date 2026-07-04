-- Channel Memory System — stores channel purposes for Kronus awareness
-- Used by kronus_core/cogs/channel_memory.py

CREATE TABLE IF NOT EXISTS channel_purposes (
    id SERIAL PRIMARY KEY,
    channel_id TEXT UNIQUE NOT NULL,
    channel_name TEXT NOT NULL,
    purpose TEXT,
    creator_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    is_compacted BOOLEAN DEFAULT false,
    tags TEXT[] DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_channel_purposes_channel_id ON channel_purposes(channel_id);
CREATE INDEX IF NOT EXISTS idx_channel_purposes_compacted ON channel_purposes(is_compacted);

-- RLS: service_role only
ALTER TABLE channel_purposes ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'channel_purposes' AND policyname = 'service_all'
    ) THEN
        CREATE POLICY service_all ON channel_purposes FOR ALL TO service_role USING (true) WITH CHECK (true);
    END IF;
END $$;
