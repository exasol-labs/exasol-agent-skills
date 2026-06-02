---
name: exasol-transformers
description: "Deploy and use the Exasol Transformers Extension for NLP/ML inference inside Exasol UDFs using Hugging Face models. Covers initialize_te_extension, deploy_scripts, upload_model, all constants (LANGUAGE_ALIAS, ACTIVATION_KEY, BFS_CONNECTION_PREFIX, HF_CONNECTION_PREFIX), selective initialization, and running inference via SQL. Requires the exasol-ai-setup skill to be completed first."
---

# Exasol Transformers Extension Skill

Trigger when the user mentions **Transformers Extension**, **Hugging Face models in Exasol**, **NLP in Exasol**, **TE extension**, **initialize_te_extension**, **deploy_scripts**, **upload_model**, **transformers UDF**, **PYTHON3_TE**, or any NLP/ML inference task inside an Exasol database.

## Prerequisites

The SCS must be configured. If not yet done, activate the **exasol-ai-setup** skill first.

Install dependencies:

```bash
pip install exasol-notebook-connector exasol-transformers-extension
```

---

## Key Constants

These constants are defined in `exasol.nb_connector.transformers_extension_wrapper`:

| Constant | Value | Purpose |
|----------|-------|---------|
| `LANGUAGE_ALIAS` | `"PYTHON3_TE"` | Language alias for the TE Script Language Container |
| `ACTIVATION_KEY` | `"ACTIVATION_KEY_PREFIX + 'te'"` | SCS key where activation SQL is saved |
| `BFS_CONNECTION_PREFIX` | `"TE_BFS"` | Prefix for BucketFS connection objects in DB |
| `HF_CONNECTION_PREFIX` | `"TE_HF"` | Prefix for Hugging Face token connection objects in DB |
| `MODELS_CACHE_DIR` | `"models_cache"` | Local directory for cached Hugging Face models |
| `LATEST_KNOWN_VERSION` | auto-detected | Package version used when no version is specified |

---

## Step 1: Initialize the Extension

Use this first-run example when the user wants notebook-connector to deploy the TE language container, create the required connection objects, and install the TE scripts in one pass.

```python
from pathlib import Path
from exasol.nb_connector.secret_store import Secrets
from exasol.nb_connector.transformers_extension_wrapper import initialize_te_extension

conf = Secrets(db_file=Path("ai_config.db"), master_password="<master-password>")

# Full initialization: deploys SLC, scripts, BFS connection, and HF token connection
initialize_te_extension(conf)
```

### What `initialize_te_extension` does (in order)

1. **Deploys the Script Language Container (SLC)** — downloads the TE SLC from GitHub releases and uploads it to BucketFS at `ai-lab/slc/`. Saves the activation SQL to the SCS under `ACTIVATION_KEY`.
2. **Creates the BucketFS connection object** — calls `ensure_bfs_connection(conf)` which runs `CREATE OR REPLACE CONNECTION [bfs_ai_lab_connection] ...` in the DB, encapsulating BucketFS credentials. The connection name is saved in `CKey.bfs_connection_name`.
3. **Ensures model subdirectory** — saves `CKey.bfs_model_subdir` in SCS if not already present.
4. **Deploys UDF scripts** — calls `deploy_scripts(conf, language_alias)` which activates the language container at session level and deploys all TE scripts into `db_schema`.
5. **Creates Hugging Face connection object** — if `CKey.huggingface_token` is in the SCS, creates `CREATE OR REPLACE CONNECTION [TE_HF_<db_user>] ...` in the DB. Saves the name to `CKey.te_hf_connection`.
6. **Saves model cache directory** — saves `MODELS_CACHE_DIR` to `CKey.te_models_cache_dir`.

### Selective Initialization (skip already-done steps)

Use this variant when the agent already knows some setup steps are complete and wants to avoid repeating slow or destructive work.

```python
initialize_te_extension(
    conf,
    version="1.2.0",                         # specific version; default: latest known
    language_alias="PYTHON3_TE",             # override language alias (normally for testing only)
    run_deploy_container=True,               # upload SLC to BucketFS (~1-2 GB, slow)
    run_deploy_scripts=True,                 # deploy UDF scripts into the DB schema
    run_encapsulate_bfs_credentials=True,    # create BFS connection object in DB
    run_encapsulate_hf_token=True,           # create HF token connection object in DB
    allow_override=True,                     # allow re-deploying over existing language alias
)
```

**Tip:** On subsequent runs, set `run_deploy_container=False` to skip the slow SLC upload if the container is already in BucketFS.

---

## Step 2: Deploy Scripts Only (standalone)

To re-deploy only the UDF scripts without touching the SLC or connection objects:

Use this when the language container is already present and the user only needs the TE SQL/UDF layer refreshed.

```python
from exasol.nb_connector.transformers_extension_wrapper import deploy_scripts

deploy_scripts(conf, language_alias="PYTHON3_TE")
```

This:
1. Opens a pyexasol connection.
2. Retrieves the activation SQL from the SCS (`get_activation_sql(conf)`) and executes it at session level.
3. Runs `ScriptsDeployer` to deploy all TE scripts into `conf.db_schema` with `install_all_scripts=True`.

---

## Step 3: Upload a Model

Models must be uploaded to BucketFS before they can be used in UDFs.

Use this example when the user needs to make a Hugging Face model available to the deployed Transformers Extension.

```python
from exasol.nb_connector.transformers_extension_wrapper import upload_model

upload_model(
    conf=conf,
    model_name="prajjwal1/bert-tiny",   # any Hugging Face model identifier
    cache_dir="/tmp/model_cache",        # local directory to cache the model
)
```

