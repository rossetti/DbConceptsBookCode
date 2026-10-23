-- HG Industries, distribution schema, stage D5: the shipment and
-- shipment_line tables. An order may have no shipment yet; a shipment line
-- ships some quantity of one order line.
--
-- Requires: stage D4, loaded into a freshly reset schema.
-- Load everything through this stage in one step: ../load/through-d5.sql

CREATE TABLE distribution.shipment (
    shipment_pk       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_number   VARCHAR(10) NOT NULL UNIQUE,
    shipped_on        DATE        NOT NULL,
    carrier           VARCHAR(40) NOT NULL,
    customer_order_fk INTEGER     NOT NULL REFERENCES distribution.customer_order (customer_order_pk),
    warehouse_fk      INTEGER     NOT NULL REFERENCES distribution.warehouse (warehouse_pk)
);

-- shipment_pk runs 1 through 11. Order SO-5004 shipped in two shipments;
-- orders SO-5011 and SO-5012 have not shipped at all.
INSERT INTO distribution.shipment
    (shipment_number, shipped_on, carrier, customer_order_fk, warehouse_fk) VALUES
    ('SH-9001', '2026-01-09', 'Boston Mountain Freight',  1, 1),
    ('SH-9002', '2026-01-12', 'Tri-State Logistics',      2, 2),
    ('SH-9003', '2026-01-16', 'Customer pickup',          3, 1),
    ('SH-9004', '2026-01-20', 'Boston Mountain Freight',  4, 1),
    ('SH-9005', '2026-01-27', 'Boston Mountain Freight',  4, 1),
    ('SH-9006', '2026-01-29', 'Tri-State Logistics',      5, 2),
    ('SH-9007', '2026-02-03', 'Tri-State Logistics',      6, 2),
    ('SH-9008', '2026-02-09', 'Tri-State Logistics',      7, 2),
    ('SH-9009', '2026-02-17', 'Customer pickup',          8, 1),
    ('SH-9010', '2026-02-24', 'Boston Mountain Freight',  9, 1),
    ('SH-9011', '2026-03-02', 'Boston Mountain Freight', 10, 1);

CREATE TABLE distribution.shipment_line (
    shipment_line_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- a shipment line is a link of the association class ShipmentLine and depends on its
    -- shipment (@sec-map-many-to-many): deleting the shipment deletes its lines
    shipment_fk      INTEGER NOT NULL REFERENCES distribution.shipment (shipment_pk)
                                      ON DELETE CASCADE,
    order_line_fk    INTEGER NOT NULL REFERENCES distribution.order_line (order_line_pk),
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    UNIQUE (shipment_fk, order_line_fk)
);

-- Three order lines are shipped only in part, leaving backorders: order
-- line 6 (3 of 6), order line 11 (20 of 25), and order line 17 (6 of 10).
INSERT INTO distribution.shipment_line (shipment_fk, order_line_fk, quantity) VALUES
    ( 1,  1, 10),
    ( 1,  2,  4),
    ( 2,  3,  6),
    ( 3,  4, 12),
    ( 3,  5,  4),
    ( 3,  6,  3),
    ( 4,  7, 20),
    ( 4,  8,  5),
    ( 5,  9, 10),
    ( 6, 10,  8),
    ( 7, 11, 20),
    ( 7, 12, 10),
    ( 8, 13,  6),
    ( 8, 14,  8),
    ( 9, 15,  3),
    (10, 16, 15),
    (10, 17,  6),
    (11, 18,  5);
