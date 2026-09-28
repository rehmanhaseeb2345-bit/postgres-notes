-- =========================================================
-- 16 · How to Build a 'Mention' System
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Designing photo_tags and caption_tags
DROP TABLE IF EXISTS photo_tags;
DROP TABLE IF EXISTS caption_tags;

CREATE TABLE photo_tags (
    id       SERIAL PRIMARY KEY,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    UNIQUE (photo_id, user_id)
);

CREATE TABLE caption_tags (
    id         SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    UNIQUE (comment_id, user_id)
);

-- 3. Storing tag positions
ALTER TABLE photo_tags
    ADD COLUMN x NUMERIC(5, 2) NOT NULL CHECK (x BETWEEN 0 AND 100),
    ADD COLUMN y NUMERIC(5, 2) NOT NULL CHECK (y BETWEEN 0 AND 100);

INSERT INTO photo_tags (photo_id, user_id, x, y) VALUES (101, 2, 50.00, 50.00);  -- bella in sunset.jpg
INSERT INTO photo_tags (photo_id, user_id, x, y) VALUES (102, 1, 35.50, 60.00);  -- alex in mountain.jpg

INSERT INTO caption_tags (comment_id, user_id) VALUES (4, 5);   -- erin @mentioned in dana's comment

-- Practice answers
SELECT u.username, pt.x, pt.y
FROM photo_tags AS pt
JOIN users AS u ON pt.user_id = u.id
WHERE pt.photo_id = 101;
