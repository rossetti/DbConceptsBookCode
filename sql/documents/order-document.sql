-- Order SO-5001 of stage D5 as one JSON document: the order, a copy of its
-- customer, and its lines, each with a copy of its product's number and
-- description (@sec-rm-other-models). Run against stage D5 or later.
SELECT json_build_object(
         'order_number', o.order_number,
         'order_date', o.order_date,
         'customer', json_build_object(
             'customer_number', c.customer_number,
             'name', c.name,
             'city', c.city,
             'state', c.state),
         'lines', (
             SELECT json_agg(json_build_object(
                        'line_number', l.line_number,
                        'product_number', p.product_number,
                        'description', p.description,
                        'quantity', l.quantity,
                        'unit_price', l.unit_price)
                      ORDER BY l.line_number)
             FROM distribution.order_line AS l
             JOIN distribution.product AS p
               ON p.product_pk = l.product_fk
             WHERE l.customer_order_fk = o.customer_order_pk))
FROM distribution.customer_order AS o
JOIN distribution.customer AS c
  ON c.customer_pk = o.customer_fk
WHERE o.order_number = 'SO-5001';
