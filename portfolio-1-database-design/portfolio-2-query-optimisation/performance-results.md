# Portfolio 2: Query 1 Performance Results

**Query: mini statement (20 most recent transfers from one account)**

```sql
SELECT transaction_id, reference, txn_type, amount, status, created_at
FROM transactions
WHERE source_account_id = 500
ORDER BY created_at DESC
LIMIT 20;
```

Table size: 200,210 rows in `transactions` (synthetic data).

## Results

| Run | Scan type | Buffers | Execution time |
|---|---|---|---|
| Baseline, parallel workers on | Parallel Seq Scan + Gather Merge | 3,715 | 215.163 ms |
| Baseline, parallel workers off | Seq Scan + Sort | 3,639 | 35.893 ms |
| After index | Index Scan | 26 | 0.228 ms |

I first ran the baseline with PostgreSQL's parallel workers on. Most of the 215 ms was worker start-up, not scanning, which would have exaggerated the index's benefit. I re-ran the baseline with `SET max_parallel_workers_per_gather = 0` and used that as the fair comparison.

## Index added

```sql
CREATE INDEX idx_transactions_source_created
ON transactions (source_account_id, created_at DESC);
```

## Execution plan: baseline (parallel off)

```
Limit  (cost=6146.92..6146.97 rows=20 width=55) (actual time=35.816..35.821 rows=20.00 loops=1)
  Buffers: shared hit=3639
  ->  Sort  (cost=6146.92..6147.42 rows=199 width=55) (actual time=35.811..35.813 rows=20.00 loops=1)
        Sort Key: created_at DESC
        Sort Method: top-N heapsort  Memory: 30kB
        ->  Seq Scan on transactions  (cost=0.00..6141.62 rows=199 width=55) (actual time=0.230..35.541 rows=200.00 loops=1)
              Filter: (source_account_id = 500)
              Rows Removed by Filter: 200010
Execution Time: 35.893 ms
```

## Execution plan: after index

```
Limit  (cost=0.42..79.16 rows=20 width=55) (actual time=0.170..0.198 rows=20.00 loops=1)
  Buffers: shared hit=23 read=3
  ->  Index Scan using idx_transactions_source_created on transactions  (cost=0.42..783.90 rows=199 width=55) (actual time=0.169..0.194 rows=20.00 loops=1)
        Index Cond: (source_account_id = 500)
Execution Time: 0.228 ms
```

## Analysis


Without an index, PostgreSQL scanned all 200,210 rows to find the 200 that belong to account 500, then sorted them. With a composite index on (source_account_id, created_at DESC), it jumps straight to that account's rows, already in date order, so the sort is no longer needed and the query can stop after 20 rows. The result is about 157 times faster and reads about 140 times fewer buffers. The trade-off is that the index takes extra disk space and slows inserts slightly, which is acceptable for a table that is read far more often than it changes.
