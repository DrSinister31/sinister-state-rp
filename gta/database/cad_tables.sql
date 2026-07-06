-- CAD Vehicle Registry + Scanner support

CREATE TABLE IF NOT EXISTS vehicle_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate TEXT NOT NULL UNIQUE,
    model TEXT,
    class TEXT,
    owner_citizenid TEXT,
    owner_name TEXT,
    registered_at TIMESTAMPTZ DEFAULT now(),
    insurance_active BOOLEAN DEFAULT true,
    stolen BOOLEAN DEFAULT false,
    flagged BOOLEAN DEFAULT false,
    flag_reason TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_vehicle_registry_plate ON vehicle_registry(plate);
CREATE INDEX IF NOT EXISTS idx_vehicle_registry_owner ON vehicle_registry(owner_citizenid);

ALTER TABLE vehicle_registry ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='vehicle_registry' AND policyname='service_all') THEN
        CREATE POLICY service_all ON vehicle_registry FOR ALL TO service_role USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Speed camera / radar log
CREATE TABLE IF NOT EXISTS speed_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate TEXT NOT NULL,
    speed INTEGER NOT NULL,
    limit_speed INTEGER DEFAULT 60,
    location TEXT,
    officer_citizenid TEXT,
    flagged BOOLEAN DEFAULT false,
    recorded_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE speed_logs ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='speed_logs' AND policyname='service_all') THEN
        CREATE POLICY service_all ON speed_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
    END IF;
END $$;
