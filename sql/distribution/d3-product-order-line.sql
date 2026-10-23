-- HG Industries, distribution schema, stage D3: the product and order_line
-- tables. An order is for one or more products through its order lines,
-- which are numbered within the order.
--
-- Requires: stage D2, loaded into a freshly reset schema.
-- Load everything through this stage in one step: ../load/through-d3.sql

CREATE TABLE distribution.product (
    product_pk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_number VARCHAR(10)   NOT NULL UNIQUE,
    description    VARCHAR(60)   NOT NULL,
    list_price     NUMERIC(10,2) NOT NULL CHECK (list_price > 0)
);

-- product_pk runs 1 through 4. The GC-400 has never been ordered.
INSERT INTO distribution.product (product_number, description, list_price) VALUES
    ('HT-100', 'Two-wheel hand truck',   89.00),
    ('HT-200', 'Convertible hand truck', 139.00),
    ('GC-300', 'Steel garden cart',      119.00),
    ('GC-400', 'Poly garden cart',       149.00);

-- An order line is identified by its order and its line number, which is a
-- key of the table (the UNIQUE constraint) as well as the surrogate key.
CREATE TABLE distribution.order_line (
    order_line_pk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- an order line is composed in its order (@sec-mapping): deleting the whole deletes it
    customer_order_fk INTEGER       NOT NULL REFERENCES distribution.customer_order (customer_order_pk)
                                             ON DELETE CASCADE,
    line_number       INTEGER       NOT NULL CHECK (line_number > 0),
    product_fk        INTEGER       NOT NULL REFERENCES distribution.product (product_pk),
    quantity          INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price        NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    UNIQUE (customer_order_fk, line_number)
);

-- order_line_pk runs 1 through 22. Order SO-5004 lists the HT-100 twice, on
-- line 1 at the list price and on line 3 at a promotional price.
INSERT INTO distribution.order_line
    (customer_order_fk, line_number, product_fk, quantity, unit_price) VALUES
    ( 1, 1, 1, 10,  89.00),
    ( 1, 2, 3,  4, 119.00),
    ( 2, 1, 2,  6, 139.00),
    ( 3, 1, 1, 12,  85.00),
    ( 3, 2, 2,  4, 135.00),
    ( 3, 3, 3,  6, 115.00),
    ( 4, 1, 1, 20,  89.00),
    ( 4, 2, 3,  5, 119.00),
    ( 4, 3, 1, 10,  79.00),
    ( 5, 1, 3,  8, 119.00),
    ( 6, 1, 1, 25,  84.00),
    ( 6, 2, 2, 10, 132.00),
    ( 7, 1, 3,  6, 119.00),
    ( 7, 2, 1,  8,  89.00),
    ( 8, 1, 2,  3, 139.00),
    ( 9, 1, 1, 15,  89.00),
    ( 9, 2, 3, 10, 115.00),
    (10, 1, 2,  5, 139.00),
    (11, 1, 1, 30,  82.00),
    (11, 2, 3, 12, 112.00),
    (12, 1, 3,  4, 119.00),
    (12, 2, 2,  2, 139.00);
