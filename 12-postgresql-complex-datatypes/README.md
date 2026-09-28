<div align="center">

# 12 · PostgreSQL Complex Datatypes

**Part 2 — Data Types & Validation** · ✅ Done

</div>

> I've been leaning on `VARCHAR` and `INTEGER` for everything since section 1, with a standing note that real prices need `NUMERIC`, not `INTEGER`. This is the section where that finally gets explained properly — and where I build the `user_profiles` table section 3 promised, which needs almost every type in this list.

💾 Every query on this page is in [`examples.sql`](examples.sql). It adds a new `user_profiles` table on top of the shared `sample-db/` schema.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Data type categories at a glance](#1-data-type-categories-at-a-glance) | The map before the details |
| 2 | [Integers: SMALLINT, INTEGER, BIGINT, SERIAL](#2-integers-smallint-integer-bigint-serial) | Same idea, different ranges and storage |
| 3 | [Exact vs floating-point numbers](#3-exact-vs-floating-point-numbers) | Why `price` should never have been `INTEGER` — or `REAL` |
| 4 | [Text: CHAR, VARCHAR, TEXT](#4-text-char-varchar-text) | Fixed-width, limited, or unlimited |
| 5 | [BOOLEAN](#5-boolean) | Three states, not two: true, false, unknown |
| 6 | [Dates, times and time zones](#6-dates-times-and-time-zones) | The type that almost always needs a time zone attached |
| 7 | [INTERVAL and date math](#7-interval-and-date-math) | Durations, and doing arithmetic on time itself |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Data type categories at a glance

**What it is:** Postgres's types group into a handful of families — I don't need to memorize all of them, just know which family a job calls for.

**Why it exists:** Picking a type isn't just "does the value fit" — it decides how much space it uses, what math is safe, and what mistakes become impossible versus silent.

| Category | Examples | Roughly: |
|---|---|---|
| Whole numbers | `SMALLINT`, `INTEGER`, `BIGINT`, `SERIAL` | Counting things |
| Numbers with decimals | `NUMERIC`, `REAL`, `DOUBLE PRECISION` | Measuring things |
| Text | `CHAR`, `VARCHAR`, `TEXT` | Words |
| True/false | `BOOLEAN` | Yes/no, with a third option: unknown |
| Points in time | `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMPTZ` | When |
| Durations | `INTERVAL` | How long |

---

## 2. Integers: SMALLINT, INTEGER, BIGINT, SERIAL

**What it is:** Three whole-number types differing only in storage size and range, plus `SERIAL`, which isn't really its own type — it's `INTEGER` with an auto-incrementing default bolted on (section 3).

**Why it exists:** A `SMALLINT` and a `BIGINT` both hold whole numbers, but a table of a billion rows using `BIGINT` ids everywhere wastes real space compared to `INTEGER`, while a counter that might one day exceed 2 billion needs `BIGINT` from the start — retrofitting it later means rewriting every foreign key that points at it.

### The three sizes

| Type | Storage | Range |
|---|--:|---|
| `SMALLINT` | 2 bytes | -32,768 to 32,767 |
| `INTEGER` | 4 bytes | about -2.1 billion to 2.1 billion |
| `BIGINT` | 8 bytes | about -9.2 quintillion to 9.2 quintillion |

### Example

```sql
CREATE TABLE stock_check (level SMALLINT);
INSERT INTO stock_check VALUES (40000);
```

**Result:** Rejected.
```
ERROR:  smallint out of range
```

`40000` is bigger than `SMALLINT`'s maximum of `32,767` — `stock` back in `products` has always been `INTEGER` for exactly this reason; a popular product's stock count could plausibly outgrow `SMALLINT`.

### ⚠️ Traps

- **Defaulting to `BIGINT` everywhere "just in case"** → it works, but doubles storage for every row and every index on that column, for a ceiling I'm extremely unlikely to need on something like a small lookup table. `INTEGER` (and `SERIAL`) is the right default; `BIGINT` is for a specific, justified reason — like an id column I genuinely expect to pass 2 billion.

---

## 3. Exact vs floating-point numbers

**What it is:** `NUMERIC` stores decimal numbers **exactly**, as digits — no rounding error, ever, at the cost of being slower to compute with. `REAL` and `DOUBLE PRECISION` store approximations using binary floating-point, the same representation almost every programming language uses for decimals — fast, but not exact.

**Why it exists:** This is the type section 1 kept pointing forward to. `products.price` has been `INTEGER` this whole course specifically to dodge this topic until now — real prices need decimals, and *which* decimal type matters far more than it looks.

### The classic demonstration

```sql
SELECT 0.1::DOUBLE PRECISION + 0.2::DOUBLE PRECISION AS float_math,
       0.1::NUMERIC        + 0.2::NUMERIC        AS exact_math;
```

**Result**

| float_math | exact_math |
|---|---|
| 0.30000000000000004 | 0.3 |

Both start from the same two numbers. `DOUBLE PRECISION` can't represent `0.1` or `0.2` exactly in binary — it stores the closest approximation of each, and the tiny errors show up the moment they're added. `NUMERIC` stores `0.1` and `0.2` as literal decimal digits, so the addition is exact.

### ⚠️ Traps

> [!WARNING]
> **Never use `REAL`/`DOUBLE PRECISION` for money.** The error above is small, but it compounds — summing thousands of floating-point prices can drift by real, visible cents. `NUMERIC` (optionally `NUMERIC(precision, scale)`, like `NUMERIC(10, 2)` for "up to 10 digits total, 2 after the decimal point") is the correct type for anything financial. `products.price` should have been `NUMERIC(10, 2)` since section 1 — I kept it as `INTEGER` purely to avoid this exact tangent until now.
- **Assuming `NUMERIC` is always the better choice** → it isn't, for everything. Scientific/statistical calculations over millions of rows often *want* the speed of `DOUBLE PRECISION` and can tolerate its tiny imprecision. Money and counts of things can't tolerate it; measurements and averages often can.

---

## 4. Text: CHAR, VARCHAR, TEXT

**What it is:** `VARCHAR(n)` stores text up to `n` characters (used throughout this course so far). `TEXT` is the same thing with no length limit at all. `CHAR(n)` stores *exactly* `n` characters, padding shorter values with trailing spaces.

**Why it exists:** For genuinely fixed-width data (a 2-letter country code, say), `CHAR(n)` documents that intent. For almost everything else — names, urls, comments — `VARCHAR`/`TEXT` are what I actually want; Postgres doesn't even have a performance difference between them the way some databases do.

### Example — the padding trap

```sql
SELECT 'Home'::CHAR(10) || '!' AS padded;
```

**Result**

| padded |
|---|
| Home      ! |

`'Home'` (4 characters) got padded out to the full 10 before the `!` was appended — 6 invisible trailing spaces are now sitting in the middle of that string. `VARCHAR(10)` or `TEXT` would have produced `'Home!'`, with nothing extra.

### ⚠️ Traps

- **Using `CHAR(n)` out of habit for ordinary text** → the padding is real, stored data, not just a display quirk — string operations like concatenation carry it forward, exactly as shown above. Comparisons (`=`) do ignore trailing spaces on `CHAR` values, which almost makes the padding invisible right up until an operation like this one exposes it.

---

## 5. BOOLEAN

**What it is:** True/false — except `NULL` is always a third, valid state: "unknown," not "false."

**Why it exists:** `is_verified` on a new `user_profiles` row genuinely might not be decided yet — that's different information from "definitely not verified," and only a nullable `BOOLEAN` can hold both.

### Syntax

```sql
column_name BOOLEAN
```

### Example

Postgres accepts several spellings for boolean literals, as **text**:

```sql
SELECT TRUE, 'true'::boolean, 't'::boolean, 'yes'::boolean, 'no'::boolean;
```

**Result:** `t`, `t`, `t`, `t`, `f` — all valid.

### ⚠️ Traps

- **Assuming a plain integer casts to boolean the same way the text `'1'` does.**
  ```sql
  SELECT 1::boolean;
  ```
  ```
  ERROR:  cannot cast type integer to boolean
  ```
  `'1'::boolean` (the **text** `'1'`) works — Postgres is parsing it as one of the recognized boolean spellings. The actual integer `1` has no such cast defined at all. Text and number look similar here but aren't interchangeable.
- **Filtering with `WHERE is_verified = false` and expecting it to include unset rows** → a `NULL` `is_verified` isn't `false`, it's unknown — same three-valued logic as every other column, all the way back to section 2. `WHERE is_verified IS NOT TRUE` is what actually means "false or unknown."

---

## 6. Dates, times and time zones

**What it is:** `DATE` (just a calendar day), `TIME` (just a clock time), `TIMESTAMP` (date + time, no time zone), and `TIMESTAMPTZ` (date + time, stored and compared with time zone awareness).

**Why it exists:** `member_since` only needs a day — `DATE` is enough. `last_login` needs to be unambiguous no matter what time zone the reader *or* the server is in — that's what `TIMESTAMPTZ` is for.

### Example

```sql
CREATE TABLE user_profiles (
    user_id      INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bio          TEXT,
    is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    birth_date   DATE,
    member_since TIMESTAMP NOT NULL,
    last_login   TIMESTAMPTZ
);

INSERT INTO user_profiles (user_id, bio, is_verified, birth_date, member_since, last_login)
VALUES
    (1, 'Photographer and coffee addict', TRUE,  '1995-03-14', '2024-01-10', '2026-09-20 14:30:00+00'),
    (2, NULL,                             FALSE, '1998-07-22', '2024-02-15', '2026-09-25 09:15:00+00'),
    (3, 'Just here for the photos',       FALSE, '1990-11-02', '2023-11-01', '2026-09-18 20:00:00+00');
```

`dana` and `erin` don't have rows here at all — a one-to-one relationship (section 3) doesn't require every parent to have a child, and `user_id` being the **primary key** here (not just a `UNIQUE` foreign key) is actually the cleaner way to express "at most one profile per user" than the separate `UNIQUE` constraint section 3 originally suggested.

`TIMESTAMPTZ` stores `+00` (UTC) internally regardless of what offset I typed in — it's displayed converted to whatever time zone the current session is set to:

```sql
SET TIME ZONE 'America/New_York';
SELECT last_login FROM user_profiles WHERE user_id = 1;
```

**Result:** `2026-09-20 10:30:00-04` — the exact same instant, displayed 4 hours earlier, because `America/New_York` was `UTC-4` on that date.

### ⚠️ Traps

- **Using plain `TIMESTAMP` for anything that involves more than one time zone.** It stores exactly the digits I gave it, with zero awareness of what zone they were in — two users logging in "at 2:00 PM" in different countries would store identical, indistinguishable values. `TIMESTAMPTZ` is almost always the right default for real-world event times; plain `TIMESTAMP` is really only safe for things that are inherently zone-less, like `member_since` here, where I only care about the calendar day.

---

## 7. INTERVAL and date math

**What it is:** `INTERVAL` is a duration — "3 days," "6 months," "1 year 2 months 3 days." Postgres can add or subtract an `INTERVAL` to/from a date or timestamp, and can compute the `INTERVAL` *between* two of them with `AGE()` or plain subtraction.

**Why it exists:** "When does this renew" and "how long ago was that" are both date-math questions that come up constantly.

### Syntax

```sql
date_or_timestamp + INTERVAL 'n unit'
AGE(later_timestamp, earlier_timestamp)
```

### Example — adding an interval

```sql
SELECT member_since, member_since + INTERVAL '1 year' AS first_renewal
FROM user_profiles WHERE user_id = 1;
```

**Result**

| member_since | first_renewal |
|---|---|
| 2024-01-10 00:00:00 | 2025-01-10 00:00:00 |

### Example — the gap between two dates

```sql
SELECT (SELECT member_since FROM user_profiles WHERE user_id = 1)
     - (SELECT member_since FROM user_profiles WHERE user_id = 3) AS gap;
```

**Result**

| gap |
|---|
| 70 days |

`alex` joined 70 days after `chris` — subtracting two timestamps produces an `INTERVAL` directly.

### Example — age, as of a fixed date

Using a fixed reference date (rather than `CURRENT_DATE`) keeps this result exact and reproducible no matter when it's read:

```sql
SELECT user_id, AGE(DATE '2026-09-28', birth_date) AS age
FROM user_profiles
ORDER BY user_id;
```

**Result**

| user_id | age |
|--:|---|
| 1 | 31 years 6 mons 14 days |
| 2 | 28 years 2 mons 6 days |
| 3 | 35 years 10 mons 26 days |

### ⚠️ Traps

- **Using `CURRENT_DATE`/`NOW()` in an example and expecting the result to stay fixed** → it won't; that's *why* the age example above pins the reference date explicitly with `DATE '2026-09-28'` instead. A real application almost always wants `AGE(CURRENT_DATE, birth_date)` — I just can't write down one "correct" result for that in notes I'll read again later.

---

## Recap

| Type | Use it for |
|---|---|
| `SMALLINT` / `INTEGER` / `BIGINT` | Whole numbers; pick by range, default to `INTEGER` |
| `NUMERIC(p, s)` | Exact decimals — money, anything that can't tolerate rounding drift |
| `REAL` / `DOUBLE PRECISION` | Approximate decimals — fast, fine for measurements, never for money |
| `VARCHAR(n)` / `TEXT` | Text — `TEXT` when there's no real limit to enforce |
| `CHAR(n)` | Genuinely fixed-width text only — the padding is real and gets carried into concatenation |
| `BOOLEAN` | True/false — remembering `NULL` is a valid third state |
| `DATE` | A calendar day, no time or zone |
| `TIMESTAMPTZ` | A precise moment, zone-aware — the default choice for real-world event times |
| `INTERVAL` | A duration — add/subtract against dates, or the result of subtracting two of them |

> **The one thing I want to remember:** `0.1 + 0.2 ≠ 0.3` in floating point, exactly, everywhere, in every language that uses it — not a Postgres quirk. `NUMERIC` exists specifically so I never have to think about that for money.

---

## Practice

**1.** Add a birth year check: is `chris` over 30, as of `2026-09-28`?

<details>
<summary>Show answer</summary>

```sql
SELECT user_id, AGE(DATE '2026-09-28', birth_date) > INTERVAL '30 years' AS over_30
FROM user_profiles WHERE user_id = 3;
```

| user_id | over_30 |
|--:|---|
| 3 | t |

(`35 years 10 mons 26 days` is greater than `30 years`.)

</details>

**2.** Which type would you use for a `latitude`/`longitude` pair on a future "photo location" feature, and why?

<details>
<summary>Show answer</summary>

`NUMERIC`, not `REAL`/`DOUBLE PRECISION` — coordinates that drift by floating-point error can shift a location by a visible amount after repeated calculations, and there's no performance-critical reason here to trade away exactness.

</details>

**3.** What's wrong with declaring a `country_code` column as `VARCHAR(2)` and inserting `'USA'`?

<details>
<summary>Show answer</summary>

`'USA'` is 3 characters, over the `VARCHAR(2)` limit:
```
ERROR:  value too long for type character varying(2)
```
Same trap as section 1's `VARCHAR(50)` name limit — Postgres won't silently truncate it.

</details>

---

## What confused me

- I genuinely expected `0.1 + 0.2` to just equal `0.3` in a database. Seeing `0.30000000000000004` printed out was the moment `NUMERIC` stopped being "the type the notes told me to use for money" and started being "the type that actually avoids a real, visible bug."
- `CHAR(n)`'s trailing-space padding felt harmless until the concatenation example. Equality comparisons quietly ignoring the padding almost hid the problem from me entirely.
- I didn't expect `1::boolean` (the number) and `'1'::boolean` (the text) to behave differently. They look like the same value; only one of them is a recognized boolean spelling.
- `TIMESTAMP` vs `TIMESTAMPTZ` seemed like a minor naming difference at first. It isn't — one of them knows what moment in time it represents regardless of where you're reading it from, and the other one doesn't know at all.

---

[⬅ 11 · Utility Operators, Keywords, and Functions](../11-utility-operators-keywords-and-functions/README.md) · [🏠 Index](../README.md) · [13 · Database-Side Validation and Constraints ➡](../13-database-side-validation-and-constraints/README.md)
