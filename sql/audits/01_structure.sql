SELECT 'accounts' AS table_name , COUNT(*) AS row_count
FROM raw.accounts

UNION ALL

SELECT 'clients', COUNT(*)
FROM raw.clients

UNION ALL

SELECT 'dispositions', COUNT(*)
FROM raw.dispositions

UNION ALL

SELECT 'transactions', COUNT(*)
FROM raw.transactions

UNION ALL

SELECT 'loans', COUNT(*)
FROM raw.loans

UNION ALL

SELECT 'cards', COUNT(*)
FROM raw.cards

UNION ALL

SELECT 'orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'districts', COUNT(*)
FROM raw.districts;