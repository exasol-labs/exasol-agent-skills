# Java & Lua UDFs

## Java UDFs

### SCALAR Script

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

### SET Script

```sql
CREATE OR REPLACE JAVA SET SCRIPT my_schema.median_calc(val DOUBLE)
EMITS (median_value DOUBLE) AS
import java.util.ArrayList;
import java.util.Collections;

class MEDIAN_CALC {
    static void run(ExaMetadata exa, ExaIterator ctx) throws Exception {
        ArrayList<Double> values = new ArrayList<>();
        do {
            Double v = ctx.getDouble("val");
            if (v != null) values.add(v);
        } while (ctx.next());

        Collections.sort(values);
        int n = values.size();
        double median = (n % 2 == 0)
            ? (values.get(n/2 - 1) + values.get(n/2)) / 2.0
            : values.get(n/2);
        ctx.emit(median);
    }
}
/
```

### Java Class Requirements

- Class name **must match** the script name (uppercased)
- Method signature: `static <return_type> run(ExaMetadata exa, ExaIterator ctx) throws Exception`
  - SCALAR with RETURNS: return type matches the SQL return type
  - SET with EMITS: return type is `void`, use `ctx.emit()`
- Lifecycle methods (optional): `static void init(ExaMetadata exa)`, `static void cleanup(ExaMetadata exa)`

### ExaIterator API

| Method | Description |
|--------|-------------|
| `ctx.getString("col")` | Get string value |
| `ctx.getInteger("col")` | Get integer value |
| `ctx.getLong("col")` | Get long value |
| `ctx.getDouble("col")` | Get double value |
| `ctx.getBigDecimal("col")` | Get decimal value |
| `ctx.getDate("col")` | Get date value (`java.sql.Date`) |
| `ctx.getTimestamp("col")` | Get timestamp value (`java.sql.Timestamp`) |
| `ctx.getBoolean("col")` | Get boolean value |
| `ctx.next()` | Advance to next row (SET only) |
| `ctx.emit(v1, v2, ...)` | Emit output row (SET only) |
| `ctx.size()` | Number of rows in group (SET only) |
| `ctx.reset()` | Reset to first row (SET only) |

### ExaMetadata API

| Method | Description |
|--------|-------------|
| `exa.getScriptSchema()` | Schema containing the script |
| `exa.getScriptName()` | Name of the script |
| `exa.getInputColumnCount()` | Number of input columns |
| `exa.getInputColumnName(i)` | Name of input column i |
| `exa.getInputColumnType(i)` | SQL type of input column i |
| `exa.getOutputColumnCount()` | Number of output columns |
| `exa.getMemoryLimit()` | Memory limit in bytes |
| `exa.getVmId()` | VM identifier for this UDF instance |

### Using External JARs

Upload JARs to BucketFS, then reference with `%jar`:

```sql
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.custom_logic(input VARCHAR(2000))
RETURNS VARCHAR(2000) AS
  %scriptclass com.mycompany.CustomProcessor;
  %jar /buckets/bfsdefault/default/jars/my-library-1.0.0.jar;
  %jar /buckets/bfsdefault/default/jars/dependency.jar;
/
```

Upload JARs to BucketFS:
```bash
curl -X PUT -T my-library-1.0.0.jar http://w:<PASSWORD>@<HOST>:2580/default/jars/
```

### JVM Options

```sql
CREATE OR REPLACE JAVA SET SCRIPT my_schema.heavy_computation(val DOUBLE)
EMITS (result DOUBLE) AS
  %jvmoption -Xms512m -Xmx2g;
  -- script body...
/
```

### Script Imports

Reuse code across Java UDF scripts:

```sql
-- Shared utility script
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.utils() RETURNS INT AS
class UTILS {
    static String sanitize(String input) {
        return input == null ? "" : input.trim().toLowerCase();
    }
}
/

-- Script that imports utilities
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.process(val VARCHAR(2000))
RETURNS VARCHAR(2000) AS
  %import my_schema.utils;

class PROCESS {
    static String run(ExaMetadata exa, ExaIterator ctx) throws Exception {
        return UTILS.sanitize(ctx.getString("val"));
    }
}
/
```

