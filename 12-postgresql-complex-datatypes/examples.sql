-- =========================================================
-- 12 · PostgreSQL Complex Datatypes
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Integers: SMALLINT, INTEGER, BIGINT, SERIAL — fails on purpose
DROP TABLE IF EXISTS stock_check;
CREATE TABLE stock_check (level SMALLINT);
-- INSERT INTO stock_check VALUES (40000);   -- ERROR: smallint out of range
DROP TABLE stock_check;

-- 3. Exact vs floating-point numbers
SELECT 0.1::DOUBLE PRECISION + 0.2::DOUBLE PRECISION AS float_math,
       0.1::NUMERIC        + 0.2::NUMERIC        AS exact_math;

-- 4. Text: CHAR, VARCHAR, TEXT
SELECT 'Home'::CHAR(10) || '!' AS padded;

-- 5. BOOLEAN
SELECT TRUE, 'true'::boolean, 't'::boolean, 'yes'::boolean, 'no'::boolean;
-- SELECT 1::boolean;   -- ERROR: cannot cast type integer to boolean

-- 6. Dates, times and time zones
DROP TABLE IF EXISTS user_profiles;
CREATE TABLE user_profiles (
    user_id      INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bio          TEXT,
    is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    birth_date   DATE,
    member_since TIMESTAMP NOT NULL,
    last_login   TIMESTAMPTZ
);

INSERT INTO user_profiles (user_id, bio, is_verified, birth_date, member_since, last_login)
VALUES
    (1, 'Photographer and coffee addict', TRUE,  '1995-03-14', '2024-01-10', '2026-09-20 14:30:00+00'),
    (2, NULL,                             FALSE, '1998-07-22', '2024-02-15', '2026-09-25 09:15:00+00'),
    (3, 'Just here for the photos',       FALSE, '1990-11-02', '2023-11-01', '2026-09-18 20:00:00+00');

SET TIME ZONE 'America/New_York';
SELECT last_login FROM user_profiles WHERE user_id = 1;
SET TIME ZONE DEFAULT;

-- 7. INTERVAL and date math
SELECT member_since, member_since + INTERVAL '1 year' AS first_renewal
FROM user_profiles WHERE user_id = 1;

SELECT (SELECT member_since FROM user_profiles WHERE user_id = 1)
     - (SELECT member_since FROM user_profiles WHERE user_id = 3) AS gap;

SELECT user_id, AGE(DATE '2026-09-28', birth_date) AS age
FROM user_profiles
ORDER BY user_id;

-- Practice answers
SELECT user_id, AGE(DATE '2026-09-28', birth_date) > INTERVAL '30 years' AS over_30
FROM user_profiles WHERE user_id = 3;

-- Trap demo: VARCHAR(2) can't hold 'USA'
-- CREATE TABLE demo_country (country_code VARCHAR(2));
-- INSERT INTO demo_country VALUES ('USA');   -- ERROR: value too long for type character varying(2)
