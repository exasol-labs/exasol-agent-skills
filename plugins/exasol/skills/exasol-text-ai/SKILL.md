---
name: exasol-text-ai
description: "Deploy and use the Exasol Text AI Extension (TXAIE) for LLM-based text extraction — feature extraction, NER, zero-shot classification — directly inside Exasol. Covers deploy_license, initialize_text_ai_extension, Extraction API, ACTIVATION_KEY, LANGUAGE_ALIAS, BFS_CONNECTION_PREFIX constants, model repository, and Defaults. Requires the exasol-ai-setup skill to be completed first."
---

# Exasol Text AI Extension Skill

Trigger when the user mentions **Text AI Extension**, **TXAIE**, **txaie**, **text extraction in Exasol**, **NER in Exasol**, **zero-shot classification in Exasol**, **feature extraction in Exasol**, **initialize_text_ai_extension**, **deploy_license**, **Extraction**, **PYTHON3_TXAIE**, or any LLM-driven text analysis task inside Exasol.

## Prerequisites

The SCS must be configured. If not yet done, activate the **exasol-ai-setup** skill first.

Install dependencies:

Use this install command when the user has not yet added the notebook-connector and Text AI Extension packages to the current Python environment.

```bash
pip install exasol-notebook-connector exasol-text-ai-extension
```

---

## Key Constants

These constants are defined in `exasol.nb_connector.text_ai_extension_wrapper`:

| Constant | Value | Purpose |
|----------|-------|---------|
| `LANGUAGE_ALIAS` | `"PYTHON3_TXAIE"` | Language alias for the TXAIE Script Language Container |
| `ACTIVATION_KEY` | `"ACTIVATION_KEY_PREFIX + 'txaie'"` | SCS key where activation SQL is saved |
| `BFS_CONNECTION_PREFIX` | `"TXAIE_BFS"` | Prefix for BucketFS connection objects in DB |
| `MODELS_CACHE_DIR` | same as TE (`"models_cache"`) | Shared with TE for backwards compatibility |
| `LEGACY_UDF_CLIENT_BINARY` | `"exaudfclient_py3"` | UDF client binary name used in SLC activation |

---

## Step 1: Deploy a License

The Text AI Extension requires a license before any DB objects can be created.

Use this example for the default first-run case where the built-in community license is sufficient.

```python
from pathlib import Path
from exasol.nb_connector.secret_store import Secrets
from exasol.nb_connector.text_ai_extension_wrapper import deploy_license

conf = Secrets(db_file=Path("ai_config.db"), master_password="<master-password>")

# Deploy community license (built into the package, no arguments needed)
deploy_license(conf)
```

**Custom license file:**

Use this variant when the user already has a license file on disk and wants to deploy that exact license.

```python
deploy_license(conf, license_file=Path("/path/to/my_license.txt"))
```

**Inline license string:**

Use this variant when the license content is already available in memory and should not be written to a separate file first.

```python
deploy_license(conf, license_content="<license-content-string>")
```

Internally, `deploy_license` opens a pyexasol connection and calls `txai_licenses.create_connection()`.

---

## Step 2: Initialize the Extension

Use this first-run example when the user wants notebook-connector to install the TXAIE language container, default models, and SQL scripts in one pass.

```python
from exasol.nb_connector.text_ai_extension_wrapper import initialize_text_ai_extension

initialize_text_ai_extension(conf)
```

### What `initialize_text_ai_extension` does (in order)

1. **Updates SCS** — saves `MODELS_CACHE_DIR` to `CKey.txaie_models_cache_dir`.
2. **Ensures BucketFS connection** — calls `ensure_bfs_connection(conf)` → `CREATE OR REPLACE CONNECTION [bfs_ai_lab_connection] ...` in the DB; saves connection name to `CKey.bfs_connection_name`.
3. **Ensures model subdirectory** — saves `CKey.bfs_model_subdir` in SCS.
4. **Installs SLC** (if `install_slc=True`) — calls `deploy_language_container()` which:
   - Downloads the TXAIE SLC from GitHub releases (if `version` given) or from a local file (if `container_file` given), or detects the installed package version automatically.
   - Uploads the SLC to BucketFS at `ai-lab/slc/`.
   - Generates activation SQL and saves it to the SCS under `ACTIVATION_KEY`.
