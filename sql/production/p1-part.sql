-- HG Industries, production schema, stage P1: the part table and its two
-- kinds, purchased_part and manufactured_part (a generalization: every part
-- is exactly one of the two). Also connects distribution to production: each
-- product becomes a reference to the manufactured part it is.
--
-- Requires: stage D5 (for the distribution.product table), loaded into a
-- freshly reset database.
-- Load everything through this stage in one step: ../load/through-p1.sql

CREATE SCHEMA production;

CREATE TABLE production.part (
    part_pk         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    part_number     VARCHAR(10)   NOT NULL UNIQUE,
    description     VARCHAR(60)   NOT NULL,
    unit_of_measure VARCHAR(4)    NOT NULL,
    standard_cost   NUMERIC(10,2) NOT NULL CHECK (standard_cost > 0)
);

-- part_pk runs 1 through 18: the manufactured parts first (1 to 8), then the
-- purchased parts (9 to 18). Tubing and bar stock are bought by the foot.
INSERT INTO production.part (part_number, description, unit_of_measure, standard_cost) VALUES
    ('HT-100', 'Two-wheel hand truck',      'EA', 52.40),
    ('HT-200', 'Convertible hand truck',    'EA', 58.90),
    ('GC-300', 'Steel garden cart',         'EA', 66.40),
    ('GC-400', 'Poly garden cart',          'EA', 79.30),
    ('FR-110', 'Hand truck frame',          'EA', 18.60),
    ('CF-310', 'Cart frame',                'EA', 14.90),
    ('WA-10',  'Wheel assembly, 10 in',     'EA',  9.85),
    ('AX-10',  'Axle, 5/8 in',              'EA',  1.95),
    ('TU-12',  'Steel tubing, 1 in',        'FT',  1.10),
    ('BS-075', 'Bar stock, 5/8 in',         'FT',  1.30),
    ('TI-10',  'Pneumatic tire, 10 in',     'EA',  3.40),
    ('RM-10',  'Steel rim, 10 in',          'EA',  2.60),
    ('BR-10',  'Ball bearing',              'EA',  0.55),
    ('TR-300', 'Steel tray',                'EA', 21.00),
    ('TR-400', 'Poly tray',                 'EA', 32.00),
    ('GR-01',  'Handle grip',               'EA',  0.80),
    ('HW-01',  'Hardware kit',              'EA',  2.25),
    ('CA-06',  'Swivel caster, 6 in',       'EA',  4.10);

-- Each subclass table's key is also a reference to the part it is.
CREATE TABLE production.manufactured_part (
    part_fk  INTEGER PRIMARY KEY REFERENCES production.part (part_pk),
    lot_size INTEGER NOT NULL CHECK (lot_size > 0)
);

INSERT INTO production.manufactured_part (part_fk, lot_size) VALUES
    (1,  50), (2,  25), (3,  40), (4,  20),
    (5, 100), (6,  80), (7, 200), (8, 400);

CREATE TABLE production.purchased_part (
    part_fk        INTEGER PRIMARY KEY REFERENCES production.part (part_pk),
    lead_time_days INTEGER NOT NULL CHECK (lead_time_days > 0)
);

INSERT INTO production.purchased_part (part_fk, lead_time_days) VALUES
    ( 9, 14), (10, 14), (11, 21), (12, 21), (13, 10),
    (14, 30), (15, 45), (16,  7), (17,  7), (18, 21);

-- Connect distribution to production. A product's number is the part number
-- of the manufactured part it is, so the new column is filled by matching
-- the two, and required once every product has its part.
ALTER TABLE distribution.product
    ADD COLUMN manufactured_part_fk INTEGER
        REFERENCES production.manufactured_part (part_fk);

UPDATE distribution.product
   SET manufactured_part_fk = production.part.part_pk
  FROM production.part
 WHERE production.part.part_number = distribution.product.product_number;

ALTER TABLE distribution.product
    ALTER COLUMN manufactured_part_fk SET NOT NULL;
