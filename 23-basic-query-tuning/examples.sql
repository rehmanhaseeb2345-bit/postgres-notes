-- =========================================================
-- 23 · Basic Query Tuning
-- Every query from my notes for this section.
--
-- Uses the full sample database plus page_views from section 6 and the
-- indexes from section 22 — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 06-working-with-large-datasets/examples.sql
--   psql -d postgres_notes -f 22-a-look-at-indexes-for-performance/examples.sql
-- Then run this file.
-- =========================================================

-- 2. EXPLAIN
EXPLAIN SELECT * FROM page_views WHERE photo_id = 101;

-- 3. EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM page_views WHERE photo_id = 101;

-- Trap: EXPLAIN ANALYZE really executes DML — this really would delete rows
-- EXPLAIN ANALYZE DELETE FROM page_views WHERE photo_id = 101;

-- 4. Reading a query plan
EXPLAIN SELECT p.url, u.username
FROM photos AS p
JOIN users AS u ON p.user_id = u.id;

-- 5. Statistics the planner uses
ANALYZE page_views;

SELECT attname, n_distinct, most_common_vals
FROM pg_stats
WHERE tablename = 'page_views' AND attname = 'photo_id';
