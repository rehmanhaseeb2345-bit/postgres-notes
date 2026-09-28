-- =========================================================
-- 15 · How to Build a 'Like' System
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. Why a simple counter column fails
ALTER TABLE photos ADD COLUMN IF NOT EXISTS likes_count INTEGER NOT NULL DEFAULT 0;
UPDATE photos SET likes_count = likes_count + 1 WHERE id = 101;
ALTER TABLE photos DROP COLUMN likes_count;   -- undo the experiment

-- 3. A likes table with UNIQUE
DROP TABLE IF EXISTS photo_likes;
CREATE TABLE photo_likes (
    user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, photo_id)
);

INSERT INTO photo_likes (user_id, photo_id) VALUES (2, 101);
-- INSERT INTO photo_likes (user_id, photo_id) VALUES (2, 101);  -- fails: duplicate

SELECT EXISTS (SELECT 1 FROM photo_likes WHERE user_id = 2 AND photo_id = 101) AS bella_liked_it;
SELECT COUNT(*) FROM photo_likes WHERE photo_id = 101;

DROP TABLE photo_likes;

-- 4. Polymorphic associations (illustrative — not used going forward)
-- CREATE TABLE likes (
--     user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     target_type VARCHAR(20) NOT NULL,
--     target_id   INTEGER NOT NULL,
--     PRIMARY KEY (user_id, target_type, target_id)
-- );

-- 5. Alternative designs — the one used from here on
DROP TABLE IF EXISTS likes;
CREATE TABLE likes (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_id   INTEGER REFERENCES photos(id)   ON DELETE CASCADE,
    comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    CONSTRAINT exactly_one_target CHECK (
        COALESCE(photo_id, comment_id) IS NOT NULL
        AND (photo_id IS NULL OR comment_id IS NULL)
    )
);

INSERT INTO likes (user_id, photo_id) VALUES (2, 101);
INSERT INTO likes (user_id, photo_id) VALUES (2, 101);   -- the NULL-uniqueness gotcha: both succeed
SELECT * FROM likes;

CREATE UNIQUE INDEX unique_photo_like   ON likes (user_id, photo_id)   WHERE photo_id IS NOT NULL;
CREATE UNIQUE INDEX unique_comment_like ON likes (user_id, comment_id) WHERE comment_id IS NOT NULL;

DELETE FROM likes;   -- clear the duplicate before the indexes existed

-- 6. Going beyond likes: reactions
DROP TABLE likes;
CREATE TABLE likes (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_id      INTEGER REFERENCES photos(id)   ON DELETE CASCADE,
    comment_id    INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    reaction_type VARCHAR(10) NOT NULL DEFAULT 'like'
        CHECK (reaction_type IN ('like', 'love', 'haha', 'wow')),
    CONSTRAINT exactly_one_target CHECK (
        COALESCE(photo_id, comment_id) IS NOT NULL
        AND (photo_id IS NULL OR comment_id IS NULL)
    )
);
CREATE UNIQUE INDEX unique_photo_like   ON likes (user_id, photo_id)   WHERE photo_id IS NOT NULL;
CREATE UNIQUE INDEX unique_comment_like ON likes (user_id, comment_id) WHERE comment_id IS NOT NULL;

-- Practice answers
SELECT EXISTS (
    SELECT 1 FROM likes WHERE user_id = 1 AND photo_id = 102
) AS already_liked;
