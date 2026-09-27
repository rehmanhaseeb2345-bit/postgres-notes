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
