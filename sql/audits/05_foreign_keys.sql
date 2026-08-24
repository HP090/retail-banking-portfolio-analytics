-- 1. accounts.district_id → districts
SELECT
    'accounts'                         AS child_table,
    'district_id'                      AS child_column,
    'districts'                        AS parent_table,
    'district_id'                      AS parent_column,
    COUNT(*)                           AS unmatched_count,
    LIST(t.district_id) FILTER (WHERE rn <= 5) AS example_unmatched_ids
FROM (
    SELECT
        a.district_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.accounts a
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.districts d WHERE d.district_id = a.district_id
    )
) t

UNION ALL

-- 2. clients.district_id → districts
SELECT
    'clients',
    'district_id',
    'districts',
    'district_id',
    COUNT(*),
    LIST(t.district_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        c.district_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.clients c
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.districts d WHERE d.district_id = c.district_id
    )
) t

UNION ALL

-- 3. dispositions.account_id → accounts
SELECT
    'dispositions',
    'account_id',
    'accounts',
    'account_id',
    COUNT(*),
    LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        d.account_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.dispositions d
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.accounts a WHERE a.account_id = d.account_id
    )
) t

UNION ALL

-- 4. dispositions.client_id → clients
SELECT
    'dispositions',
    'client_id',
    'clients',
    'client_id',
    COUNT(*),
    LIST(t.client_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        d.client_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.dispositions d
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.clients c WHERE c.client_id = d.client_id
    )
) t

UNION ALL

-- 5. transactions.account_id → accounts
SELECT
    'transactions',
    'account_id',
    'accounts',
    'account_id',
    COUNT(*),
    LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        t.account_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.transactions t
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.accounts a WHERE a.account_id = t.account_id
    )
) t

UNION ALL

-- 6. loans.account_id → accounts
SELECT
    'loans',
    'account_id',
    'accounts',
    'account_id',
    COUNT(*),
    LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        l.account_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.loans l
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.accounts a WHERE a.account_id = l.account_id
    )
) t

UNION ALL

-- 7. orders.account_id → accounts
SELECT
    'orders',
    'account_id',
    'accounts',
    'account_id',
    COUNT(*),
    LIST(t.account_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        o.account_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.orders o
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.accounts a WHERE a.account_id = o.account_id
    )
) t

UNION ALL

-- 8. cards.disp_id → dispositions
SELECT
    'cards',
    'disp_id',
    'dispositions',
    'disp_id',
    COUNT(*),
    LIST(t.disp_id) FILTER (WHERE rn <= 5)
FROM (
    SELECT
        c.disp_id,
        ROW_NUMBER() OVER () AS rn
    FROM raw.cards c
    WHERE NOT EXISTS (
        SELECT 1 FROM raw.dispositions d WHERE d.disp_id = c.disp_id
    )
) t;