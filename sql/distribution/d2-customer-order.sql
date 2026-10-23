-- HG Industries, distribution schema, stage D2: the customer_order table.
-- A customer places zero or more orders; each order belongs to one customer.
--
-- Requires: stage D1, loaded into a freshly reset schema.
-- Load everything through this stage in one step: ../load/through-d2.sql

CREATE TABLE distribution.customer_order (
    customer_order_pk   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number        VARCHAR(10) NOT NULL UNIQUE,
    order_date          DATE        NOT NULL,
    requested_ship_date DATE,
    customer_fk         INTEGER     NOT NULL REFERENCES distribution.customer (customer_pk),
    CHECK (requested_ship_date >= order_date)
);

-- customer_order_pk runs 1 through 12. Two orders have no requested ship
-- date (NULL), and customer 8 (C-1008) has never ordered.
INSERT INTO distribution.customer_order
    (order_number, order_date, requested_ship_date, customer_fk) VALUES
    ('SO-5001', '2026-01-05', '2026-01-12', 1),
    ('SO-5002', '2026-01-07', '2026-01-14', 3),
    ('SO-5003', '2026-01-12', NULL,         2),
    ('SO-5004', '2026-01-15', '2026-01-22', 1),
    ('SO-5005', '2026-01-21', '2026-02-02', 4),
    ('SO-5006', '2026-01-28', '2026-02-04', 6),
    ('SO-5007', '2026-02-03', '2026-02-10', 3),
    ('SO-5008', '2026-02-11', NULL,         5),
    ('SO-5009', '2026-02-18', '2026-02-25', 7),
    ('SO-5010', '2026-02-24', '2026-03-03', 1),
    ('SO-5011', '2026-03-04', '2026-03-11', 6),
    ('SO-5012', '2026-03-10', '2026-03-17', 2);
