# Distributed ML and HPC Patterns

Core patterns for training models, running inference, and executing iterative algorithms at scale inside Exasol. These patterns combine DISTRIBUTE BY, SET scripts, and BucketFS into end-to-end pipelines.

For UDF API basics (ctx.emit, ctx.get_dataframe, SCALAR vs SET syntax) see **exasol-udfs**. For SLC build/deploy see **exasol-udfs** `references/slc-reference.md`. For BucketFS file operations see **exasol-bucketfs**. For DISTRIBUTE BY table design see **exasol-database** `references/table-design.md`.

---

## 1. Architecture: DISTRIBUTE BY + SET Script + BucketFS

The canonical Exasol ML stack has three layers:

1. **DISTRIBUTE BY** on the training/inference key — all rows for the same entity land on the same node; SET scripts process entire groups without cross-node data movement.
2. **Python3 SET scripts** — each group runs in parallel on its node; `ctx.get_dataframe()` streams rows in chunks.
3. **BucketFS** — stores models and artifacts; every node reads from the same path `/buckets/bfsdefault/default/...`.

```sql
CREATE TABLE ml.training_data (
    entity_id  DECIMAL(18,0) NOT NULL,
    feature_ts TIMESTAMP,
    f1 DOUBLE, f2 DOUBLE, f3 DOUBLE,
    label      DOUBLE,
    DISTRIBUTE BY entity_id
);
```

DISTRIBUTE BY `entity_id` means all rows for entity 42 are always on the same node — no shuffle needed for per-entity training or inference.

---

## 2. Feature Engineering

### Two-Pass Normalization

Compute statistics in SQL (one distributed aggregation), then apply in a SET script:

```sql
-- Pass 1: compute stats
CREATE TABLE ml.feature_stats AS
SELECT
    AVG("f1") AS f1_mean, STDDEV_POP("f1") AS f1_std,
    AVG("f2") AS f2_mean, STDDEV_POP("f2") AS f2_std
FROM ml.training_data;

-- Pass 2: join stats and apply normalization via a SET script
SELECT ml.normalize_features(
    t.entity_id,
    (t."f1" - s.f1_mean) / NULLIF(s.f1_std, 0),
    (t."f2" - s.f2_mean) / NULLIF(s.f2_std, 0),
    t.label
)
FROM ml.training_data t
CROSS JOIN ml.feature_stats s
GROUP BY t.entity_id;
```

### Distributed One-Hot Encoding

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.one_hot_encode(
    entity_id DECIMAL(18,0), category VARCHAR(200)
)
EMITS (entity_id DECIMAL(18,0), category VARCHAR(200), value DOUBLE) AS
KNOWN_CATEGORIES = ['cat_a', 'cat_b', 'cat_c']

def run(ctx):
    CHUNK = 10000
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'category']
        for cat in KNOWN_CATEGORIES:
            df_out = df[['entity_id']].copy()
            df_out['category'] = cat
            df_out['value'] = (df['category'] == cat).astype(float)
            ctx.emit(df_out)
