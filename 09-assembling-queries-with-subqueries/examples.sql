-- =========================================================
-- 09 · Assembling Queries with Subqueries
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. What a subquery is
SELECT username
FROM users
WHERE id IN (SELECT user_id FROM photos);

-- 2. The shape of a result — this one fails on purpose (5 rows, not 1)
-- SELECT username FROM users WHERE id = (SELECT user_id FROM photos);

-- 3. Subqueries in SELECT
SELECT username, (SELECT COUNT(*) FROM photos) AS total_photos_ever
FROM users;

-- 4. Subqueries in FROM
SELECT photo_counts.username, photo_counts.cnt
FROM (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
) AS photo_counts
WHERE photo_counts.cnt > 0;

-- 5. Subqueries in JOIN
SELECT u.username, cc.comment_count
FROM users AS u
JOIN (
    SELECT user_id, COUNT(*) AS comment_count
    FROM comments
    GROUP BY user_id
) AS cc ON u.id = cc.user_id;

-- 6. Subqueries in WHERE
SELECT username
FROM users
WHERE id IN (SELECT user_id FROM photos);

-- Trap: NOT IN + a NULL in the subquery's result
INSERT INTO photos (url, user_id) VALUES ('orphan.jpg', NULL);

SELECT username FROM users WHERE id NOT IN (SELECT user_id FROM photos);   -- zero rows!

SELECT username FROM users
WHERE id NOT IN (SELECT user_id FROM photos WHERE user_id IS NOT NULL);    -- fixed

DELETE FROM photos WHERE url = 'orphan.jpg';   -- clean up the test row

-- 7. ALL and SOME / ANY
SELECT p.url
FROM photos AS p
WHERE (SELECT COUNT(*) FROM comments AS c WHERE c.photo_id = p.id)
      >= ALL (SELECT COUNT(*) FROM comments GROUP BY photo_id);

-- 8. Correlated subqueries
SELECT u.username,
       (SELECT COUNT(*) FROM photos AS p WHERE p.user_id = u.id) AS photo_count
FROM users AS u;

-- 9. SELECT without FROM
SELECT 1 + 1 AS sum, NOW() AS right_now, version() AS pg_version;

-- Practice answers
SELECT url, (SELECT username FROM users WHERE id = photos.user_id) AS owner
FROM photos;

SELECT username FROM (
    SELECT u.username, COUNT(c.id) AS cnt
    FROM users AS u
    LEFT JOIN comments AS c ON u.id = c.user_id
    GROUP BY u.username
) AS counts
WHERE cnt > (SELECT AVG(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM comments GROUP BY user_id
) AS averages);
