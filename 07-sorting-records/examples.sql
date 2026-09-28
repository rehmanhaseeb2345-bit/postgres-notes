-- =========================================================
-- 07 · Sorting Records
-- Every query from my notes for this section.
--
-- Uses the shared sample database plus page_views from section 6 —
-- load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 06-working-with-large-datasets/examples.sql
-- Then run this file.
-- =========================================================

-- 1. ORDER BY with ASC / DESC
SELECT comment_text, LENGTH(comment_text) AS len
FROM comments
ORDER BY len DESC;

-- 2. Sorting by more than one column
SELECT user_id, url
FROM photos
ORDER BY user_id ASC, url ASC;

SELECT comment_text, LENGTH(comment_text) AS len
FROM comments
ORDER BY len ASC, comment_text ASC;

-- 3. LIMIT
SELECT comment_text, LENGTH(comment_text) AS len
FROM comments
ORDER BY len DESC
LIMIT 3;

-- Trap: LIMIT with no ORDER BY is not meaningfully "the first N"
-- SELECT * FROM page_views LIMIT 5;

-- 4. OFFSET and pagination
SELECT id, photo_id, duration_seconds
FROM page_views
ORDER BY id
LIMIT 10 OFFSET 10;

-- Practice answers
SELECT id, photo_id FROM page_views ORDER BY id DESC LIMIT 3;

SELECT user_id, url FROM photos ORDER BY user_id DESC, url DESC;

SELECT id FROM page_views ORDER BY id LIMIT 25 OFFSET 50;
