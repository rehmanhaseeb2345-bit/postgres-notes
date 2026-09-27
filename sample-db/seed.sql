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

INSERT INTO comments (comment_text, user_id, photo_id) VALUES
    ('Beautiful!',        2, 101),
    ('Love this',         3, 101),
    ('Where is this?',    1, 102),
    ('Need this coffee',  4, 103),
    ('Great shot',        5, 104),
    ('Take me there',     2, 105);
