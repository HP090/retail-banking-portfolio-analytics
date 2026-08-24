CREATE OR REPLACE TABLE staging.stg_cards AS

SELECT
    CAST(TRIM(card_id) AS INTEGER)
        AS card_id,

    CAST(TRIM(disp_id) AS INTEGER)
        AS disposition_id,

    CASE LOWER(TRIM(type))
        WHEN 'classic'
            THEN 'Classic'

        WHEN 'junior'
            THEN 'Junior'

        WHEN 'gold'
            THEN 'Gold'

        ELSE 'Unknown'
    END AS card_type,

    CAST(TRIM(issued) AS DATE)
        AS issued_date

FROM raw.cards;