# Normalisation of the SaviourPay Schema

## First Normal Form (1NF)
Every column holds a single value, every table has a primary key, and there are no repeating groups. A customer can have many accounts and many beneficiaries, so these live in their own tables (`accounts`, `beneficiaries`) instead of columns such as `beneficiary_1` and `beneficiary_2` on `customers`.

**Deliberate exception:** `audit_logs.old_values` and `new_values` are JSONB snapshots of a changed row. They are stored as a record of what changed, not queried attribute by attribute, so I accepted the trade-off.

## Second Normal Form (2NF)
Every table is in 1NF and has no partial dependencies. Each table uses a single-column primary key (for example `customer_id`, `account_id`, `transaction_id`), so a non-key column cannot depend on only part of a key.

## Third Normal Form (3NF)
No non-key column depends on another non-key column. Examples:
- Branch `city` and `state` are stored once in `branches`, not repeated in `accounts` or `staff_users`.
- KYC tier limits are stored in `kyc_tier_limits`. If `customers` held the limits directly, they would depend on `kyc_tier` rather than on `customer_id`.
- Bank names are stored once in `banks`.

**Issue found and fixed:** after adding `bank_id` to `beneficiaries`, the old `bank_name` column remained. It depended on `bank_id`, which broke 3NF. Migration `04-fix-beneficiaries-3nf.sql` removed it.

## Deliberate denormalisation
`accounts.balance` could be calculated by summing `transactions`. I store it to make balance reads fast. Portfolio 3 keeps it correct using transactions and locking, and a balance audit query checks it against the transaction history.
