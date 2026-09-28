-- =========================================================
-- 11 · Utility Operators, Keywords, and Functions
-- Every query from my notes for this section.
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

-- 1. GREATEST and LEAST
SELECT name, price, GREATEST(price, 5) AS floor_price
FROM products;

-- 2. CASE expressions
SELECT name, price,
    CASE
        WHEN price IS NULL  THEN 'Unpriced'
        WHEN price < 10     THEN 'Budget'
        WHEN price < 100    THEN 'Midrange'
        ELSE 'Premium'
    END AS price_tier
FROM products;

SELECT category,
    CASE category
        WHEN 'Electronics' THEN '🔌'
        WHEN 'Stationery'  THEN '✏️'
        WHEN 'Home'        THEN '🏠'
    END AS icon
FROM products;

SELECT
    SUM(CASE WHEN price < 10 THEN 1 ELSE 0 END)                  AS budget_count,
    SUM(CASE WHEN price >= 10 AND price < 100 THEN 1 ELSE 0 END) AS midrange_count,
    SUM(CASE WHEN price >= 100 THEN 1 ELSE 0 END)                AS premium_count
FROM products;

-- Practice answers
SELECT name, stock, LEAST(GREATEST(stock, 10), 400) AS clamped_stock
FROM products;

SELECT name, stock,
    CASE WHEN stock > 0 THEN 'In stock' ELSE 'Out of stock' END AS availability
FROM products;

SELECT CASE WHEN price > 5 THEN 'Expensive' WHEN price <= 5 THEN 'Cheap' END
FROM products WHERE name = 'Ballpoint Pen';
