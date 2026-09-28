-- =========================================================
-- 05 · Aggregation of Records
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. Grouping vs aggregating
SELECT COUNT(*) FROM comments;

-- 2. GROUP BY
SELECT u.username, COUNT(*) AS comment_count
FROM comments AS c
JOIN users AS u ON c.user_id = u.id
GROUP BY u.username;

-- 3. Aggregate functions
SELECT
    COUNT(*)                 AS how_many,
    SUM(LENGTH(comment_text)) AS total_characters,
    AVG(LENGTH(comment_text)) AS avg_length,
    MIN(LENGTH(comment_text)) AS shortest,
    MAX(LENGTH(comment_text)) AS longest
FROM comments;

-- 4. COUNT(*) vs COUNT(column) and NULLs
SELECT u.username,
       COUNT(*)   AS row_count,
       COUNT(p.id) AS actual_photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;

-- 5. Filtering groups with HAVING
SELECT u.username, COUNT(p.id) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username
HAVING COUNT(p.id) > 1;

-- Trap: aggregates aren't allowed in WHERE
-- SELECT u.username, COUNT(p.id) AS photo_count
-- FROM users AS u
-- LEFT JOIN photos AS p ON u.id = p.user_id
-- WHERE COUNT(p.id) > 1
-- GROUP BY u.username;

-- 6. Common GROUP BY traps
-- This one fails on purpose: p.url isn't grouped or aggregated
-- SELECT u.username, p.url, COUNT(*) AS photo_count
-- FROM users AS u
-- LEFT JOIN photos AS p ON u.id = p.user_id
-- GROUP BY u.username;

-- Fix 1: add it to GROUP BY
SELECT u.username, p.url, COUNT(*) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username, p.url;

-- Fix 2: aggregate it too
SELECT u.username, MAX(p.url) AS a_photo, COUNT(p.id) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;

-- Practice answers
SELECT COUNT(DISTINCT user_id) FROM comments;

SELECT p.url, COUNT(c.id) AS comment_count
FROM photos AS p
JOIN comments AS c ON p.id = c.photo_id
GROUP BY p.url
HAVING COUNT(c.id) >= 2;
