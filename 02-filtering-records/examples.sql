-- =========================================================
-- 02 · Filtering Records
-- Every query from my notes for this section.
-- Run it:  psql -d postgres_notes -f 02-filtering-records/examples.sql
-- =========================================================

-- Start fresh every time this file runs
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    name      VARCHAR(50),
    category  VARCHAR(30),
    price     INTEGER,
    stock     INTEGER
);

-- Same products as section 01, plus a few new ones to make filtering interesting:
-- an out-of-stock item, an expensive item, and an item with no price yet (NULL).
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

-- 1. The WHERE clause and query order
SELECT name, price
FROM products
WHERE category = 'Home';

-- This one fails on purpose (alias not visible to WHERE yet) — see the notes.
-- SELECT name, price * stock AS inventory_value
-- FROM products
-- WHERE inventory_value > 3000;

-- 2. Comparison operators
SELECT name, price
FROM products
WHERE price > 40;

SELECT name, price FROM products WHERE price <> 25;   -- Ballpoint Pen (NULL) silently missing
SELECT name FROM products WHERE price IS NULL;         -- the correct way to find it

-- 3. BETWEEN, IN and NOT IN
SELECT name, price
FROM products
WHERE price BETWEEN 10 AND 60;

SELECT name, category
FROM products
WHERE category IN ('Electronics', 'Stationery');

SELECT name FROM products WHERE price NOT IN (25, 3, 40);         -- misses the NULL row silently
SELECT name FROM products WHERE price NOT IN (25, 3, 40, NULL);   -- returns ZERO rows (the trap)

-- 4. Combining conditions with AND and OR
SELECT name, category, price
FROM products
WHERE category = 'Electronics' AND price < 30;

-- Precedence trap: AND binds tighter than OR
SELECT name, category, price
FROM products
WHERE category = 'Home' OR category = 'Stationery' AND price < 5;

-- Fixed with parentheses
SELECT name, category, price
FROM products
WHERE (category = 'Home' OR category = 'Stationery') AND price < 5;

-- 5. Calculations inside WHERE
SELECT name, price, stock, price * stock AS inventory_value
FROM products
WHERE price * stock > 1300;

-- 6. Updating rows with UPDATE
UPDATE products
SET stock = 25
WHERE name = 'Bluetooth Speaker';

UPDATE products
SET price = price * 1.10
WHERE category = 'Electronics'
RETURNING name, price;   -- 25->28, 10->11, 85->94, 60->66 (rounded to fit INTEGER)

-- 7. Deleting rows with DELETE
DELETE FROM products
WHERE name = 'Sticky Notes'
RETURNING *;

-- Practice answers (run against the table as it stands after the UPDATE/DELETE above)
SELECT name, price FROM products WHERE price < 15;
SELECT name, category, price FROM products WHERE category = 'Home' OR price > 50;
SELECT name, price FROM products WHERE price BETWEEN 20 AND 70;
SELECT name FROM products WHERE stock = 0;   -- trick question: zero rows, already restocked
