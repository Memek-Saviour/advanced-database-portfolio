-- SaviourPay Digital Bank (Simulated)
-- Portfolio 1: Database Schema (PostgreSQL)

CREATE TABLE branches (
    branch_id    SERIAL PRIMARY KEY,
    branch_name  VARCHAR(100) NOT NULL,
    city         VARCHAR(60)  NOT NULL,
    state        VARCHAR(60)  NOT NULL
);

CREATE TABLE customers (
    customer_id    BIGSERIAL PRIMARY KEY,
    first_name     VARCHAR(60)  NOT NULL,
    last_name      VARCHAR(60)  NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    phone          VARCHAR(20)  NOT NULL UNIQUE,
    date_of_birth  DATE NOT NULL,
    bvn            CHAR(11) NOT NULL UNIQUE,
    kyc_status     VARCHAR(10) NOT NULL DEFAULT 'PENDING'
                   CHECK (kyc_status IN ('PENDING','VERIFIED','REJECTED')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE staff_users (
    staff_id    SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    role        VARCHAR(20) NOT NULL
                CHECK (role IN ('OPERATIONS','SUPPORT','COMPLIANCE','FRAUD_ANALYST')),
    branch_id   INT REFERENCES branches(branch_id)
);

CREATE TABLE accounts (
    account_id      BIGSERIAL PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customers(customer_id),
    branch_id       INT    NOT NULL REFERENCES branches(branch_id),
    account_number  CHAR(10) NOT NULL UNIQUE,
    account_type    VARCHAR(10) NOT NULL
                    CHECK (account_type IN ('SAVINGS','CURRENT','WALLET')),
    currency        CHAR(3) NOT NULL DEFAULT 'NGN',
    balance         NUMERIC(15,2) NOT NULL DEFAULT 0
                    CHECK (balance >= 0),
    status          VARCHAR(10) NOT NULL DEFAULT 'ACTIVE'
                    CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    opened_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE beneficiaries (
    beneficiary_id    BIGSERIAL PRIMARY KEY,
    customer_id       BIGINT NOT NULL REFERENCES customers(customer_id),
    beneficiary_name  VARCHAR(120) NOT NULL,
    account_number    CHAR(10) NOT NULL,
    bank_name         VARCHAR(80) NOT NULL,
    UNIQUE (customer_id, account_number, bank_name)
);

CREATE TABLE transactions (
    transaction_id          BIGSERIAL PRIMARY KEY,
    reference               VARCHAR(40) NOT NULL UNIQUE,
    source_account_id       BIGINT REFERENCES accounts(account_id),
    destination_account_id  BIGINT REFERENCES accounts(account_id),
    txn_type   VARCHAR(12) NOT NULL
               CHECK (txn_type IN ('DEPOSIT','WITHDRAWAL','TRANSFER','REVERSAL')),
    amount     NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    status     VARCHAR(12) NOT NULL DEFAULT 'PENDING'
               CHECK (status IN ('PENDING','SUCCESSFUL','FAILED','REVERSED')),
    reversal_of  BIGINT REFERENCES transactions(transaction_id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (source_account_id IS NOT NULL OR destination_account_id IS NOT NULL),
    CHECK (source_account_id IS DISTINCT FROM destination_account_id)
);

CREATE TABLE fraud_alerts (
    alert_id        BIGSERIAL PRIMARY KEY,
    transaction_id  BIGINT NOT NULL REFERENCES transactions(transaction_id),
    reason          VARCHAR(200) NOT NULL,
    risk_level      VARCHAR(6) NOT NULL
                    CHECK (risk_level IN ('LOW','MEDIUM','HIGH')),
    status          VARCHAR(12) NOT NULL DEFAULT 'OPEN'
                    CHECK (status IN ('OPEN','REVIEWING','CLOSED')),
    reviewed_by     INT REFERENCES staff_users(staff_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
    log_id      BIGSERIAL PRIMARY KEY,
    staff_id    INT REFERENCES staff_users(staff_id),
    table_name  VARCHAR(40) NOT NULL,
    record_id   BIGINT NOT NULL,
    action      VARCHAR(10) NOT NULL
                CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_values  JSONB,
    new_values  JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
