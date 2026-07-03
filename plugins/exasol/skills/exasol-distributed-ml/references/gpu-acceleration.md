# GPU Acceleration

Exasol supports GPU-accelerated UDFs via CUDA-enabled Script Language Containers. For SLC build/deploy basics see **exasol-udfs** `references/slc-reference.md`.

---

## Prerequisites

- **Exasol 2025.1+** — GPU passthrough is not available in earlier versions
- **NVIDIA driver on the Exasol host OS** — not inside the container; the container uses the host driver via CUDA compatibility
- If the host CUDA driver is older than v575, also install `cuda-compat-12.9.1` inside the SLC
- GPU UDFs run on **all nodes with GPUs** — if only some nodes have GPUs, those queries will fail on GPU-less nodes; use per-session SLC activation to restrict GPU sessions

### Verify GPU availability

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.check_gpu()
EMITS (node_id INT, has_gpu BOOLEAN, gpu_name VARCHAR(200)) AS
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

SELECT ml.check_gpu() FROM (SELECT 1) GROUP BY 0;
```

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

```sql
ALTER SESSION SET SCRIPT_LANGUAGES =
    'PYTHON3=localzmq+protobuf:///bfsdefault/default/slc/cuda-ml?lang=python'
    || '#buckets/bfsdefault/default/slc/cuda-ml/exaudf/exaudfclient_py3';
```

---

## PyTorch Inference UDF

Use TorchScript (`torch.jit.save/load`) rather than pickle for PyTorch models — it is Python-version-independent.

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.torch_predict(
    id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE, f3 DOUBLE
)
EMITS (id DECIMAL(18,0), prediction DOUBLE) AS
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

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT ml.rapids_kmeans(
    entity_id DECIMAL(18,0), f1 DOUBLE, f2 DOUBLE
)
EMITS (entity_id DECIMAL(18,0), cluster_id INT) AS
import cudf
import numpy as np
from cuml.cluster import KMeans

N_CLUSTERS = 5
CHUNK = 50000

def run(ctx):
    parts = []
    entity = None
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        df.columns = ['entity_id', 'f1', 'f2']
        if entity is None:
            entity = int(df['entity_id'].iloc[0])
        parts.append(df)

    import pandas as pd
    df_all = pd.concat(parts)
    gdf = cudf.from_pandas(df_all[['f1', 'f2']])

    kmeans = KMeans(n_clusters=N_CLUSTERS)
    labels = kmeans.fit_predict(gdf).to_pandas()

    df_all['cluster_id'] = labels.values
    ctx.emit(df_all[['entity_id', 'cluster_id']])
/

SELECT ml.rapids_kmeans(entity_id, "f1", "f2")
FROM ml.features
GROUP BY entity_id;
```

---

## GPU Memory Management

GPU memory is shared across all concurrent UDF processes on the same node. If multiple queries run GPU UDFs simultaneously, they compete for memory.

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

For serializing GPU-heavy queries, run them in separate sessions or use session-level resource groups if available. Avoid launching many parallel GPU queries on the same node.
