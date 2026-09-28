-- =========================================================
-- 10 · Selecting Distinct Records
-- Every query from my notes for this section.
--
-- Uses:
--   - products (recreated fresh below, same seed as section 02)
--   - the shared sample-db/ schema:
--       psql -d postgres_notes -f sample-db/schema.sql
--       psql -d postgres_notes -f sample-db/seed.sql
--   - page_views from section 06:
--       psql -d postgres_notes -f 06-working-with-large-datasets/examples.sql
-- =========================================================

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    name      VARCHAR(50),
    category  VARCHAR(30),
    price     INTEGER,
    stock     INTEGER
);

INSERT INTO products (name, category, price, stock)
VALUES
    ('Wireless Mouse',      'Electronics', 25,  120),
    ('Notebook',            'Stationery',   3,  500),
    ('Desk Lamp',           'Home',        40,   35),
    ('USB-C Cable',         'Electronics', 10,  300),
    ('Coffee Mug',          'Home',         8,  150),
    ('Mechanical Keyboard', 'Electronics', 85,   40),
    ('Sticky Notes',        'Stationery',   2,  600),
    ('Bluetooth Speaker',   'Electronics', 60,    0),
    ('Standing Desk',       'Home',       350,    5),
    ('Ballpoint Pen',       'Stationery', NULL,  800);

-- 1. DISTINCT
SELECT DISTINCT category FROM products;

-- 2. DISTINCT across several columns
SELECT DISTINCT photo_id, duration_seconds
FROM page_views
ORDER BY photo_id, duration_seconds;

-- 3. COUNT(DISTINCT column)
SELECT COUNT(*)                AS total_comments,
       COUNT(DISTINCT user_id) AS distinct_commenters
FROM comments;

-- 4. DISTINCT vs GROUP BY
SELECT DISTINCT category FROM products;
SELECT category FROM products GROUP BY category;
SELECT category, COUNT(*) AS product_count FROM products GROUP BY category;

-- Practice answers
SELECT COUNT(DISTINCT price) FROM products;

SELECT DISTINCT category, price
FROM products
ORDER BY category, price;

SELECT category FROM products GROUP BY category;
