-- The frame line's simulation results, queried in DuckDB
-- straight from a CSV file (@sec-appembedded-duckdb).
-- Run from the code folder with DuckDB's shell:
-- duckdb -echo < sql/embedded/duckdb-results.sql
.mode column
SELECT column_name, column_type
FROM (DESCRIBE
      SELECT * FROM 'data/frame-line-replications.csv');
SELECT exp_name, stat_name, COUNT(*) AS reps,
       ROUND(AVG(rep_value), 3) AS average,
       ROUND(STDDEV_SAMP(rep_value), 3) AS std_dev
FROM 'data/frame-line-replications.csv'
GROUP BY exp_name, stat_name
ORDER BY stat_name, exp_name;
PIVOT (
    SELECT rep_id, stat_name,
           ROUND(rep_value, 3) AS rep_value
    FROM 'data/frame-line-replications.csv'
    WHERE exp_name = 'TwoWelders' AND rep_id <= 3
)
ON stat_name
USING MAX(rep_value)
ORDER BY rep_id;
