# Lua Execute Scripts

Lua execute scripts are distinct from Lua UDFs. A Lua UDF processes rows inside a SQL query; a Lua execute script runs autonomously and issues its own SQL queries via `pquery()`. Execute scripts are the Exasol-native way to orchestrate multi-step workflows, iterative algorithms, and multi-phase pipelines entirely within the database — no external driver needed.

```sql
CREATE OR REPLACE LUA SCRIPT my_schema.my_orchestrator() AS
  local res = pquery("SELECT COUNT(*) FROM my_table")
  if not res.status then
    error(res.error_message)
  end
  output(res[1][1])  -- first row, first column
/

EXECUTE SCRIPT my_schema.my_orchestrator();
```

## `pquery` API

| Call | Returns |
|------|---------|
| `pquery(sql)` | `{status=bool, [1]={[1]=val,...}, error_message=str}` |
| `pquery(sql, binds)` | Same; `binds` is a table of positional `?` parameters |
| `output(msg)` | Appends a line to the script output (visible in SQL client) |

Result set is a table of rows; each row is a table of column values (1-based index). `res.status` is `true` on success. On failure, `res.error_message` contains the error text. `res` also exposes `res.rows` (row count) and `res.columns` (column metadata).

## Error Handling

Always wrap `pquery` in a helper that raises on failure:

```lua
local function sql(query)
  local res = pquery(query)
  if not res.status then
    error("SQL failed: " .. res.error_message .. "\nQuery: " .. query)
  end
  return res
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
sql("INSERT INTO ml.results SELECT ...")
```

## Iterative K-Means Orchestration

Classic use case: iterative algorithm where each step is a distributed SQL query and Lua manages the loop.

```sql
CREATE OR REPLACE LUA SCRIPT ml.kmeans_orchestrator(
  source_table  VARCHAR(200),
  k             INT,
  max_iter      INT
) AS
local function sql(q)
  local r = pquery(q)
  if not r.status then error(r.error_message) end
  return r
end

-- Initialize: sample k random points as starting centroids
sql([[
  CREATE OR REPLACE TABLE ml.centroids AS
  SELECT ROW_NUMBER() OVER () AS centroid_id, "f1", "f2"
  FROM ]] .. source_table .. [[
  ORDER BY RAND()
  LIMIT ]] .. k)

for iter = 1, max_iter do
  -- Assignment: each point gets the nearest centroid (distributed scan)
  sql([[
    CREATE OR REPLACE TABLE ml.assignments AS
    SELECT
      p."id",
      (SELECT c.centroid_id
       FROM ml.centroids c
       ORDER BY (p."f1" - c."f1") * (p."f1" - c."f1")
              + (p."f2" - c."f2") * (p."f2" - c."f2")
       LIMIT 1) AS centroid_id
    FROM ]] .. source_table .. [[ p]])

  -- Update: recompute centroids as group means (distributed aggregation)
  sql([[
    CREATE OR REPLACE TABLE ml.centroids AS
    SELECT a.centroid_id, AVG(p."f1") AS "f1", AVG(p."f2") AS "f2"
    FROM ml.assignments a
    JOIN ]] .. source_table .. [[ p ON p."id" = a."id"
    GROUP BY a.centroid_id]])

  output("Iteration " .. iter .. " complete")
end
/

EXECUTE SCRIPT ml.kmeans_orchestrator('ml.features', 5, 20) WITH OUTPUT;
```

## Combining Execute Scripts with Python SET UDFs

The power pattern for ML and HPC: Lua orchestrates the loop; a Python SET script handles the expensive distributed computation on every cluster node in parallel.

```lua
local function sql(q)
  local r = pquery(q)
  if not r.status then error(r.error_message) end
  return r
end

for iter = 1, max_iter do
  -- Python SET script: distributed gradient computation across all nodes
  sql("INSERT INTO ml.gradients "
   .. "SELECT compute_gradients(\"id\", \"f1\", \"f2\", \"label\", " .. iter .. ") "
   .. "FROM ml.features GROUP BY \"partition_key\"")

  -- Lightweight single-node aggregation: update parameters
  sql("INSERT INTO ml.params "
   .. "SELECT update_params(\"gradient\") "
   .. "FROM ml.gradients WHERE \"iter\" = " .. iter .. " GROUP BY 0")

  -- Check convergence
  local res = sql("SELECT \"loss\" FROM ml.params WHERE \"iter\" = " .. iter)
  if tonumber(res[1][1]) < 0.001 then
    output("Converged at iteration " .. iter)
    break
  end
end
```

Each `pquery` blocks until the SQL completes — the heavy parallel work happens inside Exasol while Lua just checks the result and loops.

## Limitations

- Nested `pquery` of `EXECUTE SCRIPT` is possible but has a recursion limit of 255 and a memory limit — avoid deep nesting
- `pquery` results are fully materialized in Lua memory — avoid SELECTs returning millions of rows; prefer aggregations or write results to a table
- No async execution — each `pquery` call blocks until the SQL completes
- Cannot write directly to BucketFS from Lua; use a helper Python UDF called via `pquery` to write files
