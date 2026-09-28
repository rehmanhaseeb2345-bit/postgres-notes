-- =========================================================
-- 27 · Simplifying Queries with Views
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Creating a view
DROP VIEW IF EXISTS photo_stats;
CREATE VIEW photo_stats AS
SELECT
    p.id,
    p.url,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hashtags,
    COUNT(DISTINCT l.id)  AS like_count,
    COUNT(DISTINCT pt.id) AS tag_count
FROM photos AS p
LEFT JOIN hashtags_posts AS hp ON p.id = hp.photo_id
LEFT JOIN hashtags AS h        ON hp.hashtag_id = h.id
LEFT JOIN likes AS l           ON l.photo_id = p.id
LEFT JOIN photo_tags AS pt     ON pt.photo_id = p.id
GROUP BY p.id, p.url;

SELECT url, like_count FROM photo_stats WHERE like_count > 0 ORDER BY like_count DESC;

-- 3. Changing and dropping a view
CREATE OR REPLACE VIEW photo_stats AS
SELECT
    p.id, p.url,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hashtags,
    COUNT(DISTINCT l.id)  AS like_count,
    COUNT(DISTINCT pt.id) AS tag_count,
    u.username AS owner
FROM photos AS p
JOIN users AS u ON p.user_id = u.id
LEFT JOIN hashtags_posts AS hp ON p.id = hp.photo_id
LEFT JOIN hashtags AS h        ON hp.hashtag_id = h.id
LEFT JOIN likes AS l           ON l.photo_id = p.id
LEFT JOIN photo_tags AS pt     ON pt.photo_id = p.id
GROUP BY p.id, p.url, u.username;

-- This one fails on purpose: removing a column isn't allowed
-- CREATE OR REPLACE VIEW photo_stats AS
-- SELECT p.id, p.url, COUNT(DISTINCT l.id) AS like_count
-- FROM photos AS p
-- LEFT JOIN likes AS l ON l.photo_id = p.id
-- GROUP BY p.id, p.url;

-- Practice answers
CREATE VIEW user_activity AS
SELECT u.username,
       COUNT(DISTINCT p.id) AS photo_count,
       COUNT(DISTINCT f.follower_id) AS follower_count
FROM users AS u
LEFT JOIN photos AS p    ON p.user_id = u.id
LEFT JOIN followers AS f ON f.followed_id = u.id
GROUP BY u.username;

SELECT * FROM user_activity ORDER BY username;

INSERT INTO likes (user_id, photo_id) VALUES (2, 103);   -- bella likes coffee.jpg
SELECT like_count FROM photo_stats WHERE url = 'https://example.com/coffee.jpg';
