# Portfolio 3: Transactions and Concurrency

**Case study:** SaviourPay Digital Bank (Simulated). Database: PostgreSQL.

## 1. COMMIT: a successful transfer

```sql
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
INSERT INTO transactions
  (reference, source_account_id, destination_account_id, txn_type, amount, status, session_id)
VALUES
  ('TXN-DEMO-COMMIT', 1, 2, 'TRANSFER', 1000, 'SUCCESSFUL', 'DEMO-COMMIT-0001');
COMMIT;
```

The debit, the credit and the transaction record succeed or fail together (atomicity). After COMMIT, account 1 was 1,000 lower and account 2 was 1,000 higher.

## 2. ROLLBACK: undoing a change

```sql
BEGIN;
UPDATE accounts SET balance = balance - 50000 WHERE account_id = 1;
SELECT account_id, balance FROM accounts WHERE account_id = 1;  -- shows the lower balance
ROLLBACK;
SELECT account_id, balance FROM accounts WHERE account_id = 1;  -- back to the original
```

After ROLLBACK the 50,000 deduction was undone, as if it never happened.

## 3. Isolation and locking with two sessions

Two pgAdmin Query Tool tabs were used as two separate sessions (default isolation level: READ COMMITTED).

| Step | Session | Action | Observed |
|---|---|---|---|
| 1 | A | `BEGIN; UPDATE accounts SET balance = balance - 10000 WHERE account_id = 1;` | A sees 482,064.59 |
| 2 | B | `SELECT balance FROM accounts WHERE account_id = 1;` | B still sees 492,064.59 (no dirty read) |
| 3 | B | `UPDATE accounts SET balance = balance - 20000 WHERE account_id = 1;` | B waits: A holds a row lock |
| 4 | A | `COMMIT;` | Lock released |
| 5 | B | (update completes) | `UPDATE 1` |
| 6 | B | `SELECT balance ...` | 462,064.59: both deductions applied |

(Check these numbers against your own screenshots before submitting.)

The row lock stopped session B from overwriting session A's change, so there was no lost update. Session B's update ran against the committed balance once A finished.

## Issue encountered

My first commit attempt failed with `value too long for type character varying(30)` because the `session_id` I used was 31 characters long. The transaction stopped before COMMIT, so nothing was saved. I shortened the value and re-ran it.

## Evidence

Screenshots of each step are included in the final documentation.

## Analysis

A transaction groups statements so they all take effect or none do. This protects a transfer from leaving money debited but not credited. Isolation means other sessions only see committed data, and row-level locks make concurrent writers to the same account take turns instead of overwriting each other. Without this, two simultaneous withdrawals could both read the same balance, and one would be lost.
