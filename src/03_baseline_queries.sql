-- ------------------------------------------------------------------
-- ARCHIVO: 03_baseline_queries.sql
-- DESCRIPCIÓN: Consultas originales sin optimizar para medir Línea Base.
-- USO: Ejecutar con "EXPLAIN (ANALYZE, BUFFERS)" para ver Seq Scans.
-- ------------------------------------------------------------------

-- Q1: Reporte de Ventas por Ciudad (OLAP - Agregación Masiva)
-- Problema: Scan completo de Orders y Customer. Hash Join costoso.
SELECT 
    c.city,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_revenue
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2023-01-01'
GROUP BY c.city
ORDER BY total_revenue DESC;

-- Q2: Historial de Cliente por Email (OLTP - Búsqueda Puntual)
-- Problema: Scan secuencial de 1 Millón de clientes para buscar uno solo.
SELECT 
    o.order_id, 
    o.order_date, 
    o.status, 
    o.total_amount
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
WHERE c.email = 'customer5000@example.com' 
ORDER BY o.order_date DESC
LIMIT 10;

-- Q3: Analítica de Productos (Híbrida - Joins Complejos)
-- Problema: Join de 3 tablas grandes (20M de items) sin índices.
SELECT 
    p.name as product_name,
    p.category,
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as sales_volume
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date BETWEEN '2023-06-01' AND '2023-06-30'
  AND p.category = 'Electrónica'
GROUP BY p.name, p.category
ORDER BY sales_volume DESC
LIMIT 20;