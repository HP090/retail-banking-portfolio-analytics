CREATE OR REPLACE TABLE core.dim_date AS

SELECT
    CAST(strftime(d, '%Y%m%d') AS INTEGER) AS date_key,
    d AS full_date,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(MONTH FROM d) AS month,
    strftime(d, '%B') AS month_name,
    EXTRACT(DAY FROM d) AS day,
    EXTRACT(DOW FROM d) AS day_of_week,          -- 0=Sunday in DuckDB
    strftime(d, '%A') AS day_name,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
    CASE WHEN d = last_day(d) THEN TRUE ELSE FALSE END AS is_month_end,
    strftime(d, '%Y-%m') AS year_month
FROM (SELECT CAST(UNNEST(
            generate_series(
                DATE '1993-01-01',
                DATE '1998-12-31',
                INTERVAL '1 day'
            )
        ) AS DATE
    ) AS d
);