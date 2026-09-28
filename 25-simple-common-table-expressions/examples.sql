-- =========================================================
-- 25 · Simple Common Table Expressions
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. What a CTE is (WITH)
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT username, cnt FROM photo_counts WHERE cnt > 0;

-- 3. When a CTE makes a query clearer — referenced three times
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT
    username,
    cnt,
    (SELECT AVG(cnt) FROM photo_counts) AS avg_cnt,
    cnt > (SELECT AVG(cnt) FROM photo_counts) AS above_average
FROM photo_counts
ORDER BY username;

-- Practice answers
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT username, cnt FROM photo_counts WHERE cnt > 1;

-- Trap: two references in FROM with no join condition = cartesian product
-- WITH photo_counts AS (
--     SELECT u.username, COUNT(p.id) AS cnt
--     FROM users AS u LEFT JOIN photos AS p ON u.id = p.user_id
--     GROUP BY u.username
-- )
-- SELECT * FROM photo_counts, photo_counts;
