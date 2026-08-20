# GPU Acceleration

Exasol supports GPU-accelerated UDFs via CUDA-enabled Script Language Containers. For SLC build/deploy basics see **exasol-udfs** `references/slc-reference.md`.

---

## Prerequisites

- **Exasol 2025.2+ on-premises** — GPU support is not available in earlier versions or in Exasol SaaS
- **NVIDIA driver on the Exasol host OS** — not inside the container; the container uses the host driver via CUDA compatibility
- If the host CUDA driver is older than v575, also install `cuda-compat-12.9.1` inside the SLC
- GPU UDFs run on **all nodes with GPUs** — if only some nodes have GPUs, those queries will fail on GPU-less nodes; use per-session SLC activation to restrict GPU sessions

## Enabling GPU Access in a UDF

GPU access is opt-in **per script**, not automatic just because the SLC contains CUDA libraries. Two things are required:

1. The script must be declared with the **`PYTHON_GPU`** script language, not `PYTHON3`.
2. The script body must set the `%perInstanceRequiredAcceleratorDevices` option, using the alternative `--/` statement delimiter so the `%`-line isn't parsed as part of the SQL statement:

```sql
--/
CREATE OR REPLACE PYTHON_GPU SCALAR SCRIPT ml.gpu_example()
RETURNS VARCHAR(20) AS
%perInstanceRequiredAcceleratorDevices GpuNvidia;
...
/
```

`perInstanceRequiredAcceleratorDevices` accepts:

| Value | Effect |
|-------|--------|
| `None` | No accelerator (implicit default) — always CPU. |
| `GpuNvidia` | GPU **required** — execution fails if no GPU is available. |
| `GpuNvidia\|None` | GPU **preferred** with CPU fallback — use for code that runs either way. |

Constraints:

- All UDF types (Scalar/Set, Return/Emits) are supported; **Lua is not supported**.
- Only the `run()` callback (and its init/cleanup) gets GPU access — `import_spec`/`export_spec` callbacks, dynamic output parameter callbacks, and virtual schema adapter scripts ignore the option.
- The option must be set on the **importing** UDF only. Setting it on an imported library script is a syntax error — imported scripts inherit GPU access from the UDF that imports them.
- The SLC activated for the script must be built from a CUDA-enabled flavor (see below) or execution fails even with the option set.

### Verify GPU availability

```sql
--/
CREATE OR REPLACE PYTHON_GPU SET SCRIPT ml.check_gpu()
EMITS (node_id INT, has_gpu BOOLEAN, gpu_name VARCHAR(200)) AS
%perInstanceRequiredAcceleratorDevices GpuNvidia|None;
def run(ctx):
    try:
        import torch
        has_gpu = torch.cuda.is_available()
        gpu_name = torch.cuda.get_device_name(0) if has_gpu else 'none'
    except ImportError:
        has_gpu = False
        gpu_name = 'torch not installed'
    ctx.emit(exa.meta.node_id, has_gpu, gpu_name)
/

SELECT ml.check_gpu() FROM (SELECT 1) GROUP BY 'x';
```

This uses `GpuNvidia|None` (prefer, CPU fallback) rather than enforcing `GpuNvidia`, since the whole point of this script is to report whether a GPU is present — it should still run and report `has_gpu = FALSE` on nodes without one.

---

## Building a CUDA SLC

Use the `template-Exasol-8-python-3.10-cuda-conda` flavor (or `3.12` variant for newer libraries).

### Install PyTorch with CUDA

In `flavor_customization/Dockerfile`:

```dockerfile
RUN conda install -y -c pytorch -c nvidia \
    pytorch torchvision torchaudio pytorch-cuda=12.1 && \
    conda clean -afy
```

### Install TensorFlow with CUDA

```dockerfile
RUN pip install tensorflow[and-cuda]
```

### Install RAPIDS (cuDF, cuML)

```dockerfile
RUN conda install -y -c rapidsai -c conda-forge -c nvidia \
    cudf=24.04 cuml=24.04 python=3.10 cuda-version=12.0 && \
    conda clean -afy
```

### Build and deploy

```bash
exaslct export \
    --flavor-path=flavors/template-Exasol-8-python-3.10-cuda-conda \
    --export-path ./output

exaslct deploy \
    --flavor-path=flavors/template-Exasol-8-python-3.10-cuda-conda \
    --bucketfs-host <host> --bucketfs-port 2581 \
    --bucketfs-user w --bucketfs-password <pw> \
    --bucketfs-name bfsdefault --bucket default \
    --path-in-bucket slc/cuda-ml
```

### Activate per session (recommended — avoids failures on GPU-less nodes)

The alias registered here must match the script language used in `CREATE ... SCRIPT` — `PYTHON_GPU`, not `PYTHON3`:

```sql
ALTER SESSION SET SCRIPT_LANGUAGES =
    'PYTHON_GPU=localzmq+protobuf:///bfsdefault/default/slc/cuda-ml?lang=python'
    || '#buckets/bfsdefault/default/slc/cuda-ml/exaudf/exaudfclient_py3';
```

---

## PyTorch Inference UDF

Use TorchScript (`torch.jit.save/load`) rather than pickle for PyTorch models — it is Python-version-independent.

