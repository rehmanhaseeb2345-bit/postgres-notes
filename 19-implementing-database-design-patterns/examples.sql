-- =========================================================
-- 19 · Implementing Database Design Patterns
-- Every query from my notes for this section.
--
-- This section's real output is sample-db/schema.sql and sample-db/seed.sql.
-- Load them first:
--   psql -d postgres_notes -f sample-db/schema.sql
--   psql -d postgres_notes -f sample-db/seed.sql
-- Then run this file.
-- =========================================================

-- 4. Loading the dataset — proving it hangs together
SELECT
    p.url,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hashtags,
    COUNT(DISTINCT l.id)  AS like_count,
    COUNT(DISTINCT pt.id) AS tag_count
FROM photos AS p
LEFT JOIN hashtags_posts AS hp ON p.id = hp.photo_id
LEFT JOIN hashtags AS h        ON hp.hashtag_id = h.id
LEFT JOIN likes AS l           ON l.photo_id = p.id
LEFT JOIN photo_tags AS pt     ON pt.photo_id = p.id
GROUP BY p.id, p.url
ORDER BY p.id;

-- Practice answers
SELECT DISTINCT p.url
FROM photos AS p
LEFT JOIN photo_tags AS pt ON pt.photo_id = p.id
WHERE p.user_id = 1 OR pt.user_id = 1;
