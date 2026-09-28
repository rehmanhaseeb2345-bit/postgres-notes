<div align="center">

# 06 · Working with Large Datasets

**Part 1 — SQL Fundamentals** · ✅ Done

</div>

> Everything up to now ran against 5 photos and 6 comments — small enough to eyeball the answer before running the query. That's great for learning, but it hides how these same queries feel at real scale. This section is a deliberate detour: build something with thousands of rows, and practice reading a schema I didn't design myself.

💾 Every query on this page is in [`examples.sql`](examples.sql). It adds one new table (`page_views`) on top of the shared `sample-db/` schema — see [04 · Relating Records with Joins](../04-relating-records-with-joins/README.md) for how to load that first.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Loading a larger sample database](#1-loading-a-larger-sample-database) | `generate_series` instead of typing 5,000 `INSERT`s |
| 2 | [Exploring a schema you have never seen](#2-exploring-a-schema-you-have-never-seen) | `\dt`, `\d`, and `information_schema` |
| 3 | [Practice: joining and grouping at scale](#3-practice-joining-and-grouping-at-scale) | The same joins and GROUP BYs, now over 5,000 rows |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Loading a larger sample database

**What it is:** `generate_series(start, stop)` produces a set of numbers as if it were a table — one row per number. Combined with `INSERT ... SELECT`, it's a way to generate thousands of rows without typing them.

**Why it exists:** I'm not going to hand-write 5,000 `INSERT` statements to see how a query behaves on a bigger table. Postgres can generate the rows itself.

### Syntax

```sql
SELECT * FROM generate_series(1, 5);
```

**Result**

| generate_series |
|--:|
| 1 |
| 2 |
| 3 |
| 4 |
| 5 |

### Example

A `page_views` table — one row per simulated view of a photo — built from `generate_series` instead of a seed file:

```sql
CREATE TABLE page_views (
    id               SERIAL PRIMARY KEY,
    photo_id         INTEGER REFERENCES photos(id) ON DELETE CASCADE,
    viewed_at        TIMESTAMP NOT NULL,
    duration_seconds INTEGER NOT NULL
);

INSERT INTO page_views (photo_id, viewed_at, duration_seconds)
SELECT
    (ARRAY[101, 102, 103, 104, 105])[1 + (n % 5)],
    TIMESTAMP '2026-01-01 00:00:00' + (n * INTERVAL '1 minute'),
    10 + (n % 50)
FROM generate_series(1, 5000) AS n;
```

**Result:** `INSERT 0 5000`.

Each of `n`'s 5,000 values picks a `photo_id` from the array (cycling through all 5), a `viewed_at` one minute later than the last, and a `duration_seconds` between 10 and 59. It's not *realistic* data — real traffic isn't this evenly spread — but it's deterministic, so every count in this section is exactly reproducible.

### ⚠️ Traps

- **Forgetting the array is 1-indexed.** `(ARRAY[...])[0]` isn't "the first element" in Postgres, it's `NULL` — array indexing starts at `1`, unlike most programming languages. That's why the expression above is `1 + (n % 5)`, not `n % 5`.

---

## 2. Exploring a schema you have never seen

**What it is:** Commands for looking at a table's structure without already knowing it — column names, types, constraints — before writing a single query against it.

**Why it exists:** Every real job eventually means opening a database somebody else built. I won't have README files describing every table.

### In `psql`

```
\dt              -- list every table
\d page_views    -- describe one table: columns, types, constraints, indexes
```

`\d page_views` shows exactly what `\d` showed for `photos` back in section 3 — column names, types, the `NOT NULL`s, and the foreign key — but for a table I just built and could just as easily have inherited from someone else.

### The SQL-only equivalent

`\d` is a `psql` shortcut, not real SQL — it won't work in every GUI tool. The same information is queryable directly from Postgres's own catalog:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_views';
```

**Result**

| column_name | data_type | is_nullable |
|---|---|---|
| id | integer | NO |
| photo_id | integer | YES |
| viewed_at | timestamp without time zone | NO |
| duration_seconds | integer | NO |

### A first look at the data itself

Before writing any real query, I just peek:

```sql
SELECT COUNT(*) FROM page_views;
SELECT * FROM page_views LIMIT 5;
```

**Result**

| count |
|--:|
| 5000 |

Row count first, then a handful of actual rows — enough to sanity-check that the columns hold what their names claim before building anything on top of them.

### ⚠️ Traps

- **Running `SELECT *` with no `LIMIT` on a table of unknown size** → on 5,000 rows it's harmless; on a table I've never seen that might hold 50 million, it can tie up the connection dumping all of it. `LIMIT` first, always, on anything unfamiliar.

---

## 3. Practice: joining and grouping at scale

**What it is:** The exact same tools from sections 4 and 5 — `JOIN` and `GROUP BY` — run against 5,000 rows instead of 6.

**Why it exists:** To prove those tools don't change at scale. The query looks identical; only the size of the table underneath it changed.

### Example

Total views and average watch time, per photo:

```sql
SELECT p.url,
       COUNT(*)                        AS total_views,
       ROUND(AVG(pv.duration_seconds), 1) AS avg_duration
FROM page_views AS pv
JOIN photos AS p ON pv.photo_id = p.id
GROUP BY p.url
ORDER BY p.url;
```

**Result**

| url | total_views | avg_duration |
|---|--:|--:|
| beach.jpg | 1000 | 36.5 |
| city.jpg | 1000 | 35.5 |
| coffee.jpg | 1000 | 34.5 |
| mountain.jpg | 1000 | 33.5 |
| sunset.jpg | 1000 | 32.5 |

Every photo lands on exactly 1,000 views — a side effect of `generate_series` cycling evenly, not something I'd expect from real traffic. The `avg_duration` differs per photo though, because `photo_id` and `duration_seconds` are both derived from the same `n`, just with different cycle lengths (5 and 50) — a reminder that "generated" data can carry hidden correlations a truly random sample wouldn't have.

### Rolling it up one level further: per user

```sql
SELECT u.username, COUNT(pv.id) AS total_views
FROM users AS u
LEFT JOIN photos AS p    ON u.id = p.user_id
LEFT JOIN page_views AS pv ON p.id = pv.photo_id
GROUP BY u.username
ORDER BY total_views DESC;
```

**Result**

| username | total_views |
|---|--:|
| alex | 2000 |
| bella | 1000 |
| chris | 1000 |
| erin | 1000 |
| dana | 0 |

`alex` owns 2 of the 5 photos, so his total is double everyone else's. `dana` still owns none, so both `LEFT JOIN`s together correctly carry her all the way through to `0` — not `NULL`, because `COUNT(pv.id)` on an entirely absent group returns `0` (section 5).

### ⚠️ Traps

- **Using `INNER JOIN` here instead of `LEFT JOIN`** → would silently drop `dana` from the result instead of showing her `0`, exactly the [section 4](../04-relating-records-with-joins/README.md) and [section 5](../05-aggregation-of-records/README.md) traps again — scale doesn't introduce new bugs, it just makes the old ones easier to miss in a bigger result set.

---

## Recap

| Concept | What it does |
|---|---|
| `generate_series(start, stop)` | Produces a set of numbers as rows — the basis for generating bulk test data |
| `INSERT ... SELECT ... FROM generate_series(...)` | Builds thousands of rows from one statement |
| `\dt` / `\d table_name` | `psql` shortcuts to list tables / describe one table's structure |
| `information_schema.columns` | The SQL-only, tool-independent way to ask the same question |
| `SELECT * ... LIMIT n` | Safe first look at an unfamiliar table |
| `JOIN` + `GROUP BY` at scale | Same syntax, same rules, regardless of row count |

> **The one thing I want to remember:** row count changes performance, not correctness — a query that's right on 6 rows is either right or wrong on 5,000 rows for the exact same reasons (missing `WHERE`, `INNER` vs `LEFT`, ungrouped columns). Scale doesn't forgive a bug; it just makes it harder to spot by eye.

---

## Practice

**1.** How many `page_views` rows have `duration_seconds` of 30 or more?

<details>
<summary>Show answer</summary>

```sql
SELECT COUNT(*) FROM page_views WHERE duration_seconds >= 30;
```

`duration_seconds` is `10 + (n % 50)`, so it's `>= 30` whenever `n % 50 >= 20` — 30 out of every 50 values of `n` (remainders `20` through `49`). Over 5,000 rows, that's `5000 × 30/50 = 3000`.

| count |
|--:|
| 3000 |

</details>

**2.** Which photo has the *shortest* average view duration?

<details>
<summary>Show answer</summary>

```sql
SELECT p.url, ROUND(AVG(pv.duration_seconds), 1) AS avg_duration
FROM page_views AS pv
JOIN photos AS p ON pv.photo_id = p.id
GROUP BY p.url
ORDER BY avg_duration ASC
LIMIT 1;
```

| url | avg_duration |
|---|--:|
| sunset.jpg | 32.5 |

(Sorting with `ORDER BY` and stopping early with `LIMIT` both get their own full treatment in [07 · Sorting Records](../07-sorting-records/README.md) — this is a preview.)

</details>

**3.** Using `information_schema.columns`, how would I check whether `page_views.photo_id` allows `NULL`, without running `\d` in `psql`?

<details>
<summary>Show answer</summary>

```sql
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_views' AND column_name = 'photo_id';
```

| column_name | is_nullable |
|---|---|
| photo_id | YES |

It's nullable because I never added `NOT NULL` to it — only `id`, `viewed_at`, and `duration_seconds` have that constraint.

</details>

---

## What confused me

- I expected generated data to feel "random," and got confused when every photo landed on exactly the same view count. It's not random at all — `generate_series` is completely deterministic, which is actually what let me write exact numbers in this section instead of "approximately."
- The differing `avg_duration` per photo looked like a mistake at first. It isn't — it's a real (if slightly subtle) consequence of deriving two columns from the same counter with related cycle lengths. A genuinely random dataset wouldn't show that pattern.
- I assumed `\d` was a special SQL feature. It's a `psql` client shortcut — the real source of truth is the `information_schema.columns` view, which works the same way in any tool that can run SQL.

---

[⬅ 05 · Aggregation of Records](../05-aggregation-of-records/README.md) · [🏠 Index](../README.md) · [07 · Sorting Records ➡](../07-sorting-records/README.md)
