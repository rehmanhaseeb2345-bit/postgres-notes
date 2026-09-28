-- =========================================================
-- 13 · Database-Side Validation and Constraints
-- Every query from my notes for this section.
--
-- Uses the shared sample database plus user_profiles from section 12 —
-- load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 12-postgresql-complex-datatypes/examples.sql
-- Then run this file.
-- =========================================================

-- 5. CHECK constraints — the properly-validated products table
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    name       VARCHAR(50)    NOT NULL,
    category   VARCHAR(30)    NOT NULL,
    price      NUMERIC(10, 2) CHECK (price >= 0),
    stock      INTEGER        NOT NULL DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- 2. NOT NULL — fails on purpose
-- INSERT INTO products (name, category, price, stock) VALUES (NULL, 'Home', 10, 5);

-- 3. DEFAULT values
INSERT INTO products (name, category, price, stock) VALUES ('Notebook', 'Stationery', 3.00, 500);
SELECT name, created_at FROM products WHERE name = 'Notebook';

-- 5. CHECK: negative price fails on purpose
-- INSERT INTO products (name, category, price, stock) VALUES ('Broken Lamp', 'Home', -5, 10);

-- Cross-column CHECK, added to an existing table
ALTER TABLE user_profiles
ADD CONSTRAINT birth_before_membership CHECK (birth_date < member_since);

-- 4. UNIQUE (single and multi-column)
-- INSERT INTO users (username) VALUES ('alex');   -- fails: duplicate username

DROP TABLE IF EXISTS demo_likes;
CREATE TABLE demo_likes (
    user_id  INTEGER,
    photo_id INTEGER,
    UNIQUE (user_id, photo_id)
);

INSERT INTO demo_likes VALUES (1, 101);
-- INSERT INTO demo_likes VALUES (1, 101);   -- fails: duplicate combination
INSERT INTO demo_likes VALUES (1, 102);
INSERT INTO demo_likes VALUES (2, 101);

DROP TABLE demo_likes;

-- 6. Adding constraints to an existing table
DROP TABLE IF EXISTS demo_ratings;
CREATE TABLE demo_ratings (score INTEGER);
INSERT INTO demo_ratings VALUES (5), (3), (-1);

-- ALTER TABLE demo_ratings ADD CONSTRAINT score_range CHECK (score BETWEEN 1 AND 5);
-- fails: existing row (-1) violates it

UPDATE demo_ratings SET score = 1 WHERE score = -1;
ALTER TABLE demo_ratings ADD CONSTRAINT score_range CHECK (score BETWEEN 1 AND 5);

DROP TABLE demo_ratings;

-- Practice answers
ALTER TABLE products ADD CONSTRAINT stock_non_negative CHECK (stock >= 0);

-- ALTER TABLE user_profiles ALTER COLUMN bio SET NOT NULL;   -- fails: bella's bio is NULL
UPDATE user_profiles SET bio = '' WHERE bio IS NULL;
ALTER TABLE user_profiles ALTER COLUMN bio SET NOT NULL;
