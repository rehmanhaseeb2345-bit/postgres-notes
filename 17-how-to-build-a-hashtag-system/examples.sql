-- =========================================================
-- 17 · How to Build a 'Hashtag' System
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Designing hashtags and hashtags_posts
DROP TABLE IF EXISTS hashtags_posts;
DROP TABLE IF EXISTS hashtags;

CREATE TABLE hashtags (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE hashtags_posts (
    hashtag_id INTEGER NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    photo_id   INTEGER NOT NULL REFERENCES photos(id)   ON DELETE CASCADE,
    PRIMARY KEY (hashtag_id, photo_id)
);

INSERT INTO hashtags (name) VALUES ('sunset'), ('beach'), ('summer');

INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 101 FROM hashtags WHERE name IN ('sunset', 'beach', 'summer');

SELECT p.url
FROM hashtags_posts AS hp
JOIN photos AS p ON hp.photo_id = p.id
JOIN hashtags AS h ON hp.hashtag_id = h.id
WHERE h.name = 'sunset';

-- 3. Why not store hashtags as plain text
ALTER TABLE photos ADD COLUMN IF NOT EXISTS hashtag_text VARCHAR(200);
UPDATE photos SET hashtag_text = '#sunset #beach #summer' WHERE id = 101;
SELECT url FROM photos WHERE hashtag_text LIKE '%#sunset%';
ALTER TABLE photos DROP COLUMN hashtag_text;   -- undo the experiment

-- 4. Performance considerations for counts
SELECT h.name, COUNT(*) AS post_count
FROM hashtags AS h
JOIN hashtags_posts AS hp ON h.id = hp.hashtag_id
GROUP BY h.name
ORDER BY post_count DESC;

ALTER TABLE hashtags ADD COLUMN IF NOT EXISTS post_count INTEGER NOT NULL DEFAULT 0;

-- Practice answers
SELECT h.name
FROM hashtags_posts AS hp
JOIN hashtags AS h ON hp.hashtag_id = h.id
WHERE hp.photo_id = 101;

INSERT INTO hashtags (name) VALUES ('coffee');
INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 103 FROM hashtags WHERE name = 'coffee';
