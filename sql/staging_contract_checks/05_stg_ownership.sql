-- 05_stg_ownership.sql
-- Exactly one designated owner per account

WITH owner_counts AS (
    SELECT
        account_id,
        COUNT(*) FILTER (WHERE is_owner = TRUE) AS owner_count
    FROM staging.stg_dispositions
    GROUP BY account_id
),

account_ownership AS (
    SELECT
        a.account_id,
        COALESCE(o.owner_count, 0) AS owner_count
    FROM staging.stg_accounts a
    LEFT JOIN owner_counts o
        ON a.account_id = o.account_id
)

SELECT
    'accounts_with_zero_owners' AS check_name,
    COUNT(*) AS account_count,
    LIST(account_id) FILTER (WHERE rn <= 10) AS example_account_ids
FROM (
    SELECT
        account_id,
        ROW_NUMBER() OVER () AS rn
    FROM account_ownership
    WHERE owner_count = 0
) t

UNION ALL

SELECT
    'accounts_with_multiple_owners',
    COUNT(*),
    LIST(account_id) FILTER (WHERE rn <= 10)
FROM (
    SELECT
        account_id,
        ROW_NUMBER() OVER () AS rn
    FROM account_ownership
    WHERE owner_count > 1
) t

UNION ALL

SELECT
    'accounts_with_exactly_one_owner',
    COUNT(*),
    NULL
FROM account_ownership
WHERE owner_count = 1;