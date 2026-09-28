<div align="center">

# 28 · Optimizing Queries with Materialized Views

**Part 5 — Advanced Querying** · ✅ Done

</div>

> Section 17 hand-rolled a `hashtags.post_count` column, kept in sync by whatever code inserts or deletes a `hashtags_posts` row. A materialized view is Postgres's real, built-in version of that same idea — a stored, cached result, instead of application code promising to keep a column honest.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses the full `sample-db/` schema.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Views vs materialized views](#1-views-vs-materialized-views) | Re-run every time, vs stored and stale until refreshed |
| 2 | [Creating a materialized view](#2-creating-a-materialized-view) | Section 17's hashtag counts, done properly |
| 3 | [REFRESH MATERIALIZED VIEW](#3-refresh-materialized-view) | Watching it actually go stale, then fixing it |
| 4 | [When to use one](#4-when-to-use-one) | Expensive, read-often, staleness-tolerant |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Views vs materialized views

**What it is:** A regular view (section 27) re-runs its query on every read — always current, zero storage. A **materialized** view runs its query **once**, stores the actual result on disk like a real table, and keeps serving that stored copy until explicitly told to refresh.

**Why it exists:** Some queries are expensive enough, and read often enough, that re-running them on every single access (a plain view's whole deal) is wasteful — especially when the answer doesn't need to be instantly current.

| | View | Materialized view |
|---|---|---|
| Storage | None — just the query definition | The actual result, on disk |
| Freshness | Always current | Frozen as of the last `REFRESH` |
| Read cost | Full query, every time | A stored-table read — cheap |
| Write cost | None | Cost of the full query, paid at `REFRESH` time |

---

## 2. Creating a materialized view

**What it is:** `CREATE MATERIALIZED VIEW`, otherwise identical syntax to a view.

**Why it exists:** "How many posts use each hashtag" is exactly section 17's example — a query worth caching, since trending-hashtag reads happen far more often than the underlying tags change.

### Syntax

```sql
CREATE MATERIALIZED VIEW view_name AS SELECT ...;
```

### Example

```sql
CREATE MATERIALIZED VIEW hashtag_stats AS
SELECT h.name, COUNT(*) AS post_count
FROM hashtags AS h
JOIN hashtags_posts AS hp ON h.id = hp.hashtag_id
GROUP BY h.name;

SELECT * FROM hashtag_stats ORDER BY name;
```

**Result**

| name | post_count |
|---|--:|
| beach | 1 |
| coffee | 1 |
| summer | 1 |
| sunset | 1 |

---

## 3. REFRESH MATERIALIZED VIEW

**What it is:** The command that re-runs the stored query and replaces the materialized view's contents — nothing else updates it.

**Why it exists:** Proving the "frozen until refreshed" behavior from topic 1 directly, instead of just trusting the description.

### Example

```sql
INSERT INTO hashtags_posts (hashtag_id, photo_id)
SELECT id, 103 FROM hashtags WHERE name = 'summer';   -- #summer now also tags coffee.jpg

SELECT post_count FROM hashtag_stats WHERE name = 'summer';
```

**Result:** still `1` — the real `hashtags_posts` table has genuinely changed, but `hashtag_stats` hasn't noticed, because nothing has told it to.

```sql
REFRESH MATERIALIZED VIEW hashtag_stats;
SELECT post_count FROM hashtag_stats WHERE name = 'summer';
```

**Result:** now `2`.

### ⚠️ Traps

> [!WARNING]
> **A materialized view is genuinely stale data until someone refreshes it.** Nothing refreshes it automatically — not `INSERT`, not `UPDATE`, not time passing. Whatever process depends on it being reasonably current (a cron job, a scheduled task, a manual `REFRESH`) has to actually exist, or it silently drifts further from reality forever.
- **`REFRESH MATERIALIZED VIEW` locks the view against reads while it rebuilds**, by default. `REFRESH MATERIALIZED VIEW CONCURRENTLY view_name;` allows reads to continue during the refresh — but it requires a `UNIQUE` index on the materialized view first, and is slower than the plain version.

---

## 4. When to use one

**What it is:** The specific combination that makes a materialized view worth its staleness: **expensive to compute**, **read often**, and **tolerant of being slightly out of date**.

**Why it exists:** Getting any one of those three wrong points somewhere else instead.

| If the query is... | Reach for |
|---|---|
| Cheap, or rarely read | A plain view (section 27), or just the query itself |
| Expensive, read often, staleness is fine | A materialized view, refreshed on a schedule |
| Expensive, read often, must always be current | Real optimization — an index (section 22), a better query (sections 20/23/24) |

### ⚠️ Traps

- **Using a materialized view where correctness can't tolerate any staleness at all.** "Does this user currently have enough balance for this transaction" needs the real, current answer — a materialized view refreshed every 10 minutes is actively the wrong tool there, not just a suboptimal one.

---

## Recap

| Concept | What it means |
|---|---|
| Materialized view | A view's query, run once, stored physically like a table |
| `CREATE MATERIALIZED VIEW` | Same syntax as a view, different storage behavior |
| `REFRESH MATERIALIZED VIEW` | The only thing that updates it — nothing else does |
| `REFRESH ... CONCURRENTLY` | Non-blocking refresh, needs a `UNIQUE` index first |
| Right fit | Expensive + read-often + staleness-tolerant, all three at once |

> **The one thing I want to remember:** a materialized view doesn't "get slow to update" — it simply doesn't update at all, ever, without an explicit `REFRESH`. Treating it as anything other than deliberately-stale-until-refreshed is how section 17's `post_count` drift problem comes right back, just wearing different syntax.

---

## Practice

**1.** After the `REFRESH` in topic 3, `bella` deletes her `hashtags_posts` row linking `#summer` to `coffee.jpg`. What does `SELECT post_count FROM hashtag_stats WHERE name = 'summer';` show immediately afterward?

<details>
<summary>Show answer</summary>

**Still `2`.** The materialized view only reflects the state of `hashtags_posts` as of the *last* `REFRESH` — the delete doesn't touch it until `REFRESH MATERIALIZED VIEW hashtag_stats;` runs again.

</details>

**2.** Why does `REFRESH MATERIALIZED VIEW CONCURRENTLY` need a `UNIQUE` index on the materialized view first, when the plain `REFRESH` doesn't?

<details>
<summary>Show answer</summary>

The concurrent version has to compare the old stored rows against the newly computed ones to figure out exactly what changed, row by row, while still allowing reads of the old version — it needs a way to uniquely match up "this old row" with "this new row," which is exactly what a `UNIQUE` index provides. The plain version just locks the whole thing and replaces it wholesale, with no need to match anything up.

</details>

**3.** Would a materialized view be the right choice for `photo_stats` (section 27) if the app needed the *exact current* like count the instant someone likes a photo?

<details>
<summary>Show answer</summary>

**No.** A like count that needs to be instantly current the moment a like happens fails the "staleness-tolerant" requirement — a plain view (always current, section 27) or a direct query is the right fit; a materialized view would show a stale count until its next scheduled `REFRESH`.

</details>

---

## What confused me

- I expected some Postgres background process to eventually notice `hashtags_posts` changed and refresh the materialized view on its own. Nothing does, ever — it's entirely manual (or manually scheduled) unless I trigger a `REFRESH` myself.
- I originally reached for `CONCURRENTLY` as if it were just a "make it faster" flag. It solves a completely different problem — not refresh speed, but whether *reads* are blocked *during* that refresh — and it comes with its own prerequisite (a `UNIQUE` index) I hadn't anticipated needing.
- Section 17 made a denormalized counter feel like a slightly risky, hand-rolled trick. Seeing the same idea as a first-class Postgres feature — with an explicit, honest "this is stale until refreshed" contract instead of hoping app code stays correct — made it feel like the more trustworthy version of the same idea, not a different one.

---

[⬅ 27 · Simplifying Queries with Views](../27-simplifying-queries-with-views/README.md) · [🏠 Index](../README.md) · [29 · Handling Concurrency and Reversibility with Transactions ➡](../29-handling-concurrency-and-reversibility-with-transactions/README.md)
