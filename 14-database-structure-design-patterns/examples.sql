-- =========================================================
-- 14 · Database Structure Design Patterns
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 1. Worked example: photo albums
DROP TABLE IF EXISTS album_photos;
DROP TABLE IF EXISTS albums;

CREATE TABLE albums (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE album_photos (
    album_id INTEGER NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    PRIMARY KEY (album_id, photo_id)
);

INSERT INTO albums (name, user_id) VALUES ('Summer Trip', 1);
INSERT INTO album_photos (album_id, photo_id) VALUES (1, 101), (1, 103);

SELECT p.url
FROM album_photos AS ap
JOIN photos AS p ON ap.photo_id = p.id
WHERE ap.album_id = 1;

-- Practice answers
-- (photo_tags is illustrative only — tags table doesn't exist yet, see section 17)
-- CREATE TABLE photo_tags (
--     photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
--     tag_id   INTEGER NOT NULL REFERENCES tags(id)    ON DELETE CASCADE,
--     PRIMARY KEY (photo_id, tag_id)
-- );

SELECT album_id, photo_id FROM album_photos;
