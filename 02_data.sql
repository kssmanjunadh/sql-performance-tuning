-- Populate categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Gadgets, computers, phones'),
('Clothing', 'Apparel and accessories'),
('Home & Kitchen', 'Furniture, cookware, decor'),
('Books', 'Printed and digital books'),
('Toys', 'Games and children''s toys');

-- Populate products (500 random products)
INSERT INTO products (name, description, price, stock_quantity, category_id)
SELECT
    'Product ' || g,
    'Description for product ' || g,
    round((random() * 100 + 1)::numeric, 2),
    floor(random() * 200 + 1)::int,
    floor(random() * 5 + 1)::int
FROM generate_series(1, 500) AS g;

-- Populate customers (50k)
INSERT INTO customers (first_name, last_name, email, registration_date, phone, address)
SELECT
    'FirstName' || g,
    'LastName' || g,
    'user' || g || '@example.com',
    CURRENT_DATE - (random() * 3650)::int,
    '555-' || lpad((random() * 10000)::int::text, 4, '0'),
    'Address ' || g || ', City'
FROM generate_series(1, 50000) AS g;

-- Populate orders (100k)
INSERT INTO orders (customer_id, order_date, total_amount, status)
SELECT
    floor(random() * 50000 + 1)::int,
    CURRENT_DATE - (random() * 730)::int,
    0, -- will be updated later based on order items
    (ARRAY['pending','paid','shipped','delivered','cancelled'])[floor(random()*5+1)]
FROM generate_series(1, 100000) AS g;

-- Populate order_items (approx 200k) – each order has 1‑5 items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
SELECT
    o.order_id,
    floor(random() * 500 + 1)::int,
    floor(random() * 5 + 1)::int,
    p.price,
    round((random() * 15)::numeric, 2)
FROM orders o
CROSS JOIN LATERAL (
    SELECT price FROM products WHERE product_id = floor(random() * 500 + 1)::int LIMIT 1
) p
WHERE random() < 0.2  -- generates ~20 items per order on average, giving ~2M rows – but we want ~200k, so adjust.
-- Actually, to get ~200k rows with 100k orders, average 2 items per order.
-- The above would give ~2M if we used random < 1. So we'll use a different approach.

-- Better approach: for each order, generate 1‑3 items using generate_series.
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
SELECT
    o.order_id,
    floor(random() * 500 + 1)::int,
    floor(random() * 5 + 1)::int,
    p.price,
    round((random() * 15)::numeric, 2)
FROM orders o
CROSS JOIN LATERAL generate_series(1, (random() * 2 + 1)::int) AS g
CROSS JOIN LATERAL (
    SELECT price FROM products WHERE product_id = floor(random() * 500 + 1)::int LIMIT 1
) p;

-- Now update orders.total_amount to sum of its items' (quantity * unit_price * (1 - discount/100))
UPDATE orders o
SET total_amount = (
    SELECT COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 0)
    FROM order_items oi
    WHERE oi.order_id = o.order_id
);
