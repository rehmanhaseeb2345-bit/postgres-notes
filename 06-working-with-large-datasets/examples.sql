-- =========================================================
-- 06 · Working with Large Datasets
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. Loading a larger sample database
SELECT * FROM generate_series(1, 5);

DROP TABLE IF EXISTS page_views;
CREATE TABLE page_views (
    id               SERIAL PRIMARY KEY,
    photo_id         INTEGER REFERENCES photos(id) ON DELETE CASCADE,
    viewed_at        TIMESTAMP NOT NULL,
    duration_seconds INTEGER NOT NULL
);

INSERT INTO page_views (photo_id, viewed_at, duration_seconds)
SELECT
    (ARRAY[101, 102, 103, 104, 105])[1 + (n % 5)],
    TIMESTAMP '2026-01-01 00:00:00' + (n * INTERVAL '1 minute'),
    10 + (n % 50)
FROM generate_series(1, 5000) AS n;

-- 2. Exploring a schema you have never seen
-- \dt
-- \d page_views

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_views';

SELECT COUNT(*) FROM page_views;
SELECT * FROM page_views LIMIT 5;

-- 3. Practice: joining and grouping at scale
SELECT p.url,
       COUNT(*)                           AS total_views,
       ROUND(AVG(pv.duration_seconds), 1) AS avg_duration
FROM page_views AS pv
JOIN photos AS p ON pv.photo_id = p.id
GROUP BY p.url
ORDER BY p.url;

SELECT u.username, COUNT(pv.id) AS total_views
FROM users AS u
LEFT JOIN photos AS p     ON u.id = p.user_id
LEFT JOIN page_views AS pv ON p.id = pv.photo_id
GROUP BY u.username
ORDER BY total_views DESC;

-- Practice answers
SELECT COUNT(*) FROM page_views WHERE duration_seconds >= 30;

SELECT p.url, ROUND(AVG(pv.duration_seconds), 1) AS avg_duration
FROM page_views AS pv
JOIN photos AS p ON pv.photo_id = p.id
GROUP BY p.url
ORDER BY avg_duration ASC
LIMIT 1;

SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_views' AND column_name = 'photo_id';
