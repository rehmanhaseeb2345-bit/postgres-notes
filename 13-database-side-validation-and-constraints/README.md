<div align="center">

# 13 · Database-Side Validation and Constraints

**Part 2 — Data Types & Validation** · ✅ Done

</div>

> I've been quietly relying on constraints since section 3 — `NOT NULL`, `UNIQUE`, foreign keys — without ever asking *why* the database should be the one enforcing them instead of the app. This section is that question, plus the tools I hadn't used yet: `DEFAULT`, `CHECK`, and how to bolt any of this onto a table that already exists.

💾 Every query on this page is in [`examples.sql`](examples.sql). It uses `products`, rebuilt here with real constraints, and `user_profiles` from section 12.

### 📌 What's in here

| # | Topic | In one line |
|:-:|---|---|
| 1 | [Where validation should live](#1-where-validation-should-live) | The app can be bypassed; the database can't |
| 2 | [NOT NULL](#2-not-null) | A column that must always have a value |
| 3 | [DEFAULT values](#3-default-values) | What a column becomes when I don't specify it |
| 4 | [UNIQUE (single and multi-column)](#4-unique-single-and-multi-column) | No duplicates — of one column, or a combination |
| 5 | [CHECK constraints](#5-check-constraints) | Any condition a row must satisfy, including across columns |
| 6 | [Adding constraints to an existing table](#6-adding-constraints-to-an-existing-table) | Retrofitting rules onto data that already exists |
| ✔ | [Recap](#recap) · [Practice](#practice) · [What confused me](#what-confused-me) | |

---

## 1. Where validation should live

**What it is:** A choice between checking data in the application (before it's ever sent) and checking it in the database (right before it's stored) — and the answer, almost always, is both.

**Why it exists:** They protect against different things.

| Layer | Catches bad data from... | Feels like, to a user | Still enforced if... |
|---|---|---|---|
| App / frontend | Obvious typos, empty fields | An instant, friendly error message | ...only every write goes through that one app |
| Database | Literally anything | A blunt constraint-violation error | ...always — a script, a migration, a different app, direct `psql` access |

### Why I care about the database layer specifically

An app-level "email can't be blank" check is great UX. It does nothing at all the moment a second app, a data-import script, or a one-off `psql` session writes to the same table — none of them run the first app's validation code. A database constraint runs no matter *what* wrote the row.

### ⚠️ Traps

- **Treating app-level validation as sufficient on its own** → it's the friendly first line of defense, not the actual guarantee. The database constraint is what makes "this can never happen" an actual promise instead of a hope.

---

## 2. NOT NULL

**What it is:** Rejects any insert or update that would leave a column's value unset. Already in use since section 3 (`users.username`).

**Why it exists:** Some columns are meaningless empty — a photo with no `url` isn't a photo at all.

### Syntax

```sql
column_name TYPE NOT NULL
```

### Example

```sql
INSERT INTO products (name, category, price, stock) VALUES (NULL, 'Home', 10, 5);
```

**Result:** Rejected (once `name` is declared `NOT NULL`, rebuilt in topic 5).
```
ERROR:  null value in column "name" of relation "products" violates not-null constraint
```

### ⚠️ Traps

- **Assuming `NOT NULL` means "not empty."** An empty string `''` satisfies `NOT NULL` just fine — it's a real value, just an empty one. `NOT NULL` only blocks the *absence* of a value, not a technically-valid-but-useless one. `CHECK` (topic 5) is what catches that.

---

## 3. DEFAULT values

**What it is:** The value a column gets automatically when an `INSERT` doesn't mention it.

**Why it exists:** Some columns have an obvious, correct starting value — `stock` for a brand-new product is almost always `0`, not unknown.

### Syntax

```sql
column_name TYPE DEFAULT value
```

### Example

Already in use in `user_profiles` (section 12):

```sql
is_verified BOOLEAN NOT NULL DEFAULT FALSE
```

A `DEFAULT` can also be a function call, evaluated at insert time — rebuilding `products` with a creation timestamp:

```sql
created_at TIMESTAMP NOT NULL DEFAULT NOW()
```

```sql
INSERT INTO products (name, category, price, stock) VALUES ('Notebook', 'Stationery', 3.00, 500);
SELECT name, created_at FROM products WHERE name = 'Notebook';
```

**Result:** `created_at` is filled in automatically — whatever moment the `INSERT` actually ran, not a value I typed.

### ⚠️ Traps

- **Explicitly inserting `NULL` and expecting the `DEFAULT` to kick in instead.** It won't — `DEFAULT` only applies when a column is *omitted* entirely from the `INSERT`. Writing `INSERT INTO products (..., stock) VALUES (..., NULL)` stores an actual `NULL`, not `0`, even with `stock INTEGER DEFAULT 0` declared. (And if the column is also `NOT NULL`, that combination just fails outright.)

---

## 4. UNIQUE (single and multi-column)

**What it is:** Guarantees no two rows share the same value in a column — or, for multi-column `UNIQUE`, the same *combination* of values across several columns.

**Why it exists:** `users.username UNIQUE` (section 3) stops two accounts from claiming the same name. A future `likes` table needs a different shape of uniqueness: not "no duplicate `user_id`," but "this exact user can't like this exact photo twice."

### Syntax

```sql
column_name TYPE UNIQUE;                 -- single column
UNIQUE (column1, column2);               -- combination of columns
```

### Example — single column (recap)

```sql
INSERT INTO users (username) VALUES ('alex');
```
```
ERROR:  duplicate key value violates unique constraint "users_username_key"
```

### Example — multi-column

A minimal preview of the `likes` table from [15 · How to Build a 'Like' System](../15-how-to-build-a-like-system/README.md):

```sql
CREATE TABLE demo_likes (
    user_id  INTEGER,
    photo_id INTEGER,
    UNIQUE (user_id, photo_id)
);

INSERT INTO demo_likes VALUES (1, 101);   -- fine
INSERT INTO demo_likes VALUES (1, 101);   -- rejected: exact same combination
INSERT INTO demo_likes VALUES (1, 102);   -- fine: different photo
INSERT INTO demo_likes VALUES (2, 101);   -- fine: different user
```

The second `INSERT` fails — `(1, 101)` already exists. Neither `user_id` nor `photo_id` is unique *on its own* (both appear more than once across the table), only the **pair** has to be.

### ⚠️ Traps

- **Reaching for two separate single-column `UNIQUE`s to express "unique combination."** `UNIQUE (user_id, photo_id)` and `user_id UNIQUE, photo_id UNIQUE` mean completely different things — the second would mean *each user could like at most one photo, ever*, which isn't the rule I want at all.

---

## 5. CHECK constraints

**What it is:** A condition, written using ordinary SQL expressions, that every row must satisfy — not just "is this present" or "is this unique," but any rule at all, including ones spanning multiple columns.

**Why it exists:** `price >= 0` and `birth_date` being before `member_since` aren't things `NOT NULL` or `UNIQUE` can express — they need an actual condition.

### Syntax

```sql
column_name TYPE CHECK (condition);          -- one column
CHECK (condition_using_several_columns);      -- across columns
```

### Example — rebuilding products properly

This is the version `products` should have been since section 1:

```sql
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    name       VARCHAR(50)  NOT NULL,
    category   VARCHAR(30)  NOT NULL,
    price      NUMERIC(10, 2) CHECK (price >= 0),
    stock      INTEGER      NOT NULL DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

INSERT INTO products (name, category, price, stock) VALUES ('Broken Lamp', 'Home', -5, 10);
```

**Result:** Rejected.
```
ERROR:  new row for relation "products" violates check constraint "products_price_check"
```

### Example — a cross-column CHECK

Nobody should be able to join before they're born:

```sql
ALTER TABLE user_profiles
ADD CONSTRAINT birth_before_membership CHECK (birth_date < member_since);
```

**Result:** `ALTER TABLE` — all 3 existing rows already satisfy it (every user's `birth_date` is decades before their `member_since`), so this succeeds immediately with no data to fix.

### ⚠️ Traps

- **Assuming `CHECK` rejects `NULL`.** It doesn't. `price >= 0` evaluates to `NULL` (unknown) when `price` is `NULL`, and a `CHECK` only fails a row when its condition is definitely `FALSE` — `NULL` counts as "passes," the exact same three-valued logic from section 2. `Ballpoint Pen`'s unpriced row would sail through `CHECK (price >= 0)` untouched. `NOT NULL` is still the right tool if a value must always be present.

---

## 6. Adding constraints to an existing table

**What it is:** `ALTER TABLE` can add `NOT NULL`, `UNIQUE`, `CHECK`, or a foreign key to a table that's already been created and already has rows — not just at `CREATE TABLE` time.

**Why it exists:** Real schemas evolve. A rule I didn't think of in section 1 can still be added in section 13, on the same table, without rebuilding it from scratch.

### Syntax

```sql
ALTER TABLE table_name ALTER COLUMN column_name SET NOT NULL;
ALTER TABLE table_name ADD CONSTRAINT constraint_name CHECK (condition);
ALTER TABLE table_name ADD CONSTRAINT constraint_name UNIQUE (column_name);
```

### Example — existing data can block a new constraint

```sql
CREATE TABLE demo_ratings (score INTEGER);
INSERT INTO demo_ratings VALUES (5), (3), (-1);   -- -1 slipped in before I thought to validate it

ALTER TABLE demo_ratings ADD CONSTRAINT score_range CHECK (score BETWEEN 1 AND 5);
```

**Result:** Rejected.
```
ERROR:  check constraint "score_range" of relation "demo_ratings" is violated by some row
```

Postgres won't add a rule that the *existing* data already breaks. Fixing the bad row first makes it succeed:

```sql
UPDATE demo_ratings SET score = 1 WHERE score = -1;
ALTER TABLE demo_ratings ADD CONSTRAINT score_range CHECK (score BETWEEN 1 AND 5);
```

**Result:** `ALTER TABLE` — now that every row qualifies.

### ⚠️ Traps

- **Assuming a new `NOT NULL` behaves the same way** → it does, and for the same reason: `ALTER TABLE ... ALTER COLUMN x SET NOT NULL` fails outright if even one existing row currently has `x IS NULL`. Same rule, same fix — clean up the data, then add the constraint.

---

## Recap

| Tool | Enforces |
|---|---|
| `NOT NULL` | A value must always be present — but an empty string still counts as present |
| `DEFAULT value` | What an *omitted* column becomes — explicit `NULL` still overrides it |
| `UNIQUE (col)` | No duplicate values in that column |
| `UNIQUE (col1, col2)` | No duplicate *combinations* across those columns |
| `CHECK (condition)` | Any rule at all — but `NULL` passes it, same three-valued logic as `WHERE` |
| `ALTER TABLE ... ADD CONSTRAINT` | Retrofits any of the above onto an existing table — existing violations must be fixed first |

> **The one thing I want to remember:** app-side validation is for the user's experience; database-side validation is the actual guarantee. I want both, but only one of them is non-negotiable.

---

## Practice

**1.** Add a rule so `products.stock` can never be negative — assume the table already exists without it.

<details>
<summary>Show answer</summary>

```sql
ALTER TABLE products ADD CONSTRAINT stock_non_negative CHECK (stock >= 0);
```

</details>

**2.** Why does `CHECK (price >= 0)` allow a `NULL` price through, and what would actually stop `price` from being unset at all?

<details>
<summary>Show answer</summary>

`NULL >= 0` evaluates to `NULL`, not `FALSE`, and a `CHECK` constraint only rejects rows where the condition is definitely `FALSE` — `NULL` is treated as passing. To also require a price to be *present*, `price` needs `NOT NULL` in addition to the `CHECK`.

</details>

**3.** This fails — why, and how would you fix it?
```sql
ALTER TABLE user_profiles ALTER COLUMN bio SET NOT NULL;
```

<details>
<summary>Show answer</summary>

`bella`'s `bio` is already `NULL` in the seed data, and `ALTER TABLE ... SET NOT NULL` refuses to apply while any existing row violates it:
```
ERROR:  column "bio" of relation "user_profiles" contains null values
```
Fix the existing row first (`UPDATE user_profiles SET bio = '' WHERE bio IS NULL;`, or give it real content), then re-run the `ALTER TABLE`.

</details>

---

## What confused me

- I assumed `NOT NULL` meant "must be a real, meaningful value." It only means "must be present" — an empty string sails right through, which is why `CHECK` and `NOT NULL` are different tools solving different problems.
- I expected `CHECK` to behave like `WHERE` in the sense of rejecting anything not definitively true. It actually only rejects definite `FALSE` — a `NULL` result passes, which caught me off guard until I connected it back to the exact same three-valued logic from section 2.
- Explicitly inserting `NULL` into a column with a `DEFAULT` not falling back to that default felt wrong at first. `DEFAULT` only fires when the column is left out of the statement entirely — an explicit `NULL` is still a value I chose to provide.
- I thought adding a constraint to an existing table would just quietly start applying "from now on." It doesn't — Postgres checks it against every row that's already there, immediately, and refuses the whole operation if any of them fail.

---

[⬅ 12 · PostgreSQL Complex Datatypes](../12-postgresql-complex-datatypes/README.md) · [🏠 Index](../README.md) · [14 · Database Structure Design Patterns ➡](../14-database-structure-design-patterns/README.md)