/
```

Unknown categories get all-zero encoding (no row emitted for unknown values).

---

## 3. Per-Entity (Federated) Training

Train one model per entity in parallel. Each entity's rows form one group; SET scripts run independently on each node.

### Preferred: `partial_fit` (incremental, memory-efficient)

Use algorithms that support `partial_fit` — no full-group materialization needed:

| Algorithm | `partial_fit`? | Notes |
|-----------|---------------|-------|
| `SGDClassifier` / `SGDRegressor` | Yes | Multi-epoch with `ctx.reset()` for convergence |
| `PassiveAggressiveClassifier` | Yes | |
| `Perceptron` | Yes | |
| `MiniBatchKMeans` | Yes | |
| `GaussianNB` / `BernoulliNB` / `MultinomialNB` | Yes | Single pass usually sufficient |
| `IncrementalPCA` | Yes | |
| `MLPClassifier` / `MLPRegressor` | Yes | Multi-epoch for convergence |
| `RandomForestClassifier` | No | Use collect-then-fit or map-reduce ensemble |
| `GradientBoostingRegressor` | No | Use map-reduce ensemble |
| `IsolationForest` | No | Use collect-then-fit (small groups) |

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.train_entity_model(
    entity_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE, label DOUBLE
)
EMITS (entity_id DECIMAL(18,0), model_path VARCHAR(500), final_loss DOUBLE) AS
import pickle, io, numpy as np
from sklearn.linear_model import SGDRegressor

CHUNK = 5000
BUCKET = '/buckets/bfsdefault/default/models'
MAX_EPOCHS = 10
CONVERGE_DELTA = 1e-4

def run(ctx):
    entity = None
    model = SGDRegressor(max_iter=1, warm_start=True)
    prev_loss = float('inf')

    for epoch in range(MAX_EPOCHS):
        ctx.reset()
        while True:
            df = ctx.get_dataframe(num_rows=CHUNK)
            if df is None:
                break
            df.columns = ['entity_id', 'f1', 'f2', 'label']
            if entity is None:
                entity = int(df['entity_id'].iloc[0])
            X = df[['f1', 'f2']].values
            y = df['label'].values
            model.partial_fit(X, y)

        # convergence check after each epoch
        ctx.reset()
        preds, actuals = [], []
        while True:
            df = ctx.get_dataframe(num_rows=CHUNK)
            if df is None:
                break
            df.columns = ['entity_id', 'f1', 'f2', 'label']
            X = df[['f1', 'f2']].values
            preds.extend(model.predict(X))
            actuals.extend(df['label'].values)
        loss = float(np.mean((np.array(preds) - np.array(actuals)) ** 2))
        if abs(prev_loss - loss) < CONVERGE_DELTA:
            break
        prev_loss = loss

    path = f'{BUCKET}/entity_{entity}.pkl'
    with open(path, 'wb') as f:
        pickle.dump(model, f)
    ctx.emit(entity, f'models/entity_{entity}.pkl', prev_loss)
/

SELECT ml.train_entity_model(entity_id, "f1", "f2", label)
FROM ml.training_data
GROUP BY entity_id;
```

### Fallback: Collect-Then-Fit

For algorithms without `partial_fit`. Accumulate all chunks into numpy arrays, then call `model.fit()`. Only safe when the group fits in `exa.meta.memory_limit`.

```python
def run(ctx):
    X_parts, y_parts = [], []
    while True:
        df = ctx.get_dataframe(num_rows=5000)
        if df is None:
            break
        df.columns = ['entity_id', 'f1', 'f2', 'label']
        X_parts.append(df[['f1', 'f2']].values)
        y_parts.append(df['label'].values)
    X = np.vstack(X_parts)
    y = np.concatenate(y_parts)
    model.fit(X, y)
```

**BucketFS replication caveat**: A model written to `/buckets/...` from inside a UDF is immediately available on the writing node but replicates to other nodes asynchronously. For inference queries that run immediately after training, add a brief pause or run inference with `DISTRIBUTE BY entity_id` to guarantee the reading node is the same as the writing node.

---

## 4. Global Model (Single-Node)

Force all data to one node for algorithms that need the full dataset:

```sql
SELECT ml.train_global_model("f1", "f2", label)
FROM ml.training_data
GROUP BY 'x';
```

`GROUP BY 'x'` (any non-integer constant) sends all rows to a single node. Don't use an integer literal like `GROUP BY 0` — Exasol parses integer literals in `GROUP BY` as ordinal column references, and `0` is below the minimum valid ordinal (`1`), so it fails with `Wrong column number`. Only viable when the full dataset fits in one node's memory limit (`exa.meta.memory_limit`). Check first:

```sql
SELECT COUNT(*) * 8 * 3 AS estimated_bytes  -- 3 DOUBLE columns × 8 bytes
FROM ml.training_data;
```

---

## 5. Batch Inference

Two-pass pattern: identify the entity on the first chunk, load the model, reset, then stream all chunks for prediction.

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.batch_predict(
    entity_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE
)
EMITS (entity_id DECIMAL(18,0), prediction DOUBLE) AS
import pickle, json
from datetime import datetime

BUCKET = '/buckets/bfsdefault/default'
CHUNK = 10000
_model_cache = {}

