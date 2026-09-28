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

---

## Aggregation · [05](05-aggregation-of-records/README.md)

```sql
-- One row per distinct value
SELECT u.username, COUNT(*) AS comment_count
FROM comments AS c
JOIN users AS u ON c.user_id = u.id
GROUP BY u.username;

-- COUNT(*) counts rows; COUNT(column) skips NULLs (they diverge after LEFT JOIN)
SELECT u.username, COUNT(*) AS row_count, COUNT(p.id) AS real_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;

-- HAVING filters groups (after aggregation); WHERE can't reference an aggregate
SELECT u.username, COUNT(p.id) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username
HAVING COUNT(p.id) > 1;
```

**Remember:** every `SELECT`ed column must be grouped or aggregated, no exceptions · `AVG` on zero rows is `NULL`, not `0` · `HAVING` runs after grouping, `WHERE` runs before it.

---

## Large Datasets · [06](06-working-with-large-datasets/README.md)

```sql
-- Generate bulk rows instead of typing them
INSERT INTO page_views (photo_id, viewed_at, duration_seconds)
SELECT (ARRAY[101,102,103,104,105])[1 + (n % 5)],
       TIMESTAMP '2026-01-01' + (n * INTERVAL '1 minute'),
       10 + (n % 50)
FROM generate_series(1, 5000) AS n;

-- Explore an unfamiliar table
-- \dt              -- list tables (psql)
-- \d page_views    -- describe one table (psql)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_views';

SELECT * FROM page_views LIMIT 5;   -- always LIMIT on an unknown table first
```

**Remember:** Postgres arrays are 1-indexed, not 0-indexed · a query that's correct on 6 rows is correct (or wrong) for the same reasons on 5,000 · `information_schema.columns` works in any tool, `\d` only works in `psql`.

---

## Sorting · [07](07-sorting-records/README.md)

```sql
-- Sort, with a tiebreaker column
SELECT user_id, url FROM photos ORDER BY user_id ASC, url ASC;

-- Top N
SELECT comment_text FROM comments ORDER BY LENGTH(comment_text) DESC LIMIT 3;

-- One page of a larger result (page 2, 10 per page)
SELECT id FROM page_views ORDER BY id LIMIT 10 OFFSET 10;
```

**Remember:** `LIMIT`/`OFFSET` without `ORDER BY` isn't meaningfully "the first N" — always sort first · `DESC` only applies to the column it's attached to, not every column after it · `OFFSET` gets slower the further in you page, since Postgres still walks past every skipped row.

---

## Sets · [08](08-unions-and-intersections-with-sets/README.md)

```sql
-- UNION removes duplicates from the combined result; UNION ALL keeps them
SELECT username FROM a UNION SELECT username FROM b;
SELECT username FROM a UNION ALL SELECT username FROM b;

-- INTERSECT: only rows in both · EXCEPT: rows in the first, not the second
SELECT username FROM a INTERSECT SELECT username FROM b;
SELECT username FROM a EXCEPT SELECT username FROM b;   -- order matters!
```

**Remember:** both sides need the same number of columns, in compatible types, matched by position (not name) · `EXCEPT` is not symmetric — `A EXCEPT B` ≠ `B EXCEPT A` · the result's column names come from the first query only.

---

## Subqueries · [09](09-assembling-queries-with-subqueries/README.md)

```sql
-- In WHERE: IN is really "= ANY", NOT IN is really "<> ALL"
SELECT username FROM users WHERE id IN (SELECT user_id FROM photos);

-- In SELECT: must return exactly one value (correlated if it uses the outer row)
SELECT u.username,
       (SELECT COUNT(*) FROM photos p WHERE p.user_id = u.id) AS photo_count
FROM users u;

-- In FROM: needs an alias
SELECT t.username, t.cnt FROM (
    SELECT username, COUNT(*) AS cnt FROM users GROUP BY username
) AS t;

-- ALL / ANY (SOME): compare against every / any row a subquery returns
SELECT url FROM photos p
WHERE (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id)
      >= ALL (SELECT COUNT(*) FROM comments GROUP BY photo_id);
```

**Remember:** a `NULL` anywhere in a `NOT IN` subquery's results zeroes out the whole query — filter it with `WHERE col IS NOT NULL` inside the subquery · a subquery used as a scalar must return exactly one row or it errors · a `FROM`-clause subquery always needs an alias.

---

## Distinct · [10](10-selecting-distinct-records/README.md)

```sql
-- Dedupe whole rows (or a combination of columns)
SELECT DISTINCT category FROM products;
SELECT DISTINCT photo_id, duration_seconds FROM page_views;

-- Count distinct values, not rows
SELECT COUNT(DISTINCT user_id) FROM comments;

-- Same result as DISTINCT here, but GROUP BY also allows aggregates
SELECT category FROM products GROUP BY category;
```

**Remember:** multi-column `DISTINCT` dedupes on the *combination*, not each column separately · `COUNT(DISTINCT col)` still ignores `NULL` · reach for `GROUP BY` instead the moment you also want a count/sum per group.

---

## Utility Operators · [11](11-utility-operators-keywords-and-functions/README.md)

```sql
-- Biggest/smallest of a few values in one row (NOT the same as MAX/MIN across rows)
SELECT GREATEST(price, 5) FROM products;   -- ignores NULL unless every argument is NULL

-- Branching logic as a value
SELECT CASE
    WHEN price < 10  THEN 'Budget'
    WHEN price < 100 THEN 'Midrange'
    ELSE 'Premium'
END AS price_tier FROM products;

-- Conditional counting inside an aggregate
SELECT SUM(CASE WHEN price < 10 THEN 1 ELSE 0 END) AS budget_count FROM products;
```

**Remember:** `GREATEST`/`LEAST` are the rare functions that don't propagate `NULL` · `CASE` branches are checked top to bottom, first match wins · no matching branch and no `ELSE` → silently `NULL`, not an error.

---

## Datatypes · [12](12-postgresql-complex-datatypes/README.md)

```sql
-- NUMERIC is exact; REAL/DOUBLE PRECISION are approximate — never use float for money
SELECT 0.1::DOUBLE PRECISION + 0.2::DOUBLE PRECISION;  -- 0.30000000000000004
SELECT 0.1::NUMERIC + 0.2::NUMERIC;                    -- 0.3

-- TIMESTAMPTZ is the default for real-world event times; TIMESTAMP has no time zone
last_login TIMESTAMPTZ,
member_since TIMESTAMP NOT NULL

-- Date math
SELECT member_since + INTERVAL '1 year' FROM user_profiles;
SELECT AGE(DATE '2026-09-28', birth_date) FROM user_profiles;
```

**Remember:** `NUMERIC(p,s)` for money and anything that can't tolerate rounding drift · `CHAR(n)` pads with real trailing spaces that survive concatenation · `'1'::boolean` (text) works, `1::boolean` (integer) doesn't · `BOOLEAN` has three states — `TRUE`, `FALSE`, and `NULL` (unknown).
