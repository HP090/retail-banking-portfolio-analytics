CREATE OR REPLACE TABLE mart.mart_loan_portfolio AS

WITH base AS (
    SELECT
        l.loan_id,
        l.account_key,
        a.district_id,
        l.origination_date,
        l.origination_year,
        l.loan_amount,
        l.duration_months,
        l.monthly_payment,
        l.scheduled_maturity_date,
        l.status_code,
        l.status_group
    FROM core.fct_loans l
    LEFT JOIN core.dim_account a
        ON l.account_key = a.account_id
),

month_ends AS (
    SELECT last_day(d) AS month_end
    FROM (
        SELECT UNNEST(generate_series(
            DATE '1993-01-01',
            DATE '1998-12-31',
            INTERVAL '1 month'
        )) AS d
    )
),

three_month_back AS (
    SELECT
        a.loan_id,
        a.account_key,
        a.origination_date,
        b.month_end AS lookback_month_end
    FROM base a
    INNER JOIN month_ends b
        ON  b.month_end <  last_day(DATE_TRUNC('month', a.origination_date))
        AND b.month_end >= last_day(DATE_TRUNC('month', a.origination_date) - INTERVAL 3 MONTH)
),

pre_origination_inflow AS (
    SELECT
        a.loan_id,
        COUNT(b.external_credit_inflows) AS pre_origination_months_observed,
        CASE
            WHEN COUNT(b.external_credit_inflows) = 3
                THEN AVG(b.external_credit_inflows)
            ELSE NULL
        END AS pre_origination_avg_inflow
    FROM three_month_back a
    LEFT JOIN core.fct_account_monthly_snapshot b
        ON  a.account_key = b.account_id
        AND a.lookback_month_end = b.month_end
    GROUP BY a.loan_id
),

pre_origination_balance AS (
    SELECT
        a.loan_id,
        COUNT(b.month_end_balance) FILTER (WHERE b.balance_known_as_of_month_end)
       AS pre_origination_balance_months_observed,
        CASE
            WHEN COUNT(b.month_end_balance) FILTER (WHERE b.balance_known_as_of_month_end) = 3
                THEN AVG(b.month_end_balance) FILTER (WHERE b.balance_known_as_of_month_end)
            ELSE NULL
        END AS pre_origination_avg_balance,
        CASE
            WHEN COUNT(b.month_end_balance) FILTER (WHERE b.balance_known_as_of_month_end) = 3
                THEN MIN(b.month_end_balance) FILTER (WHERE b.balance_known_as_of_month_end)
            ELSE NULL
        END AS pre_origination_min_balance
    FROM three_month_back a
    LEFT JOIN core.fct_account_monthly_snapshot b
        ON  a.account_key = b.account_id
        AND a.lookback_month_end = b.month_end
    GROUP BY a.loan_id
)

SELECT
    b.loan_id,
    b.account_key AS account_id,
    b.district_id,
    b.origination_date,
    b.origination_year,
    b.loan_amount,
    b.duration_months,
    b.monthly_payment,
    b.scheduled_maturity_date,
    b.status_code,
    b.status_group,

    i.pre_origination_avg_inflow,
    i.pre_origination_months_observed,
    p.pre_origination_avg_balance,
    p.pre_origination_min_balance,
    p.pre_origination_balance_months_observed,

    CASE
        WHEN i.pre_origination_avg_inflow IS NULL
          OR i.pre_origination_avg_inflow <= 0
            THEN NULL
        ELSE b.monthly_payment / i.pre_origination_avg_inflow
    END AS payment_to_inflow_ratio,

    CASE
        WHEN i.pre_origination_avg_inflow IS NULL THEN 'insufficient_history'
        WHEN i.pre_origination_avg_inflow < 5000 THEN 'low'
        WHEN i.pre_origination_avg_inflow < 10000 THEN 'medium'
        ELSE 'high'
    END AS pre_origination_inflow_band,

    CASE
        WHEN p.pre_origination_avg_balance IS NULL THEN 'insufficient_history'
        WHEN p.pre_origination_avg_balance < 10000 THEN 'low'
        WHEN p.pre_origination_avg_balance < 25000 THEN 'medium'
        ELSE 'high'
    END AS pre_origination_balance_band,

    CASE
        WHEN i.pre_origination_avg_inflow IS NULL
          OR i.pre_origination_avg_inflow <= 0 THEN 'insufficient_history'
        WHEN b.monthly_payment / i.pre_origination_avg_inflow <= 0.30 THEN 'comfortable'
        WHEN b.monthly_payment / i.pre_origination_avg_inflow <= 0.50 THEN 'stretched'
        ELSE 'high_burden'
    END AS payment_to_inflow_band

FROM base b
LEFT JOIN pre_origination_inflow i
    ON b.loan_id = i.loan_id
LEFT JOIN pre_origination_balance p
    ON b.loan_id = p.loan_id;

