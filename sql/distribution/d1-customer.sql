-- HG Industries, distribution schema, stage D1: the customer table.
--
-- Requires: nothing. Run ../reset.sql first to start over.
-- Load everything through this stage in one step: ../load/through-d1.sql

CREATE SCHEMA distribution;

CREATE TABLE distribution.customer (
    customer_pk     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(10) NOT NULL UNIQUE,
    name            VARCHAR(60) NOT NULL,
    city            VARCHAR(40) NOT NULL,
    state           CHAR(2)     NOT NULL
);

-- The rows are inserted in this order, so customer_pk runs 1 through 8.
INSERT INTO distribution.customer (customer_number, name, city, state) VALUES
    ('C-1001', 'Riverside Hardware',       'Fayetteville', 'AR'),
    ('C-1002', 'Summit Farm Supply',       'Springdale',   'AR'),
    ('C-1003', 'Cedar Creek Home Center',  'Tulsa',        'OK'),
    ('C-1004', 'Midtown Tool Supply',      'Joplin',       'MO'),
    ('C-1005', 'Prairie Garden Center',    'Fort Smith',   'AR'),
    ('C-1006', 'Lakeside Distributors',    'Springfield',  'MO'),
    ('C-1007', 'Tri-County Farm and Home', 'Bentonville',  'AR'),
    ('C-1008', 'Northgate Hardware',       'Little Rock',  'AR');
