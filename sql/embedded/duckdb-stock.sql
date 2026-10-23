-- Stock levels of stage D4 in an embedded DuckDB database
-- (@sec-appembedded-duckdb). Run with DuckDB's shell:
-- duckdb -echo stock.duckdb < duckdb-stock.sql
.mode column
CREATE SEQUENCE warehouse_seq;
CREATE TABLE warehouse (
    warehouse_pk INTEGER
        DEFAULT nextval('warehouse_seq') PRIMARY KEY,
    warehouse_code VARCHAR(10) NOT NULL UNIQUE,
    city VARCHAR(40) NOT NULL,
    state CHAR(2) NOT NULL
);
CREATE SEQUENCE stock_level_seq;
CREATE TABLE stock_level (
    stock_level_pk INTEGER
        DEFAULT nextval('stock_level_seq') PRIMARY KEY,
    warehouse_fk INTEGER NOT NULL REFERENCES warehouse,
    product_number VARCHAR(10) NOT NULL,
    quantity_on_hand INTEGER NOT NULL
        CHECK (quantity_on_hand >= 0),
    UNIQUE (warehouse_fk, product_number)
);
INSERT INTO warehouse (warehouse_code, city, state)
VALUES ('W-FAY', 'Fayetteville', 'AR'), ('W-TUL', 'Tulsa', 'OK');
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (1, 'HT-100', 120), (1, 'GC-300', 18), (2, 'HT-100', 60);
SELECT w.warehouse_code, s.product_number, s.quantity_on_hand
FROM stock_level AS s
JOIN warehouse AS w ON w.warehouse_pk = s.warehouse_fk
ORDER BY w.warehouse_code, s.product_number;
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (2, 'GC-300', 'forty');
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (9, 'HT-200', 5);
UPDATE warehouse SET city = 'Springdale'
WHERE warehouse_code = 'W-FAY';
UPDATE warehouse SET warehouse_code = 'W-SPR'
WHERE warehouse_code = 'W-FAY';
SELECT * FROM warehouse;
