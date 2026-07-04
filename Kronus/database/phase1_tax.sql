-- Phase 1: Tax system seed data

-- Ensure general_fund exists in city_treasury
INSERT INTO city_treasury (fund_name, balance)
VALUES ('general_fund', 0)
ON CONFLICT (fund_name) DO NOTHING;

-- Seed budget allocations
INSERT INTO city_budget_allocations (fund_name, kronus_default_percentage)
VALUES
    ('police_fund', 35),
    ('ems_fund', 25),
    ('fire_fund', 15),
    ('infrastructure_fund', 10),
    ('education_fund', 5),
    ('parks_fund', 3),
    ('transportation_fund', 7)
ON CONFLICT (fund_name) DO NOTHING;

-- Ensure all treasury funds exist
INSERT INTO city_treasury (fund_name, balance)
VALUES
    ('police_fund', 0),
    ('ems_fund', 0),
    ('fire_fund', 0),
    ('infrastructure_fund', 0),
    ('education_fund', 0),
    ('parks_fund', 0),
    ('transportation_fund', 0)
ON CONFLICT (fund_name) DO NOTHING;
