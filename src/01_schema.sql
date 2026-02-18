-- ------------------------------------------------------------------
-- ARCHIVO: 01_schema.sql
-- DESCRIPCIÓN: Estructura DDL inicial para EafitShop (OLTP).
-- AUTOR: Equipo EafitShop
-- ------------------------------------------------------------------

-- 1. Limpieza de entorno (Drop Tables si existen)
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS order_item CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS customer CASCADE;

-- 2. Limpieza de tipos ENUM
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN DROP TYPE order_status; END IF;
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN DROP TYPE payment_method; END IF;
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN DROP TYPE payment_status; END IF;
END$$;

-- 3. Creación de Tipos
CREATE TYPE order_status AS ENUM ('CREATED','PAID','SHIPPED','COMPLETED','CANCELLED');
CREATE TYPE payment_method AS ENUM ('CARD','CASH','TRANSFER','QR','WALLET','PSE','CASH_ON_DELIVERY');
CREATE TYPE payment_status AS ENUM ('PENDING','APPROVED','REJECTED','REFUNDED');

-- 4. Creación de Tablas
CREATE TABLE customer (
  customer_id BIGINT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  city VARCHAR(50),
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE product (
  product_id BIGINT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
  order_id BIGINT PRIMARY KEY,
  customer_id BIGINT REFERENCES customer(customer_id),
  order_date TIMESTAMPTZ DEFAULT now(),
  status order_status DEFAULT 'CREATED',
  total_amount NUMERIC(12,2) DEFAULT 0
);

CREATE TABLE order_item (
  order_item_id BIGINT PRIMARY KEY,
  order_id BIGINT REFERENCES orders(order_id),
  product_id BIGINT REFERENCES product(product_id),
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL
);

CREATE TABLE payment (
  payment_id BIGINT PRIMARY KEY,
  order_id BIGINT REFERENCES orders(order_id),
  payment_date TIMESTAMPTZ DEFAULT now(),
  payment_method payment_method,
  payment_status payment_status
);