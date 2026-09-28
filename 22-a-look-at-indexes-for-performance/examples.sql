-- =========================================================
-- 22 · A Look at Indexes for Performance
-- Every query from my notes for this section.
--
-- Uses the full sample database plus page_views from section 6 —
-- load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 06-working-with-large-datasets/examples.sql
-- Then run this file.
-- =========================================================

-- 4. Creating and dropping indexes
DROP INDEX IF EXISTS idx_page_views_photo_id;
CREATE INDEX idx_page_views_photo_id ON page_views (photo_id);

-- 5. Benchmarking with and without an index
DROP INDEX IF EXISTS idx_page_views_photo_id;
EXPLAIN SELECT * FROM page_views WHERE photo_id = 101;

CREATE INDEX idx_page_views_photo_id ON page_views (photo_id);
EXPLAIN SELECT * FROM page_views WHERE photo_id = 101;

-- 8. Indexes Postgres creates automatically
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'users';
SELECT indexname FROM pg_indexes WHERE tablename = 'photos';

-- The gap this reveals — indexing the foreign key columns by hand
CREATE INDEX idx_photos_user_id ON photos (user_id);

-- Practice answers
CREATE INDEX idx_comments_photo_id ON comments (photo_id);
