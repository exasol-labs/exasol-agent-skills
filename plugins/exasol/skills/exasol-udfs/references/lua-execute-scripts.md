# Lua Execute Scripts

Lua execute scripts are distinct from Lua UDFs. A Lua UDF processes rows inside a SQL query; a Lua execute script runs autonomously and issues its own SQL queries via `query()` (and, for protected execution, `pquery()`). Execute scripts are the Exasol-native way to orchestrate multi-step workflows, iterative algorithms, and multi-phase pipelines entirely within the database — no external driver needed.

```sql
CREATE OR REPLACE LUA SCRIPT my_schema.my_orchestrator() AS
  local res = query("SELECT COUNT(*) FROM my_table")
  output(res[1][1])  -- first row, first column
/

EXECUTE SCRIPT my_schema.my_orchestrator();
```

## `query` and `pquery`

| Call | Returns | On failure |
|------|---------|------------|
| `query(sql)` | For `SELECT`: a 1-indexed array of rows; each row indexed by column position (`res[1][1]`) or name (`res[1].MY_COLUMN`), row count via `#res`. For other DML: a table with `rows_inserted`, `rows_updated`, `rows_deleted`, `rows_affected`, `statement_text`, `statement_id`. | Raises a Lua error and **terminates the script** — no wrapper needed for fail-fast behavior. |
| `pquery(sql)` | Two return values: `success` (boolean), `result` (the same shape as `query()`'s return on success). | `success` is `false`; `result` is a table with `error_message` and `error_code` — the script keeps running. |
| `query(sql, binds)` / `pquery(sql, binds)` | Same as above | — binds is a table of named parameters referenced as `::name` in the SQL, e.g. `query([[INSERT INTO ::t VALUES :v]], {t=table_name, v=values[i]})` |
| `output(msg)` | Appends a line to the script output (visible in SQL client) | — |

Default to `query()` for orchestration loops — most iterative pipelines want to abort immediately on a SQL error, and `query()` already does that natively. Reach for `pquery()` only when you need to catch a failure and keep going (e.g. retry logic, or probing whether an object exists).

## Error Handling

`query()` needs no wrapper — it already raises on failure. Use `pquery()` when you want to handle the error yourself instead of aborting the script:

```lua
local success, result = pquery([[DROP USER my_user]])
if not success then
  error("SQL failed: " .. result.error_message)
end
```

## Script Parameters and Output

Scripts accept typed parameters in the signature:

```sql
CREATE OR REPLACE LUA SCRIPT ml.my_script(
  source_table  VARCHAR(200),
  iterations    INT,
  threshold     DOUBLE
) AS
  output("Running on: " .. source_table)
  output("Iterations: " .. iterations)
/

EXECUTE SCRIPT ml.my_script('ml.features', 20, 0.001);
```

`output()` messages are returned as a result set by default. To always return a result table of all `output()` calls (and discard the script's return value), use `WITH OUTPUT`:

```sql
EXECUTE SCRIPT ml.my_script('ml.features', 20, 0.001) WITH OUTPUT;
```

To pass computed results back to SQL, write them to a table inside the script:

```lua
query("INSERT INTO ml.results SELECT ...")
```

## Combining Execute Scripts with Python SET UDFs

The power pattern for ML and HPC: Lua orchestrates the loop; a Python SET script handles the expensive distributed computation on every cluster node in parallel.

```lua
for iter = 1, max_iter do
  -- Python SET script: distributed gradient computation across all nodes
  query("INSERT INTO ml.gradients "
   .. "SELECT compute_gradients(\"id\", \"f1\", \"f2\", \"label\", " .. iter .. ") "
   .. "FROM ml.features GROUP BY \"partition_key\"")

  -- Lightweight single-node aggregation: update parameters
  query("INSERT INTO ml.params "
   .. "SELECT update_params(\"gradient\") "
   .. "FROM ml.gradients WHERE \"iter\" = " .. iter .. " GROUP BY 0")

  -- Check convergence
  local res = query("SELECT \"loss\" FROM ml.params WHERE \"iter\" = " .. iter)
  if tonumber(res[1][1]) < 0.001 then
    output("Converged at iteration " .. iter)
    break
  end
end
```

Each `query` call blocks until the SQL completes — the heavy parallel work happens inside Exasol while Lua just checks the result and loops.

## Limitations

- Nested `query`/`pquery` calls to `EXECUTE SCRIPT` are possible but have a recursion limit of 255 and a memory limit — avoid deep nesting
- `query`/`pquery` results are fully materialized in Lua memory — avoid SELECTs returning millions of rows; prefer aggregations or write results to a table
- No async execution — each `query`/`pquery` call blocks until the SQL completes
- Cannot write directly to BucketFS from Lua; use a helper Python UDF called via `query` to write files
