-- =========================================================
-- 18 · How to Design a 'Follower' System
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
--
-- This follow graph is reused in section 26 (Recursive CTEs).
-- =========================================================

DROP TABLE IF EXISTS followers;
CREATE TABLE followers (
    follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followed_id)
);

INSERT INTO followers (follower_id, followed_id) VALUES
    (1, 2),  -- alex follows bella
    (2, 1),  -- bella follows alex  (mutual)
    (1, 3),  -- alex follows chris
    (2, 3),  -- bella follows chris
    (2, 5),  -- bella follows erin
    (3, 4),  -- chris follows dana
    (4, 5),  -- dana follows erin
    (5, 1);  -- erin follows alex  (closes a loop)

-- 2. Designing the followers table
SELECT u.username FROM followers f JOIN users u ON f.followed_id = u.id WHERE f.follower_id = 1;
SELECT u.username FROM followers f JOIN users u ON f.follower_id = u.id WHERE f.followed_id = 1;

SELECT f1.follower_id, f1.followed_id
FROM followers AS f1
JOIN followers AS f2
  ON f1.follower_id = f2.followed_id
 AND f1.followed_id = f2.follower_id
WHERE f1.follower_id < f1.followed_id;

-- 3. Preventing self-follows and duplicate follows
ALTER TABLE followers ADD CONSTRAINT no_self_follow CHECK (follower_id <> followed_id);

-- INSERT INTO followers (follower_id, followed_id) VALUES (1, 1);   -- fails: self-follow
-- INSERT INTO followers (follower_id, followed_id) VALUES (1, 2);   -- fails: duplicate

-- Practice answers
SELECT follower_id, COUNT(*) AS following_count
FROM followers
GROUP BY follower_id
ORDER BY follower_id;

SELECT followed_id, COUNT(*) AS follower_count
FROM followers
GROUP BY followed_id
ORDER BY follower_count DESC;
