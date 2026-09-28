-- =========================================================
-- 28 · Optimizing Queries with Materialized Views
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Creating a materialized view
DROP MATERIALIZED VIEW IF EXISTS hashtag_stats;
CREATE MATERIALIZED VIEW hashtag_stats AS
SELECT h.name, COUNT(*) AS post_count
FROM hashtags AS h
JOIN hashtags_posts AS hp ON h.id = hp.hashtag_id
GROUP BY h.name;

SELECT * FROM hashtag_stats ORDER BY name;

-- 3. REFRESH MATERIALIZED VIEW
INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 103 FROM hashtags WHERE name = 'summer';

SELECT post_count FROM hashtag_stats WHERE name = 'summer';   -- still 1, stale

REFRESH MATERIALIZED VIEW hashtag_stats;
SELECT post_count FROM hashtag_stats WHERE name = 'summer';   -- now 2

-- Practice answers
DELETE FROM hashtags_posts
WHERE photo_id = 103 AND hashtag_id = (SELECT id FROM hashtags WHERE name = 'summer');

SELECT post_count FROM hashtag_stats WHERE name = 'summer';   -- still 2, stale again