### ADAPTER Scripts (Virtual Schemas)

Java ADAPTER scripts power Virtual Schemas:

```sql
CREATE OR REPLACE JAVA ADAPTER SCRIPT adapter_schema.jdbc_adapter AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/virtual-schema-dist-12.0.0.jar;
  %jar /buckets/bfsdefault/default/postgresql-42.7.1.jar;
/
```

### Maven Dependency for External Development

```xml
<dependency>
    <groupId>com.exasol</groupId>
    <artifactId>udf-api-java</artifactId>
    <version>1.0.4</version>
</dependency>
```

### Debugging

```xml
<dependency>
    <groupId>com.exasol</groupId>
    <artifactId>udf-debugging-java</artifactId>
    <version>0.6.11</version>
    <scope>test</scope>
</dependency>
```

System properties:
- `-Dtest.debug=true` — Remote debugging on port 8000
- `-Dtest.coverage=true` — JaCoCo code coverage
- `-Dtest.jprofiler=true` — JProfiler on port 11002
- `-Dtest.udf-logs=true` — Capture stdout to `target/udf-logs/`

### Java Performance Notes

- ~1 second JVM startup overhead per UDF invocation
- For latency-sensitive operations, consider Lua instead
- Load resources (models, configs) once in a static `init()` method, not per-row
- Java 11 and Java 17 are both supported (via OpenJDK in the SLC)

---

## Lua UDFs

Lua runs natively in Exasol's built-in Lua 5.4 runtime — no SLC needed, sub-millisecond startup. Lua is **not expandable** via Script Language Containers (it is compiled directly into the Exasol engine).

### SCALAR Script

```sql
CREATE OR REPLACE LUA SCALAR SCRIPT my_schema.my_average(a DOUBLE, b DOUBLE)
RETURNS DOUBLE AS
function run(ctx)
    if ctx.a == nil or ctx.b == nil then
        return null
    end
    return (ctx.a + ctx.b) / 2
end
/

SELECT my_average(x, y) FROM t;
```

### SET Script

```sql
CREATE OR REPLACE LUA SET SCRIPT my_schema.concat_values(val VARCHAR(200))
EMITS (result VARCHAR(2000000)) AS
function run(ctx)
    local parts = {}
    repeat
        if ctx.val ~= null then
            parts[#parts + 1] = ctx.val
        end
    until not ctx.next()
    ctx.emit(table.concat(parts, ", "))
end
/
```

### Lua Context API

| Method/Property | SCALAR | SET | Description |
|----------------|--------|-----|-------------|
| `ctx.<column>` | yes | yes | Access input column value |
| `return value` | yes | no | Return single value (RETURNS) |
| `ctx.emit(v1, v2, ...)` | no | yes | Emit output row (EMITS) |
| `ctx.next()` | no | yes | Advance to next row; returns `false` at end |
| `ctx.size()` | no | yes | Number of rows in current group |
| `ctx.reset()` | no | yes | Reset iterator to first row |

### Available Lua Libraries

These libraries are bundled with Exasol and available without SLC customization:

- `math` — math functions
- `table` — table manipulation
- `string` — pattern matching, formatting
- `luasocket` — TCP/UDP networking, HTTP
- `luaexpat` — XML parsing
- `lua-cjson` — JSON encoding/decoding

### When to Use Lua

- **Low-latency operations** — no JVM/Python startup overhead
- **Simple transforms** — string processing, math, JSON parsing
- **Row-level security** — fast per-row access control checks

### Lua Limitations

- **Not expandable via SLC** — cannot add external packages
- **Smaller library ecosystem** — limited to bundled libraries
- **No pip/maven equivalent** — must inline or bundle all code
