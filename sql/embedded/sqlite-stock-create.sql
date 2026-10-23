-- Stock levels of stage D4 in an embedded SQLite database
-- (@sec-appembedded-sqlite). Run with:  sqlite3 -echo stock.db < sqlite-stock-create.sql
.headers on
.mode column
CREATE TABLE warehouse (
    warehouse_pk INTEGER PRIMARY KEY,
    warehouse_code TEXT NOT NULL UNIQUE,
    city TEXT NOT NULL,
    state TEXT NOT NULL
);
CREATE TABLE stock_level (
    stock_level_pk INTEGER PRIMARY KEY,
    warehouse_fk INTEGER NOT NULL REFERENCES warehouse,
    product_number TEXT NOT NULL,
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
