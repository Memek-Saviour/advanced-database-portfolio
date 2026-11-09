-- KYC tier limits for SaviourPay
-- Source: <CBN circular title, date, link>

UPDATE kyc_tier_limits
SET max_balance = <300000.00>, daily_transfer_limit = <50000.00>
WHERE tier = 1;

UPDATE kyc_tier_limits
SET max_balance = <500000.00>, daily_transfer_limit = <100000.00>
WHERE tier = 2;

UPDATE kyc_tier_limits
SET max_balance = <NULL>, daily_transfer_limit = <5000000.00>
WHERE tier = 3;