def _load_model(entity_id):
    if entity_id not in _model_cache:
        try:
            latest_path = f'{BUCKET}/models/latest_{entity_id}.json'
            with open(latest_path) as f:
                meta = json.load(f)
            with open(f'{BUCKET}/{meta["path"]}', 'rb') as f:
                _model_cache[entity_id] = pickle.load(f)
        except FileNotFoundError:
            _model_cache[entity_id] = None
    return _model_cache[entity_id]

def run(ctx):
    # Pass 1: read first chunk to get entity_id and load model
    df = ctx.get_dataframe(num_rows=1)
    entity = int(df['0'].iloc[0])
    model = _load_model(entity)
    ctx.reset()

    # Pass 2: stream chunks and predict
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'f1', 'f2']
        if model is None:
            for _, row in df.iterrows():
                ctx.emit(int(row['entity_id']), None)
        else:
            X = df[['f1', 'f2']].values
            preds = model.predict(X)
            df['prediction'] = preds
            ctx.emit(df[['entity_id', 'prediction']])
/

SELECT ml.batch_predict(entity_id, "f1", "f2")
FROM ml.inference_data
GROUP BY entity_id;
```

---

## 6. Distributed Ensemble Training (Map-Reduce)

For algorithms like Random Forest and Bagging where the final model is a combination of independently trained sub-models.

### Phase 1 (Map): Train sub-models in parallel

```sql
CREATE TABLE ml.sub_models AS
SELECT ml.train_sub_model("partition_id", "f1", "f2", "label")
FROM (
    SELECT MOD(ROWNUM, 16) AS "partition_id", "f1", "f2", "label"
    FROM ml.training_data
) t
GROUP BY "partition_id";
```

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.train_sub_model(
    partition_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE, label DOUBLE
)
EMITS (partition_id DECIMAL(18,0), model_path VARCHAR(500)) AS
import pickle
from sklearn.ensemble import RandomForestClassifier

BUCKET = '/buckets/bfsdefault/default/models/ensemble'
CHUNK = 5000

def run(ctx):
    X_parts, y_parts = [], []
    partition = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['partition_id', 'f1', 'f2', 'label']
        if partition is None:
            partition = int(df['partition_id'].iloc[0])
        X_parts.append(df[['f1', 'f2']].values)
        y_parts.append(df['label'].values)

    import numpy as np
    X = np.vstack(X_parts)
    y = np.concatenate(y_parts)

    # Small forest — will be combined in reduce phase
    model = RandomForestClassifier(n_estimators=10)
    model.fit(X, y)

    path = f'{BUCKET}/sub_{partition}.pkl'
    with open(path, 'wb') as f:
        pickle.dump(model, f)
    ctx.emit(partition, f'models/ensemble/sub_{partition}.pkl')
/
```

### Phase 2 (Reduce): Combine sub-models into final ensemble

```sql
SELECT ml.combine_ensemble("partition_id", "model_path")
FROM ml.sub_models
GROUP BY 'x';
```

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.combine_ensemble(
    partition_id DECIMAL(18,0), model_path VARCHAR(500)
)
EMITS (model_path VARCHAR(500), n_estimators DECIMAL(10,0)) AS
import pickle

BUCKET = '/buckets/bfsdefault/default'
CHUNK = 100

def run(ctx):
    all_estimators = []
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['partition_id', 'model_path']
        for path in df['model_path']:
            with open(f'{BUCKET}/{path}', 'rb') as f:
                sub_model = pickle.load(f)
            all_estimators.extend(sub_model.estimators_)

    # Reconstruct a single forest from all sub-model trees
    import copy
    from sklearn.ensemble import RandomForestClassifier
    combined = copy.copy(sub_model)  # copy metadata from last sub-model
    combined.estimators_ = all_estimators
    combined.n_estimators = len(all_estimators)

    final_path = f'{BUCKET}/models/ensemble/final.pkl'
    with open(final_path, 'wb') as f:
        pickle.dump(combined, f)
    ctx.emit('models/ensemble/final.pkl', len(all_estimators))
