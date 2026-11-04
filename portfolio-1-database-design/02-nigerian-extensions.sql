-- SaviourPay: Nigerian banking extensions (PostgreSQL)
-- Run after schema.sql

-- 1. Tiered KYC with account limits
CREATE TABLE kyc_tier_limits (
    tier                  SMALLINT PRIMARY KEY CHECK (tier IN (1, 2, 3)),
    description           VARCHAR(100) NOT NULL,
    max_balance           NUMERIC(15,2),
    daily_transfer_limit  NUMERIC(15,2)
);

INSERT INTO kyc_tier_limits (tier, description) VALUES
    (1, 'Tier 1 - basic account', 300000.00, 50000.00), 
    (2, 'Tier 2 - standard account', 500000.00, 200000.00),
    (3, 'Tier 3 - full KYC account', NULL, Null); -- Unlimited / risk-based per bank policy

-- TODO: fill in max_balance and daily_transfer_limit using the
-- current CBN figures, and cite the source in the README.

ALTER TABLE customers
    ADD COLUMN kyc_tier SMALLINT NOT NULL DEFAULT 1
    REFERENCES kyc_tier_limits(tier);

-- 2. National Identification Number alongside BVN
ALTER TABLE customers
    ADD COLUMN nin CHAR(11) UNIQUE;

-- 3. Banks, CBN bank codes and NIBSS session references
CREATE TABLE banks (
    bank_id        SERIAL PRIMARY KEY,
    bank_name      VARCHAR(100) NOT NULL UNIQUE,
    cbn_bank_code  VARCHAR(6) NOT NULL UNIQUE
);

ALTER TABLE beneficiaries
    ADD COLUMN bank_id INT REFERENCES banks(bank_id);

ALTER TABLE transactions
    ADD COLUMN session_id VARCHAR(30) UNIQUE;
