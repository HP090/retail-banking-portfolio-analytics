-- 01_stg_primary_keys.sql
-- Primary-key uniqueness and non-null checks on staging tables

SELECT
    'stg_accounts' AS table_name,
    'account_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT account_id) AS unique_keys,
    COUNT(*) - COUNT(DISTINCT account_id) AS duplicate_key_count,
    COUNT(*) FILTER (WHERE account_id IS NULL) AS missing_key_count
FROM staging.stg_accounts

UNION ALL

SELECT
    'stg_clients',
    'client_id',
    COUNT(*),
    COUNT(DISTINCT client_id),
    COUNT(*) - COUNT(DISTINCT client_id),
    COUNT(*) FILTER (WHERE client_id IS NULL)
FROM staging.stg_clients

UNION ALL

SELECT
    'stg_dispositions',
    'disposition_id',
    COUNT(*),
    COUNT(DISTINCT disposition_id),
    COUNT(*) - COUNT(DISTINCT disposition_id),
    COUNT(*) FILTER (WHERE disposition_id IS NULL)
FROM staging.stg_dispositions

UNION ALL

SELECT
    'stg_cards',
    'card_id',
    COUNT(*),
    COUNT(DISTINCT card_id),
    COUNT(*) - COUNT(DISTINCT card_id),
    COUNT(*) FILTER (WHERE card_id IS NULL)
FROM staging.stg_cards

UNION ALL

SELECT
    'stg_orders',
    'order_id',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id),
    COUNT(*) FILTER (WHERE order_id IS NULL)
FROM staging.stg_orders

UNION ALL

SELECT
    'stg_districts',
    'district_id',
    COUNT(*),
    COUNT(DISTINCT district_id),
    COUNT(*) - COUNT(DISTINCT district_id),
    COUNT(*) FILTER (WHERE district_id IS NULL)
FROM staging.stg_districts

UNION ALL

SELECT
    'stg_loans',
    'loan_id',
    COUNT(*),
    COUNT(DISTINCT loan_id),
    COUNT(*) - COUNT(DISTINCT loan_id),
    COUNT(*) FILTER (WHERE loan_id IS NULL)
FROM staging.stg_loans

UNION ALL

SELECT
    'stg_transactions',
    'transaction_id',
    COUNT(*),
    COUNT(DISTINCT transaction_id),
    COUNT(*) - COUNT(DISTINCT transaction_id),
    COUNT(*) FILTER (WHERE transaction_id IS NULL)
FROM staging.stg_transactions;