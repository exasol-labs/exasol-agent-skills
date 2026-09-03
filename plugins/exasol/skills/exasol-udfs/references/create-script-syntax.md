# CREATE SCRIPT Syntax by Language

Working `CREATE SCRIPT` bodies for each supported language, plus the variadic
(dynamic-parameter) forms. For the per-language APIs behind these samples see
`udf-python.md` and `udf-java-lua.md`.

## Python SCALAR

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

## Python SET

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

## Java SCALAR

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

## Java with External JARs

```sql
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.custom(input VARCHAR(2000))
RETURNS VARCHAR(2000) AS
  %scriptclass com.mycompany.MyProcessor;
  %jar /buckets/bfsdefault/default/jars/my-lib.jar;
/
```

## Lua SCALAR

```sql
CREATE OR REPLACE LUA SCALAR SCRIPT my_schema.my_avg(a DOUBLE, b DOUBLE)
RETURNS DOUBLE AS
function run(ctx)
    if ctx.a == nil or ctx.b == nil then return null end
    return (ctx.a + ctx.b) / 2
end
/
```

## R SET (ML Prediction)

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

## Variadic Scripts (Dynamic Parameters)

Use `...` to accept any number of input columns, output columns, or both.

### Dynamic Input

```sql
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT schema.to_json(...) RETURNS VARCHAR(2000000) AS
import simplejson
def run(ctx):
    obj = {}
    for i in range(0, exa.meta.input_column_count, 2):
        obj[ctx[i]] = ctx[i+1]   # caller passes: name, value, name, value, ...
    return simplejson.dumps(obj)
/

SELECT to_json('fruit', fruit, 'price', price) FROM products;
```

- Access by index: `ctx[i]` — **0-based in Python/Java, 1-based in Lua/R**
- Parameter names inside a variadic script are always `0`, `1`, `2`, ... — never the original column names
- `exa.meta.input_column_count` — total number of input columns
- `exa.meta.input_columns[i].name / .sql_type` — per-column metadata

### Dynamic Output (`EMITS(...)`)

Declare `EMITS(...)` in `CREATE SCRIPT`. At call time, columns must be provided one of two ways:

| Method | Where specified | Use when |
|--------|----------------|----------|
| **EMITS in SELECT** | Caller's SQL query | Output structure depends on data values |
| **`default_output_columns()`** | Script body | Output structure derivable from input column count/types alone |

```sql
-- EMITS in SELECT (required when output depends on data content)
SELECT split_csv(line) EMITS (a VARCHAR(100), b VARCHAR(100), c VARCHAR(100)) FROM t;
```

```python
# default_output_columns() — called before run(), no ctx/data access available
def default_output_columns():
    parts = []
    for i in range(exa.meta.input_column_count):
        parts.append("c" + exa.meta.input_columns[i].name + " " + exa.meta.input_columns[i].sql_type)
    return ",".join(parts)
```

If neither is provided, the query fails with:
> *The script has dynamic return arguments. Either specify the return arguments in the query via EMITS or implement the method default_output_columns in the UDF.*
