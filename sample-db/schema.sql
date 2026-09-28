-- Sample database used by the examples in these notes.
-- A small Instagram-style app: users, photos, comments, likes (on either
-- a photo or a comment), tags (in a photo or a caption), hashtags, and
-- a self-referencing follower graph.
--
-- Built up gradually across sections 3, 12, and 15-19 — this file is the
-- final, assembled version those sections walk through piece by piece.

DROP TABLE IF EXISTS followers;
DROP TABLE IF EXISTS hashtags_posts;
DROP TABLE IF EXISTS hashtags;
DROP TABLE IF EXISTS caption_tags;
DROP TABLE IF EXISTS photo_tags;
DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS users;

-- Section 3
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

-- Section 12 — one-to-one, user_id doubles as the primary key
CREATE TABLE user_profiles (
    user_id      INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bio          TEXT,
    is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    birth_date   DATE,
    member_since TIMESTAMP NOT NULL,
    last_login   TIMESTAMPTZ,
    CHECK (birth_date < member_since)
);

-- Section 15 — likes a photo OR a comment, never both, never neither
CREATE TABLE likes (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_id      INTEGER REFERENCES photos(id)   ON DELETE CASCADE,
    comment_id    INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    reaction_type VARCHAR(10) NOT NULL DEFAULT 'like'
        CHECK (reaction_type IN ('like', 'love', 'haha', 'wow')),
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT exactly_one_target CHECK (
        COALESCE(photo_id, comment_id) IS NOT NULL
        AND (photo_id IS NULL OR comment_id IS NULL)
    )
);
-- Plain UNIQUE doesn't work with two nullable target columns (NULLs aren't
-- distinct from each other) — partial indexes are the fix, see section 15.
CREATE UNIQUE INDEX unique_photo_like   ON likes (user_id, photo_id)   WHERE photo_id IS NOT NULL;
CREATE UNIQUE INDEX unique_comment_like ON likes (user_id, comment_id) WHERE comment_id IS NOT NULL;

-- Section 16 — two separate tables; their columns genuinely differ
CREATE TABLE photo_tags (
    id       SERIAL PRIMARY KEY,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    x        NUMERIC(5, 2) NOT NULL CHECK (x BETWEEN 0 AND 100),
    y        NUMERIC(5, 2) NOT NULL CHECK (y BETWEEN 0 AND 100),
    UNIQUE (photo_id, user_id)
);

CREATE TABLE caption_tags (
    id         SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    UNIQUE (comment_id, user_id)
);

-- Section 17
CREATE TABLE hashtags (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE hashtags_posts (
    hashtag_id INTEGER NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    photo_id   INTEGER NOT NULL REFERENCES photos(id)   ON DELETE CASCADE,
    PRIMARY KEY (hashtag_id, photo_id)
);

-- Section 18 — self-referencing many-to-many
CREATE TABLE followers (
    follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followed_id),
    CHECK (follower_id <> followed_id)
);
