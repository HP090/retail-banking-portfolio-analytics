CREATE OR REPLACE TABLE mart.mart_relationship_segment_summary AS

WITH totals AS (
    SELECT
        COUNT(*) AS total_accounts,
        SUM(GREATEST(latest_observed_balance, 0)) AS total_positive_balance
    FROM mart.mart_relationship_segments
)

SELECT
    s.primary_segment,
    s.district_id
    COUNT(*) AS account_count,
    COUNT(*) * 1.0 / MAX(t.total_accounts) AS pct_of_accounts,

    SUM(GREATEST(s.latest_observed_balance, 0)) AS positive_balance_total,
    SUM(GREATEST(s.latest_observed_balance, 0)) * 1.0
        / NULLIF(MAX(t.total_positive_balance), 0) AS pct_of_positive_balance,

    AVG(s.recency_days) AS avg_recency_days,
    AVG(s.frequency) AS avg_frequency,
    AVG(s.monetary_value) AS avg_monetary_value,

    COUNT(*) FILTER (WHERE s.has_qualifying_activity_history) AS accounts_with_activity_history,
    COUNT(*) FILTER (WHERE s.flag_has_card) AS accounts_with_card,
    COUNT(*) FILTER (WHERE s.flag_has_loan) AS accounts_with_loan,
    COUNT(*) FILTER (WHERE s.flag_overdrawn) AS overdrawn_accounts,
    COUNT(*) FILTER (WHERE s.flag_no_activity_history) AS no_activity_history_accounts,
    COUNT(*) FILTER (WHERE s.flag_balance_declining) AS balance_declining_accounts
FROM mart.mart_relationship_segments s
CROSS JOIN totals t
GROUP BY s.primary_segment,s.district_id;