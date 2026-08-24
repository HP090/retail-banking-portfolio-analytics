-- 1. LOAN STATUS CODES
SELECT
    'loans' AS table_name,
    'status' AS column_name,
    status AS recorded_value,
    COUNT(*) AS occurrence_count
FROM raw.loans
GROUP BY status

UNION ALL

-- 2. CARD TYPES
SELECT
    'cards',
    'type',
    type,
    COUNT(*)
FROM raw.cards
GROUP BY type

UNION ALL

-- 3. DISPOSITION TYPES
SELECT
    'dispositions',
    'type',
    type,
    COUNT(*)
FROM raw.dispositions
GROUP BY type

UNION ALL

-- 4. TRANSACTION DIRECTION (PRIJEM, VYDAJ, etc.)
SELECT
    'transactions',
    'type',
    type,
    COUNT(*)
FROM raw.transactions
GROUP BY type

UNION ALL

-- 5. TRANSACTION OPERATION (VKLAD, PREVOD, etc.)
SELECT
    'transactions',
    'operation',
    operation,
    COUNT(*)
FROM raw.transactions
GROUP BY operation

UNION ALL

-- 6. TRANSACTION PURPOSE (k_symbol)
SELECT
    'transactions',
    'k_symbol',
    k_symbol,
    COUNT(*)
FROM raw.transactions
GROUP BY k_symbol


UNION ALL

-- 7.Account statement frequency
SELECT
    'accounts',
    'frequency',
    frequency,
    COUNT(*)
FROM raw.accounts
GROUP BY frequency

UNION ALL

-- 8.Standing-order purpose
SELECT
    'orders',
    'k_symbol',
    k_symbol,
    COUNT(*)
FROM raw.orders
GROUP BY k_symbol