/
```

### Multi-Phase Reduce (for large numbers of sub-models)

When combining thousands of sub-models at once would exhaust single-node memory, reduce in rounds:

```sql
-- Intermediate combine: groups of 8 → 8 merged models
CREATE TABLE ml.partial_models AS
SELECT ml.combine_ensemble("partition_id", "model_path")
FROM ml.sub_models
GROUP BY MOD("partition_id", 8);

-- Final combine: 8 → 1
SELECT ml.combine_ensemble("partition_id", "model_path")
FROM ml.partial_models
GROUP BY 'x';
```

### SON Algorithm for Frequent Itemset Mining

Same map-reduce structure applied to data mining:

```sql
-- Phase 1: local FP-Growth on each transaction partition
CREATE TABLE ml.local_itemsets AS
SELECT ml.local_fp_growth("partition_id", "txn_id", "item", 0.01)
FROM (
    SELECT MOD(ROWNUM, 16) AS "partition_id", "txn_id", "item"
    FROM market.transactions
) t
GROUP BY "partition_id";
```

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.local_fp_growth(
    partition_id DECIMAL(18,0), txn_id DECIMAL(18,0),
    item VARCHAR(200), min_support DOUBLE
)
EMITS (itemset VARCHAR(2000), local_support DOUBLE) AS
import json
CHUNK = 10000

def run(ctx):
    from mlxtend.frequent_patterns import fpgrowth
    from mlxtend.preprocessing import TransactionEncoder
    import pandas as pd

    transactions = {}
    min_sup = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['partition_id', 'txn_id', 'item', 'min_support']
        if min_sup is None:
            min_sup = float(df['min_support'].iloc[0])
        for txn, grp in df.groupby('txn_id'):
            transactions.setdefault(txn, set()).update(grp['item'])

    te = TransactionEncoder()
    te_array = te.fit_transform([list(v) for v in transactions.values()])
    df_enc = pd.DataFrame(te_array, columns=te.columns_)
    freq = fpgrowth(df_enc, min_support=min_sup, use_colnames=True)

    n_txn = len(transactions)
    for _, row in freq.iterrows():
        ctx.emit(json.dumps(sorted(row['itemsets'])), float(row['support'] * n_txn))
/
```

Key property: a globally frequent itemset must be locally frequent in at least one partition (Apriori property) — the union of local results is a complete candidate set with no false negatives.

```sql
-- Phase 2: collect candidate itemsets (union of all local frequent itemsets)
CREATE TABLE ml.candidates AS
SELECT DISTINCT "itemset" FROM ml.local_itemsets;

-- Phase 3: verify global support by joining back to full transactions
SELECT c."itemset", COUNT(DISTINCT t."txn_id") AS global_support
FROM ml.candidates c
JOIN market.transactions t
  ON JSON_VALUE(c."itemset", '$[0]') = t."item"  -- simplified; adapt for multi-item sets
GROUP BY c."itemset"
HAVING COUNT(DISTINCT t."txn_id") >= :min_support_count;
```

---

## 7. Parallel Hyperparameter Search

Cross-join a parameter grid with training data; each group runs one cross-validation:

```sql
-- Build parameter grid
CREATE TABLE ml.hp_grid AS
SELECT
    ROW_NUMBER() OVER (ORDER BY n_est, max_d) AS group_key,
    n_est, max_d
FROM (
    SELECT 50 AS n_est, 3 AS max_d UNION ALL
    SELECT 100, 3 UNION ALL
    SELECT 100, 5 UNION ALL
    SELECT 200, 5
) p;

-- Run grid search: one group per HP combination
SELECT ml.hp_search("group_key", "n_est", "max_d", "f1", "f2", "label")
FROM ml.hp_grid g
CROSS JOIN ml.training_data t
GROUP BY g."group_key";
```

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.hp_search(
    group_key DECIMAL(18,0), n_est DECIMAL(10,0), max_d DECIMAL(10,0),
    f1 DOUBLE, f2 DOUBLE, label DOUBLE
)
EMITS (n_estimators DECIMAL(10,0), max_depth DECIMAL(10,0), cv_rmse DOUBLE) AS
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score
import numpy as np

CHUNK = 5000

