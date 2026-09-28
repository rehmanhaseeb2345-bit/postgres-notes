-- =========================================================
-- 04 · Relating Records with Joins
-- Every query from my notes for this section.
--
-- Uses the shared sample database — load these first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file:
--   psql -d postgres_notes -f 04-relating-records-with-joins/examples.sql
-- =========================================================

-- 1. What a join actually does (old comma-join style)
SELECT photos.url, users.username
FROM photos, users
WHERE photos.user_id = users.id;

-- Trap: forgetting WHERE gives a silent 25-row Cartesian product
-- SELECT photos.url, users.username FROM photos, users;

-- 2. Table aliases and column-name conflicts
-- This one fails on purpose: "id" exists in both tables
-- SELECT id FROM photos JOIN users ON photos.user_id = users.id;

SELECT p.id, p.url, u.username
FROM photos AS p
JOIN users AS u ON p.user_id = u.id;

-- 3. INNER JOIN
SELECT p.url, u.username
FROM photos AS p
INNER JOIN users AS u ON p.user_id = u.id;

-- Trap: JOIN with no ON is a syntax error, not a silent cartesian product
-- SELECT * FROM photos JOIN users;

-- 4. LEFT JOIN and RIGHT JOIN
SELECT u.username, p.url
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id;

SELECT u.username, p.url
FROM photos AS p
RIGHT JOIN users AS u ON p.user_id = u.id;

-- 5. FULL JOIN (isolated demo tables)
CREATE TABLE morning_shift (username VARCHAR(50));
CREATE TABLE evening_shift (username VARCHAR(50));

INSERT INTO morning_shift VALUES ('alex'), ('bella'), ('chris');
INSERT INTO evening_shift VALUES ('bella'), ('dana');

SELECT morning_shift.username AS morning, evening_shift.username AS evening
FROM morning_shift
FULL JOIN evening_shift ON morning_shift.username = evening_shift.username;

DROP TABLE morning_shift;
DROP TABLE evening_shift;

-- 6. Does the order of tables matter?
SELECT u.username, p.url FROM users AS u LEFT JOIN photos AS p ON u.id = p.user_id;
SELECT p.url, u.username FROM photos AS p LEFT JOIN users AS u ON p.user_id = u.id;

-- 7. Joins combined with WHERE
SELECT p.url, c.comment_text
FROM photos AS p
JOIN comments AS c ON p.id = c.photo_id
WHERE c.user_id = 2;

-- Trap: WHERE on the outer side's column undoes the LEFT JOIN
SELECT u.username, p.url
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
WHERE p.url LIKE '%.jpg%';   -- dana silently disappears

-- Fixed: move the condition into ON
SELECT u.username, p.url
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id AND p.url LIKE '%.jpg%';   -- dana is back

-- 8. Joining three or more tables
SELECT
    commenter.username AS commented_by,
    owner.username     AS photo_owner,
    p.url,
    c.comment_text
FROM comments AS c
JOIN photos AS p        ON c.photo_id = p.id
JOIN users AS owner      ON p.user_id = owner.id
JOIN users AS commenter  ON c.user_id = commenter.id;

-- Practice answers
SELECT u.username
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
WHERE p.id IS NULL;

SELECT p.url, c.comment_text, u.username AS photo_owner
FROM comments AS c
JOIN photos AS p ON c.photo_id = p.id
JOIN users AS u  ON p.user_id = u.id;
