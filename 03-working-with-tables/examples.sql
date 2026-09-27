-- =========================================================
-- 03 · Working with Tables
-- Every query from my notes for this section.
-- Run it:  psql -d postgres_notes -f 03-working-with-tables/examples.sql
--
-- This builds the same users/photos/comments schema that now lives in
-- sample-db/, so later sections can load that instead of repeating this.
-- =========================================================

-- Start fresh every time this file runs
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS users;

-- 3. Primary keys and SERIAL / 4. Foreign keys
CREATE TABLE users (
    id       SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE photos (
    id      SERIAL PRIMARY KEY,
    url     VARCHAR(200) NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE comments (
    id           SERIAL PRIMARY KEY,
    comment_text VARCHAR(240) NOT NULL,
    user_id      INTEGER REFERENCES users(id) ON DELETE CASCADE,
    photo_id     INTEGER REFERENCES photos(id) ON DELETE CASCADE
);

-- 3. SERIAL trap: an explicit id insert doesn't move the sequence forward
CREATE TABLE demo (id SERIAL PRIMARY KEY, note TEXT);

INSERT INTO demo (id, note) VALUES (100, 'inserted by hand');
INSERT INTO demo (note)     VALUES ('inserted normally');   -- gets id = 1, not 101!

SELECT * FROM demo;

DROP TABLE demo;

-- Seed data (parents before children — see topic 5)
INSERT INTO users (username) VALUES
    ('alex'), ('bella'), ('chris'), ('dana'), ('erin');

INSERT INTO photos (id, url, user_id) VALUES
    (101, 'https://example.com/sunset.jpg',   1),
    (102, 'https://example.com/mountain.jpg', 2),
    (103, 'https://example.com/coffee.jpg',   1),
    (104, 'https://example.com/city.jpg',     3),
    (105, 'https://example.com/beach.jpg',    5);

-- Keep the id sequence in sync after inserting ids by hand (see topic 3)
SELECT setval(pg_get_serial_sequence('photos', 'id'), (SELECT MAX(id) FROM photos));

INSERT INTO comments (comment_text, user_id, photo_id) VALUES
    ('Beautiful!',        2, 101),
    ('Love this',         3, 101),
    ('Where is this?',    1, 102),
    ('Need this coffee',  4, 103),
    ('Great shot',        5, 104),
    ('Take me there',     2, 105);

-- 5. Foreign key rules when inserting — this one fails on purpose
-- INSERT INTO photos (url, user_id)
-- VALUES ('https://example.com/ghost.jpg', 99);
-- ERROR:  insert or update on table "photos" violates foreign key constraint "photos_user_id_fkey"

-- Dropping a parent before its children also fails on purpose
-- DROP TABLE users;
-- ERROR:  cannot drop table users because other objects depend on it

-- 6. ON DELETE CASCADE, two levels deep
SELECT COUNT(*) AS users_before    FROM users;
SELECT COUNT(*) AS photos_before   FROM photos;
SELECT COUNT(*) AS comments_before FROM comments;

DELETE FROM users WHERE username = 'chris';

SELECT COUNT(*) AS users_after    FROM users;
SELECT COUNT(*) AS photos_after   FROM photos;
SELECT COUNT(*) AS comments_after FROM comments;

-- 6. ON DELETE SET NULL, for contrast (isolated demo tables)
CREATE TABLE demo_owners (id SERIAL PRIMARY KEY, name TEXT);
CREATE TABLE demo_notes (
    id       SERIAL PRIMARY KEY,
    note     TEXT,
    owner_id INTEGER REFERENCES demo_owners(id) ON DELETE SET NULL
);

INSERT INTO demo_owners (name) VALUES ('temp owner');
INSERT INTO demo_notes (note, owner_id) VALUES ('a note', 1);

DELETE FROM demo_owners WHERE name = 'temp owner';

SELECT * FROM demo_notes;   -- owner_id is now NULL, the row itself survives

DROP TABLE demo_notes;
DROP TABLE demo_owners;

-- Practice answer (question 3)
CREATE TABLE likes (
    id       SERIAL PRIMARY KEY,
    user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE
);
