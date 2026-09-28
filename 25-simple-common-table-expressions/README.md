<div align="center">

# 25 · Simple Common Table Expressions

**Part 5 — Advanced Querying** · ✅ Done

</div>

> Section 9 built a result, gave it an alias, and used it in `FROM` — a subquery. A CTE is the same idea with the naming moved to the *top* of the query instead of buried inside it, and it turns out that's not just tidier — it lets the same named result get reused more than once in one statement, which a subquery genuinely cannot do.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses the full `sample-db/` schema.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [What a CTE is (WITH)](#1-what-a-cte-is-with) | Naming a result before using it |
| 2 | [CTEs vs subqueries](#2-ctes-vs-subqueries) | Same result, one real structural difference |
| 3 | [When a CTE makes a query clearer](#3-when-a-cte-makes-a-query-clearer) | Referencing the same named result more than once |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. What a CTE is (WITH)

**What it is:** A **Common Table Expression** — a named, temporary result, declared with `WITH` before the main query, then used in `FROM` like an ordinary table.

**Why it exists:** Naming a multi-step result *before* the query that uses it reads in the order I actually think in — "first this, then that" — instead of a subquery buried inline, read inside-out.

### Syntax

```sql
WITH name AS (
    SELECT ...
)
SELECT ... FROM name;
```

### Example

```sql
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT username, cnt FROM photo_counts WHERE cnt > 0;
```

**Result**

| username | cnt |
|---|--:|
| alex | 2 |
| bella | 1 |
| chris | 1 |
| erin | 1 |

---

## 2. CTEs vs subqueries

**What it is:** For a single use, a CTE and a `FROM`-clause subquery (section 9) produce the **identical** result — this is the exact same query as section 9's `photo_counts` example, restructured.

**Why it exists:** They're not competing tools for different jobs — a CTE names the same thing a subquery already does, just written differently.

### Side by side

```sql
-- Subquery (section 9)
SELECT photo_counts.username, photo_counts.cnt
FROM (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
) AS photo_counts
WHERE photo_counts.cnt > 0;

-- CTE
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT username, cnt FROM photo_counts WHERE cnt > 0;
```

Identical output. The real difference isn't in this query at all — it shows up the moment the same named result is needed **twice** (topic 3).

### ⚠️ Traps

- **Assuming a CTE is automatically faster.** It isn't inherently — recent Postgres versions can inline a CTE into the surrounding query the same way a subquery would be, when that's cheaper. A CTE is a readability and reuse tool first; performance follows from what the planner decides to do with it either way.

---

## 3. When a CTE makes a query clearer

**What it is:** The genuine structural win — referencing the *same* CTE more than once in one query, instead of duplicating the underlying subquery.

**Why it exists:** "Each user's count, compared to the average count" needs the same grouped result twice: once per row, once aggregated down to a single average. A subquery would mean writing that `GROUP BY` out twice (or nesting it awkwardly); a CTE names it once.

### Example

```sql
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT
    username,
    cnt,
    (SELECT AVG(cnt) FROM photo_counts) AS avg_cnt,
    cnt > (SELECT AVG(cnt) FROM photo_counts) AS above_average
FROM photo_counts
ORDER BY username;
```

**Result**

| username | cnt | avg_cnt | above_average |
|---|--:|--:|---|
| alex | 2 | 1.0 | t |
| bella | 1 | 1.0 | f |
| chris | 1 | 1.0 | f |
| dana | 0 | 1.0 | f |
| erin | 1 | 1.0 | f |

`photo_counts` is referenced **three times** — once as the main `FROM`, twice inside the `AVG(...)` subqueries — all defined in exactly one place. If the underlying logic ever needed to change (say, only counting photos from the last 30 days), it changes in one spot, not three.

### ⚠️ Traps

- **Reaching for a CTE purely out of habit, for a result only ever used once.** Topic 2 showed that case is identical either way — the reuse case in this topic is the actual reason to prefer one.

---

## Recap

| Concept | What it means |
|---|---|
| `WITH name AS (...)` | Names a result before the query that uses it |
| CTE vs subquery, single use | Identical result — pure style preference |
| CTE, referenced multiple times | The one case a subquery genuinely can't match without duplicating itself |

> **The one thing I want to remember:** a CTE isn't a different *kind* of query from a subquery — it's the same idea, given a name that can be reused. The name is the entire feature.

---

## Practice

**1.** Rewrite section 5's `HAVING COUNT(p.id) > 1` example (users with more than one photo) using a CTE instead of the direct `GROUP BY`/`HAVING`.

<details>
<summary>Show answer</summary>

```sql
WITH photo_counts AS (
    SELECT u.username, COUNT(p.id) AS cnt
    FROM users AS u
    LEFT JOIN photos AS p ON u.id = p.user_id
    GROUP BY u.username
)
SELECT username, cnt FROM photo_counts WHERE cnt > 1;
```

| username | cnt |
|---|--:|
| alex | 2 |

</details>

**2.** Why does `above_average` in topic 3's example use two separate `(SELECT AVG(cnt) FROM photo_counts)` subqueries instead of one column?

<details>
<summary>Show answer</summary>

Each is a genuinely separate scalar subquery, evaluated in its own expression position — `SELECT` can't share one subquery's value across two different output columns without repeating the reference. What *is* shared is `photo_counts` itself — defined once, read three times, never redefined.

</details>

**3.** Would `WITH photo_counts AS (...) SELECT * FROM photo_counts, photo_counts;` (referencing it twice in `FROM`) work, and what would it mean?

<details>
<summary>Show answer</summary>

It runs, but it's a Cartesian product of `photo_counts` against itself (section 4's comma-join trap) — 5 rows × 5 rows = 25, almost certainly not what was intended. Referencing a CTE more than once is fine; referencing it twice in the same `FROM` list without a join condition hits the exact same old-style-join pitfall as any other pair of tables.

</details>

---

## What confused me

- I expected a CTE to be a genuinely different mechanism from a subquery, performance included. Learning it's the same underlying operation, sometimes literally inlined by the planner into the equivalent subquery form, reframed it as a naming convenience rather than a distinct feature.
- The "why would I ever need this over a subquery" question didn't resolve until the reuse example. A single-use CTE really is just a style choice; the *first* time I needed the same computed result twice in one query is when the actual reason clicked.

---

[⬅ 24 · Advanced Query Tuning](../24-advanced-query-tuning/README.md) · [🏠 Index](../README.md) · [26 · Recursive Common Table Expressions ➡](../26-recursive-common-table-expressions/README.md)