```sql
--/
CREATE OR REPLACE PYTHON_GPU SET SCRIPT ml.torch_predict(
    id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE, f3 DOUBLE
)
EMITS (id DECIMAL(18,0), prediction DOUBLE) AS
%perInstanceRequiredAcceleratorDevices GpuNvidia|None;
import torch
import numpy as np

_model = torch.jit.load('/buckets/bfsdefault/default/models/my_model.pt')
_model.eval()
_device = 'cuda' if torch.cuda.is_available() else 'cpu'
_model = _model.to(_device)

CHUNK = 10000

def run(ctx):
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['id', 'f1', 'f2', 'f3']
        X = torch.tensor(
            df[['f1', 'f2', 'f3']].values,
            dtype=torch.float32
        ).to(_device)
        with torch.no_grad():
            preds = _model(X).cpu().numpy().flatten()
        df['prediction'] = preds
        ctx.emit(df[['id', 'prediction']])
/
```

**Export the model before uploading** (in training environment):

```python
scripted = torch.jit.script(model)
torch.jit.save(scripted, 'my_model.pt')
```

```bash
exapump bucketfs cp my_model.pt models/my_model.pt
```

---

## RAPIDS cuML (GPU-Accelerated scikit-learn)

Convert each chunk to a `cudf.DataFrame` and accumulate on the GPU as it streams in, rather than collecting pandas chunks in host memory and converting once at the end — the latter is bounded by the UDF's host `memory_limit` before a single byte reaches the GPU, while moving chunks over immediately bounds memory by GPU memory instead:

```sql
--/
CREATE OR REPLACE PYTHON_GPU SET SCRIPT ml.rapids_kmeans(
    entity_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE
)
EMITS (entity_id DECIMAL(18,0), cluster_id INT) AS
%perInstanceRequiredAcceleratorDevices GpuNvidia;
import cudf
from cuml.cluster import KMeans

N_CLUSTERS = 5
CHUNK = 50000

def run(ctx):
    gdf_parts = []
    entity = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'f1', 'f2']
        if entity is None:
            entity = int(df['entity_id'].iloc[0])
        # Move this chunk to the GPU now instead of holding it in host memory
        gdf_parts.append(cudf.DataFrame.from_pandas(df))

    gdf_all = cudf.concat(gdf_parts)

    kmeans = KMeans(n_clusters=N_CLUSTERS)
    labels = kmeans.fit_predict(gdf_all[['f1', 'f2']])

    gdf_all['cluster_id'] = labels
    ctx.emit(gdf_all[['entity_id', 'cluster_id']].to_pandas())
/

SELECT ml.rapids_kmeans(entity_id, "f1", "f2")
FROM ml.features
GROUP BY entity_id;
```

This uses `GpuNvidia` (enforced) rather than `GpuNvidia|None` — cuDF/cuML have no CPU fallback path, so there's nothing useful this UDF can do without a GPU.

Note: UDF instances currently cannot communicate with each other, so there's no way to shard a single large group's GPU work across multiple instances or nodes — a group's data (and the GPU memory it needs) is confined to whichever one instance processes it.

---

## GPU Memory Management

GPUs are a managed, **exclusively-reserved** resource in Exasol — independent of the general resource manager and its consumer groups. In each select/sub-select statement, only a **single UDF call** is allowed exclusive use of all available GPUs; the reservation is made per UDF call.

- **Across concurrent queries**: if multiple queries, each containing one GPU-accelerated UDF call, run at the same time, Exasol automatically **serializes** them — each waits until the GPUs are freed by the others. You don't need to manually run them in separate sessions to avoid contention; that serialization already happens.
- **Within a single query**: using more than one GPU-accelerated UDF call in the same select/sub-select is **not safely supported** — it's undefined which call actually gets the GPUs; the rest either fail or silently fall back to CPU, depending on their `perInstanceRequiredAcceleratorDevices` value (`GpuNvidia` fails, `GpuNvidia|None` falls back).

Recommendations from the docs:

- **Use only one GPU-accelerated UDF call per query** — avoids the undefined multi-UDF contention above entirely.
- **Use UDF instance limiting** to control how many instances of *that one* UDF call share the reserved GPUs among themselves, with `perNodeAndCallInstanceLimit` alongside `perInstanceRequiredAcceleratorDevices`. For example, to force all of one UDF call's work onto a single instance so it has the node's GPUs to itself:
  ```sql
  --/
  CREATE OR REPLACE PYTHON_GPU SCALAR SCRIPT ml.gpu_example()
  RETURNS VARCHAR(20) AS
  %perNodeAndCallInstanceLimit 1;
  %perInstanceRequiredAcceleratorDevices GpuNvidia;
  ...
  /
  ```
- **Use query timeouts** (`QUERY_TIMEOUT` — system level via `ALTER SYSTEM`, session level via `ALTER SESSION`, or consumer-group level via the resource manager) on queries with GPU-accelerated UDFs, so a runaway query can't hold the exclusive GPU reservation indefinitely and block every other GPU query behind it.

Independently of the reservation model above, free GPU memory within a single instance as work completes:

```python
def run(ctx):
    try:
        # ... GPU work ...
        pass
    finally:
        try:
            import torch
            torch.cuda.empty_cache()
        except Exception:
            pass
```
