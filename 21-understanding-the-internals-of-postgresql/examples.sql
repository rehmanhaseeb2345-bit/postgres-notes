-- =========================================================
-- 21 · Understanding the Internals of PostgreSQL
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. The data directory and where tables live
SHOW data_directory;
SELECT pg_relation_filepath('users');

-- 2. Heap files, blocks, and tuples
SELECT ctid, username FROM users;
