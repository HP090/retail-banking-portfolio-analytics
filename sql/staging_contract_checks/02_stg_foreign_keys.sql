-- 02_stg_foreign_keys.sql
-- Foreign-key integrity checks on staging tables

-- 1. stg_accounts.district_id → stg_districts.district_id
SELECT
    'stg_accounts' AS child_table,
    'district_id' AS child_column,
    'stg_districts' AS parent_table,
    'district_id' AS parent_column,
    COUNT(*) AS unmatched_count,
    LIST(t.district_id) FILTER (WHERE rn <= 5) AS example_unmatched_ids
FROM (
    SELECT a.district_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_accounts a
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_districts d
        WHERE d.district_id = a.district_id
    )
) t

UNION ALL

-- 2. stg_clients.district_id → stg_districts.district_id
SELECT
    'stg_clients', 'district_id', 'stg_districts', 'district_id',
    COUNT(*), LIST(t.district_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT c.district_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_clients c
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_districts d
        WHERE d.district_id = c.district_id
    )
) t

UNION ALL

-- 3. stg_dispositions.account_id → stg_accounts.account_id
SELECT
    'stg_dispositions', 'account_id', 'stg_accounts', 'account_id',
    COUNT(*), LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT d.account_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_dispositions d
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_accounts a
        WHERE a.account_id = d.account_id
    )
) t

UNION ALL

-- 4. stg_dispositions.client_id → stg_clients.client_id
SELECT
    'stg_dispositions', 'client_id', 'stg_clients', 'client_id',
    COUNT(*), LIST(t.client_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT d.client_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_dispositions d
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_clients c
        WHERE c.client_id = d.client_id
    )
) t

UNION ALL

-- 5. stg_transactions.account_id → stg_accounts.account_id
SELECT
    'stg_transactions', 'account_id', 'stg_accounts', 'account_id',
    COUNT(*), LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT t.account_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_transactions t
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_accounts a
        WHERE a.account_id = t.account_id
    )
) t

UNION ALL

-- 6. stg_loans.account_id → stg_accounts.account_id
SELECT
    'stg_loans', 'account_id', 'stg_accounts', 'account_id',
    COUNT(*), LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT l.account_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_loans l
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_accounts a
        WHERE a.account_id = l.account_id
    )
) t

UNION ALL

-- 7. stg_orders.account_id → stg_accounts.account_id
SELECT
    'stg_orders', 'account_id', 'stg_accounts', 'account_id',
    COUNT(*), LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT o.account_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_orders o
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_accounts a
        WHERE a.account_id = o.account_id
    )
) t

UNION ALL

-- 8. stg_cards.disposition_id → stg_dispositions.disposition_id
SELECT
    'stg_cards', 'disposition_id', 'stg_dispositions', 'disposition_id',
    COUNT(*), LIST(t.disposition_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT c.disposition_id, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_cards c
    WHERE NOT EXISTS (
        SELECT 1 FROM staging.stg_dispositions d
        WHERE d.disposition_id = c.disposition_id
    )
) t;

