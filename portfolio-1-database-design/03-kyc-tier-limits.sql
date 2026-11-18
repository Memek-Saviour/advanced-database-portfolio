-- KYC tier limits for SaviourPay (wallet platform)
-- Primary source: CBN circular BPS/DIR/GEN/CIR/04/007, 11 September 2017,
-- revising tiered KYC limits.
-- Secondary source: Pryme, "KYC tiers in Nigeria: Tier 1, 2 and 3 limits",
-- 16 Oct 2026, https://www.mypryme.com/blog/kyc-tier-limits-nigeria
-- (accessed 19 Nov 2026).
-- These are regulatory ceilings; a provider may set lower limits.

UPDATE kyc_tier_limits
SET max_balance = 300000.00, daily_transfer_limit = 50000.00
WHERE tier = 1;

UPDATE kyc_tier_limits
SET max_balance = 500000.00, daily_transfer_limit = 200000.00
WHERE tier = 2;

-- Tier 3: balance is unlimited (NULL)
UPDATE kyc_tier_limits
SET max_balance = NULL, daily_transfer_limit = 5000000.00
WHERE tier = 3;
