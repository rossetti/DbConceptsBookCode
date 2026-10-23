-- HG Industries, distribution schema, stage D4: the warehouse and
-- stock_level tables. How many of a product a warehouse holds belongs to the
-- pairing of warehouse and product.
--
-- Requires: stage D3, loaded into a freshly reset schema.
-- Load everything through this stage in one step: ../load/through-d4.sql

CREATE TABLE distribution.warehouse (
    warehouse_pk   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_code VARCHAR(10) NOT NULL UNIQUE,
    city           VARCHAR(40) NOT NULL,
    state          CHAR(2)     NOT NULL
);

-- warehouse_pk: 1 is the plant warehouse in Fayetteville, 2 is Tulsa.
INSERT INTO distribution.warehouse (warehouse_code, city, state) VALUES
    ('W-FAY', 'Fayetteville', 'AR'),
    ('W-TUL', 'Tulsa',        'OK');

CREATE TABLE distribution.stock_level (
    stock_level_pk   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_fk     INTEGER NOT NULL REFERENCES distribution.warehouse (warehouse_pk),
    product_fk       INTEGER NOT NULL REFERENCES distribution.product (product_pk),
    quantity_on_hand INTEGER NOT NULL CHECK (quantity_on_hand >= 0),
    reorder_point    INTEGER NOT NULL CHECK (reorder_point >= 0),
    UNIQUE (warehouse_fk, product_fk)
);

-- Two stock levels are below their reorder points: the GC-300 in
-- Fayetteville and the GC-400 in Tulsa, which has none on hand.
INSERT INTO distribution.stock_level
    (warehouse_fk, product_fk, quantity_on_hand, reorder_point) VALUES
    (1, 1, 120, 40),
    (1, 2,  35, 20),
    (1, 3,  18, 25),
    (1, 4,  30, 10),
    (2, 1,  60, 30),
    (2, 2,  15, 10),
    (2, 3,  40, 20),
    (2, 4,   0,  5);
