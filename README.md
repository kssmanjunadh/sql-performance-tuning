# SQL Performance Tuning – Personal Project

This project demonstrates the process of identifying and fixing slow queries in a relational database. It covers:

- Designing a normalized schema for an e‑commerce store.
- Generating realistic test data (50k customers, 500 products, 100k orders, 200k order items).
- Writing complex analytical queries (monthly sales, top customers, inactive customers, low stock alerts).
- Analysing execution plans using `EXPLAIN ANALYZE`.
- Applying indexing strategies (B‑tree, composite, covering indexes).
- Creating stored procedures for automated reporting and data validation.

## Requirements

- PostgreSQL 13 or higher
- `pg_stat_statements` extension (optional, for deeper analysis)

## Setup

1. Create a database: `CREATE DATABASE performance_tuning;`
2. Connect to it: `\c performance_tuning`
3. Run scripts in order:
   - `sql/01_schema.sql`
   - `sql/02_data.sql`  (this may take 2‑5 minutes)
   - `sql/03_queries.sql`  – run the queries and note their execution times.
   - `sql/04_optimization.sql` – apply indexes and re‑run queries; compare plans.
   - `sql/05_stored_procedures.sql` – create procedures and test them.

To clean up: `sql/06_drop.sql`

## Observations

- Query 1 (Monthly sales by category) improved from ~3.5s to ~150ms after indexing.
- Query 2 (Top 10 customers) improved from ~1.2s to ~80ms.
- The stored procedure for monthly report now runs in under 200ms.

## Learning Outcomes

- The importance of covering indexes for large fact tables.
- How to read `EXPLAIN` output (Seq Scan vs Index Scan, sort costs, buffer usage).
- Balancing index maintenance overhead against query performance.
