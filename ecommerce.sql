SET FOREIGN_KEY_CHECKS = 0;

-- 1) Create database
CREATE DATABASE IF NOT EXISTS ecommerce_db
CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;
USE ecommerce_db;

SET FOREIGN_KEY_CHECKS = 1;

-- 2) Core tables

-- roles: simple role table (optional RBAC)
CREATE TABLE IF NOT EXISTS roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL, -- store password hash, not plain text
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(30),
  is_active TINYINT NOT NULL DEFAULT 1, -- FIXED: removed display width
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_roles: many-to-many between users and roles
CREATE TABLE IF NOT EXISTS user_roles (
  user_id BIGINT NOT NULL,
  role_id INT NOT NULL,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_userroles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_userroles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- addresses: one user -> many addresses
CREATE TABLE IF NOT EXISTS addresses (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  label VARCHAR(100), -- e.g., Home, Office
  street VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) DEFAULT 'Kenya',
  is_default TINYINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_address_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- categories: product categories, supports hierarchy (parent_id)
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  slug VARCHAR(150) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- products: product master
CREATE TABLE IF NOT EXISTS products (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  short_description VARCHAR(512),
  description TEXT,
  price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  compare_at_price DECIMAL(12,2) DEFAULT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KES',
  weight_kg DECIMAL(8,3) DEFAULT NULL,
  attributes JSON DEFAULT NULL, -- flexible attributes (color, size, etc.)
  is_active TINYINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- product_images: multiple images per product
CREATE TABLE IF NOT EXISTS product_images (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT NOT NULL,
  url VARCHAR(1024) NOT NULL,
  alt_text VARCHAR(255),
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_prodimg_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- product_categories: many-to-many product <-> category
CREATE TABLE IF NOT EXISTS product_categories (
  product_id BIGINT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  CONSTRAINT fk_prodcat_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_prodcat_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- inventory: simple stock record per product (single location)
CREATE TABLE IF NOT EXISTS inventory (
  product_id BIGINT PRIMARY KEY,
  quantity INT NOT NULL DEFAULT 0,
  reserved INT NOT NULL DEFAULT 0,
  min_stock_level INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- coupons (optional)
CREATE TABLE IF NOT EXISTS coupons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  discount_percent DECIMAL(5,2) DEFAULT NULL, -- e.g., 10.00 for 10%
  discount_amount DECIMAL(12,2) DEFAULT NULL, -- fixed amount discount
  valid_from DATE,
  valid_until DATE,
  is_active TINYINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- orders: order header
CREATE TABLE IF NOT EXISTS orders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, paid, shipped, cancelled, refunded
  coupon_id INT NULL,
  shipping_address_id BIGINT NULL,
  billing_address_id BIGINT NULL,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  shipping_cost DECIMAL(12,2) DEFAULT 0.00,
  tax_amount DECIMAL(12,2) DEFAULT 0.00,
  discount_amount DECIMAL(12,2) DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_order_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_order_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL,
  CONSTRAINT fk_order_shipping_addr FOREIGN KEY (shipping_address_id) REFERENCES addresses(id) ON DELETE SET NULL,
  CONSTRAINT fk_order_billing_addr FOREIGN KEY (billing_address_id) REFERENCES addresses(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- order_items: items (use a surrogate line id for allowing duplicate products in an order)
CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  sku VARCHAR(100) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  line_total DECIMAL(12,2) AS (unit_price * quantity) STORED,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_orderitems_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- payments: payment records for orders
CREATE TABLE IF NOT EXISTS payments (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  provider VARCHAR(100) NOT NULL, -- e.g., Stripe, PayPal
  provider_payment_id VARCHAR(255),
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KES',
  status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, succeeded, failed, refunded
  paid_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- reviews: product reviews by users
CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  body TEXT,
  is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 3) Useful Indexes (beyond primary keys)

CREATE INDEX idx_products_name ON products (name);
CREATE INDEX idx_products_price ON products (price);
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_order_number ON orders (order_number);

-- 4) Sample data (minimal) - for testing

-- Roles
INSERT INTO roles (name, description) VALUES
('customer', 'Standard customer role'),
('admin', 'Administrator with elevated privileges');

-- Users (password_hash are placeholders; in production use salted bcrypt/etc.)
INSERT INTO users (email, password_hash, first_name, last_name, phone) VALUES
('alice@example.com', '$2b$12$EXAMPLEHASH', 'Alice', 'Adams', '+254700000001'),
('bob@example.com', '$2b$12$EXAMPLEHASH', 'Bob', 'Brown', '+254700000002');

-- Assign role: Alice = customer, Bob = admin
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'customer' WHERE u.email = 'alice@example.com';
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r ON r.name = 'admin' WHERE u.email = 'bob@example.com';

-- Categories
INSERT INTO categories (name, slug, description) VALUES
('Home Cleaning', 'home-cleaning', 'Cleaning services & home products'),
('Office Cleaning', 'office-cleaning', 'Office cleaning products'),
('Supplies', 'supplies', 'Cleaning supplies & products');

-- Products (sample)
INSERT INTO products (sku, name, short_description, price, currency, attributes) VALUES
('SKU-001', 'All-Purpose Cleaner', 'Multi-surface cleaning liquid', 5.99, 'KES', JSON_OBJECT('size','1L','fragile',false)),
('SKU-002', 'Premium Microfiber Cloth', 'Lint-free cleaning cloth', 2.50, 'KES', JSON_OBJECT('size','30x30cm','color','blue')),
('SKU-003', 'Vacuum Cleaner Pro', 'Compact vacuum for home', 120.00, 'KES', JSON_OBJECT('wattage','1200W','color','red'));

-- Product images (sample placeholder URLs)
INSERT INTO product_images (product_id, url, alt_text, sort_order) VALUES
(1, '"C:\Users\user\Desktop\ASSIGNMENT\Week-8-Assignment-Final-Project\All-purpose cleaner.png"', 'All-purpose cleaner bottle', 0),
(2, '"C:\Users\user\Desktop\ASSIGNMENT\Week-8-Assignment-Final-Project\Microfiber cloth.png"', 'Microfiber cloth', 0),
(3, '"C:\Users\user\Desktop\ASSIGNMENT\Week-8-Assignment-Final-Project\Vacuum cleaner.png"', 'Vacuum Cleaner Pro', 0);

-- Link products to categories
INSERT INTO product_categories (product_id, category_id) VALUES
(1, 3), -- cleaner -> supplies
(2, 3), -- cloth -> supplies
(3, 1); -- vacuum -> home cleaning

-- Inventory
INSERT INTO inventory (product_id, quantity, reserved, min_stock_level) VALUES
(1, 150, 0, 10),
(2, 300, 0, 20),
(3, 25, 0, 1);

-- Addresses
INSERT INTO addresses (user_id, label, street, city, state, postal_code, country, is_default)
VALUES
(1, 'Home', '1 Koinange St', 'Nairobi', 'Nairobi County', '00100', 'Kenya', 1),
(2, 'Office', '2 Kimathi St', 'Nairobi', 'Nairobi County', '00100', 'Kenya', 1);

-- Orders (sample)
INSERT INTO orders (user_id, order_number, status, subtotal, shipping_cost, tax_amount, discount_amount, total_amount, shipping_address_id, billing_address_id)
VALUES
(1, 'ORD-2025-0001', 'pending', 10.49, 1.50, 0.00, 0.00, 11.99, 1, 1);

-- Order items
INSERT INTO order_items (order_id, product_id, sku, product_name, unit_price, quantity)
VALUES
(LAST_INSERT_ID(), 1, 'SKU-001', 'All-Purpose Cleaner', 5.99, 1);

-- Payments (sample: none paid yet)
-- No payment inserted for pending order

-- Reviews
INSERT INTO reviews (product_id, user_id, rating, title, body, is_verified_purchase)
VALUES
(1, 1, 5, 'Great cleaner', 'Worked very well for kitchen surfaces', 1);

-- 5) Example views and helper objects (

-- A simple view for order summary
CREATE OR REPLACE VIEW v_order_summary AS
SELECT o.id AS order_id,
       o.order_number,
       o.user_id,
       u.email AS user_email,
       o.total_amount,
       o.status,
       o.placed_at
FROM orders o
LEFT JOIN users u ON u.id = o.user_id;

