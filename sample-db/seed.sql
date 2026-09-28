-- Seed data for the sample database. Run after schema.sql.

INSERT INTO users (username) VALUES
    ('alex'),
    ('bella'),
    ('chris'),
    ('dana'),
    ('erin');

INSERT INTO photos (id, url, user_id) VALUES
    (101, 'https://example.com/sunset.jpg',   1),
    (102, 'https://example.com/mountain.jpg', 2),
    (103, 'https://example.com/coffee.jpg',   1),
    (104, 'https://example.com/city.jpg',     3),
    (105, 'https://example.com/beach.jpg',    5);

-- Keep the id sequence in sync after inserting ids by hand.
SELECT setval(pg_get_serial_sequence('photos', 'id'), (SELECT MAX(id) FROM photos));

-- comments get ids 1-6 automatically, in this order
INSERT INTO comments (comment_text, user_id, photo_id) VALUES
    ('Beautiful!',        2, 101),   -- id 1
    ('Love this',         3, 101),   -- id 2
    ('Where is this?',    1, 102),   -- id 3
    ('Need this coffee',  4, 103),   -- id 4
    ('Great shot',        5, 104),   -- id 5
    ('Take me there',     2, 105);   -- id 6

INSERT INTO user_profiles (user_id, bio, is_verified, birth_date, member_since, last_login)
VALUES
    (1, 'Photographer and coffee addict', TRUE,  '1995-03-14', '2024-01-10', '2026-09-20 14:30:00+00'),
    (2, NULL,                             FALSE, '1998-07-22', '2024-02-15', '2026-09-25 09:15:00+00'),
    (3, 'Just here for the photos',       FALSE, '1990-11-02', '2023-11-01', '2026-09-18 20:00:00+00');
    -- dana and erin have no profile row — a one-to-one doesn't require one

INSERT INTO likes (user_id, photo_id, comment_id, reaction_type) VALUES
    (2, 101, NULL, 'love'),   -- bella loves sunset.jpg
    (3, 101, NULL, 'like'),   -- chris likes sunset.jpg
    (1, 102, NULL, 'like'),   -- alex likes mountain.jpg
    (5, 104, NULL, 'haha'),   -- erin reacts haha to city.jpg
    (1, NULL, 1,   'like'),   -- alex likes bella's 'Beautiful!' comment
    (4, NULL, 3,   'wow');    -- dana wows alex's 'Where is this?' comment

INSERT INTO photo_tags (photo_id, user_id, x, y) VALUES
    (101, 2, 50.00, 50.00),   -- bella tagged in sunset.jpg
    (102, 1, 35.50, 60.00);   -- alex tagged in mountain.jpg

INSERT INTO caption_tags (comment_id, user_id) VALUES
    (4, 5);   -- erin @mentioned in dana's 'Need this coffee' comment

INSERT INTO hashtags (name) VALUES ('sunset'), ('beach'), ('summer'), ('coffee');

INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 101 FROM hashtags WHERE name IN ('sunset', 'beach', 'summer');

INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 103 FROM hashtags WHERE name = 'coffee';

-- Follow graph: a mutual pair (alex/bella) and a loop (alex -> chris -> dana -> erin -> alex)
INSERT INTO followers (follower_id, followed_id) VALUES
    (1, 2),  -- alex follows bella
    (2, 1),  -- bella follows alex
    (1, 3),  -- alex follows chris
    (2, 3),  -- bella follows chris
    (2, 5),  -- bella follows erin
    (3, 4),  -- chris follows dana
    (4, 5),  -- dana follows erin
    (5, 1);  -- erin follows alex
