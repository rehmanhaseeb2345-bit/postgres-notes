-- =========================================================
-- 24 · Advanced Query Tuning
-- Every query from my notes for this section.
--
-- Uses the full sample database plus page_views + its index (sections
-- 6, 22) — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 06-working-with-large-datasets/examples.sql
--   psql -d postgres_notes -f 22-a-look-at-indexes-for-performance/examples.sql
-- Then run this file.
-- =========================================================

-- 2. Calculating cost by hand
SELECT relpages, reltuples FROM pg_class WHERE relname = 'page_views';

-- 3. Cost settings
SHOW seq_page_cost;
SHOW random_page_cost;
SHOW cpu_tuple_cost;

-- 4. Startup cost vs total cost
EXPLAIN SELECT * FROM page_views ORDER BY viewed_at LIMIT 5;

-- 5. Why Postgres sometimes ignores your index
EXPLAIN SELECT * FROM page_views WHERE photo_id IN (101, 102, 103, 104, 105);

-- Practice answers
EXPLAIN SELECT * FROM page_views WHERE photo_id = 101;
EXPLAIN SELECT * FROM page_views ORDER BY id LIMIT 5;
