-- ------------------------------------------------------------------
-- ARCHIVO: 04_optimization_indexes.sql
-- DESCRIPCIÓN: Creación de índices B-Tree para optimizar Joins y Filtros.
-- IMPACTO PRINCIPAL: Soluciona Q2 y mejora Q3.
-- ------------------------------------------------------------------

-- 1. Índices para Foreign Keys (Vital para reducir costo de JOINS)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_item_order_id ON order_item(order_id);
CREATE INDEX idx_order_item_product_id ON order_item(product_id);

-- 2. Índices para columnas de filtrado (WHERE)
CREATE INDEX idx_customer_email ON customer(email); -- Para Q2
CREATE INDEX idx_product_category ON product(category); -- Para Q3
CREATE INDEX idx_orders_order_date ON orders(order_date); -- Para Q1 y Q3

-- 3. Índice Cubridor (Covering Index) para Q3
-- Permite "Index Only Scan" evitando ir a la tabla principal.
CREATE INDEX idx_order_item_covering 
ON order_item(product_id, order_id) 
INCLUDE (quantity, unit_price);

-- Actualizar estadísticas
ANALYZE;