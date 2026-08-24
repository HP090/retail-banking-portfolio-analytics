-- 1. transactions.amount
SELECT
    'transactions'                              AS table_name,
    'amount'                                    AS column_name,
    COUNT(*)                                    AS total_source_values,
    COUNT(TRY_CAST(amount AS DOUBLE))           AS successfully_parsed_numeric_values,
    COUNT(*) - COUNT(TRY_CAST(amount AS DOUBLE)) AS unparseable_or_missing_values,
    MIN(TRY_CAST(amount AS DOUBLE))             AS minimum,
    MEDIAN(TRY_CAST(amount AS DOUBLE))          AS median,
    MAX(TRY_CAST(amount AS DOUBLE))             AS maximum
FROM raw.transactions

UNION ALL

-- 2. transactions.balance
SELECT
    'transactions',
    'balance',
    COUNT(*),
    COUNT(TRY_CAST(balance AS DOUBLE)),
    COUNT(*) - COUNT(TRY_CAST(balance AS DOUBLE)),
    MIN(TRY_CAST(balance AS DOUBLE)),
    MEDIAN(TRY_CAST(balance AS DOUBLE)),
    MAX(TRY_CAST(balance AS DOUBLE))
FROM raw.transactions

UNION ALL

-- 3. loans.amount
SELECT
    'loans',
    'amount',
    COUNT(*),
    COUNT(TRY_CAST(amount AS DOUBLE)),
    COUNT(*) - COUNT(TRY_CAST(amount AS DOUBLE)),
    MIN(TRY_CAST(amount AS DOUBLE)),
    MEDIAN(TRY_CAST(amount AS DOUBLE)),
    MAX(TRY_CAST(amount AS DOUBLE))
FROM raw.loans

UNION ALL

-- 4. loans.payments
SELECT
    'loans',
    'payments',
    COUNT(*),
    COUNT(TRY_CAST(payments AS DOUBLE)),
    COUNT(*) - COUNT(TRY_CAST(payments AS DOUBLE)),
    MIN(TRY_CAST(payments AS DOUBLE)),
    MEDIAN(TRY_CAST(payments AS DOUBLE)),
    MAX(TRY_CAST(payments AS DOUBLE))
FROM raw.loans

UNION ALL

-- 5. orders.amount
SELECT
    'orders',
    'amount',
    COUNT(*),
    COUNT(TRY_CAST(amount AS DOUBLE)),
    COUNT(*) - COUNT(TRY_CAST(amount AS DOUBLE)),
    MIN(TRY_CAST(amount AS DOUBLE)),
    MEDIAN(TRY_CAST(amount AS DOUBLE)),
    MAX(TRY_CAST(amount AS DOUBLE))
FROM raw.orders;