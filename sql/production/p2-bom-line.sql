-- HG Industries, production schema, stage P2: the bom_line table, the bill
-- of materials. An assembly (a manufactured part) is made of components
-- (any parts), and a component may itself be an assembly.
--
-- Requires: stage P1, loaded into a freshly reset database.
-- Load everything through this stage in one step: ../load/through-p2.sql

CREATE TABLE production.bom_line (
    bom_line_pk  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assembly_fk  INTEGER      NOT NULL REFERENCES production.manufactured_part (part_fk),
    component_fk INTEGER      NOT NULL REFERENCES production.part (part_pk),
    quantity_per NUMERIC(8,3) NOT NULL CHECK (quantity_per > 0),
    UNIQUE (assembly_fk, component_fk),
    CHECK (assembly_fk <> component_fk)
);

-- The wheel assembly (7, WA-10) is used in all four products. The deepest
-- path runs HT-100 (1) to WA-10 (7) to AX-10 (8) to BS-075 (10).
INSERT INTO production.bom_line (assembly_fk, component_fk, quantity_per) VALUES
    -- HT-100 two-wheel hand truck
    (1,  5,  1), (1,  7,  2), (1, 16,  2), (1, 17,  1),
    -- HT-200 convertible hand truck
    (2,  5,  1), (2,  7,  2), (2, 18,  2), (2, 17,  1),
    -- GC-300 steel garden cart
    (3,  6,  1), (3, 14,  1), (3,  7,  2), (3, 17,  1),
    -- GC-400 poly garden cart
    (4,  6,  1), (4, 15,  1), (4,  7,  2), (4, 17,  1),
    -- FR-110 hand truck frame and CF-310 cart frame, from tubing (feet)
    (5,  9, 14),
    (6,  9, 10),
    -- WA-10 wheel assembly
    (7, 11,  1), (7, 12,  1), (7,  8,  1), (7, 13,  2),
    -- AX-10 axle, from bar stock (feet)
    (8, 10,  1.25);
