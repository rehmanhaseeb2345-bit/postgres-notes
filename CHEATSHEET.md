# 📝 PostgreSQL Cheatsheet

My one-page syntax reference. Every entry links back to the full explanation.
It grows as I finish each section.

[🏠 Back to index](README.md)

---

## Basics · [01](01-simple-sql-statements/README.md)

```sql
-- Create a table
CREATE TABLE products (
    name   VARCHAR(50),
    price  INTEGER
);

-- Insert rows (values match columns by position)
INSERT INTO products (name, price)
VALUES ('Notebook', 3), ('Desk Lamp', 40);

-- Read data
SELECT * FROM products;
SELECT name, price FROM products;

-- Calculated column + alias
SELECT name, price * 2 AS double_price FROM products;

-- Text
SELECT name || ' costs ' || price  AS label,
       CONCAT(name, '!')           AS excited,
       UPPER(name), LOWER(name), LENGTH(name)
FROM products;
```

**Remember:** text in `'single quotes'` · `7 / 2 = 3` (integer division) · `||` with `NULL` gives `NULL`, `CONCAT` skips it.

---

## Filtering · [02](02-filtering-records/README.md)

```sql
-- Comparison operators
SELECT * FROM products WHERE price > 40;
SELECT * FROM products WHERE price IS NULL;        -- never use = NULL or <> NULL

-- Ranges and lists
SELECT * FROM products WHERE price BETWEEN 10 AND 60;   -- inclusive both ends
SELECT * FROM products WHERE category IN ('Electronics', 'Stationery');
SELECT * FROM products WHERE category NOT IN ('Electronics');  -- avoid if the list/column can contain NULL

-- Combining conditions (AND binds tighter than OR — use parentheses!)
SELECT * FROM products WHERE (category = 'Home' OR category = 'Stationery') AND price < 5;

-- Calculations inside WHERE (can't reference a SELECT alias — repeat the expression)
SELECT * FROM products WHERE price * stock > 1300;

-- Change existing rows
UPDATE products SET stock = 25 WHERE name = 'Bluetooth Speaker' RETURNING *;

-- Remove rows for good
DELETE FROM products WHERE name = 'Sticky Notes' RETURNING *;
```

**Remember:** `WHERE` runs before `SELECT`, so it can't see column aliases · `NULL` is never `=` or `<>` anything, use `IS NULL` / `IS NOT NULL` · a `NULL` inside a `NOT IN (...)` list silently zeroes out the whole result · always preview an `UPDATE`/`DELETE`'s `WHERE` with a plain `SELECT` first — there's no undo.

---

## Working with Tables · [03](03-working-with-tables/README.md)

```sql
-- Primary key: auto-incrementing identity
CREATE TABLE users (
    id       SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE
);

-- Foreign key: must match a real row in the parent table (or be NULL)
CREATE TABLE photos (
    id      SERIAL PRIMARY KEY,
    url     VARCHAR(200) NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
);

-- ON DELETE options: CASCADE (delete children too) · SET NULL (disconnect) ·
-- SET DEFAULT (fall back) · RESTRICT / NO ACTION (block the delete, the default)

-- Explicit ids don't move a SERIAL sequence forward — resync it by hand:
SELECT setval(pg_get_serial_sequence('photos', 'id'), (SELECT MAX(id) FROM photos));
```

**Remember:** create/insert parents before children, drop children before parents · a foreign key is checked on every insert/update, not just a naming convention · `ON DELETE` defaults to `NO ACTION` (blocks the delete) if you don't specify one · `CASCADE` can ripple through more than one table in a single `DELETE`.

---

## Relating Records with Joins · [04](04-relating-records-with-joins/README.md)

```sql
-- INNER JOIN: only rows that match on both sides
SELECT p.url, u.username
FROM photos AS p
JOIN users AS u ON p.user_id = u.id;

-- LEFT JOIN: keep every row from the left table, NULL if no match
SELECT u.username, p.url
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id;

-- Find rows with no match at all
SELECT u.username
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
WHERE p.id IS NULL;

-- FULL JOIN: keep every row from both sides
SELECT a.x, b.x FROM a FULL JOIN b ON a.x = b.x;

-- Joining the same table twice needs two different aliases
SELECT c.comment_text, owner.username AS photo_owner, commenter.username AS commented_by
FROM comments AS c
JOIN photos AS p       ON c.photo_id = p.id
JOIN users AS owner     ON p.user_id = owner.id
JOIN users AS commenter ON c.user_id = commenter.id;
```

**Remember:** `JOIN` without `ON`/`USING` is a syntax error (good — the old comma-join style fails silently instead) · `RIGHT JOIN` is just `LEFT JOIN` with the tables swapped · a `WHERE` on the outer side's column can silently turn a `LEFT JOIN` back into an `INNER JOIN` — put that condition in `ON` instead.
