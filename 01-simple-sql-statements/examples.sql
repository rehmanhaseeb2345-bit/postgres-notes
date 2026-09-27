-- =========================================================
-- 01 · Simple — But Powerful — SQL Statements
-- Every query from my notes for this section.
-- Run it:  psql -d postgres_notes -f 01-simple-sql-statements/examples.sql
-- =========================================================

-- Start fresh every time this file runs
DROP TABLE IF EXISTS products;

-- 2. Creating a table
CREATE TABLE products (
    name      VARCHAR(50),
    category  VARCHAR(30),
    price     INTEGER,
    stock     INTEGER
);

-- 3. Inserting rows
INSERT INTO products (name, category, price, stock)
VALUES
    ('Wireless Mouse', 'Electronics', 25, 120),
    ('Notebook',       'Stationery',   3, 500),
    ('Desk Lamp',      'Home',        40,  35),
    ('USB-C Cable',    'Electronics', 10, 300),
    ('Coffee Mug',     'Home',         8, 150);

-- 4. Reading data
SELECT * FROM products;
SELECT price, name FROM products;

-- 5. Calculated columns and aliases
SELECT name, price * stock AS inventory_value
FROM products;

SELECT 7 / 2    AS integer_division,   -- 3  (decimals dropped!)
       7 / 2.0  AS decimal_division,   -- 3.5
       7 % 2    AS remainder,          -- 1
       2 ^ 3    AS power,              -- 8
       |/ 16    AS square_root,        -- 4
       @ -5     AS absolute_value;     -- 5

-- 6. String operators and functions
SELECT
    name || ' (' || category || ')' AS label,
    UPPER(name)                     AS shouting,
    LENGTH(name)                    AS name_length
FROM products;

SELECT UPPER(CONCAT(name, ' - ', category)) AS tag
FROM products;

SELECT 'Mug' || NULL       AS with_pipes,    -- NULL
       CONCAT('Mug', NULL) AS with_concat;   -- Mug

-- Practice answers
SELECT name, price * 0.9 AS sale_price FROM products;
SELECT UPPER(name) || ': ' || stock || ' in stock' AS summary FROM products;
SELECT name, LENGTH(name) FROM products;
