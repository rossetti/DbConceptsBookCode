-- HG Industries, sales schema, stage S: a star schema for analyzing sales,
-- built from the operational schemas. One fact table, order_line_fact, at the
-- grain of one row per order line, surrounded by three dimensions: date_dim,
-- customer_dim, and product_dim.
--
-- This script is an extract, transform, and load (ETL) process written in
-- SQL: it reads distribution and production (extract), derives attributes
-- the operational tables do not carry, such as a customer's sales region and
-- a product's product line (transform), and inserts the results, replacing
-- each business identifier with the dimension's surrogate key (load).
--
-- Requires: stage G (the year of history), loaded into a freshly reset
-- database. It also runs after any stage from P1 on, over less data.
-- Load everything through this stage in one step: ../load/through-s.sql

CREATE SCHEMA sales;

-- The date dimension: one row for every day of 2026 and 2027, whether or not
-- anything was ordered that day. Its columns are the ways a date is grouped.
-- "year", "month", and "day" are reserved words in the SQL standard, hence
-- calendar_year and calendar_month.
CREATE TABLE sales.date_dim (
    date_dim_pk      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_date        DATE        NOT NULL UNIQUE,
    calendar_year    INTEGER     NOT NULL,
    calendar_quarter INTEGER     NOT NULL CHECK (calendar_quarter BETWEEN 1 AND 4),
    calendar_month   INTEGER     NOT NULL CHECK (calendar_month BETWEEN 1 AND 12),
    month_name       VARCHAR(9)  NOT NULL,
    day_of_month     INTEGER     NOT NULL,
    day_of_week      INTEGER     NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    day_name         VARCHAR(9)  NOT NULL,
    is_weekend       BOOLEAN     NOT NULL
);

-- day_of_week follows ISO 8601: Monday is 1 and Sunday is 7. The FM prefix
-- stops TO_CHAR padding month and day names with trailing spaces.
INSERT INTO sales.date_dim
    (full_date, calendar_year, calendar_quarter, calendar_month, month_name,
     day_of_month, day_of_week, day_name, is_weekend)
SELECT d::DATE,
       EXTRACT(YEAR FROM d)::INTEGER,
       EXTRACT(QUARTER FROM d)::INTEGER,
       EXTRACT(MONTH FROM d)::INTEGER,
       TO_CHAR(d, 'FMMonth'),
       EXTRACT(DAY FROM d)::INTEGER,
       EXTRACT(ISODOW FROM d)::INTEGER,
       TO_CHAR(d, 'FMDay'),
       EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series(DATE '2026-01-01', DATE '2027-12-31', INTERVAL '1 day') AS d
ORDER BY d;

-- The customer dimension. The sales region is derived: customers in
-- Oklahoma, Kansas, and Texas are served from the Tulsa warehouse, all others
-- from Fayetteville.
CREATE TABLE sales.customer_dim (
    customer_dim_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(10) NOT NULL UNIQUE,
    name            VARCHAR(60) NOT NULL,
    city            VARCHAR(40) NOT NULL,
    state           CHAR(2)     NOT NULL,
    sales_region    VARCHAR(20) NOT NULL
);

INSERT INTO sales.customer_dim (customer_number, name, city, state, sales_region)
SELECT c.customer_number, c.name, c.city, c.state,
       CASE WHEN c.state IN ('OK', 'KS', 'TX') THEN 'Tulsa region'
            ELSE 'Fayetteville region' END
FROM distribution.customer c
ORDER BY c.customer_number;

-- The product dimension. The product line is derived from the product
-- number, and the standard cost comes from production, through the
-- manufactured part each product is.
CREATE TABLE sales.product_dim (
    product_dim_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_number VARCHAR(10)   NOT NULL UNIQUE,
    description    VARCHAR(60)   NOT NULL,
    product_line   VARCHAR(20)   NOT NULL,
    list_price     NUMERIC(10,2) NOT NULL,
    standard_cost  NUMERIC(10,2) NOT NULL
);

INSERT INTO sales.product_dim
    (product_number, description, product_line, list_price, standard_cost)
SELECT p.product_number, p.description,
       CASE WHEN p.product_number LIKE 'HT-%' THEN 'Hand trucks'
            ELSE 'Garden carts' END,
       p.list_price, pt.standard_cost
FROM distribution.product p
JOIN production.part pt ON pt.part_pk = p.manufactured_part_fk
ORDER BY p.product_number;

-- The fact table: one row per order line. The order and line numbers are
-- kept as degenerate dimensions (identifiers with no dimension table of
-- their own). The measures are additive, so they can be summed across any
-- dimension: the quantity, the amount charged, the discount from list price,
-- and the standard cost of the goods.
CREATE TABLE sales.order_line_fact (
    order_line_fact_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_date_fk      INTEGER       NOT NULL REFERENCES sales.date_dim (date_dim_pk),
    customer_dim_fk    INTEGER       NOT NULL REFERENCES sales.customer_dim (customer_dim_pk),
    product_dim_fk     INTEGER       NOT NULL REFERENCES sales.product_dim (product_dim_pk),
    order_number       VARCHAR(10)   NOT NULL,
    line_number        INTEGER       NOT NULL,
    quantity           INTEGER       NOT NULL,
    sales_amount       NUMERIC(12,2) NOT NULL,
    discount_amount    NUMERIC(12,2) NOT NULL,
    cost_amount        NUMERIC(12,2) NOT NULL,
    UNIQUE (order_number, line_number)
);

-- Each operational row's business identifiers (the order date, the customer
-- number, the product number) are looked up in the dimensions to find the
-- surrogate keys the fact table stores.
INSERT INTO sales.order_line_fact
    (order_date_fk, customer_dim_fk, product_dim_fk, order_number, line_number,
     quantity, sales_amount, discount_amount, cost_amount)
SELECT dd.date_dim_pk, cd.customer_dim_pk, pd.product_dim_pk,
       o.order_number, l.line_number,
       l.quantity,
       l.quantity * l.unit_price,
       l.quantity * (pd.list_price - l.unit_price),
       l.quantity * pd.standard_cost
FROM distribution.order_line l
JOIN distribution.customer_order o ON o.customer_order_pk = l.customer_order_fk
JOIN distribution.customer c ON c.customer_pk = o.customer_fk
JOIN distribution.product p ON p.product_pk = l.product_fk
JOIN sales.date_dim dd ON dd.full_date = o.order_date
JOIN sales.customer_dim cd ON cd.customer_number = c.customer_number
JOIN sales.product_dim pd ON pd.product_number = p.product_number
ORDER BY o.order_number, l.line_number;