- If `CKey.huggingface_token` is in the SCS, it is passed automatically to the Hugging Face API.
- Additional keyword arguments are forwarded to `AutoTokenizer.from_pretrained` and `AutoModel.from_pretrained`.
- An explicit `token` kwarg overrides the token in the SCS.

### Supported model types (examples)

| Task | Example model |
|------|--------------|
| Text classification | `distilbert-base-uncased-finetuned-sst-2-english` |
| Token classification (NER) | `dslim/bert-base-NER` |
| Text generation | `gpt2` |
| Question answering | `deepset/roberta-base-squad2` |
| Zero-shot classification | `facebook/bart-large-mnli` |
| Feature extraction / embeddings | `sentence-transformers/all-MiniLM-L6-v2` |
| Fill mask | `bert-base-uncased` |
| Translation | `Helsinki-NLP/opus-mt-en-de` |
| Summarization | `facebook/bart-large-cnn` |

---

## Step 4: Retrieve Connection Object Names

After initialization, the connection object names are saved in the SCS:

Use this readback step when later SQL or deployment steps need the exact persisted connection names or model paths.

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey

bfs_connection = conf.get(CKey.bfs_connection_name)    # e.g. "bfs_ai_lab_connection"
hf_connection  = conf.get(CKey.te_hf_connection)       # e.g. "TE_HF_sys" (or "" if no token)
models_subdir  = conf.get(CKey.bfs_model_subdir)
cache_dir      = conf.get(CKey.te_models_cache_dir)    # "models_cache"
```

---

## Step 5: Run Inference via SQL

After deployment, call TE UDF scripts directly in SQL. All scripts are in `db_schema`.

**Important:** Substitute `<schema>`, `<bfs_conn>`, and `<hf_conn>` with values from the SCS.

### Text Classification

This query pattern classifies each input text with a named Hugging Face classification model through the deployed TE UDF.

```sql
SELECT "<schema>".TE_TEXT_CLASSIFY(
    <text_column>,
    'distilbert-base-uncased-finetuned-sst-2-english',
    '<bfs_conn>',
    '<hf_conn>'
)
FROM my_table;
```

### Token Classification (NER)

This query pattern extracts named entities and labels from each input text.

```sql
SELECT "<schema>".TE_TOKEN_CLASSIFY(
    <text_column>,
    'dslim/bert-base-NER',
    '<bfs_conn>',
    '<hf_conn>'
)
FROM my_table;
```

### Text Generation

This query pattern uses a generative model to produce text continuations from prompt values stored in the table.

```sql
SELECT "<schema>".TE_TEXT_GENERATE(
    <prompt_column>,
    'gpt2',
    '<bfs_conn>',
    '<hf_conn>'
)
FROM my_table;
```

### Zero-Shot Classification

This query pattern classifies each text against runtime-provided labels without a task-specific fine-tuned model in the database code itself.

```sql
SELECT "<schema>".TE_ZERO_SHOT_CLASSIFY(
    <text_column>,
    'label1,label2,label3',
    'facebook/bart-large-mnli',
    '<bfs_conn>',
    '<hf_conn>'
)
FROM my_table;
```

### Feature Extraction / Embeddings

This query pattern produces vector-like feature outputs or embeddings for downstream search, clustering, or similarity use cases.

```sql
SELECT "<schema>".TE_FEATURE_EXTRACT(
    <text_column>,
    'sentence-transformers/all-MiniLM-L6-v2',
    '<bfs_conn>',
    '<hf_conn>'
)
FROM my_table;
```

---

## Complete Example

Use this full example when the user wants one Python flow that covers first-run TE setup, model upload, and post-setup inspection.

```python
from pathlib import Path
from exasol.nb_connector.secret_store import Secrets
from exasol.nb_connector.transformers_extension_wrapper import (
    initialize_te_extension,
    upload_model,
    deploy_scripts,
)
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey

conf = Secrets(db_file=Path("ai_config.db"), master_password="s3cr3t")

# First run: full initialization
initialize_te_extension(conf)

# Upload a model
upload_model(conf, model_name="prajjwal1/bert-tiny", cache_dir="/tmp/cache")

# Check connection names
print("BFS connection:", conf.get(CKey.bfs_connection_name))
print("HF connection:", conf.get(CKey.te_hf_connection))

# Subsequent runs: skip SLC upload
# initialize_te_extension(conf, run_deploy_container=False)

# Or just re-deploy scripts alone
# deploy_scripts(conf, language_alias="PYTHON3_TE")
```

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `RuntimeError: Language alias already exists` | SLC already deployed | Set `allow_override=True` |
| `NotImplementedError` on `upload_model_from_cache` | Temporarily disabled | Use `upload_model()` directly |
| Model not found in UDF | Model not uploaded | Run `upload_model()` first |
| SLC upload very slow | SLC is ~1-2 GB | Expected; run once, then set `run_deploy_container=False` |
| `AttributeError` for `bfs_connection_name` | `ensure_bfs_connection` not called | Run `initialize_te_extension` or call `ensure_bfs_connection(conf)` |

---

## Related Skills

- **exasol-ai-setup**: Configure the SCS and DB/BucketFS credentials first.
- **exasol-text-ai**: Higher-level Text AI Extension with built-in default models and extraction pipeline API.
- **exasol-bucketfs**: Inspect or manage BucketFS files directly.
- **exasol-udfs**: Write custom UDF scripts in Exasol.
