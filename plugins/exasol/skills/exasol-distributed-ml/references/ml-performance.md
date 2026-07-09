# ML and HPC Performance Tuning

Diagnosing and fixing performance problems specific to ML workloads in Exasol. For general query profiling see **exasol-database** `references/query-profiling.md`.

---

## 1. Profiling SET Scripts

Standard Exasol query profiling covers UDF execution as well. Use `$EXA_PROFILE_DETAILS_LAST_DAY` to see per-node timing:

```sql
ALTER SESSION SET PROFILE = 'ON';

SELECT ml.batch_predict(entity_id, "f1", "f2")
FROM ml.inference_data
GROUP BY entity_id;

ALTER SESSION SET PROFILE = 'OFF';
FLUSH STATISTICS;

-- Per-node UDF timing for the last query
SELECT "IPROC", "PART_NAME", "DURATION", "ROWS", "CPU"
FROM "$EXA_PROFILE_DETAILS_LAST_DAY"
WHERE "SESSION_ID" = CURRENT_SESSION
  AND "PART_NAME" = 'UDF'
ORDER BY "STMT_ID" DESC, "IPROC";
```

A node where `DURATION` is 5x other nodes indicates either data skew (that node received disproportionately large groups) or slow model loading on that specific node.

---

## 2. Data Skew in ML Workloads

ML workloads are especially sensitive to skew because group sizes vary enormously — one entity may have 1M rows while another has 10. Check before training:

```sql
-- Distribution of group sizes
SELECT entity_id, COUNT(*) AS group_size
FROM ml.training_data
GROUP BY entity_id
ORDER BY group_size DESC
LIMIT 20;

-- Preview distribution across nodes before table creation
SELECT value2proc(entity_id) AS future_node, COUNT(*) AS rows
FROM ml.training_data
GROUP BY 1
ORDER BY 1;
```

**Mitigation for large entities**: sub-batch by time window or a hash sub-key:

```sql
-- Split large entities into sub-groups of ~50k rows
SELECT entity_id,
       FLOOR((ROW_NUMBER() OVER (PARTITION BY entity_id ORDER BY feature_ts) - 1) / 50000)
           AS sub_batch,
       "f1", "f2", label
FROM ml.training_data
WHERE entity_id = :large_entity_id;
```

---

## 3. Memory Management — Three Tiers

Choose the approach based on algorithm support:

### Tier 1: `partial_fit` streaming (best — O(chunk) memory)

For algorithms supporting incremental learning. Single pass if one epoch suffices (`GaussianNB`, `IncrementalPCA`); multi-epoch loop with `ctx.reset()` for convergence-sensitive algorithms (SGD, MLP):

```python
CHUNK = 5000
model = SGDRegressor(max_iter=1, warm_start=True)

for epoch in range(MAX_EPOCHS):
    ctx.reset()
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        model.partial_fit(df[features].values, df['label'].values)
    if converged(model):
        break
```

### Tier 2: Chunked multi-pass with `ctx.reset()` (memory bounded to one chunk)

For two-pass algorithms (compute stats in pass 1, apply in pass 2):

```python
CHUNK = 5000
n = 0
mean = 0.0
M2 = 0.0

# Pass 1: Welford online algorithm for running mean and variance
while True:
    df = ctx.get_dataframe(num_rows=CHUNK)
    if df is None:
        break
    for val in df['f1']:
        n += 1
        delta = val - mean
        mean += delta / n
        M2 += delta * (val - mean)
std = (M2 / n) ** 0.5

ctx.reset()

# Pass 2: apply normalization and emit
while True:
    df = ctx.get_dataframe(num_rows=CHUNK)
    if df is None:
        break
    df['f1_norm'] = (df['f1'] - mean) / std
    ctx.emit(df[['id', 'f1_norm']])
```

### Tier 3: Collect-then-fit (only for small groups)

Accumulate all chunks into numpy arrays, call `model.fit()` once. Only acceptable when the group is known to fit in memory. Use `exa.meta.memory_limit` to check:

```python
# Rough check: 8 bytes per float × n_features × expected_rows
estimated_bytes = 8 * 3 * 100_000  # 3 features, 100k rows
if estimated_bytes > exa.meta.memory_limit * 0.5:
    # too large — switch to partial_fit or raise an error
    pass
```

**`ctx.get_dataframe(num_rows='all')` is an anti-pattern** for large groups — it materializes the entire group at once.

---

## 4. Model Load Time

**Module-level lazy init** is the key optimization — the UDF process is reused across all `run()` calls within a query, so the model is opened once per node per query:

```python
_model = None

def _ensure_model():
    global _model
    if _model is None:
        import pickle
        with open('/buckets/bfsdefault/default/models/model.pkl', 'rb') as f:
            _model = pickle.load(f)
    return _model

def run(ctx):
    model = _ensure_model()
    ...
```

**Anti-pattern**: opening the file inside `run()` = one file open per group. For 10,000 entities this means 10,000 file opens per query node — catastrophic.

---

## 5. Iterative Algorithm Overhead

For Lua-orchestrated loops, minimize SQL round-trips per iteration:

- Each `pquery` call is one SQL execution — batch gradient computation and parameter update into as few queries as possible
- Prefer: one SET script query that computes gradients for all partitions, then one aggregate query to update parameters
- Avoid: one `pquery` per partition (serial execution, no parallelism)

```lua
-- Good: one distributed query covers all partitions
sql("INSERT INTO ml.gradients SELECT compute_gradients(...) FROM ml.features GROUP BY partition_key")

-- Bad: loop over partitions one by one
for p = 0, num_partitions - 1 do
    sql("INSERT INTO ml.gradients SELECT compute_gradients(...) FROM ml.features WHERE partition_key = " .. p)
end
```

---

## 6. Group Size Tuning for Hyperparameter Search

When the HP grid is large (100+ combinations), many small groups create UDF startup overhead. Batch multiple HP configs per group:

```sql
-- Instead of GROUP BY group_key (100 groups of data size N)
-- Use GROUP BY MOD(group_key, 10) — 10 groups, each processing 10 HP configs
SELECT ml.hp_search_batch(MOD("group_key", 10), "n_est", "max_d", "f1", "f2", "label")
FROM ml.hp_grid g
CROSS JOIN ml.training_data t
GROUP BY MOD(g."group_key", 10);
```

The `hp_search_batch` UDF reads HP configs from the first chunk, processes each config against all data rows collected in pass 1.

---

## 7. OOM Anti-Patterns

| Cause | Fix |
|-------|-----|
| `ctx.get_dataframe(num_rows='all')` on large groups | Chunked loop + `ctx.reset()` for multi-pass |
| `GROUP BY 'x'` on full table | Only when dataset < `exa.meta.memory_limit` |
| Model loading inside `run()` | Move to module-level lazy init |
| GPU tensor not freed between groups | `torch.cuda.empty_cache()` in `finally` |
| Collect-then-fit on skewed entity with 10M rows | Use `partial_fit` or map-reduce ensemble |
| `pquery` result of millions of rows read into Lua | Aggregate in SQL first; only read summary rows into Lua |
