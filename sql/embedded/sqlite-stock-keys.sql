-- Foreign keys are enforced only when a connection asks
-- (@sec-appembedded-sqlite).
.headers on
.mode column
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (9, 'HT-200', 5);
PRAGMA foreign_keys = ON;
INSERT INTO stock_level
    (warehouse_fk, product_number, quantity_on_hand)
VALUES (9, 'GC-400', 7);
SELECT stock_level_pk, warehouse_fk, product_number
FROM stock_level
WHERE warehouse_fk NOT IN (SELECT warehouse_pk FROM warehouse);
