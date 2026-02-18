-- ------------------------------------------------------------------
-- ARCHIVO: 02_generate_data.sql
-- DESCRIPCIÓN: Generación de Datos Sintéticos (Big Data).
-- VOLUMEN: ~5 Millones de órdenes.
-- NOTA: Puede tardar 3-5 minutos en Docker local.
-- ------------------------------------------------------------------

-- Limpiar tablas antes de cargar
TRUNCATE TABLE payment, order_item, orders, product, customer RESTART IDENTITY CASCADE;

-- 1. Customers (1 Millón)
INSERT INTO customer (customer_id, name, email, city, created_at)
SELECT
  gs AS customer_id,
  'Customer ' || gs,
  'customer' || gs || '@example.com',
  (ARRAY['Medellín','Bogotá','Cali','Barranquilla','Bucaramanga','Cartagena','Manizales','Pereira','Santa Marta','Ibagué'])[1 + (random()*9)::int],
  now() - (random() * interval '8 years')
FROM generate_series(1, 1000000) gs;

-- 2. Products (100,000)
INSERT INTO product (product_id, name, category, price)
SELECT
  gs AS product_id,
  'Product ' || gs,
  (ARRAY['Electrónica','Hogar','Deportes','Libros','Moda','Juguetes','Salud','Alimentos','Automotor','Ferretería'])[1 + (random()*9)::int],
  round((random()*990 + 10)::numeric, 2)
FROM generate_series(1, 100000) gs;

-- 3. Orders (5 Millones)
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount)
SELECT
  gs AS order_id,
  1 + (random()*999999)::bigint AS customer_id,
  now() - (random() * interval '5 years') AS order_date,
  (ARRAY['CREATED','PAID','SHIPPED','COMPLETED','CANCELLED'])[1 + (random()*4)::int]::order_status,
  round((random()*800 + 10)::numeric, 2)
FROM generate_series(1, 5000000) gs;

-- 4. Order Items (20 Millones - 4 items por orden)
INSERT INTO order_item (order_item_id, order_id, product_id, quantity, unit_price)
SELECT
  gs AS order_item_id,
  1 + ((gs-1) / 4)::bigint AS order_id,
  1 + (random()*99999)::bigint AS product_id,
  1 + (random()*4)::int AS quantity,
  round((random()*400 + 5)::numeric, 2) AS unit_price
FROM generate_series(1, 20000000) gs;

-- 5. Payments (4 Millones - 80% de órdenes)
INSERT INTO payment (payment_id, order_id, payment_date, payment_method, payment_status)
SELECT
  gs AS payment_id,
  gs AS order_id,
  (SELECT order_date FROM orders o WHERE o.order_id = gs) + (random() * interval '3 hours'),
  (ARRAY['CARD','PSE','CASH_ON_DELIVERY','TRANSFER','WALLET'])[1 + (random()*4)::int]::payment_method,
  (ARRAY['APPROVED','REJECTED','PENDING'])[1 + (random()*2)::int]::payment_status
FROM generate_series(1, 4000000) gs;

-- Actualizar estadísticas del motor
ANALYZE;