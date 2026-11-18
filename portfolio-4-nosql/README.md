# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** SaviourPay Digital Bank (Simulated). Database: MongoDB Atlas (free M0 cluster, document model).

## What is stored in MongoDB, and why

SaviourPay's financial records (accounts, balances, transfers) stay in PostgreSQL, where constraints and ACID transactions protect the money. MongoDB holds the `transaction_logs` collection: an append-only record of each transaction event with its channel-specific details.

Different channels produce different extra data:
- **Mobile app:** device, OS, app version, location
- **USSD:** session code, network, duration
- **ATM:** terminal ID, city, failure reason

In SQL, each of these would need extra nullable columns or extra tables. In a document store, each log simply carries the fields that apply to it, and a new channel can be added without altering a schema.

## Setup

- Cluster: `SaviourPayCluster` on MongoDB Atlas (M0 free tier, AWS Paris, 3-node replica set)
- Database: `saviourpay`
- Collection: `transaction_logs`
- Three documents were inserted through the Atlas Data Explorer (JSON view): a mobile app transfer, a USSD transfer and a failed ATM withdrawal. All data is synthetic.

## Sample document (USSD transfer)

```json
{
  "transaction_ref": "TXN0000000102",
  "account_number": "1000000002",
  "type": "TRANSFER",
  "amount": 180000,
  "currency": "NGN",
  "status": "SUCCESSFUL",
  "channel": "USSD",
  "timestamp": "2026-03-02T11:40:00Z",
  "ussd_session": { "code": "*000#", "network": "Sample Network", "duration_seconds": 42 },
  "fraud_signals": ["new_beneficiary", "amount_above_usual"]
}
```

## Queries run

1. Logs with at least one fraud signal (returned 2 documents):

```
{ "fraud_signals.0": { "$exists": true } }
```

2. Successful transfers of 100,000 or more (returned 1 document, the 180,000 USSD transfer):

```
{ "status": "SUCCESSFUL", "amount": { "$gte": 100000 } }
```

## Why a document model suits this data

- **Flexible schema:** each channel stores its own extra fields without empty columns.
- **Nested data:** device, location and USSD details sit inside one document, so a log is read in one lookup with no joins.
- **Append-heavy workload:** logs are written once and rarely changed, which suits a document store that can scale out.

## Trade-offs

- No foreign keys or table-level constraints, so MongoDB cannot guarantee that an `account_number` exists. The application or a nightly check has to do that.
- Joining logs to customer data is less natural than in SQL.
- For that reason balances and transfers remain in PostgreSQL, and only the logs live in MongoDB.

## Analysis

I chose MongoDB for transaction logs because each channel records different details, and a document can hold exactly the fields it needs. I kept money in PostgreSQL because balances need strict constraints and transactions. Using both gives each database the job it does best.

## Evidence

Screenshots (cluster running, collection created, three documents, both queries) are included in the final documentation.
