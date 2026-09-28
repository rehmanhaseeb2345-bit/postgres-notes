<div align="center">

# 16 · How to Build a 'Mention' System

**Part 3 — Database Design** · ✅ Done

</div>

> "Tag a friend in this photo" and "@mention someone in a comment" sound like the same feature wearing two names. Designing both side by side is what finally made it obvious when "one table" is the right call (section 14's `album_photos`, section 15's `likes`) and when it very much isn't.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses the shared `sample-db/` schema.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Photo tags vs caption tags](#1-photo-tags-vs-caption-tags) | Tagging a person *in* an image vs mentioning them in text |
| 2 | [Designing photo_tags and caption_tags](#2-designing-photo_tags-and-caption_tags) | Two tables, two different real shapes |
| 3 | [Storing tag positions](#3-storing-tag-positions) | Where on the photo the tag actually sits |
| 4 | [One table or two?](#4-one-table-or-two) | Why this answer differs from section 15's |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Photo tags vs caption tags

**What it is:** Two different features that both involve "connect a user to a piece of content":

- **Photo tags** — "this person is *in* this photo," anchored to a specific point on the image.
- **Caption tags** — "`@bella`, check this out" inside a comment's text, with no position at all, just a mention.

**Why it exists:** They look similar from a distance ("mentioning a user") but need genuinely different data — a photo tag is meaningless without an `(x, y)` position; a caption tag is meaningless *with* one.

---

## 2. Designing photo_tags and caption_tags

**What it is:** Two join tables, one per feature.

**Why it exists:** Following section 14's process — different properties (topic 3) is exactly the signal that these are two distinct "nouns," not one.

### Syntax

```sql
CREATE TABLE photo_tags (
    id       SERIAL PRIMARY KEY,
    photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
    user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    UNIQUE (photo_id, user_id)
);

CREATE TABLE caption_tags (
    id         SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    UNIQUE (comment_id, user_id)
);
```

### Example

```sql
INSERT INTO photo_tags (photo_id, user_id) VALUES (101, 2);   -- bella is tagged in sunset.jpg
INSERT INTO caption_tags (comment_id, user_id) VALUES (4, 5); -- erin is @mentioned in dana's comment
```

`UNIQUE (photo_id, user_id)` means the same person can't be tagged in the same photo twice — but *can* be tagged in many different photos, and many different people can be tagged in the same photo. A genuine many-to-many, same shape as `album_photos`.

---

## 3. Storing tag positions

**What it is:** Where on the photo a tag sits, usually as a percentage of width/height rather than raw pixels.

**Why it exists:** A photo tag needs a dot to render *somewhere* on the image. Percentages (not pixel coordinates) mean the tag stays in the right spot no matter what size the photo is actually displayed at.

### Syntax

```sql
ALTER TABLE photo_tags
    ADD COLUMN x NUMERIC(5, 2) NOT NULL CHECK (x BETWEEN 0 AND 100),
    ADD COLUMN y NUMERIC(5, 2) NOT NULL CHECK (y BETWEEN 0 AND 100);
```

### Example

```sql
INSERT INTO photo_tags (photo_id, user_id, x, y) VALUES (102, 1, 35.50, 60.00);
```

`(35.50, 60.00)` means "35.5% across, 60% down" — a dot roughly left-of-center, in the lower half of `mountain.jpg`, regardless of whether it's displayed as a 200px thumbnail or a full-screen image.

### ⚠️ Traps

- **`caption_tags` has no equivalent columns, and shouldn't.** A position genuinely doesn't apply to a text mention — trying to force both tables into one shape (topic 4) is exactly what would make this column meaningless half the time.

---

## 4. One table or two?

**What it is:** The actual decision process — and why it lands differently here than it did for `likes` (section 15).

**Why it exists:** "Should this be one table or two" doesn't have a universal answer; it depends on whether the *columns* genuinely diverge.

### The comparison that matters

| | `likes` (section 15) | tags (this section) |
|---|---|---|
| Targets | A photo *or* a comment | A photo *or* a comment |
| Extra columns needed | Same for both (`reaction_type`) | **Different** (`x`/`y` only make sense for photos) |
| Verdict | One table, nullable FKs | Two separate tables |

`likes` merged into one table specifically *because* a like on a photo and a like on a comment needed identical columns beyond the target itself. `photo_tags` and `caption_tags` need genuinely different columns — forcing them into one table would mean `x`/`y` sitting there `NULL` on every single caption-tag row, `CHECK`-constrained to a range that's meaningless for them in the first place.

### ⚠️ Traps

- **Applying section 15's answer here as a rule, instead of re-asking the question.** "Two things that both connect a user to content" isn't enough information on its own — it was never really about *how many* targets a thing has, it's about whether the rest of the row looks the same for each target.

---

## Recap

| Concept | What it does |
|---|---|
| `photo_tags` | Who's tagged *in* a photo, at a specific `(x, y)` |
| `caption_tags` | Who's mentioned in a comment's text, no position |
| `UNIQUE (photo_id, user_id)` / `UNIQUE (comment_id, user_id)` | Can't tag the same person in the same place twice |
| `x`, `y` as `NUMERIC(5,2)` percentages | Position that survives the photo being displayed at any size |
| One table vs two | Decided by whether the non-target columns actually match — not by how many targets exist |

> **The one thing I want to remember:** "many-to-many, targeting one of two tables" isn't a single pattern with one right answer — section 15 and this section hit the identical-sounding problem and landed on opposite designs, because the *columns*, not the relationship shape, were what actually differed.

---

## Practice

**1.** Show every user tagged in `sunset.jpg` (photo `101`), with their tag position.

<details>
<summary>Show answer</summary>

```sql
SELECT u.username, pt.x, pt.y
FROM photo_tags AS pt
JOIN users AS u ON pt.user_id = u.id
WHERE pt.photo_id = 101;
```

</details>

**2.** A new feature request: users can tag *locations* (not people) in photos, as free text like `"Paris, France"`. Should this reuse `photo_tags`, or does it need its own table? Why?

<details>
<summary>Show answer</summary>

**Its own table.** A location tag has no `user_id` at all (there's no user being referenced, just a place name) — reusing `photo_tags` would mean `user_id` sitting there `NOT NULL` with nothing meaningful to put in it. Same test as topic 4: the columns don't actually match.

</details>

**3.** What does `UNIQUE (photo_id, user_id)` on `photo_tags` *not* prevent, that might still be worth guarding against?

<details>
<summary>Show answer</summary>

It doesn't stop the **same user from being tagged twice in different spots** on the same photo — `UNIQUE` blocks a duplicate `(photo_id, user_id)` pair, which already means "person X, tagged once, in photo Y" is the actual current rule, not "person X, tagged multiple times." That's arguably correct behavior already, just worth noticing it's a side effect of the constraint rather than something explicitly designed for.

</details>

---

## What confused me

- I started building one `tags` table for both features before working through the columns explicitly. `x`/`y` sitting `NULL` on every caption tag was the tell that I'd merged two different things because they *sounded* similar.
- I assumed position had to be exact pixels. Percentages clicked once I considered the same photo being a tiny thumbnail in one place and full-width somewhere else — pixel coordinates would point at the wrong spot in one of those two contexts.
- Section 15 made me expect a rule like "polymorphic targets always become nullable-FK-plus-CHECK." This section is the reminder that the actual rule is narrower: it only applies when the rest of the row looks the same either way.

---

[⬅ 15 · How to Build a 'Like' System](../15-how-to-build-a-like-system/README.md) · [🏠 Index](../README.md) · [17 · How to Build a 'Hashtag' System ➡](../17-how-to-build-a-hashtag-system/README.md)
