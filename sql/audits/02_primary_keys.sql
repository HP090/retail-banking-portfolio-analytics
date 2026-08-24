SELECT
    'accounts' AS table_name,
    'account_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT account_id) AS unique_keys,
    COUNT(account_id) - COUNT(DISTINCT account_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN account_id IS NULL THEN 1
            WHEN LOWER(TRIM(account_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.accounts

UNION ALL

SELECT
    'clients' AS table_name,
    'client_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT client_id) AS unique_keys,
    COUNT(client_id) - COUNT(DISTINCT client_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN client_id IS NULL THEN 1
            WHEN LOWER(TRIM(client_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.clients

UNION ALL

SELECT
    'dispositions' AS table_name,
    'disp_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT disp_id) AS unique_keys,
    COUNT(disp_id) - COUNT(DISTINCT disp_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN disp_id IS NULL THEN 1
            WHEN LOWER(TRIM(disp_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.dispositions

UNION ALL

SELECT
    'transactions' AS table_name,
    'trans_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT trans_id) AS unique_keys,
    COUNT(trans_id) - COUNT(DISTINCT trans_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN trans_id IS NULL THEN 1
            WHEN LOWER(TRIM(trans_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.transactions

UNION ALL

SELECT
    'loans' AS table_name,
    'loan_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_keys,
    COUNT(loan_id) - COUNT(DISTINCT loan_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN loan_id IS NULL THEN 1
            WHEN LOWER(TRIM(loan_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.loans

UNION ALL

SELECT
    'cards' AS table_name,
    'card_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT card_id) AS unique_keys,
    COUNT(card_id) - COUNT(DISTINCT card_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN card_id IS NULL THEN 1
            WHEN LOWER(TRIM(card_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.cards

UNION ALL

SELECT
    'orders' AS table_name,
    'order_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_keys,
    COUNT(order_id) - COUNT(DISTINCT order_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN order_id IS NULL THEN 1
            WHEN LOWER(TRIM(order_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.orders

UNION ALL

SELECT
    'districts' AS table_name,
    'district_id' AS primary_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT district_id) AS unique_keys,
    COUNT(district_id) - COUNT(DISTINCT district_id) AS total_duplicate_key_count,
    SUM(
        CASE
            WHEN district_id IS NULL THEN 1
            WHEN LOWER(TRIM(district_id)) IN ('', '?', 'unknown', 'null') THEN 1
            ELSE 0
        END
    ) AS total_missing_keys
FROM raw.districts;






