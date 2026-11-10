# Portfolio 1: Database Design and Modelling

**Case study:** SaviourPay Digital Bank (Simulated)

**Status:** Design complete. Scripts still to be run and tested in PostgreSQL (see Portfolio 2).

## Deliverables

- [x] Case study description (see the root README)
- [x] ER diagram
- [x] Relational schema
- [x] Keys and constraints
- [x] Normalisation explanation

## Files

| File | Purpose |
|---|---|
| `schema.sql` | Base schema: 8 tables with keys and constraints |
| `02-nigerian-extensions.sql` | KYC tiers, NIN, banks table, NIBSS session ID |
| `03-kyc-tier-limits.sql` | Tier limits, with the source cited in the file |
| `04-fix-beneficiaries-3nf.sql` | Removes a duplicated column to restore 3NF |
| `er-diagram.md` | ER diagram (Mermaid) |
| `normalisation.md` | 1NF, 2NF and 3NF explanation |

## Run order

Run the SQL files in numeric order: `schema.sql`, then 02, 03 and 04.

## How this was implemented and tested

(To be completed after the scripts have been run in PostgreSQL.)
