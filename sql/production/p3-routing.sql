-- HG Industries, production schema, stage P3: work centers and their
-- machines, the operators certified on the machines, each manufactured
-- part's routing (its operations, numbered within the part), and work
-- orders.
--
-- Requires: stage P2, loaded into a freshly reset database.
-- Load everything through this stage in one step: ../load/through-p3.sql

CREATE TABLE production.work_center (
    work_center_pk   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    work_center_code VARCHAR(6)    NOT NULL UNIQUE,
    name             VARCHAR(40)   NOT NULL,
    hourly_rate      NUMERIC(8,2)  NOT NULL CHECK (hourly_rate > 0)
);

-- work_center_pk runs 1 through 5. Assembly (5) has no machines.
INSERT INTO production.work_center (work_center_code, name, hourly_rate) VALUES
    ('SAW', 'Saw',        42.00),
    ('MCH', 'Machining',  68.00),
    ('WLD', 'Welding',    55.00),
    ('PNT', 'Paint',      48.00),
    ('ASM', 'Assembly',   38.00);

CREATE TABLE production.machine (
    machine_pk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    machine_number VARCHAR(10) NOT NULL UNIQUE,
    model          VARCHAR(40) NOT NULL,
    installed_on   DATE        NOT NULL,
    work_center_fk INTEGER     NOT NULL REFERENCES production.work_center (work_center_pk)
);

-- machine_pk runs 1 through 7. No one is certified yet on the robotic
-- welder (7), installed in January 2026.
INSERT INTO production.machine (machine_number, model, installed_on, work_center_fk) VALUES
    ('M-01', 'Band saw BS-20',          '2018-04-10', 1),
    ('M-02', 'CNC lathe TL-8',          '2020-09-15', 2),
    ('M-03', 'Drill press DP-15',       '2016-02-01', 2),
    ('M-04', 'MIG welder MW-250',       '2019-06-20', 3),
    ('M-05', 'MIG welder MW-250',       '2021-03-08', 3),
    ('M-06', 'Powder coat booth PB-12', '2017-11-30', 4),
    ('M-07', 'Robotic welder RW-6',     '2026-01-12', 3);

CREATE TABLE production.operator (
    operator_pk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_number VARCHAR(10) NOT NULL UNIQUE,
    name            VARCHAR(60) NOT NULL,
    hire_date       DATE        NOT NULL
);

-- operator_pk runs 1 through 6. Tom Becker (6), hired in January 2026, has no
-- certification yet.
INSERT INTO production.operator (employee_number, name, hire_date) VALUES
    ('E-201', 'Maria Lopez',   '2014-03-17'),
    ('E-202', 'James Carter',  '2016-08-01'),
    ('E-203', 'Linda Nguyen',  '2018-05-21'),
    ('E-204', 'Robert Hayes',  '2019-10-07'),
    ('E-205', 'Aisha Patel',   '2022-02-14'),
    ('E-206', 'Tom Becker',    '2026-01-05');

CREATE TABLE production.certification (
    certification_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operator_fk      INTEGER NOT NULL REFERENCES production.operator (operator_pk),
    machine_fk       INTEGER NOT NULL REFERENCES production.machine (machine_pk),
    certified_on     DATE    NOT NULL,
    level            INTEGER NOT NULL CHECK (level BETWEEN 1 AND 3),
    UNIQUE (operator_fk, machine_fk)
);

INSERT INTO production.certification (operator_fk, machine_fk, certified_on, level) VALUES
    (1, 1, '2014-05-01', 3),
    (1, 4, '2015-02-10', 2),
    (2, 2, '2020-10-01', 3),
    (2, 3, '2016-09-15', 2),
    (3, 4, '2018-07-01', 3),
    (3, 5, '2021-04-01', 3),
    (3, 6, '2019-01-15', 2),
    (4, 1, '2020-01-10', 2),
    (4, 6, '2020-03-02', 3),
    (5, 5, '2022-05-01', 1);

