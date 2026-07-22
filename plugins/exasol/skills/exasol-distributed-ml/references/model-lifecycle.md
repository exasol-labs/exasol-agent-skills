# Model Lifecycle in BucketFS

Covers serialization format selection, versioning conventions, loading patterns inside UDFs, and cleanup. For BucketFS file operations (cp/ls/rm) see **exasol-bucketfs**.

---

## Serialization Format

Choose based on production lifespan and framework:

| Format | Library | Best For | Pros | Cons |
|--------|---------|----------|------|------|
| pickle | stdlib | scikit-learn, statsmodels, exploration | No extra deps, fast | Python-version coupled; untrusted files are a security risk |
| joblib | joblib | scikit-learn with large numpy arrays | Better compression for arrays | Same Python coupling |
| ONNX | onnx, onnxruntime | Production, cross-framework | Framework-agnostic, versioned schema, faster inference | Explicit export step |
| TorchScript | torch.jit | PyTorch production | No Python needed at inference time | PyTorch-only |
| SavedModel | tensorflow | TensorFlow production | Serving-ready | TF-only |

**Rule of thumb**: use ONNX for anything that will stay in production longer than a week. Use pickle/joblib for exploration and per-entity models trained inside UDFs (self-contained, short-lived).

---

## Versioning Convention

BucketFS has no directory metadata or symlinks. Use a path convention plus a JSON pointer file:

```
models/
  <model_name>/
    v1/
      model.<ext>
      metadata.json        ← version, training date, metrics, feature schema
    v2/
      model.<ext>
      metadata.json
    latest.json            ← {"version": "v2", "path": "models/iris_clf/v2/model.pkl"}
```

`latest.json` is a small pointer file. Updating the model is atomic: upload the new artifact and metadata, then overwrite `latest.json` (BucketFS writes are atomic — a file is either fully written or absent).

### Deploying a New Version

```bash
# 1. Upload new artifact
exapump bucketfs cp ./model_v3.pkl models/iris_clf/v3/model.pkl
exapump bucketfs cp ./metadata_v3.json models/iris_clf/v3/metadata.json

# 2. Atomically promote to latest
exapump bucketfs cp ./latest_v3.json models/iris_clf/latest.json
```

`latest_v3.json` content:
```json
{"version": "v3", "path": "models/iris_clf/v3/model.pkl"}
```

The UDF reads `latest.json` on each invocation (cached at module level — see loading pattern below).

---

## UDF Load Pattern

Load models at module level so the file is opened once per UDF process, not once per group.

### Single model (lazy init)

```python
import pickle, json

BUCKET = '/buckets/bfsdefault/default'
_model = None

def _load_model():
    global _model
    if _model is None:
        with open(f'{BUCKET}/models/iris_clf/latest.json') as f:
            meta = json.load(f)
        with open(f'{BUCKET}/{meta["path"]}', 'rb') as f:
            _model = pickle.load(f)
    return _model

def run(ctx):
    model = _load_model()
    ...
```

### Multi-model registry (keyed by entity or model name)

```python
import pickle, json

BUCKET = '/buckets/bfsdefault/default'
_registry = {}

def _get_model(model_key):
    if model_key not in _registry:
        try:
            with open(f'{BUCKET}/models/{model_key}/latest.json') as f:
                meta = json.load(f)
            with open(f'{BUCKET}/{meta["path"]}', 'rb') as f:
                _registry[model_key] = pickle.load(f)
        except FileNotFoundError:
            _registry[model_key] = None
    return _registry[model_key]

def run(ctx):
    # Pass 1: identify model key from first chunk
    df = ctx.get_dataframe(num_rows=1)
    model_key = str(df.iloc[0, 0])
    model = _get_model(model_key)
    ctx.reset()
    # Pass 2: predict
    ...
```

**Anti-pattern**: opening the model file inside `run()` causes one file open per group — catastrophic for performance when there are thousands of entities.

---

## ONNX Export and Inference

### Export (outside Exasol, in training environment)

```python
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

n_features = X_train.shape[1]
initial_type = [('float_input', FloatTensorType([None, n_features]))]
onnx_model = convert_sklearn(sklearn_model, initial_types=initial_type)
with open('model.onnx', 'wb') as f:
    f.write(onnx_model.SerializeToString())
```

Upload:
```bash
exapump bucketfs cp model.onnx models/iris_clf/v1/model.onnx
```

### Inference inside UDF (requires `onnxruntime` in SLC)

```python
import onnxruntime as rt
import numpy as np

_sess = rt.InferenceSession('/buckets/bfsdefault/default/models/iris_clf/v1/model.onnx')
_input_name = _sess.get_inputs()[0].name

def run(ctx):
    CHUNK = 10000
    while True:
        df = ctx.get_dataframe(num_rows=CHUNK)
        if df is None:
            break
        X = df[feature_cols].values.astype(np.float32)
        preds = _sess.run(None, {_input_name: X})[0].flatten()
        df['prediction'] = preds
        ctx.emit(df[['id', 'prediction']])
```

---

## Cleanup

```bash
# List all versions for a model
exapump bucketfs ls -r models/iris_clf/

# Remove an old version (always verify latest.json does NOT point to it first)
exapump bucketfs rm models/iris_clf/v1/model.pkl
exapump bucketfs rm models/iris_clf/v1/metadata.json

# Verify latest pointer is intact
exapump bucketfs ls models/iris_clf/
```
