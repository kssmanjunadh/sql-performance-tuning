-- ============================================================
-- Complex Analytical Queries (before indexing)
-- ============================================================

-- Enable timing
\timing on

-- 1. Monthly sales by category for the last year
--    Returns: year, month, category name, total sales amount
SELECT
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    c.name AS category,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)) AS total_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
  AND o.status != 'cancelled'
GROUP BY year, month, c.name
ORDER BY year, month, total_sales DESC;

-- 2. Top 10 customers by total spend
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status != 'cancelled'
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- 3. Customers who have not placed an order in the last 6 months (inactive)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months'
    OR MAX(o.order_date) IS NULL;

-- 4. Products with low stock relative to total quantity sold (stock < 10 * average monthly sales)
WITH product_sales AS (
    SELECT
        p.product_id,
        p.name,
        p.stock_quantity,
        COALESCE(SUM(oi.quantity), 0) AS total_sold,
        COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) AS months_active
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status != 'cancelled'
    GROUP BY p.product_id, p.name, p.stock_quantity
)
SELECT
    product_id,
    name,
    stock_quantity,
    total_sold,
    CASE WHEN months_active = 0 THEN 0 ELSE total_sold / months_active END AS avg_monthly_sales
FROM product_sales
WHERE stock_quantity < 10 * COALESCE(total_sold / NULLIF(months_active, 0), 0)
ORDER BY avg_monthly_sales DESC;
