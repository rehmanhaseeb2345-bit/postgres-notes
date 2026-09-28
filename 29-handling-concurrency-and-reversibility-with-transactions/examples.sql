-- =========================================================
-- 29 · Handling Concurrency and Reversibility with Transactions
-- Every query from my notes for this section.
--
-- Uses the full sample database and the albums/album_photos tables
-- from section 14 — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
--   psql -d postgres_notes -f 14-database-structure-design-patterns/examples.sql
-- Then run this file.
-- =========================================================

-- 2. BEGIN, COMMIT, ROLLBACK
INSERT INTO albums (name, user_id) VALUES ('Coffee Shots', 1);   -- album id 2

BEGIN;
DELETE FROM album_photos WHERE album_id = 1 AND photo_id = 103;
INSERT INTO album_photos (album_id, photo_id) VALUES (2, 103);
COMMIT;

SELECT * FROM album_photos ORDER BY album_id, photo_id;

BEGIN;
DELETE FROM photos WHERE id = 101;
ROLLBACK;

SELECT * FROM photos WHERE id = 101;   -- still there

-- 3. Aborted transactions and errors
BEGIN;
INSERT INTO users (username) VALUES ('newuser');
-- INSERT INTO users (username) VALUES ('alex');   -- fails: duplicate username
-- SELECT * FROM users;                             -- also fails: transaction aborted
ROLLBACK;

SELECT COUNT(*) FROM users;   -- back to 5, 'newuser' never stuck
