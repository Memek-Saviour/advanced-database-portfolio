# Portfolio 2: Query 2 Performance Results

**Query: weekly transfer report per branch (join of 3 tables with aggregation)**

```sql
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
```

Returns 5 rows, one per branch. Table size: 200,210 rows in `transactions` (synthetic data). Parallel workers were turned off (`SET max_parallel_workers_per_gather = 0`) for a fair comparison.

## Results

| Run | Scan on transactions | Buffers | Execution time |
|---|---|---|---|
| Before index | Seq Scan | 3,662 | 35.168 ms |
| After index | Index Scan on idx_transactions_created_at | 122 | 12.379 ms |

## Index added

```sql
CREATE INDEX idx_transactions_created_at
ON transactions (created_at);
```

## Execution plan: before (key lines)

```
Sort  (actual time=35.017..35.036 rows=5.00 loops=1)
  ->  HashAggregate  (actual time=34.999..35.020 rows=5.00 loops=1)
        ->  Nested Loop  (actual time=8.332..33.802 rows=3360.00 loops=1)
              ->  Hash Join  Hash Cond: (t.source_account_id = a.account_id)
                    ->  Seq Scan on transactions t  (actual time=7.859..30.497 rows=3360.00 loops=1)
                          Rows Removed by Filter: 196850
                          Buffers: shared hit=3639
                    ->  Hash
                          ->  Seq Scan on accounts a
              ->  Memoize  Cache Key: a.branch_id
                    ->  Index Scan using branches_pkey on branches b
Execution Time: 35.168 ms
```

## Execution plan: after (key lines)

```
Sort  (actual time=12.230..12.234 rows=5.00 loops=1)
  ->  HashAggregate  (actual time=12.204..12.212 rows=5.00 loops=1)
        ->  Hash Join  Hash Cond: (a.branch_id = b.branch_id)
              ->  Hash Join  Hash Cond: (t.source_account_id = a.account_id)
                    ->  Index Scan using idx_transactions_created_at on transactions t
                          (actual time=0.229..4.803 rows=3360.00 loops=1)
                          Rows Removed by Filter: 1680
                          Buffers: shared hit=92 read=16
                    ->  Hash
                          ->  Seq Scan on accounts a
              ->  Hash
                    ->  Seq Scan on branches b
Execution Time: 12.379 ms
```

## Analysis

The query reports one week of successful transfers, but the table holds about nine months of data. Without an index, PostgreSQL read all 200,210 rows and discarded 196,850 of them. An index on `created_at` lets it jump straight to the week's rows. The speed-up is about 2.8 times and the buffers read fall about 30 times. The gain is smaller than in Query 1 because the joins and the aggregation of 3,360 rows still take time, and the index scan returns some rows (1,680) that the transaction type and status filter then removes. A composite index including those columns could reduce that further, but the benefit would be small for this data size.
