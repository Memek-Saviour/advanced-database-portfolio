-- KYC tier limits for SaviourPay (wallet platform)
-- Tier 1 and Tier 3 source: CBN circular BPS/DIR/GEN/CIR/04/007,
-- 7 September 2017, "Review of daily mobile money wallet
-- transaction and balance limit"
-- Tier 2 daily limit source: REPLACE THIS WITH YOUR SOURCE
-- Note: verify against current CBN figures before submission.

UPDATE kyc_tier_limits
SET max_balance = 300000.00, daily_transfer_limit = 50000.00
WHERE tier = 1;

UPDATE kyc_tier_limits
SET max_balance = 500000.00, daily_transfer_limit = 100000.00
WHERE tier = 2;

-- Tier 3: balance is unlimited (NULL)
UPDATE kyc_tier_limits
SET max_balance = NULL, daily_transfer_limit = 5000000.00
WHERE tier = 3;
