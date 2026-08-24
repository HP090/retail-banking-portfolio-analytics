CREATE OR REPLACE TABLE core.dim_transaction_type AS

WITH unique_types AS (
    SELECT DISTINCT
        direction,
        operation,
        purpose
    FROM staging.stg_transactions
    WHERE direction IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY direction,operation,purpose) AS transaction_type_key,
    direction,
    operation,
    purpose
FROM unique_types
