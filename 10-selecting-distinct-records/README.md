<div align="center">

# 10 · Selecting Distinct Records

**Part 1 — SQL Fundamentals** · ✅ Done

</div>

> Section 5 needed `COUNT(DISTINCT user_id)` before this topic technically existed yet, with a promissory note pointing here. This is the short section that makes good on it — and it's short precisely because the idea is simple: sometimes I just want to know *what values exist*, not how many rows have them.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses `products` (from sections 1–2), the shared `sample-db/` schema, and `page_views` (from section 6).

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [DISTINCT](#1-distinct) | Removing duplicate whole rows from a result |
| 2 | [DISTINCT across several columns](#2-distinct-across-several-columns) | Uniqueness of the *combination*, not each column alone |
| 3 | [COUNT(DISTINCT column)](#3-countdistinct-column) | How many different values, not how many rows |
| 4 | [DISTINCT vs GROUP BY](#4-distinct-vs-group-by) | Overlapping tools with a different real purpose |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. DISTINCT

**What it is:** `SELECT DISTINCT` removes duplicate rows from the result — keeping only one copy of each unique row.

**Why it exists:** "What categories do I sell?" doesn't need one row per product — it needs one row per *distinct* category.

### Syntax

```sql
SELECT DISTINCT column FROM table_name;
```

### Example

```sql
SELECT DISTINCT category FROM products;
```

**Result**

| category |
|---|
| Electronics |
| Stationery |
| Home |

`products` has 10 rows (section 2's expanded seed data) across only 3 categories — `DISTINCT` collapses the 10 down to those 3.

### ⚠️ Traps

- **`DISTINCT` applies to the whole selected row, not just the first column** → `SELECT DISTINCT category, price FROM products;` doesn't collapse by category alone; two rows are only merged if *both* `category` and `price` match exactly. Full coverage of that is topic 2.

---

## 2. DISTINCT across several columns

**What it is:** With more than one column selected, `DISTINCT` keeps a row unless the entire **combination** of values has appeared already.

**Why it exists:** "Which photo/duration combinations have actually occurred" is a different, more specific question than "which photos exist" or "which durations exist" separately.

### Syntax

```sql
SELECT DISTINCT column1, column2 FROM table_name;
```

### Example

`page_views` has 5,000 rows, cycling through 5 photos and 50 possible durations:

```sql
SELECT DISTINCT photo_id, duration_seconds
FROM page_views
ORDER BY photo_id, duration_seconds;
```

**Result:** exactly **50 rows** — not the 5,000 of the raw table, and not simply `5 × 50 = 250` either. Each photo only ever co-occurs with 10 of the 50 possible durations (a side effect of how section 6's generator derived both columns from the same counter), so the real combination count is `5 photos × 10 durations each = 50`.

### ⚠️ Traps

- **Assuming column-count multiplies out evenly** → I expected something closer to `250` distinct pairs (5 × 50) before actually running this. `DISTINCT` reports what combinations *really occurred*, not the theoretical maximum — a reminder to check real data instead of assuming.

---

## 3. COUNT(DISTINCT column)

**What it is:** Counts how many **different values** a column has — not how many rows.

**Why it exists:** "How many people have commented" and "how many comments exist" are different questions if any single person commented more than once.

### Syntax

```sql
SELECT COUNT(DISTINCT column) FROM table_name;
```

### Example

```sql
SELECT COUNT(*)               AS total_comments,
       COUNT(DISTINCT user_id) AS distinct_commenters
FROM comments;
```

**Result**

| total_comments | distinct_commenters |
|--:|--:|
| 6 | 5 |

`bella` wrote 2 of the 6 comments, so `total_comments` counts her twice while `distinct_commenters` counts her once — same underlying fact, two different honest answers depending on which question I'm actually asking.

### ⚠️ Traps

- **`COUNT(DISTINCT column)` still ignores `NULL`s, same as plain `COUNT(column)` from [05 · Aggregation](../05-aggregation-of-records/README.md#4-count-vs-countcolumn-and-nulls)** → a `NULL` doesn't count as "a distinct value" here either.

---

## 4. DISTINCT vs GROUP BY

**What it is:** For the exact same columns, `SELECT DISTINCT col FROM t` and `SELECT col FROM t GROUP BY col` return the same rows. `GROUP BY` additionally lets me attach aggregate functions to each group; plain `DISTINCT` doesn't aggregate anything, it only deduplicates.

**Why it exists:** They solve overlapping problems, but `GROUP BY` is the right tool the moment I need a *number* per group, not just the group's existence.

### Example

Identical output, different tools:

```sql
SELECT DISTINCT category FROM products;

SELECT category FROM products GROUP BY category;
```

**Result (both)**

| category |
|---|
| Electronics |
| Stationery |
| Home |

The moment I also want *how many* products are in each category, only `GROUP BY` can express it:

```sql
SELECT category, COUNT(*) AS product_count
FROM products
GROUP BY category;
```

`SELECT DISTINCT category, COUNT(*) FROM products;` isn't the same query — `DISTINCT` doesn't create groups for `COUNT(*)` to run against, so that would just count *all* products once per row, then (nonsensically) try to deduplicate a result that's already one repeated number.

### ⚠️ Traps

- **Reaching for `DISTINCT` when the real question needs a count per group** → if the next sentence after "distinct X" is "...and how many of each," that's `GROUP BY`, not `DISTINCT`.

---

## Recap

| Concept | What it does |
|---|---|
| `SELECT DISTINCT col` | Removes duplicate rows, based on the selected column(s) |
| `SELECT DISTINCT col1, col2` | Deduplicates on the *combination*, not each column separately |
| `COUNT(DISTINCT col)` | Counts distinct values, not rows — ignores `NULL` |
| `DISTINCT` vs `GROUP BY` | Same dedup result for plain columns; only `GROUP BY` supports aggregates per group |

> **The one thing I want to remember:** `DISTINCT` answers "what exists"; `GROUP BY` answers "what exists, and here's a number about each one." The instant a count or sum enters the sentence, it's `GROUP BY`.

---

## Practice

**1.** How many distinct prices exist in `products`?

<details>
<summary>Show answer</summary>

```sql
SELECT COUNT(DISTINCT price) FROM products;
```

Prices in the section 2 seed data: 25, 3, 40, 10, 8, 85, 2, 60, 350, and `NULL` (`Ballpoint Pen`) — 9 distinct non-`NULL` values.

| count |
|--:|
| 9 |

</details>

**2.** Which (category, price) combinations exist in `products`, sorted?

<details>
<summary>Show answer</summary>

```sql
SELECT DISTINCT category, price
FROM products
ORDER BY category, price;
```

10 rows, since no two products in the seed data share both the same category *and* the same price.

</details>

**3.** Rewrite `SELECT DISTINCT category FROM products;` using `GROUP BY` instead, and explain when you'd actually prefer the `GROUP BY` version.

<details>
<summary>Show answer</summary>

```sql
SELECT category FROM products GROUP BY category;
```

Identical output either way. I'd prefer the `GROUP BY` version the moment I *also* want an aggregate alongside it, like `COUNT(*)` or `AVG(price)` per category — at that point `DISTINCT` can't express the question at all.

</details>

---

## What confused me

- I expected `DISTINCT photo_id, duration_seconds` to be roughly "distinct photo_ids times distinct durations." It's neither — it's exactly the count of combinations that actually occur in the real data, which can be far smaller than the theoretical maximum.
- `SELECT DISTINCT category, COUNT(*) FROM products;` looked like it should work. It runs, but it doesn't mean what I wanted — `COUNT(*)` there counts the whole table once per output row, not per category, because nothing has grouped the rows first.
- I didn't expect `COUNT(DISTINCT column)` to skip `NULL`s too. It follows the exact same rule as plain `COUNT(column)` — I just hadn't thought to ask the question with `DISTINCT` in the mix yet.

---

[⬅ 09 · Assembling Queries with Subqueries](../09-assembling-queries-with-subqueries/README.md) · [🏠 Index](../README.md) · [11 · Utility Operators, Keywords, and Functions ➡](../11-utility-operators-keywords-and-functions/README.md)
