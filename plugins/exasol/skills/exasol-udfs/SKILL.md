---
name: exasol-udfs
description: "Exasol User Defined Functions (UDFs) and Script Language Containers (SLCs). Covers CREATE SCRIPT, SCALAR and SET functions, ExaIterator API, Python/Java/Lua/R scripts, BucketFS file access, GPU-accelerated UDFs, and building/deploying custom Script Language Containers with exaslct."
---

# Exasol UDFs & Script Language Containers

Trigger when the user mentions **UDF**, **user defined function**, **CREATE SCRIPT**, **ExaIterator**, **SCALAR**, **SET EMITS**, **BucketFS**, **script language container**, **SLC**, **exaslct**, **custom packages**, **GPU UDF**, **ctx.emit**, **ctx.next**, or any UDF/SLC-related topic.

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
| **Lua 5.4** | <10ms | Low-latency transforms, row-level security | No (natively compiled into Exasol) |
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
    return re.sub(r'[^\w\s]', '', ctx.input).strip().lower()
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

### Java SCALAR

```sql
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.hash_value(input VARCHAR(2000))
RETURNS VARCHAR(64) AS
import java.security.MessageDigest;

class HASH_VALUE {
    static String run(ExaMetadata exa, ExaIterator ctx) throws Exception {
        String input = ctx.getString("input");
        if (input == null) return null;
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(input.getBytes("UTF-8"));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) hex.append(String.format("%02x", b));
        return hex.toString();
    }
}
/
```

### Java with External JARs

```sql
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.custom(input VARCHAR(2000))
RETURNS VARCHAR(2000) AS
  %scriptclass com.mycompany.MyProcessor;
  %jar /buckets/bfsdefault/default/jars/my-lib.jar;
/
```

### Lua SCALAR

```sql
CREATE OR REPLACE LUA SCALAR SCRIPT my_schema.my_avg(a DOUBLE, b DOUBLE)
RETURNS DOUBLE AS
function run(ctx)
    if ctx.a == nil or ctx.b == nil then return null end
    return (ctx.a + ctx.b) / 2
end
/
```

### R SET (ML Prediction)

```sql
CREATE OR REPLACE R SET SCRIPT my_schema.predict(
    feature1 DOUBLE, feature2 DOUBLE
)
EMITS (prediction DOUBLE) AS
run <- function(ctx) {
    model <- readRDS("/buckets/bfsdefault/default/models/model.rds")
    repeat {
        if (!ctx$next_row(1000)) break
        df <- data.frame(f1 = ctx$feature1, f2 = ctx$feature2)
        ctx$emit(predict(model, newdata = df))
    }
}
/
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

**Important:** There is no `emit_dataframe()` method — use `ctx.emit(dataframe)` to emit a DataFrame.

### Java

| Method | Description |
|--------|-------------|
| `ctx.getString("col")` | Get string value |
| `ctx.getInteger("col")` | Get integer value |
| `ctx.getDouble("col")` | Get double value |
| `ctx.getBigDecimal("col")` | Get decimal value |
| `ctx.getDate("col")` | Get date value |
| `ctx.getTimestamp("col")` | Get timestamp value |
| `ctx.next()` | Advance to next row (SET only) |
| `ctx.emit(v1, v2, ...)` | Emit output row (SET only) |
| `ctx.size()` | Row count in group (SET only) |
| `ctx.reset()` | Reset to first row (SET only) |

## BucketFS File Access

All languages can read files from BucketFS at `/buckets/<service>/<bucket>/<path>`:

```python
# Python — load a pickled ML model
import pickle
with open('/buckets/bfsdefault/default/models/model.pkl', 'rb') as f:
    model = pickle.load(f)
```

```java
// Java — reference JARs via %jar directive
%jar /buckets/bfsdefault/default/jars/my-library.jar;
```

**Performance tip:** Load models/resources once (outside the row loop or in a module-level variable), not per-row.

## GPU Acceleration (Exasol 2025.2+)

Exasol supports GPU-accelerated UDFs via CUDA-enabled Script Language Containers:

- Use `template-Exasol-8-python-3.{10,12}-cuda-conda` flavors
- Requires NVIDIA driver on the Exasol host
- Install GPU libraries (PyTorch, TensorFlow, RAPIDS) via conda in the SLC
- Standard UDF API — no code changes needed beyond importing GPU libraries

## Script Language Containers (SLC) Overview

UDFs run inside Script Language Containers — Docker-based runtime environments. The default SLC includes standard libraries. When you need additional packages (e.g., scikit-learn, PyTorch, custom JARs), build a custom SLC.

### When You Need a Custom SLC

- Installing pip/conda packages not in the default container
- Adding system libraries (apt packages)
- Using a different Python version (3.10 vs 3.12)
- Enabling GPU/CUDA support
- Adding R packages from CRAN

### Quick Activation

```sql
-- Activate for current session
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///<bfs-name>/<bucket>/<path>/<container>?lang=python#buckets/<bfs-name>/<bucket>/<path>/<container>/exaudf/exaudfclient_py3';

-- Activate system-wide (requires admin)
ALTER SYSTEM SET SCRIPT_LANGUAGES='...';
```

### Install the Build Tool

```bash
pip install exasol-script-languages-container-tool
```

## Performance Tips

- **Load once, use many**: Load models/resources outside the row loop
- **Use SET for batching**: Collect rows into a list/DataFrame, process in bulk
- **Lua for low latency**: Avoids JVM/Python startup overhead
- **Parallelism is automatic**: UDFs run on all cluster nodes simultaneously

## Detailed References

- **Python patterns** — context API, DataFrame pattern, type mapping, testing: [references/udf-python.md](references/udf-python.md)
- **Java & Lua patterns** — ExaMetadata API, JARs, adapters, Lua libraries: [references/udf-java-lua.md](references/udf-java-lua.md)
- **Building custom SLCs** — exaslct CLI, flavors, customization, deployment, troubleshooting: [references/slc-reference.md](references/slc-reference.md)
