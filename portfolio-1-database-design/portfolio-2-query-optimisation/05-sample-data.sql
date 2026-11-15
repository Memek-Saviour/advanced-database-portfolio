-- 05-sample-data.sql
-- SaviourPay synthetic sample data. Run ONCE on a fresh database
-- after files 01 to 04. Assumes account IDs start at 1.
-- Bank codes: verify against the CBN/NIBSS list before submission.

INSERT INTO branches (branch_name, city, state) VALUES
 ('Ikeja Branch','Ikeja','Lagos'),
 ('Victoria Island Branch','Lagos','Lagos'),
 ('Wuse Branch','Abuja','FCT'),
 ('Port Harcourt Branch','Port Harcourt','Rivers'),
 ('Kano Branch','Kano','Kano');

INSERT INTO banks (bank_name, cbn_bank_code) VALUES
 ('Access Bank','044'),
 ('Guaranty Trust Bank','058'),
 ('First Bank of Nigeria','011'),
 ('United Bank for Africa','033'),
 ('Zenith Bank','057');

INSERT INTO staff_users (full_name, email, role, branch_id) VALUES
 ('Amaka Obi','amaka.obi@saviourpay.test','OPERATIONS',1),
 ('Tunde Bello','tunde.bello@saviourpay.test','SUPPORT',2),
 ('Ngozi Eze','ngozi.eze@saviourpay.test','COMPLIANCE',3),
 ('Ibrahim Musa','ibrahim.musa@saviourpay.test','FRAUD_ANALYST',5);

INSERT INTO customers
 (first_name, last_name, email, phone, date_of_birth, bvn, nin, kyc_status, kyc_tier)
SELECT 'Customer' || g, 'Test' || g,
       'customer' || g || '@saviourpay.test',
       '0801' || lpad(g::text, 7, '0'),
       DATE '1980-01-01' + (g % 9000),
       (22000000000 + g)::text,
       (33000000000 + g)::text,
       CASE WHEN g % 10 = 0 THEN 'PENDING' ELSE 'VERIFIED' END,
       (g % 3) + 1
FROM generate_series(1, 1000) g;

INSERT INTO accounts
 (customer_id, branch_id, account_number, account_type, balance, status)
SELECT c.customer_id,
       (c.customer_id % 5) + 1,
       (1000000000 + c.customer_id)::text,
       (ARRAY['SAVINGS','CURRENT','WALLET'])[(c.customer_id % 3) + 1],
       round((random() * 500000)::numeric, 2),
       'ACTIVE'
FROM customers c;

INSERT INTO beneficiaries (customer_id, beneficiary_name, account_number, bank_id)
SELECT c.customer_id,
       'Beneficiary ' || c.customer_id,
       (2000000000 + c.customer_id)::text,
       (c.customer_id % 5) + 1
FROM customers c
WHERE c.customer_id <= 300;

-- 200,000 transfers between the 1,000 accounts
INSERT INTO transactions
 (reference, source_account_id, destination_account_id, txn_type,
  amount, status, created_at, session_id)
SELECT 'TXN' || lpad(g::text, 10, '0'),
       src,
       CASE WHEN dst = src THEN (src % 1000) + 1 ELSE dst END,
       'TRANSFER',
       round((random() * 200000 + 100)::numeric, 2),
       (ARRAY['SUCCESSFUL','SUCCESSFUL','SUCCESSFUL','SUCCESSFUL','FAILED','PENDING'])[(g % 6) + 1],
       TIMESTAMPTZ '2026-01-01 00:00:00+01' + (g * interval '2 minutes'),
       lpad(g::text, 30, '0')
FROM (
  SELECT g,
         ((g * 7) % 1000) + 1      AS src,
         ((g * 13 + 5) % 1000) + 1 AS dst
  FROM generate_series(1, 200000) g
) t;

-- Deposits (no source account)
INSERT INTO transactions
 (reference, source_account_id, destination_account_id, txn_type, amount, status)
SELECT 'DEP' || lpad(a.account_id::text, 10, '0'),
       NULL, a.account_id, 'DEPOSIT', 50000, 'SUCCESSFUL'
FROM accounts a
WHERE a.account_id <= 200;

-- Reversals of some failed transfers (new rows pointing at the original)
INSERT INTO transactions
 (reference, source_account_id, destination_account_id, txn_type,
  amount, status, reversal_of)
SELECT 'REV' || reference, destination_account_id, source_account_id,
       'REVERSAL', amount, 'SUCCESSFUL', transaction_id
FROM transactions
WHERE status = 'FAILED' AND txn_type = 'TRANSFER' AND transaction_id <= 60;

-- Fraud alerts on large transfers
INSERT INTO fraud_alerts (transaction_id, reason, risk_level, status, reviewed_by)
SELECT transaction_id, 'Unusually large transfer', 'HIGH', 'OPEN', 4
FROM transactions
WHERE txn_type = 'TRANSFER' AND amount > 199000
LIMIT 50;

-- Check the row counts
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'fraud_alerts', COUNT(*) FROM fraud_alerts;
