# My topic template

I copy this block every time I write up a new topic, so every page in my notes looks and reads the same.

````markdown
## Topic name

**What it is:** One or two plain sentences.

**Why it exists:** The problem it solves, in one or two sentences.

### Syntax

```sql
KEYWORD column_name
FROM table_name;
```

### Example

What this example does, in one sentence.

```sql
SELECT username
FROM users
WHERE id = 1;
```

**Result**

| username |
|---|
| alex |

### Visual *(optional)*

```mermaid
flowchart LR
  A[Step one] --> B[Step two]
```

### ⚠️ Traps

- The mistake → what happens → how to avoid it.

### Practice

> A small exercise.

<details>
<summary>Show answer</summary>

```sql
-- answer here
```

</details>
````

## My rules for writing

- Plain English and short sentences, written the way I'd explain it to a friend.
- I run every example in Postgres before writing it down. No untested queries.
- SQL keywords in UPPERCASE, table and column names in lowercase.
- Use **bold** only for the one idea to remember.
- Use Mermaid for diagrams so they render on GitHub and Notion.
- Mark "nice-to-know" topics clearly so they can be skipped.
