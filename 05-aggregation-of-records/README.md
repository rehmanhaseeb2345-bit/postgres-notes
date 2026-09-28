<div align="center">

# 05 · Aggregation of Records

**Part 1 — SQL Fundamentals** · ✅ Done

</div>

> Every query so far has returned one output row per input row (or per matched pair, after a join). This section is the first time a query collapses *many* rows down into *one* — "how many comments does each photo have" isn't a question about any single row, it's a question about a whole group of them.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses the shared `sample-db/` schema — see [04 · Relating Records with Joins](../04-relating-records-with-joins/README.md) for how to load it.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Grouping vs aggregating](#1-grouping-vs-aggregating) | Collapsing the whole table vs collapsing it per bucket |
| 2 | [GROUP BY](#2-group-by) | One result row per distinct value |
| 3 | [Aggregate functions](#3-aggregate-functions) | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` |
| 4 | [COUNT(*) vs COUNT(column) and NULLs](#4-count-vs-countcolumn-and-nulls) | A subtle bug after a LEFT JOIN |
| 5 | [Filtering groups with HAVING](#5-filtering-groups-with-having) | `WHERE` filters rows; `HAVING` filters groups |
| 6 | [Common GROUP BY traps](#6-common-group-by-traps) | The error that teaches the whole topic |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Grouping vs aggregating

**What it is:** An **aggregate function** (`COUNT`, `SUM`, ...) takes many rows and returns one value. **`GROUP BY`** decides how many "many rows" buckets there are to begin with — without it, an aggregate collapses the *entire* table into a single row.

**Why it exists:** "How many comments are there" and "how many comments does each user have" are both aggregation questions, but they need a different number of result rows — one, or one per user. `GROUP BY` is what tells Postgres which.

### Example — no GROUP BY at all

```sql
SELECT COUNT(*) FROM comments;
```

**Result**

| count |
|--:|
| 6 |

The whole table, one number. There's no way to also see individual comments in this same result — the row-level detail is gone the moment I aggregate.

```mermaid
flowchart LR
    A["6 comment rows"] --> B["COUNT(*)"]
    B --> C["1 row: 6"]
```

### ⚠️ Traps

- **Expecting an aggregate and a plain column side by side without `GROUP BY`** → covered fully in [6 · Common GROUP BY traps](#6-common-group-by-traps), but the short version: Postgres won't guess which of the many rows' values to show next to a collapsed number.

---

## 2. GROUP BY

**What it is:** Buckets rows by the value(s) in one or more columns, so an aggregate function runs once *per bucket* instead of once for the whole table.

**Why it exists:** "One number per group" is a much more common need than "one number total."

### Syntax

```sql
SELECT grouping_column, aggregate_function(column)
FROM table_name
GROUP BY grouping_column;
```

### Example

How many comments has each user written?

```sql
SELECT u.username, COUNT(*) AS comment_count
FROM comments AS c
JOIN users AS u ON c.user_id = u.id
GROUP BY u.username;
```

**Result**

| username | comment_count |
|---|--:|
| alex | 1 |
| bella | 2 |
| chris | 1 |
| dana | 1 |
| erin | 1 |

One row per **distinct `username`** in the joined result, not one row per comment. `bella` wrote 2 comments; both collapse into a single row here.

### ⚠️ Traps

- **Grouping by a column that isn't actually unique per row I care about** → I grouped by `u.username` here instead of `u.id`. It works because usernames are `UNIQUE` (section 3), but grouping by a column with no uniqueness guarantee can quietly merge things I meant to keep separate.

---

## 3. Aggregate functions

**What it is:** Functions that reduce a group of rows to a single value: `COUNT` (how many), `SUM` (total), `AVG` (mean), `MIN`, `MAX`.

**Why it exists:** These five cover almost every "summarize this group" question I actually ask.

### Syntax

```sql
SELECT COUNT(column), SUM(column), AVG(column), MIN(column), MAX(column)
FROM table_name;
```

### Example

Using `LENGTH(comment_text)` as a stand-in for "how substantial is this comment":

```sql
SELECT
    COUNT(*)                 AS how_many,
    SUM(LENGTH(comment_text)) AS total_characters,
    AVG(LENGTH(comment_text)) AS avg_length,
    MIN(LENGTH(comment_text)) AS shortest,
    MAX(LENGTH(comment_text)) AS longest
FROM comments;
```

**Result**

| how_many | total_characters | avg_length | shortest | longest |
|--:|--:|--:|--:|--:|
| 6 | 72 | 12 | 9 | 16 |

`'Love this'` is the shortest at 9 characters, `'Need this coffee'` the longest at 16.

### ⚠️ Traps

- **`AVG` on an empty group returns `NULL`, not `0`.** If a user had zero comments, `AVG(LENGTH(comment_text))` for their group would be `NULL` — a genuinely unanswerable average, not zero. `COUNT` is the one aggregate that always returns a number, even `0`, because it's counting rows rather than computing from a value.

---

## 4. COUNT(*) vs COUNT(column) and NULLs

**What it is:** `COUNT(*)` counts **rows**. `COUNT(some_column)` counts rows where `some_column` is **not `NULL`**. They're only the same when that column is never `NULL`.

**Why it exists:** After a `LEFT JOIN`, unmatched rows exist but are full of `NULL`s — `COUNT(*)` doesn't know or care that a row is "fake."

### Example

`dana` has no photos. After `LEFT JOIN`ing her in anyway (section 4), she gets exactly one row, entirely `NULL` on the `photos` side:

```sql
SELECT u.username,
       COUNT(*)   AS row_count,
       COUNT(p.id) AS actual_photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;
```

**Result**

| username | row_count | actual_photo_count |
|---|--:|--:|
| alex | 2 | 2 |
| bella | 1 | 1 |
| chris | 1 | 1 |
| dana | 1 | 0 |
| erin | 1 | 1 |

For everyone except `dana`, both columns agree. For `dana`, `COUNT(*)` says `1` — because the `LEFT JOIN` still produced one row for her — while `COUNT(p.id)` correctly says `0`, since that row's `p.id` is `NULL` and `COUNT(column)` skips `NULL`s.

### ⚠️ Traps

- **Using `COUNT(*)` after a `LEFT JOIN` when I actually meant "how many matches"** → `row_count` above is a trap I'd fall straight into by habit. `COUNT(*)` after an outer join counts joined *rows*, which is not the same thing as counting real related records the moment any group has zero matches.

---

## 5. Filtering groups with HAVING

**What it is:** `HAVING` filters out entire *groups* after aggregation, using a condition on an aggregate value. `WHERE` filters individual *rows*, before grouping even happens.

**Why it exists:** "Users with more than one photo" isn't something `WHERE` can express — no single row knows how many photos its user has in total. That number only exists after grouping.

### Syntax

```sql
SELECT grouping_column, aggregate_function(column)
FROM table_name
GROUP BY grouping_column
HAVING aggregate_function(column) condition;
```

### Example

```sql
SELECT u.username, COUNT(p.id) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username
HAVING COUNT(p.id) > 1;
```

**Result**

| username | photo_count |
|---|--:|
| alex | 2 |

Everyone else has `0` or `1` photo, so only `alex` survives `HAVING`.

```mermaid
flowchart LR
    A["FROM + LEFT JOIN"] --> B["GROUP BY username"]
    B --> C["HAVING COUNT > 1"]
    C --> D["SELECT"]
```

This is the real order of operations: grouping and `HAVING` both happen *before* `SELECT`, in the same spirit as `WHERE` running before `SELECT` back in [01 · Simple SQL Statements](../01-simple-sql-statements/README.md).

### ⚠️ Traps

- **Trying to write the same condition in `WHERE` instead** → 
  ```sql
  SELECT u.username, COUNT(p.id) AS photo_count
  FROM users AS u
  LEFT JOIN photos AS p ON u.id = p.user_id
  WHERE COUNT(p.id) > 1
  GROUP BY u.username;
  ```
  ```
  ERROR:  aggregate functions are not allowed in WHERE
  ```
  `WHERE` runs before grouping exists, so `COUNT(p.id)` has no meaning yet at that point in the query. Anything that needs an aggregate value has to go in `HAVING`.

---

## 6. Common GROUP BY traps

**What it is:** The single rule that explains almost every `GROUP BY` error: every column in `SELECT` must either be in the `GROUP BY` list, or be wrapped in an aggregate function. No exceptions.

**Why it exists:** If a column isn't grouped or aggregated, Postgres has no way to pick *which* of the many rows' values to show for it — there could be several different answers per group, and Postgres refuses to silently pick one for me.

### Example

```sql
SELECT u.username, p.url, COUNT(*) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;
```

**Result:** Rejected.
```
ERROR:  column "p.url" must appear in the GROUP BY clause or be used in an aggregate function
```

`alex` has two different `url` values (`sunset.jpg` and `coffee.jpg`) in his group — there's no single correct `p.url` to display next to his row, so Postgres won't let the query run at all.

### The two fixes

Either add the column to `GROUP BY` (and accept more, smaller groups):

```sql
SELECT u.username, p.url, COUNT(*) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username, p.url;   -- now one row per user+photo, not per user
```

...or aggregate it too, if a single representative value is actually fine:

```sql
SELECT u.username, MAX(p.url) AS a_photo, COUNT(p.id) AS photo_count
FROM users AS u
LEFT JOIN photos AS p ON u.id = p.user_id
GROUP BY u.username;
```

### ⚠️ Traps

- **Some other databases (notably older MySQL) allow this and silently pick an arbitrary row's value.** Postgres refusing outright feels stricter at first, but it's the safer default — I'd rather get an error now than a query that returns a different, wrong-feeling `p.url` every time it happens to run.

---

## Recap

| Concept | What it does |
|---|---|
| Aggregate function, no `GROUP BY` | Collapses the whole table to one row |
| `GROUP BY column` | One result row per distinct value (or combination) |
| `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` | The five core summarizing functions |
| `COUNT(*)` vs `COUNT(column)` | Rows vs non-`NULL` values — they diverge after outer joins |
| `HAVING` | Filters *groups*, using aggregate values — runs after grouping |
| `WHERE` | Filters *rows*, before grouping — can't reference an aggregate |
| Every `SELECT`ed column | Must be grouped or aggregated, or Postgres refuses to run the query |

> **The one thing I want to remember:** if a column shows up in `SELECT` next to an aggregate function, it has to be in `GROUP BY` too — there's no such thing as "just show me one of them."

---

## Practice

**1.** How many distinct users have written at least one comment?

<details>
<summary>Show answer</summary>

```sql
SELECT COUNT(DISTINCT user_id) FROM comments;
```

| count |
|--:|
| 5 |

All 5 users have written at least one comment (`(DISTINCT ...)` gets its own section — [10 · Selecting Distinct Records](../10-selecting-distinct-records/README.md)).

</details>

**2.** For each photo, show its url and how many comments it has, but only for photos with 2 or more comments.

<details>
<summary>Show answer</summary>

```sql
SELECT p.url, COUNT(c.id) AS comment_count
FROM photos AS p
JOIN comments AS c ON p.id = c.photo_id
GROUP BY p.url
HAVING COUNT(c.id) >= 2;
```

| url | comment_count |
|---|--:|
| sunset.jpg | 2 |

</details>

**3.** What's wrong with this query, and what does Postgres say?
```sql
SELECT c.user_id, c.comment_text, COUNT(*)
FROM comments c
GROUP BY c.user_id;
```

<details>
<summary>Show answer</summary>

`c.comment_text` isn't grouped or aggregated, and most users have written comments with different text, so there's no single value to show. Postgres rejects it:
```
ERROR:  column "c.comment_text" must appear in the GROUP BY clause or be used in an aggregate function
```

</details>

**4.** Using the `LEFT JOIN` from topic 4, which query correctly answers "how many photos does each user have" — the one using `COUNT(*)` or the one using `COUNT(p.id)`? Why does it matter here specifically?

<details>
<summary>Show answer</summary>

`COUNT(p.id)`. It matters because `dana` has zero photos: `COUNT(*)` would report `1` for her (counting the single `NULL`-filled row the `LEFT JOIN` produced), while `COUNT(p.id)` correctly reports `0`. For every user who actually has at least one photo, both give the same answer — the bug only shows up for rows with no match at all.

</details>

---

## What confused me

- I expected `GROUP BY` to sort the results. It doesn't promise any order at all (same as plain `SELECT` back in section 1) — I still need `ORDER BY` if I care about the order, which is coming in [07 · Sorting Records](../07-sorting-records/README.md).
- The "column must appear in GROUP BY or be aggregated" error felt like an arbitrary restriction the first few times. It clicked once I imagined `alex`'s group actually containing two different `url` values at once — there genuinely is no single right answer for that column.
- I didn't expect `COUNT(*)` and `COUNT(column)` to ever disagree. They only diverge after an outer join introduces `NULL`-filled rows — with a plain table or an `INNER JOIN`, they're identical.
- `HAVING` felt redundant with `WHERE` until I tried writing an aggregate condition in `WHERE` and got a straight-up error. `WHERE` genuinely runs too early to know any group's total.

---

[⬅ 04 · Relating Records with Joins](../04-relating-records-with-joins/README.md) · [🏠 Index](../README.md) · [06 · Working with Large Datasets ➡](../06-working-with-large-datasets/README.md)
