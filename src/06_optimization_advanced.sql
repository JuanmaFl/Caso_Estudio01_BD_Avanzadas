-- ------------------------------------------------------------------
-- ARCHIVO: 06_optimization_advanced.sql
-- DESCRIPCIÓN: Técnicas avanzadas para solucionar los cuellos de botella finales.
-- ------------------------------------------------------------------

-- ==========================================
-- TÉCNICA 1: VISTA MATERIALIZADA (Para Q1)
-- ==========================================
-- Soluciona el problema de agregación masiva pre-calculando el resultado.

DROP MATERIALIZED VIEW IF EXISTS mv_sales_report;

CREATE MATERIALIZED VIEW mv_sales_report AS
SELECT 
    c.city,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_revenue
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2023-01-01'
GROUP BY c.city;

-- Índice en la vista para acceso instantáneo
CREATE INDEX idx_mv_sales_city ON mv_sales_report(city);

-- Consulta sobre la Vista Materializada
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM mv_sales_report
ORDER BY total_revenue DESC;

-- ==========================================
-- TÉCNICA 2: QUERY REWRITING - CTEs (Para Q3)
-- ==========================================
-- Soluciona el problema de I/O reduciendo el dataset antes del JOIN.


-- Q3 REESCRITA: Filtrado anticipado con CTEs
EXPLAIN (ANALYZE, BUFFERS)
WITH target_products AS (
    -- 1. Primero sacamos solo los productos de Electrónica (son pocos)
    SELECT product_id, name, category 
    FROM product 
    WHERE category = 'Electrónica'
),
target_orders AS (
    -- 2. Sacamos solo los IDs de órdenes del mes (índice rápido)
    SELECT order_id 
    FROM orders 
    WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30'
)
SELECT 
    tp.name, 
    tp.category, 
    SUM(oi.quantity) as units, 
    SUM(oi.quantity * oi.unit_price) as volume
FROM order_item oi
JOIN target_products tp ON oi.product_id = tp.product_id -- Filtra items por producto
JOIN target_orders to_rd ON oi.order_id = to_rd.order_id   -- Filtra items por fecha
GROUP BY tp.name, tp.category
ORDER BY volume DESC 
LIMIT 20;