-- =========================================================
-- 30 · Managing Database Design with Schema Migrations
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 4. Writing and running migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
    version    VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Migration 001: add a non-negative stock CHECK (up)
BEGIN;
ALTER TABLE products ADD CONSTRAINT stock_non_negative CHECK (stock >= 0);
INSERT INTO schema_migrations (version) VALUES ('001_add_stock_non_negative');
COMMIT;

-- Migration 002: add photos.updated_at (up)
BEGIN;
ALTER TABLE photos ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
INSERT INTO schema_migrations (version) VALUES ('002_add_photos_updated_at');
COMMIT;

SELECT * FROM schema_migrations ORDER BY version;

-- 5. Reverting migrations — reverse order: 002 first, then 001
BEGIN;
ALTER TABLE photos DROP COLUMN updated_at;
DELETE FROM schema_migrations WHERE version = '002_add_photos_updated_at';
COMMIT;

BEGIN;
ALTER TABLE products DROP CONSTRAINT stock_non_negative;
DELETE FROM schema_migrations WHERE version = '001_add_stock_non_negative';
COMMIT;

-- Practice answers
-- Migration: add user_profiles.bio_updated_at (up)
ALTER TABLE user_profiles ADD COLUMN bio_updated_at TIMESTAMPTZ;
-- (down)
-- ALTER TABLE user_profiles DROP COLUMN bio_updated_at;
