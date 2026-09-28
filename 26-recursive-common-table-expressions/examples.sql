-- =========================================================
-- 26 · Recursive Common Table Expressions
-- Every query from my notes for this section.
--
-- Uses the full sample database and its follow graph (section 18) —
-- load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 2. How recursion runs, step by step
WITH RECURSIVE reachable AS (
    SELECT followed_id AS user_id, 1 AS depth, ARRAY[1, followed_id] AS path
    FROM followers
    WHERE follower_id = 1

    UNION ALL

    SELECT f.followed_id, r.depth + 1, r.path || f.followed_id
    FROM followers AS f
    JOIN reachable AS r ON f.follower_id = r.user_id
    WHERE r.depth < 3
      AND NOT (f.followed_id = ANY (r.path))
)
SELECT * FROM reachable ORDER BY depth, user_id;

-- 3. Example: follower suggestions
WITH RECURSIVE reachable AS (
    SELECT followed_id AS user_id, 1 AS depth, ARRAY[1, followed_id] AS path
    FROM followers
    WHERE follower_id = 1

    UNION ALL

    SELECT f.followed_id, r.depth + 1, r.path || f.followed_id
    FROM followers AS f
    JOIN reachable AS r ON f.follower_id = r.user_id
    WHERE r.depth < 3
      AND NOT (f.followed_id = ANY (r.path))
)
SELECT u.username, MIN(r.depth) AS shortest_hops
FROM reachable AS r
JOIN users AS u ON u.id = r.user_id
WHERE r.user_id NOT IN (SELECT followed_id FROM followers WHERE follower_id = 1)
GROUP BY u.username
ORDER BY shortest_hops, u.username;

-- Practice answers
WITH RECURSIVE reachable AS (
    SELECT followed_id AS user_id, 1 AS depth, ARRAY[2, followed_id] AS path
    FROM followers WHERE follower_id = 2
    UNION ALL
    SELECT f.followed_id, r.depth + 1, r.path || f.followed_id
    FROM followers AS f JOIN reachable AS r ON f.follower_id = r.user_id
    WHERE r.depth < 2 AND NOT (f.followed_id = ANY (r.path))
)
SELECT DISTINCT user_id, MIN(depth) AS shortest_hops FROM reachable GROUP BY user_id ORDER BY shortest_hops;
