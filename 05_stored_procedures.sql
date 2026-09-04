-- ============================================================
-- Stored Procedure 1: Generate Monthly Sales Report
-- ============================================================
CREATE OR REPLACE FUNCTION generate_monthly_sales_report(p_month DATE)
RETURNS TABLE(
    category_name TEXT,
    total_sales NUMERIC,
    order_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name::TEXT,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100))::NUMERIC,
        COUNT(DISTINCT o.order_id)::BIGINT
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', p_month)
      AND o.status != 'cancelled'
    GROUP BY c.name
    ORDER BY total_sales DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM generate_monthly_sales_report('2025-01-01');

-- ============================================================
-- Stored Procedure 2: Validate Order Data
--   Checks if each order's total_amount matches the sum of its items.
--   Returns rows where mismatch exists.
-- ============================================================
CREATE OR REPLACE FUNCTION validate_order_data(p_order_id INT DEFAULT NULL)
RETURNS TABLE(
    order_id INT,
    computed_total NUMERIC,
    stored_total NUMERIC,
    difference NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.order_id,
        COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 0) AS computed,
        o.total_amount AS stored,
        COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 0) - o.total_amount AS diff
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE (p_order_id IS NULL OR o.order_id = p_order_id)
    GROUP BY o.order_id, o.total_amount
    HAVING ABS(COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)), 0) - o.total_amount) > 0.01;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM validate_order_data();  -- all orders
-- SELECT * FROM validate_order_data(12345); -- specific order

-- ============================================================
-- Stored Procedure 3: Automated Refresh of Low Stock Alert (could be a materialized view)
-- ============================================================
-- Not necessary for this demo, but we can create a function to email/alert if needed.