5. **Installs default models** (if `install_models=True`) — uploads 3 default Hugging Face models to BucketFS using `install_model()`:

   | Task | Default model |
   |------|--------------|
   | Feature extraction | `DEFAULT_FEATURE_EXTRACTION_MODEL` |
   | Named entity recognition | `DEFAULT_NAMED_ENTITY_MODEL` |
   | Zero-shot classification | `DEFAULT_NLI_MODEL` |

6. **Installs scripts** (if `install_scripts=True`) — opens a pyexasol connection with the configured schema and calls `create_scripts()` to deploy all TXAIE UDF scripts.

### Selective Initialization (skip already-done steps)

Use this variant when the agent already knows which parts are installed and wants to skip slow or redundant steps.

```python
initialize_text_ai_extension(
    conf,
    container_file=None,                  # optional: Path to local SLC tar.gz
    version=None,                         # optional: version string, e.g. "1.2.0"
    install_slc=True,                     # upload SLC to BucketFS (slow, ~2-3 GB)
    install_scripts=True,                 # deploy TXAIE scripts into DB schema
    install_models=True,                  # upload default HF models to BucketFS
    allow_override_language_alias=True,   # allow re-deploying over existing language alias
)
```

**Common patterns:**

Use these short variants when the user only needs one specific adjustment, such as skipping the SLC upload or installing from a pinned version.

```python
# Skip SLC if already uploaded
initialize_text_ai_extension(conf, install_slc=False)

# Install from a specific version
initialize_text_ai_extension(conf, version="1.2.0")

# Install from a local SLC file
initialize_text_ai_extension(conf, container_file=Path("/tmp/txaie_slc.tar.gz"))

# Only re-deploy scripts (fastest, no model/SLC work)
initialize_text_ai_extension(conf, install_slc=False, install_models=False)
```

---

## Step 3: Run Extractions via the Python API

The `Extraction` class is the main interface for running Text AI tasks. It wraps the full pipeline: gets activation SQL from SCS, opens a pyexasol connection, and runs the extraction.

### Import

Use these imports when the user wants to build a higher-level extraction pipeline instead of calling lower-level SQL UDFs directly.

```python
from exasol.nb_connector.text_ai_extension_wrapper import Extraction
from exasol.ai.text.extraction.abstract_extraction import Output, Defaults
```

### Feature Extraction (Embeddings)

This example shows how to generate embeddings or similar feature vectors from an input text column and write the results into a target table.

```python
from exasol.ai.text.extractors.feature_extractor import FeatureExtractor

extraction = Extraction(
    extractor=FeatureExtractor(
        input_table="AI_SCHEMA.PRODUCT_REVIEWS",
        input_column="REVIEW_TEXT",
    ),
    output=Output(
        table="AI_SCHEMA.REVIEW_EMBEDDINGS",
        columns=["REVIEW_ID", "EMBEDDING"],
    ),
)
extraction.run(conf)
```

### Named Entity Recognition (NER)

This example shows how to extract named entities and labels from a text column and persist them into an output table.

```python
from exasol.ai.text.extractors.ner_extractor import NERExtractor

extraction = Extraction(
    extractor=NERExtractor(
        input_table="AI_SCHEMA.DOCUMENTS",
        input_column="BODY",
    ),
    output=Output(
        table="AI_SCHEMA.ENTITIES",
        columns=["DOC_ID", "ENTITY", "LABEL", "SCORE"],
    ),
)
extraction.run(conf)
```

### Zero-Shot Classification

This example shows how to classify free-form text against runtime-supplied labels without training a task-specific model inside the user workflow.

```python
from exasol.ai.text.extractors.zero_shot_extractor import ZeroShotExtractor

extraction = Extraction(
    extractor=ZeroShotExtractor(
        input_table="AI_SCHEMA.REVIEWS",
        input_column="REVIEW_TEXT",
        candidate_labels=["positive", "negative", "neutral"],
    ),
    output=Output(
        table="AI_SCHEMA.REVIEW_CLASSES",
        columns=["REVIEW_ID", "LABEL", "SCORE"],
    ),
)
extraction.run(conf)
```

