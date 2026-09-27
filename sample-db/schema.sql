-- Sample database used by the examples in these notes.
-- A tiny photo-sharing app: users post photos, users comment on photos.
-- Later sections (20+) add a bigger Instagram-style schema.

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS users;

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
