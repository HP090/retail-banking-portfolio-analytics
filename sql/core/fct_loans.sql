CREATE OR REPLACE TABLE core.fct_loans AS

SELECT
    l.loan_id,

    -- Keys
    CAST(strftime(l.origination_date, '%Y%m%d') AS INTEGER) AS origination_date_key,
    l.account_id AS account_key,

    -- Measures
    l.loan_amount,
    l.duration_months,
    l.monthly_payment,

    -- Status
    l.status_code,
    l.status_group,

    -- Derived
    l.scheduled_maturity_date,
    l.origination_date,
    l.origination_year,
    l.status_as_of_date

FROM staging.stg_loans l;