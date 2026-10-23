-- HG Industries' orders as JSON documents in PostgreSQL (@sec-appnosql-jsonb).
-- Run against stage D5: load sql/load/through-d5.sql first. The script leaves
-- the table distribution.order_document holding the twelve orders of stage D5
-- as documents; reload stage D5 to remove it. The two changes that show what
-- goes wrong with documents run last, in a transaction that is rolled back.

-- The table: a key, and one column for the document.

CREATE TABLE distribution.order_document (
    order_number VARCHAR(10) PRIMARY KEY,
    document     JSONB NOT NULL
);

-- One document per order, built from the relational tables.

INSERT INTO distribution.order_document
SELECT o.order_number,
       jsonb_build_object(
         'order_number', o.order_number,
         'order_date', o.order_date,
         'customer', jsonb_build_object(
             'customer_number', c.customer_number,
             'name', c.name,
             'city', c.city,
             'state', c.state),
         'lines', (
             SELECT jsonb_agg(jsonb_build_object(
                        'line_number', l.line_number,
                        'product_number', p.product_number,
                        'description', p.description,
                        'quantity', l.quantity,
                        'unit_price', l.unit_price)
                      ORDER BY l.line_number)
             FROM distribution.order_line AS l
             JOIN distribution.product AS p
               ON p.product_pk = l.product_fk
             WHERE l.customer_order_fk
                   = o.customer_order_pk))
FROM distribution.customer_order AS o
JOIN distribution.customer AS c
  ON c.customer_pk = o.customer_fk;

-- January's orders, read from their documents.

SELECT order_number,
       document -> 'customer' ->> 'name' AS customer,
       jsonb_array_length(document -> 'lines') AS lines
FROM distribution.order_document
WHERE document ->> 'order_date' < '2026-02-01'
ORDER BY order_number;

-- The orders that include a GC-300.

SELECT order_number,
       document ->> 'order_date' AS order_date
FROM distribution.order_document
WHERE document @> '{"lines":
          [{"product_number": "GC-300"}]}'
ORDER BY order_number;

-- Units ordered by product, from the documents and from the tables.

SELECT line ->> 'product_number' AS product,
       SUM((line ->> 'quantity')::INTEGER) AS units
FROM distribution.order_document,
     jsonb_array_elements(document -> 'lines') AS line
GROUP BY line ->> 'product_number'
ORDER BY product;

SELECT p.product_number AS product,
       SUM(l.quantity) AS units
FROM distribution.order_line AS l
JOIN distribution.product AS p
  ON p.product_pk = l.product_fk
GROUP BY p.product_number
ORDER BY product;

-- What goes wrong: a copy left behind by a change, and a misspelled field.
-- Both are undone by the ROLLBACK at the end.
BEGIN;

UPDATE distribution.product
SET description = 'Steel utility cart'
WHERE product_number = 'GC-300';

SELECT p.description AS in_product,
       line ->> 'description' AS in_documents,
       COUNT(*) AS lines
FROM distribution.order_document AS d
CROSS JOIN jsonb_array_elements(d.document -> 'lines')
     AS line
JOIN distribution.product AS p
  ON p.product_number = line ->> 'product_number'
WHERE p.product_number = 'GC-300'
GROUP BY p.description, line ->> 'description';

INSERT INTO distribution.order_document
VALUES ('SO-5013', '{"order_number": "SO-5013",
  "order_date": "2026-03-12",
  "customer": {"customer_number": "C-1009"},
  "lines": [{"line_number": 1,
             "product_number": "GC-300",
             "qty": 5, "unit_price": 119.00}]}');

SELECT line ->> 'product_number' AS product,
       SUM((line ->> 'quantity')::INTEGER) AS units,
       COUNT(*) AS lines
FROM distribution.order_document,
     jsonb_array_elements(document -> 'lines') AS line
GROUP BY line ->> 'product_number'
ORDER BY product;

ROLLBACK;