def run(ctx):
    X_parts, y_parts = [], []
    n_est = max_d = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['group_key', 'n_est', 'max_d', 'f1', 'f2', 'label']
        if n_est is None:
            n_est = int(df['n_est'].iloc[0])
            max_d = int(df['max_d'].iloc[0])
        X_parts.append(df[['f1', 'f2']].values)
        y_parts.append(df['label'].values)

    X = np.vstack(X_parts)
    y = np.concatenate(y_parts)
    model = RandomForestRegressor(n_estimators=n_est, max_depth=max_d)
    scores = cross_val_score(model, X, y, scoring='neg_root_mean_squared_error', cv=5)
    ctx.emit(n_est, max_d, float(-scores.mean()))
/
```

**Optimization**: batch multiple HP configs per group with `MOD(group_key, N)` to amortize UDF startup cost when the grid is large.

---

## 8. Iterative Algorithms

### Preferred: Lua Execute Script with `query`

Orchestrate iterations entirely in-database. See **exasol-udfs** `references/lua-execute-scripts.md` for the `query`/`pquery` API — default to `query()` for these loops since it already raises on failure, so no error-handling wrapper is needed.

**K-means** — pure SQL + Lua, no UDFs needed. A naive assignment/update loop has three gaps that matter at scale: it never stops early once centroids settle, it can silently lose clusters, and it can seed duplicate centroids. The version below fixes all three.

**Prerequisite:** `source_table` should be `DISTRIBUTE BY "id"` — see **exasol-database** `references/table-design.md`. Both the assignment step's per-point nearest-centroid lookup and the update step's join back to `source_table` key off `"id"`, so distributing on it keeps each point's row on the node that computes its own assignment.

The update step's `GROUP BY a.centroid_id` only ever emits a row for centroid IDs that have at least one assigned point — there is no "empty group" row, not even with `NULL` aggregates. If a centroid attracts zero points in some iteration, its row disappears from `ml.centroids` entirely and the cluster count silently drops below `k` for every remaining iteration unless something detects and fixes it. The fix: snapshot centroids before the update, diff old vs. new IDs to find anything missing, and reseed each missing centroid at the point currently farthest from its own (surviving) centroid — the standard remedy for the k-means empty-cluster problem, expressible with two `ROW_NUMBER()` rankings joined rank-to-rank (no UDF, no cross-join fan-out).

```sql
CREATE OR REPLACE LUA SCRIPT ml.kmeans_orchestrator(
  source_table  VARCHAR(200),
  k             INT,
  max_iter      INT,
  tol           DOUBLE
) AS
-- Initialize: sample k DISTINCT points as starting centroids. Sampling
-- from distinct feature vectors (not raw rows) avoids seeding two
-- centroids at the exact same point when source_table has duplicate
-- or near-duplicate rows. Needs >= k distinct ("f1","f2") vectors.
query([[
  CREATE OR REPLACE TABLE ml.centroids AS
  SELECT ROW_NUMBER() OVER (ORDER BY "sample_order") AS centroid_id, "f1", "f2"
  FROM (
    SELECT "f1", "f2", RAND() AS "sample_order"
    FROM (SELECT DISTINCT "f1", "f2" FROM ]] .. source_table .. [[) d
    ORDER BY "sample_order"
    LIMIT ]] .. k .. [[
  ) sampled]])

