-- ============================================================
-- Step 1: Analyse execution plans before indexing
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT ... -- copy Query 1 here (monthly sales)

-- Observe high costs: Seq Scans on large tables, expensive sorts.

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

-- Indexes for filtering (WHERE) and joining
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

CREATE INDEX idx_products_category_id ON products(category_id);

-- Composite covering index for the monthly sales query
-- It covers all columns used in JOIN, WHERE, GROUP BY, and aggregates.
-- This can be a covering index if we include the needed columns, but we need to consider.
-- Since we need SUM(quantity * unit_price * (1-discount/100)), we cannot index that expression easily.
-- But we can reduce lookups.
CREATE INDEX idx_order_items_composite ON order_items(order_id, product_id) INCLUDE (quantity, unit_price, discount);
-- Actually, INCLUDE is for covering indexes. However, PostgreSQL doesn't support INCLUDE for non-unique indexes in all versions? It does from 11.
-- Alternatively, we can create a multi-column index on order_id, product_id, quantity, unit_price, discount.
-- But better: index on (order_id, product_id) and then the other columns are in the table.
-- For this demonstration, we'll use:

CREATE INDEX idx_order_items_covering ON order_items(order_id, product_id, quantity, unit_price, discount);

-- For customer top spend, index on orders(customer_id, total_amount) can help.
CREATE INDEX idx_orders_customer_total ON orders(customer_id, total_amount) WHERE status != 'cancelled';

-- For inactive customers, we already have idx_orders_customer_id and idx_orders_order_date.
-- For product low stock, we need indexes on order_items(product_id) and orders(order_date) already created.

-- Analyze tables to update statistics
ANALYZE orders;
ANALYZE order_items;
ANALYZE products;
ANALYZE categories;
ANALYZE customers;

-- ============================================================
-- Step 3: Re‑run queries and compare plans
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT ... -- same Query 1 – now should show Index Only Scans or Index Scans with much lower cost.

-- Expected improvements:
-- Query 1: from Seq Scan on order_items (2M rows) to Index Scan using idx_order_items_covering, plus Index Scan on orders using idx_orders_order_date.
-- Query 2: uses idx_orders_customer_total to avoid sorting large result sets.
-- Query 3: uses idx_orders_customer_id and idx_orders_order_date for quick aggregation.
-- Query 4: uses idx_order_items_product_id to aggregate sales per product.

-- ============================================================
-- Step 4: Additional optimisation – partial indexes
-- ============================================================

-- For active orders only:
CREATE INDEX idx_orders_active_customer ON orders(customer_id) WHERE status != 'cancelled';

-- For low stock query, we might create a materialized view if needed.
