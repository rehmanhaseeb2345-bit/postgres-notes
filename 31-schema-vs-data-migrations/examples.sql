-- =========================================================
-- 31 · Schema vs Data Migrations
-- Every query from my notes for this section.
--
-- Uses the full sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- Simulate a legacy row that predates any validation
INSERT INTO hashtags (name) VALUES ('Winter');

-- 3. The multi-step migration process
-- Step 2 - migrate (data)
UPDATE hashtags SET name = LOWER(name) WHERE name <> LOWER(name);
SELECT * FROM hashtags ORDER BY name;

-- Step 3 - contract (schema) — succeeds only because step 2 already ran
ALTER TABLE hashtags ADD CONSTRAINT hashtag_name_lowercase CHECK (name = LOWER(name));

-- What step 3 would have done if run before step 2 (illustrative, not run):
-- ERROR:  check constraint "hashtag_name_lowercase" of relation "hashtags" is violated by some row

-- 4. Running data migrations safely with transactions (illustrated pattern)
-- UPDATE hashtags SET name = LOWER(name)
-- WHERE id BETWEEN 1 AND 1000 AND name <> LOWER(name);
-- COMMIT;
-- UPDATE hashtags SET name = LOWER(name)
-- WHERE id BETWEEN 1001 AND 2000 AND name <> LOWER(name);
-- COMMIT;

-- Practice answers
ALTER TABLE photos ADD COLUMN caption TEXT;