for iter = 1, max_iter do
  -- Snapshot centroids before this iteration's update — used both to
  -- measure convergence and to identify any centroid that loses all
  -- its points below.
  query("CREATE OR REPLACE TABLE ml.centroids_prev AS SELECT * FROM ml.centroids")

  -- Assignment: each point gets the nearest centroid (distributed scan)
  query([[
    CREATE OR REPLACE TABLE ml.assignments AS
    SELECT
      p."id",
      (SELECT c.centroid_id
       FROM ml.centroids_prev c
       ORDER BY (p."f1" - c."f1") * (p."f1" - c."f1")
              + (p."f2" - c."f2") * (p."f2" - c."f2")
       LIMIT 1) AS centroid_id
    FROM ]] .. source_table .. [[ p]])

  -- Update: recompute centroids as group means (distributed aggregation).
  -- A centroid_id with zero assigned points has no row here at all.
  query([[
    CREATE OR REPLACE TABLE ml.centroids_updated AS
    SELECT a.centroid_id, AVG(p."f1") AS "f1", AVG(p."f2") AS "f2"
    FROM ml.assignments a
    JOIN ]] .. source_table .. [[ p ON p."id" = a."id"
    GROUP BY a.centroid_id]])

  -- Reseed any centroid that lost all its points: pair each missing
  -- centroid_id (present in centroids_prev, absent from
  -- centroids_updated) with the point currently farthest from its own
  -- (surviving) centroid, ranked on both sides via ROW_NUMBER() so no
  -- cross join is needed.
  query([[
    CREATE OR REPLACE TABLE ml.centroids AS
    SELECT centroid_id, "f1", "f2" FROM ml.centroids_updated
    UNION ALL
    SELECT missing.centroid_id, farthest."f1", farthest."f2"
    FROM (
      SELECT prev.centroid_id,
             ROW_NUMBER() OVER (ORDER BY prev.centroid_id) AS rn
      FROM ml.centroids_prev prev
      LEFT JOIN ml.centroids_updated upd ON upd.centroid_id = prev.centroid_id
      WHERE upd.centroid_id IS NULL
    ) missing
    JOIN (
      SELECT p."f1", p."f2",
             ROW_NUMBER() OVER (
               ORDER BY (p."f1" - cu."f1") * (p."f1" - cu."f1")
                      + (p."f2" - cu."f2") * (p."f2" - cu."f2") DESC
             ) AS rn
      FROM ml.assignments a
      JOIN ]] .. source_table .. [[ p ON p."id" = a."id"
      JOIN ml.centroids_updated cu ON cu.centroid_id = a.centroid_id
    ) farthest ON farthest.rn = missing.rn]])

  -- Convergence check: max squared movement of any centroid since the
  -- start of this iteration. A reseeded centroid shows a large
  -- "movement" by construction, so this correctly avoids declaring
  -- convergence while a cluster is still being re-seeded.
  local res = query([[
    SELECT MAX(
      (n."f1" - p."f1") * (n."f1" - p."f1")
    + (n."f2" - p."f2") * (n."f2" - p."f2")
    )
    FROM ml.centroids n
    JOIN ml.centroids_prev p ON p.centroid_id = n.centroid_id]])

  local max_shift = tonumber(res[1][1])
  output("Iteration " .. iter .. " complete (max centroid shift " .. tostring(max_shift) .. ")")

  if max_shift ~= nil and max_shift < tol then
    output("Converged at iteration " .. iter)
    break
  end
end
/

EXECUTE SCRIPT ml.kmeans_orchestrator('ml.features', 5, 20, 0.0001) WITH OUTPUT;
```

`tol` is a **squared**-distance threshold (sum of squared per-feature differences, not Euclidean distance) — `0.0001` stops the loop once no centroid moves more than roughly `0.01` in combined per-dimension terms between iterations.

**SGD with distributed gradients** — Lua orchestrates, Python SET script does the heavy work:

```lua
for iter = 1, max_iter do
    query("INSERT INTO ml.gradients "
     .. "SELECT compute_gradients(\"id\", \"f1\", \"f2\", \"label\", " .. iter .. ") "
     .. "FROM ml.features GROUP BY \"partition_key\"")
    query("INSERT INTO ml.params "
     .. "SELECT update_params(\"gradient\") "
     .. "FROM ml.gradients WHERE \"iter\" = " .. iter .. " GROUP BY 'x'")
    local res = query("SELECT \"loss\" FROM ml.params WHERE \"iter\" = " .. iter)
    if tonumber(res[1][1]) < 0.001 then break end
end
```

**Apriori for frequent itemset mining** — Lua iterates k (itemset size):

```lua
-- k=1: count individual item support
query("CREATE OR REPLACE TABLE ml.freq_1 AS "
 .. "SELECT \"item\", COUNT(DISTINCT \"txn_id\") AS support "
 .. "FROM market.transactions GROUP BY \"item\" "
 .. "HAVING COUNT(DISTINCT \"txn_id\") >= " .. min_support)

