-- =========================================================
-- 20 · Approaching and Writing Complex Queries
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Worked example: two aggregates at once
SELECT u.username, p.id AS photo_id, f.follower_id
FROM users AS u
LEFT JOIN photos AS p    ON p.user_id = u.id
LEFT JOIN followers AS f ON f.followed_id = u.id;

SELECT u.username,
       COUNT(DISTINCT p.id) AS photo_count,
       COUNT(DISTINCT f.follower_id) AS follower_count
FROM users AS u
LEFT JOIN photos AS p    ON p.user_id = u.id
LEFT JOIN followers AS f ON f.followed_id = u.id
GROUP BY u.username
ORDER BY u.username;

-- 3. Worked example: the best row per group
SELECT u.username, p.url, l.id AS like_id
FROM users AS u
JOIN photos AS p ON p.user_id = u.id
LEFT JOIN likes AS l ON l.photo_id = p.id;

SELECT u.username, p.url, COUNT(l.id) AS like_count
FROM users AS u
JOIN photos AS p ON p.user_id = u.id
LEFT JOIN likes AS l ON l.photo_id = p.id
GROUP BY u.username, p.url
ORDER BY u.username, like_count DESC;

SELECT DISTINCT ON (u.username) u.username, p.url, COUNT(l.id) AS like_count
FROM users AS u
JOIN photos AS p ON p.user_id = u.id
LEFT JOIN likes AS l ON l.photo_id = p.id
GROUP BY u.username, p.url
ORDER BY u.username, like_count DESC;

-- Practice answers
SELECT DISTINCT ON (u.username) u.username, c.comment_text, COUNT(l.id) AS like_count
FROM users AS u
JOIN comments AS c ON c.user_id = u.id
LEFT JOIN likes AS l ON l.comment_id = c.id
GROUP BY u.username, c.id, c.comment_text
ORDER BY u.username, like_count DESC;