-- An operation is identified by its part and its operation number, which is
-- a key of the table (the UNIQUE constraint) as well as the surrogate key.
CREATE TABLE production.operation (
    operation_pk          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- an operation is composed in its part's routing (@sec-mapping): deleting the whole deletes it
    manufactured_part_fk  INTEGER      NOT NULL REFERENCES production.manufactured_part (part_fk)
                                                ON DELETE CASCADE,
    operation_number      INTEGER      NOT NULL CHECK (operation_number > 0),
    description           VARCHAR(40)  NOT NULL,
    setup_minutes         NUMERIC(6,1) NOT NULL CHECK (setup_minutes >= 0),
    run_minutes_per_unit  NUMERIC(6,2) NOT NULL CHECK (run_minutes_per_unit > 0),
    work_center_fk        INTEGER      NOT NULL REFERENCES production.work_center (work_center_pk),
    UNIQUE (manufactured_part_fk, operation_number)
);

INSERT INTO production.operation
    (manufactured_part_fk, operation_number, description, setup_minutes, run_minutes_per_unit, work_center_fk) VALUES
    -- FR-110 hand truck frame
    (5, 10, 'Cut tubing',     15, 2.50, 1),
    (5, 20, 'Weld frame',     20, 6.00, 3),
    (5, 30, 'Powder coat',    30, 3.00, 4),
    -- CF-310 cart frame
    (6, 10, 'Cut tubing',     15, 2.00, 1),
    (6, 20, 'Weld frame',     20, 5.00, 3),
    (6, 30, 'Powder coat',    30, 2.50, 4),
    -- AX-10 axle
    (8, 10, 'Cut bar stock',  10, 0.50, 1),
    (8, 20, 'Turn and drill', 45, 1.50, 2),
    -- WA-10 wheel assembly
    (7, 10, 'Assemble wheel', 10, 2.00, 5),
    -- The four products
    (1, 10, 'Final assembly', 15, 8.00, 5),
    (2, 10, 'Final assembly', 15, 10.00, 5),
    (3, 10, 'Final assembly', 15, 9.00, 5),
    (4, 10, 'Final assembly', 15, 9.00, 5);

CREATE TABLE production.work_order (
    work_order_pk        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    work_order_number    VARCHAR(10) NOT NULL UNIQUE,
    manufactured_part_fk INTEGER     NOT NULL REFERENCES production.manufactured_part (part_fk),
    quantity             INTEGER     NOT NULL CHECK (quantity > 0),
    released_on          DATE        NOT NULL,
    due_on               DATE        NOT NULL,
    completed_on         DATE,
    CHECK (due_on >= released_on),
    CHECK (completed_on >= released_on)
);

-- Three work orders are still open (completed_on is NULL), and two finished
-- after their due dates (WO-7003 and WO-7006).
INSERT INTO production.work_order
    (work_order_number, manufactured_part_fk, quantity, released_on, due_on, completed_on) VALUES
    ('WO-7001', 1,  50, '2026-01-05', '2026-01-16', '2026-01-15'),
    ('WO-7002', 7, 200, '2026-01-06', '2026-01-13', '2026-01-12'),
    ('WO-7003', 3,  40, '2026-01-19', '2026-01-30', '2026-02-02'),
    ('WO-7004', 5, 100, '2026-01-26', '2026-02-06', '2026-02-05'),
    ('WO-7005', 8, 400, '2026-02-02', '2026-02-09', '2026-02-09'),
    ('WO-7006', 2,  25, '2026-02-09', '2026-02-20', '2026-02-24'),
    ('WO-7007', 6,  80, '2026-02-16', '2026-02-27', '2026-02-26'),
    ('WO-7008', 1,  50, '2026-03-02', '2026-03-13', NULL),
    ('WO-7009', 7, 200, '2026-03-09', '2026-03-16', NULL),
    ('WO-7010', 4,  20, '2026-03-16', '2026-03-27', NULL);
