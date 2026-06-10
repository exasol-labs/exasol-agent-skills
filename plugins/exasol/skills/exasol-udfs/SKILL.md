---
name: exasol-udfs
description: "Exasol User Defined Functions (UDFs) and Script Language Containers (SLCs). Covers CREATE SCRIPT, SCALAR and SET functions, ExaIterator API, Python/Java/Lua/R scripts, BucketFS file access, GPU-accelerated UDFs, and building/deploying custom Script Language Containers with exaslct."
---

# Exasol UDFs & Script Language Containers

Trigger when the user mentions **UDF**, **user defined function**, **CREATE SCRIPT**, **ExaIterator**, **SCALAR**, **SET EMITS**, **BucketFS**, **script language container**, **SLC**, **exaslct**, **ScriptLanguageContainer**, **get_activation_sql**, **open_pyexasol_connection_with_lang_definitions**, **custom packages**, **GPU UDF**, **ctx.emit**, **ctx.next**, **variadic script**, **dynamic parameters**, **EMITS(...)**, **default_output_columns**, or any UDF/SLC-related topic.

## When to Use UDFs

Use UDFs to extend SQL with custom logic that runs inside the Exasol cluster:
- Per-row transforms (cleaning, parsing, hashing)
- Custom aggregation across grouped rows
- ML model inference (load model from BucketFS, score rows)
- Calling external APIs from within SQL
- Batch processing with DataFrames

## SCALAR vs SET Decision Guide

| | SCALAR | SET |
|---|--------|-----|
| **Input** | One row at a time | Group of rows (via GROUP BY) |
| **Output** | `RETURNS <type>` (single value) | `EMITS (col1 TYPE, ...)` (zero or more rows) |
| **Row iteration** | Not needed | `ctx.next()` loop required |
| **SQL usage** | `SELECT udf(col) FROM t` | `SELECT udf(col) FROM t GROUP BY key` |
| **Use case** | Per-row transforms | Aggregation, ML batch predict, multi-row emit |

## Language Selection

| Language | Startup | Best For | Expandable via SLC? |
|----------|---------|----------|---------------------|
| **Python 3** (3.10 or 3.12) | ~200ms | ML, data science, pandas, string processing | Yes |
| **Java** (11 or 17) | ~1s | Enterprise libs, type safety, Virtual Schema adapters | Yes |
| **Lua 5.4** | <10ms | Low-latency transforms, row-level security | No |
| **R** (4.4) | ~200ms | Statistical modeling, R model deployment | Yes |

## CREATE SCRIPT Syntax

### Python SCALAR

```sql
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT my_schema.clean_text(input VARCHAR(10000))
RETURNS VARCHAR(10000) AS
import re
def run(ctx):
    if ctx.input is None:
        return None
    return re.sub(r"[^\w\s]", "", ctx.input).strip().lower()
/

SELECT clean_text(description) FROM products;
```

### Python SET

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT my_schema.top_n(
    item VARCHAR(200), score DOUBLE, n INT
)
EMITS (item VARCHAR(200), score DOUBLE) AS
def run(ctx):
    rows = []
    limit = ctx.n
    while True:
        rows.append((ctx.item, ctx.score))
        if not ctx.next():
            break
    rows.sort(key=lambda x: x[1], reverse=True)
    for item, score in rows[:limit]:
        ctx.emit(item, score)
/

SELECT top_n(product, revenue, 5) FROM sales GROUP BY category;
```

## ExaIterator API Quick Reference

### Python

| Method/Property | SCALAR | SET | Description |
|----------------|--------|-----|-------------|
| `ctx.<column>` | yes | yes | Access input column value |
| `return value` | yes | no | Return single value (RETURNS) |
| `ctx.emit(v1, v2, ...)` | no | yes | Emit output row (EMITS) |
| `ctx.emit(dataframe)` | no | yes | Emit DataFrame as rows |
| `ctx.next()` | no | yes | Advance to next row; returns `False` at end |
| `ctx.size()` | no | yes | Number of rows in current group |
| `ctx.reset()` | no | yes | Reset iterator to first row |
| `ctx.get_dataframe(num_rows, start_col)` | no | yes | Get rows as pandas DataFrame |

### Quick Activation

When the user asks specifically for Notebook Connector SLC APIs, also load:

- `references/notebook-connector-slc.md`

```sql
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///<bfs-name>/<bucket>/<path>/<container>?lang=python#buckets/<bfs-name>/<bucket>/<path>/<container>/exaudf/exaudfclient_py3';
```

## Related Skills

- **exasol-bucketfs**: For uploading JARs, models, and SLC archives to BucketFS.
- **exasol-database**: For SQL execution, schema management, and related DB work around UDFs.
