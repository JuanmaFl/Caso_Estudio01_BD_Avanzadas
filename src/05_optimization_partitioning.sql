-- ------------------------------------------------------------------
-- ARCHIVO: 05_optimization_partitioning.sql
-- DESCRIPCIÓN: Implementación de Particionamiento por Rango (Fechas).
-- OBJETIVO: Intentar optimizar Q1 (aunque la Vista Materializada fue mejor).
-- ------------------------------------------------------------------

-- 1. Crear tabla padre particionada
CREATE TABLE orders_part (
  order_id      BIGINT,
  customer_id   BIGINT NOT NULL,
  order_date    TIMESTAMPTZ NOT NULL,
  status        order_status NOT NULL,
  total_amount  NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0)
) PARTITION BY RANGE (order_date);

-- 2. Crear particiones anuales
CREATE TABLE orders_part_2019 PARTITION OF orders_part FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE orders_part_2020 PARTITION OF orders_part FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE orders_part_2021 PARTITION OF orders_part FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE orders_part_2022 PARTITION OF orders_part FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE orders_part_2023 PARTITION OF orders_part FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE orders_part_2024 PARTITION OF orders_part FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE orders_part_default PARTITION OF orders_part DEFAULT;

-- 3. Migración de datos (ADVERTENCIA: Tarda varios minutos)
-- INSERT INTO orders_part SELECT * FROM orders;

-- 4. Índices en particiones
CREATE INDEX idx_orders_part_date ON orders_part(order_date);
CREATE INDEX idx_orders_part_customer ON orders_part(customer_id);

ANALYZE orders_part;