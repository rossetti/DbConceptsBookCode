-- A value of the wrong type in an INTEGER column (@sec-appembedded-sqlite).
.headers on
.mode column
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (2, 'GC-300', 'forty');
SELECT product_number, quantity_on_hand,
       typeof(quantity_on_hand) AS stored_as
FROM stock_level
WHERE warehouse_fk = 2;
CREATE TABLE stock_count (
    product_number TEXT NOT NULL,
    counted INTEGER NOT NULL
) STRICT;
INSERT INTO stock_count VALUES ('GC-300', 'forty');
