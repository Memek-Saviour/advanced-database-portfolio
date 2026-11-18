-- 06-queries-and-indexes.sql
-- Portfolio 2: queries and indexes for SaviourPay.
-- Run after 05-sample-data.sql.

-- To reproduce the "before" results, drop the indexes first:
-- DROP INDEX IF EXISTS idx_transactions_source_created;
-- DROP INDEX IF EXISTS idx_transactions_created_at;

-- Fair comparison: turn parallel workers off for this session.
SET max_parallel_workers_per_gather = 0;

-- Query 1: mini statement (20 most recent transfers from one account)
-- Add EXPLAIN (ANALYZE, BUFFERS) in front to see the plan.
SELECT transaction_id, reference, txn_type, amount, status, created_at
FROM transactions
WHERE source_account_id = 500
ORDER BY created_at DESC
LIMIT 20;

-- Index for Query 1
CREATE INDEX IF NOT EXISTS idx_transactions_source_created
ON transactions (source_account_id, created_at DESC);

-- Query 2: weekly transfer report per branch (3-table join with aggregation)
SELECT b.branch_name,
       COUNT(*)      AS transfer_count,
       SUM(t.amount) AS total_amount
FROM transactions t
JOIN accounts a ON a.account_id = t.source_account_id
JOIN branches b ON b.branch_id = a.branch_id
WHERE t.txn_type = 'TRANSFER'
  AND t.status = 'SUCCESSFUL'
  AND t.created_at >= '2026-03-01'
  AND t.created_at <  '2026-03-08'
GROUP BY b.branch_name
ORDER BY total_amount DESC;

-- Index for Query 2
CREATE INDEX IF NOT EXISTS idx_transactions_created_at
ON transactions (created_at);

-- Refresh planner statistics after creating indexes
ANALYZE transactions;
