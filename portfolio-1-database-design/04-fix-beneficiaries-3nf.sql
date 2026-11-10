-- Fix 3NF violation: beneficiaries.bank_name duplicates banks.bank_name
-- (bank_name depends on bank_id, not on beneficiary_id).
-- Run after 02-nigerian-extensions.sql.
-- Dropping bank_name also drops the old UNIQUE constraint that used it.

ALTER TABLE beneficiaries DROP COLUMN bank_name;

-- Safe on a fresh database. If beneficiaries already had rows,
-- set their bank_id first.
ALTER TABLE beneficiaries ALTER COLUMN bank_id SET NOT NULL;

ALTER TABLE beneficiaries
    ADD CONSTRAINT beneficiaries_customer_account_bank_key
    UNIQUE (customer_id, account_number, bank_id);