-- k=2: count pairs
query("CREATE OR REPLACE TABLE ml.freq_2 AS "
 .. "SELECT t1.\"item\" AS item1, t2.\"item\" AS item2, COUNT(DISTINCT t1.\"txn_id\") AS support "
 .. "FROM market.transactions t1 "
 .. "JOIN market.transactions t2 ON t1.\"txn_id\" = t2.\"txn_id\" AND t1.\"item\" < t2.\"item\" "
 .. "JOIN ml.freq_1 f1 ON f1.\"item\" = t1.\"item\" "
 .. "JOIN ml.freq_1 f2 ON f2.\"item\" = t2.\"item\" "
 .. "GROUP BY t1.\"item\", t2.\"item\" "
 .. "HAVING COUNT(DISTINCT t1.\"txn_id\") >= " .. min_support)

-- At k>=3, join fanout becomes prohibitive — hand off to SON algorithm (Section 6)
```

`CREATE TABLE ... AS SELECT` doesn't reliably report a row count on its own — follow each step with `local res = query("SELECT COUNT(*) FROM ml.freq_" .. k)` and stop iterating once `tonumber(res[1][1]) == 0`.

### Fallback: External Python Driver

For complex orchestration or existing Python training pipelines. Calls `exapump sql` in a loop with the same logical structure as the Lua approach:

```python
import subprocess

def run_sql(query):
    result = subprocess.run(
        ['exapump', 'sql', '--profile', 'default', query],
        capture_output=True, text=True, check=True
    )
    return result.stdout

for iteration in range(max_iter):
    run_sql(f"INSERT INTO ml.gradients SELECT compute_gradients(..., {iteration}) FROM ml.features GROUP BY partition_key")
    loss = float(run_sql("SELECT loss FROM ml.params ORDER BY iter DESC LIMIT 1"))
    if loss < 0.001:
        break
```

---

## 9. Per-Entity Forecasting

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.forecast_entity(
    entity_id DECIMAL(18,0), feature_ts TIMESTAMP, value DOUBLE
)
EMITS (entity_id DECIMAL(18,0), forecast_ts TIMESTAMP, forecast DOUBLE) AS
from statsmodels.tsa.arima.model import ARIMA
import pandas as pd
import numpy as np

CHUNK = 10000

def run(ctx):
    parts = []
    entity = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'ts', 'value']
        if entity is None:
            entity = int(df['entity_id'].iloc[0])
        parts.append(df)

    df = pd.concat(parts).sort_values('ts')
    series = df['value'].values

    model = ARIMA(series, order=(2, 1, 2))
    fit = model.fit()
    forecasts = fit.forecast(steps=10)

    last_ts = df['ts'].iloc[-1]
    for i, fc in enumerate(forecasts):
        forecast_ts = pd.Timestamp(last_ts) + pd.DateOffset(periods=i+1)
        ctx.emit(entity, forecast_ts, float(fc))
/

-- ORDER BY within groups is respected
SELECT ml.forecast_entity(entity_id, feature_ts, value)
FROM ml.timeseries
GROUP BY entity_id
ORDER BY feature_ts;
```

---

## 10. Anomaly Detection

IsolationForest runs independently per entity — embarrassingly parallel:

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.detect_anomalies(
    entity_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE
)
EMITS (entity_id DECIMAL(18,0), is_anomaly BOOLEAN, anomaly_score DOUBLE) AS
from sklearn.ensemble import IsolationForest
import numpy as np

CHUNK = 5000

def run(ctx):
    X_parts = []
    entity = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'f1', 'f2']
        if entity is None:
            entity = int(df['entity_id'].iloc[0])
        X_parts.append(df[['f1', 'f2']].values)

    X = np.vstack(X_parts)
    model = IsolationForest(contamination=0.05)
    predictions = model.fit_predict(X)
    scores = model.decision_function(X)

    for pred, score in zip(predictions, scores):
        ctx.emit(entity, bool(pred == -1), float(score))
/

SELECT ml.detect_anomalies(entity_id, "f1", "f2")
FROM ml.sensor_data
GROUP BY entity_id;
```
