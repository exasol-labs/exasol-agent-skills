---
name: exasol-transformers
description: "Deploy and use the Exasol Transformers Extension for NLP inference inside Exasol with notebook-connector. Covers initialize_te_extension, deploy_scripts, Hugging Face model upload, activation SQL, and the current TE SQL UDF surface."
---

# Exasol Transformers Extension Skill

Trigger when the user mentions **Transformers Extension**, **TE extension**, **initialize_te_extension**, **deploy_scripts**, **Hugging Face models in Exasol**, **TE UDF**, **PYTHON3_TE**, or NLP inference inside Exasol.

## Prerequisites

The secure config store must already contain complete DB and BucketFS values. If not, activate **exasol-ai-setup** first.

Install the Notebook Connector transformers extra:

```bash
pip install "notebook-connector[transformers]"
```

## Main Entry Points

### Full setup

Use this first when the user wants notebook-connector to deploy the TE language
container, create the required connection objects, and install the TE scripts.

```python
from exasol.nb_connector.transformers_extension_wrapper import initialize_te_extension

initialize_te_extension(my_secrets)
```

`initialize_te_extension()` can:

1. upload the pre-built TE Script Language Container to BucketFS
2. create the BucketFS `CONNECTION` object used by the UDFs
3. create the Hugging Face token `CONNECTION` object when `huggingface_token` is set
4. deploy the TE UDF scripts into the configured schema

Useful flags when re-running setup:

```python
initialize_te_extension(
    my_secrets,
    run_deploy_container=False,
    run_deploy_scripts=True,
    run_encapsulate_bfs_credentials=False,
    run_encapsulate_hf_token=False,
    allow_override=True,
)
```

### Deploy scripts only

Use this when the SLC is already in BucketFS and the user only needs the SQL/UDF layer refreshed.

```python
from exasol.nb_connector.transformers_extension_wrapper import (
    LANGUAGE_ALIAS,
    deploy_scripts,
)

deploy_scripts(my_secrets, language_alias=LANGUAGE_ALIAS)
```

### Activation SQL

Before running TE UDFs from SQL, activate the language container in the
session:

```python
from exasol.nb_connector.language_container_activation import get_activation_sql

print(get_activation_sql(my_secrets))
```

## Model Handling

Models must be available in BucketFS before the TE UDFs can use them.

Use the bundled Transformers notebooks as the source of truth for complete
model-loading workflows. For programmatic setup, initialize the extension first
and then ensure the desired model artifacts are present under the configured
model subdirectory in BucketFS.

If the user needs private or gated Hugging Face models, store
`huggingface_token` in the SCS before initialization so notebook-connector can
create the corresponding DB `CONNECTION` object.

## Current SQL UDF Surface

These examples reflect the current notebook-connector docs branch.

### Text generation

```sql
SELECT MY_SCHEMA.TE_TEXT_GENERATION_UDF(
    NULL,
    'TE_BFS_SYS',
    'models',
    'gpt2',
    'Exasol can',
    32,
    TRUE
);
```

### Fill-mask prediction

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_FILLING_MASK_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'bert-base-uncased',
        'Exasol is a [MASK] database.',
        5
    )
)
SELECT filled_text, score, rank, error_message
FROM MODEL_OUTPUT
ORDER BY score DESC;
```

### Sequence classification

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_SEQUENCE_CLASSIFICATION_SINGLE_TEXT_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'arpanghoshal/EkmanClassifier',
        'Oh my God!',
        'HIGHEST'
    )
)
SELECT label, score, rank, error_message
FROM MODEL_OUTPUT;
```

Use the text-pair UDF when the model compares two texts:

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_SEQUENCE_CLASSIFICATION_TEXT_PAIR_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'arpanghoshal/EkmanClassifier',
        'Oh my God!',
        'I lost my purse.',
        'ALL'
    )
)
SELECT label, score, rank, error_message
FROM MODEL_OUTPUT
ORDER BY score DESC;
```

### Zero-shot classification

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_ZERO_SHOT_TEXT_CLASSIFICATION_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'facebook/bart-large-mnli',
        'Notebook Connector simplifies Exasol AI workflows.',
        'documentation,databases,networking',
        'ALL'
    )
)
SELECT label, score, error_message
FROM MODEL_OUTPUT
ORDER BY score DESC;
```

### Question answering

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_QUESTION_ANSWERING_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'distilbert-base-cased-distilled-squad',
        'What does Notebook Connector simplify?',
        'Notebook Connector simplifies Exasol AI workflows.',
        5
    )
)
SELECT answer, score, error_message
FROM MODEL_OUTPUT
ORDER BY score DESC;
```

### Token classification

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_TOKEN_CLASSIFICATION_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        'dslim/bert-base-NER',
        'Exasol is headquartered in Nuremberg.',
        NULL
    )
)
SELECT start_pos, end_pos, word, entity, error_message
FROM MODEL_OUTPUT
ORDER BY start_pos, end_pos;
```

### Translation

```sql
WITH MODEL_OUTPUT AS (
    SELECT MY_SCHEMA.TE_TRANSLATION_UDF(
        NULL,
        'TE_BFS_SYS',
        'models',
        't5-small',
        'Hello world',
        'en',
        'de',
        32
    )
)
SELECT translation_text, error_message
FROM MODEL_OUTPUT;
```

### Model management

```sql
SELECT MY_SCHEMA.TE_LIST_MODELS_UDF('TE_BFS_SYS', 'models');
SELECT MY_SCHEMA.TE_DELETE_MODEL_UDF('TE_BFS_SYS', 'models', 'gpt2');
```

## Validation

Validate setup in layers:

- after initialization, run `print(get_activation_sql(my_secrets))` and confirm the returned SQL contains the TE language definition
- if the SLC is already present, re-run `deploy_scripts(...)` as a lightweight script-level validation
- after model upload and activation, run one minimal TE SQL UDF call such as `TE_LIST_MODELS_UDF`

Success signals:

- activation SQL is present and non-empty
- script deployment completes without language-activation errors
- at least one TE UDF call returns rows instead of missing-language or missing-script errors

Expected failure mode:

- if DB, BucketFS, or Hugging Face settings are incomplete, initialization or UDF execution should fail until **exasol-ai-setup** has been completed with real values

## Guidance

- Use **exasol-ai-setup** when SCS, DB, or BucketFS values are still missing.
- Use **exasol-bucketfs** when the user needs to inspect or manipulate the uploaded SLC or model files directly.
- Use **exasol-udfs** when the task is about language activation or custom UDF work beyond the packaged TE surface.
