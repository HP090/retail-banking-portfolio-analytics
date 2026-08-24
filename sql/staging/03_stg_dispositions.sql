CREATE OR REPLACE TABLE staging.stg_dispositions AS

SELECT
    CAST(TRIM(disp_id) AS INTEGER) AS disposition_id,
    CAST(TRIM(client_id) AS INTEGER) AS client_id,
    CAST(TRIM(account_id) AS INTEGER) AS account_id,

    CASE UPPER(TRIM(type))
        WHEN 'OWNER'
            THEN 'owner'

        WHEN 'DISPONENT'
            THEN 'authorised_user'

        ELSE 'unknown'
    END AS relationship_type,

    CASE UPPER(TRIM(type))
        WHEN 'OWNER'
            THEN TRUE

        WHEN 'DISPONENT'
            THEN FALSE

        ELSE NULL
    END AS is_owner

FROM raw.dispositions;