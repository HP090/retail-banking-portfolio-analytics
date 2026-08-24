-- 06_stg_card_and_code_checks.sql
-- Card resolution + unmapped code coverage


-- PART 1: Card resolution

SELECT
    'cards_missing_full_resolution' AS check_name,
    COUNT(*) AS violation_count,
    LIST(card_id) FILTER (WHERE rn <= 10) AS example_values
FROM (
    SELECT
        c.card_id,
        ROW_NUMBER() OVER () AS rn
    FROM staging.stg_cards c
    LEFT JOIN staging.stg_dispositions d
        ON c.disposition_id = d.disposition_id
    LEFT JOIN staging.stg_clients cl
        ON d.client_id = cl.client_id
    LEFT JOIN staging.stg_accounts a
        ON d.account_id = a.account_id
    WHERE d.disposition_id IS NULL
       OR cl.client_id IS NULL
       OR a.account_id IS NULL
) t

UNION ALL


-- PART 2: Unmapped codes in transactions

SELECT
    'transactions_unmapped_direction',
    COUNT(*),
    LIST(original_type) FILTER (WHERE rn <= 10)
FROM (
    SELECT original_type, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_transactions
    WHERE direction = 'unmapped'
) t

UNION ALL

SELECT
    'transactions_unmapped_operation',
    COUNT(*),
    LIST(original_operation) FILTER (WHERE rn <= 10)
FROM (
    SELECT original_operation, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_transactions
    WHERE operation = 'unmapped'
) t

UNION ALL

SELECT
    'transactions_unmapped_purpose',
    COUNT(*),
    LIST(original_k_symbol) FILTER (WHERE rn <= 10)
FROM (
    SELECT original_k_symbol, ROW_NUMBER() OVER () AS rn
    FROM staging.stg_transactions
    WHERE purpose = 'unmapped'
) t

UNION ALL


-- PART 3: Unmapped codes in orders

SELECT
    'orders_unmapped_purpose',
    COUNT(*),
    NULL
FROM staging.stg_orders
WHERE order_purpose = 'unmapped';