CREATE OR REPLACE TABLE core.fct_transactions AS
       
SELECT
    t.transaction_id,

    -- Date key
    CAST(strftime(t.transaction_date, '%Y%m%d') AS INTEGER) AS date_key,

    -- Account key
    t.account_id AS account_key,

    -- Transaction type key (joined from dim_transaction_type)
    tt.transaction_type_key,

    -- Measures
    t.amount,
    t.credit_amount,
    t.debit_amount,
    t.signed_amount,
    t.reported_balance,

    -- Useful attributes
    t.direction,
    t.operation,
    t.purpose,
    t.is_qualifying_account_activity,
    t.is_external_credit_inflow,

    t.transaction_date,
    t.transaction_month

FROM staging.stg_transactions t
LEFT JOIN core.dim_transaction_type tt
    ON t.direction IS NOT DISTINCT FROM tt.direction
   AND t.operation IS NOT DISTINCT FROM tt.operation
   AND t.purpose IS NOT DISTINCT FROM tt.purpose;