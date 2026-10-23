-- HG Industries, quality schema, stage Q: characteristics of parts with
-- their specification limits, inspections of parts by production's
-- operators, the measurements each inspection takes, and the defects it
-- finds.
--
-- Requires: stage P3 (for production.part and production.operator), loaded
-- into a freshly reset database.
-- Load everything through this stage in one step: ../load/through-q.sql

CREATE SCHEMA quality;

CREATE TABLE quality.characteristic (
    characteristic_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- a characteristic is composed in its part (@sec-mapping): deleting the whole deletes it
    part_fk           INTEGER       NOT NULL REFERENCES production.part (part_pk)
                                             ON DELETE CASCADE,
    name              VARCHAR(40)   NOT NULL,
    nominal           NUMERIC(10,4) NOT NULL,
    lower_spec_limit  NUMERIC(10,4),
    upper_spec_limit  NUMERIC(10,4),
    unit              VARCHAR(10)   NOT NULL,
    UNIQUE (part_fk, name),
    CHECK (lower_spec_limit IS NOT NULL OR upper_spec_limit IS NOT NULL),
    CHECK (lower_spec_limit <= nominal AND nominal <= upper_spec_limit)
);

-- characteristic_pk runs 1 through 5. Weld strength (3) has a lower limit
-- only: stronger is never out of specification, so its upper limit is NULL.
INSERT INTO quality.characteristic
    (part_fk, name, nominal, lower_spec_limit, upper_spec_limit, unit) VALUES
    (8, 'Diameter',           0.6250,  0.6200,  0.6300, 'in'),
    (8, 'Length',            12.0000, 11.9500, 12.0500, 'in'),
    (5, 'Weld strength',   1800.0000, 1500.0000,  NULL,  'lbf'),
    (5, 'Coating thickness',  3.0000,  2.0000,  4.0000, 'mil'),
    (6, 'Coating thickness',  3.0000,  2.0000,  4.0000, 'mil');

CREATE TABLE quality.defect_type (
    defect_type_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    defect_code    VARCHAR(4)  NOT NULL UNIQUE,
    description    VARCHAR(40) NOT NULL
);

-- defect_type_pk runs 1 through 6. No crack (6) has ever been found.
INSERT INTO quality.defect_type (defect_code, description) VALUES
    ('SCR', 'Scratch'),
    ('POR', 'Weld porosity'),
    ('RUN', 'Paint run'),
    ('DIM', 'Out of dimension'),
    ('BUR', 'Burr'),
    ('CRK', 'Crack');

CREATE TABLE quality.inspection (
    inspection_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    part_fk       INTEGER     NOT NULL REFERENCES production.part (part_pk),
    operator_fk   INTEGER     NOT NULL REFERENCES production.operator (operator_pk),
    inspected_at  TIMESTAMP   NOT NULL,
    lot_number    VARCHAR(12) NOT NULL
);

-- inspection_pk runs 1 through 20: axles (1 to 8), hand truck frames (9 to
-- 14), and cart frames (15 to 20), each from the lots of one work order.
INSERT INTO quality.inspection (part_fk, operator_fk, inspected_at, lot_number) VALUES
    (8, 2, '2026-02-09 08:00', 'L7005-01'),
    (8, 5, '2026-02-10 08:00', 'L7005-02'),
    (8, 2, '2026-02-11 08:00', 'L7005-03'),
    (8, 5, '2026-02-12 08:00', 'L7005-04'),
    (8, 2, '2026-02-13 08:00', 'L7005-05'),
    (8, 5, '2026-02-16 08:00', 'L7005-06'),
    (8, 2, '2026-02-17 08:00', 'L7005-07'),
    (8, 5, '2026-02-18 08:00', 'L7005-08'),
    (5, 4, '2026-01-28 13:00', 'L7004-01'),
    (5, 3, '2026-01-29 13:00', 'L7004-02'),
    (5, 4, '2026-01-30 13:00', 'L7004-03'),
    (5, 3, '2026-02-02 13:00', 'L7004-04'),
    (5, 4, '2026-02-03 13:00', 'L7004-05'),
    (5, 3, '2026-02-04 13:00', 'L7004-06'),
    (6, 4, '2026-02-18 14:00', 'L7007-01'),
    (6, 3, '2026-02-19 14:00', 'L7007-02'),
    (6, 4, '2026-02-20 14:00', 'L7007-03'),
    (6, 3, '2026-02-23 14:00', 'L7007-04'),
    (6, 4, '2026-02-24 14:00', 'L7007-05'),
    (6, 3, '2026-02-25 14:00', 'L7007-06');

CREATE TABLE quality.measurement (
    measurement_pk    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inspection_fk     INTEGER       NOT NULL REFERENCES quality.inspection (inspection_pk),
    characteristic_fk INTEGER       NOT NULL REFERENCES quality.characteristic (characteristic_pk),
    measured_value    NUMERIC(10,4) NOT NULL,
    UNIQUE (inspection_fk, characteristic_fk)
);

-- The axle diameter drifts upward across its eight inspections and ends
-- above its upper limit. Linda Nguyen (operator 3) reads coating thickness
-- consistently lower than Robert Hayes (operator 4) does.
INSERT INTO quality.measurement (inspection_fk, characteristic_fk, measured_value) VALUES
    -- Axles: diameter (1) and length (2)
    ( 1, 1, 0.6241), ( 1, 2, 12.0040),
    ( 2, 1, 0.6244), ( 2, 2, 11.9980),
    ( 3, 1, 0.6248), ( 3, 2, 12.0100),
    ( 4, 1, 0.6251), ( 4, 2, 12.0010),
    ( 5, 1, 0.6257), ( 5, 2, 11.9930),
    ( 6, 1, 0.6266), ( 6, 2, 12.0060),
    ( 7, 1, 0.6279), ( 7, 2, 11.9410),
    ( 8, 1, 0.6304), ( 8, 2, 12.0020),
    -- Hand truck frames: weld strength (3) and coating thickness (4)
    ( 9, 3, 1840), ( 9, 4, 3.1),
    (10, 3, 1795), (10, 4, 2.4),
    (11, 3, 1460), (11, 4, 3.3),
    (12, 3, 1822), (12, 4, 2.3),
    (13, 3, 1868), (13, 4, 3.6),
    (14, 3, 1810), (14, 4, 1.9),
    -- Cart frames: coating thickness (5)
    (15, 5, 3.4),
    (16, 5, 2.6),
    (17, 5, 4.3),
    (18, 5, 2.5),
    (19, 5, 3.5),
    (20, 5, 2.7);

CREATE TABLE quality.defect_count (
    defect_count_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inspection_fk   INTEGER NOT NULL REFERENCES quality.inspection (inspection_pk),
    defect_type_fk  INTEGER NOT NULL REFERENCES quality.defect_type (defect_type_pk),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    UNIQUE (inspection_fk, defect_type_fk)
);

-- Paint runs (3) outnumber every other defect combined.
INSERT INTO quality.defect_count (inspection_fk, defect_type_fk, quantity) VALUES
    ( 3, 5, 1),
    ( 7, 4, 1),
    ( 8, 4, 1),
    ( 8, 5, 2),
    ( 9, 2, 1),
    (10, 3, 2),
    (11, 2, 3),
    (12, 3, 1),
    (13, 1, 1),
    (14, 3, 4),
    (16, 3, 3),
    (17, 3, 6),
    (18, 3, 2),
    (19, 1, 2),
    (20, 3, 1);