### Customizing Defaults (parallelism, batch size, model repository)

Use this block when the user needs to tune execution behavior rather than relying on the default extraction settings.

```python
extraction = Extraction(
    extractor=FeatureExtractor(...),
    output=Output(...),
    defaults=Defaults(
        parallelism_per_node=4,    # number of parallel UDF workers per node
        batch_size=32,             # inference batch size
        model_repository=None,     # if None, auto-resolved from SCS via create_model_repository(conf)
    ),
)
```

If `defaults.model_repository` is `None` (the default), `Extraction.run()` calls `defaults_with_model_repository(conf)` which automatically creates a model repository from the SCS using `create_model_repository(conf)`. You do not need to set this manually in normal use.

### How `Extraction.run()` works internally

This block is explanatory rather than a user script. It teaches the agent what notebook-connector resolves under the hood before the extraction runs.

```python
# Internally does:
activation_sql = get_activation_sql(conf)           # retrieves from SCS ACTIVATION_KEY
defaults = self.defaults_with_model_repository(conf) # resolves model_repository if needed
with open_pyexasol_connection(conf, compression=True) as connection:
    connection.execute(query=activation_sql)          # activates language container
    TextAiExtraction(...).run(
        pyexasol_con=connection,
        temporary_db_object_schema=conf.db_schema,
        language_alias="PYTHON3_TXAIE",
    )
```

---

## Step 4: Read Auto-Set SCS Keys After Initialization

Use this readback step when later debugging or follow-up code needs the resolved BucketFS connection name or model directory from the secure config store.

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey

bfs_conn   = conf.get(CKey.bfs_connection_name)        # e.g. "bfs_ai_lab_connection"
model_dir  = conf.get(CKey.bfs_model_subdir)
cache_dir  = conf.get(CKey.txaie_models_cache_dir)     # "models_cache"
```

---

## Complete Example

Use this full example when the user wants one Python flow that covers license deployment, TXAIE initialization, and an end-to-end extraction run.

```python
from pathlib import Path
from exasol.nb_connector.secret_store import Secrets
from exasol.nb_connector.text_ai_extension_wrapper import (
    deploy_license,
    initialize_text_ai_extension,
    Extraction,
)
from exasol.ai.text.extractors.feature_extractor import FeatureExtractor
from exasol.ai.text.extraction.abstract_extraction import Output

conf = Secrets(db_file=Path("ai_config.db"), master_password="s3cr3t")

# 1. Deploy license (required once)
deploy_license(conf)

# 2. Initialize (first run: all steps)
initialize_text_ai_extension(conf)

# 3. Run feature extraction
extraction = Extraction(
    extractor=FeatureExtractor(
        input_table="AI_SCHEMA.PRODUCT_REVIEWS",
        input_column="REVIEW_TEXT",
    ),
    output=Output(
        table="AI_SCHEMA.REVIEW_EMBEDDINGS",
        columns=["REVIEW_ID", "EMBEDDING"],
    ),
)
extraction.run(conf)

print("Embeddings stored in AI_SCHEMA.REVIEW_EMBEDDINGS")
```

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `LicenseError` | License not deployed | Run `deploy_license(conf)` before `initialize_text_ai_extension` |
| SLC upload very slow | SLC is ~2-3 GB | Expected; run once, then use `install_slc=False` |
| Model not found | Models not uploaded | Run with `install_models=True` |
| `RuntimeError: Language alias already exists` | Re-deploying SLC | Set `allow_override_language_alias=True` |
| Import errors with pylint / mypy | Cython packages in extension | Known issue (see GitHub issue #206); add `# pylint: skip-file` on consumer files |
| `AttributeError` for `txaie_models_cache_dir` | `initialize_text_ai_extension` not yet run | Run initialization first |

---

## Related Skills

- **exasol-ai-setup**: Configure SCS and credentials first.
- **exasol-transformers**: Lower-level extension with full Hugging Face model choice and direct SQL UDF interface.
- **exasol-bucketfs**: Inspect or manage BucketFS files (SLCs, models).
- **exasol-udfs**: Write custom Python UDFs in Exasol.
