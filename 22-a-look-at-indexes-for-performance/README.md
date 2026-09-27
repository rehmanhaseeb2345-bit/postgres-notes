# 22 · A Look at Indexes for Performance

> **Part 4 — Complex Queries & Performance**  
> How indexes make lookups fast, and what they cost.

**Status:** ⬜ Haven't written this one up yet. Coming soon!

---

## What I'll cover here

- [ ] The problem: full table scans
- [ ] What an index is
- [ ] How a B-tree index finds a row
- [ ] Creating and dropping indexes
- [ ] Benchmarking with and without an index
- [ ] Downsides of indexes
- [ ] Index types
- [ ] Indexes Postgres creates automatically

<!--
Write each topic below using the structure in TEMPLATE.md:
## Topic name → Definition → Why it exists → Syntax → Example → Result
→ Visual (optional) → ⚠️ Traps → 🧪 Try it
Tick the box above when a topic is done.
-->

---

[⬅ 21 · Understanding the Internals of PostgreSQL](../21-understanding-the-internals-of-postgresql/README.md) · [🏠 Index](../README.md) · [23 · Basic Query Tuning ➡](../23-basic-query-tuning/README.md)
