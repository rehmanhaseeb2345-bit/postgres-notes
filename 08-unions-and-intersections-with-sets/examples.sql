-- =========================================================
-- 08 · Unions and Intersections with Sets
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. UNION
SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id
UNION
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id
ORDER BY username;

-- 2. UNION vs UNION ALL
SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id
UNION ALL
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id;

-- 3. INTERSECT / INTERSECT ALL
SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id
INTERSECT
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id
ORDER BY username;

SELECT * FROM (VALUES ('bella'), ('bella'), ('chris')) AS a(name)
INTERSECT ALL
SELECT * FROM (VALUES ('bella'), ('dana')) AS b(name);

-- 4. EXCEPT / EXCEPT ALL
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id
EXCEPT
SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id;

SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id
EXCEPT
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id;

-- 5. The rules: columns and types — both of these fail on purpose
-- SELECT username FROM users
-- UNION
-- SELECT username, id FROM users;

-- SELECT id FROM users
-- UNION
-- SELECT username FROM users;

-- Practice answers
SELECT u.username FROM users AS u JOIN photos AS p ON u.id = p.user_id
EXCEPT
SELECT u.username FROM users AS u JOIN comments AS c ON u.id = c.user_id;

-- SELECT username, id FROM users
-- UNION
-- SELECT id, username FROM users;   -- fails: column types don't line up positionally
