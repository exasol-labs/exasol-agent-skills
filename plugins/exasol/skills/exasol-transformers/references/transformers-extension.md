# Exasol Transformers Extension AI Functions

Use this reference for the notebook-connector setup and SQL usage of the
Exasol Transformers Extension. It covers:

- `initialize_te_extension(...)`
- model installation with `install_model(...)`
- language activation with `get_activation_sql(...)`
- the current `AI_*` Function names and behavior
- validation and large-model operational guidance

This reference does not change the extension package or deployment design.
Keep database and BucketFS credentials in `Secrets`; do not place credentials,
tokens, or private data in examples.

## Prerequisites

The secure configuration store must contain the database and BucketFS values
required by notebook-connector:

```text
db_host_name, db_port, db_user, db_password, db_schema
bfs_host_name, bfs_port, bfs_service, bfs_bucket, bfs_user, bfs_password
```

Add `huggingface_token` only when the selected model is private or gated. The
database user must have the minimum permissions needed for the target schema,
language, scripts, and BucketFS connection. Do not use shared accounts. Use
approved TLS endpoints and certificate validation for database, BucketFS, and
model-provider traffic.

Before installation, check the model license, provider terms, revision,
supported task, data residency, and whether the input data is authorized for
model processing. Verify the model source and downloaded artifacts using the
provider's supported integrity mechanism, and pin the model revision and
extension/package versions where supported. Record those versions with the
workload so the operational choice is reproducible and reviewable. Use
synthetic text in validation examples.

Tokens belong in the supported secret store, not in source code, SQL, command
history, or notebook output. Use supported expiry, rotation, and cleanup
behavior; do not recommend long-lived credentials by default. Protect local
model caches, generated outputs, and configuration files because they may
contain sensitive data.

Keep the boundaries clear: notebook-connector is local tooling, the Exasol
database executes the UDF, BucketFS stores the language container and model
artifacts, and the model provider supplies the source artifacts. Each boundary
has its own identity, permissions, network path, and audit responsibility.

## Initialize the extension

```python
from exasol.nb_connector.transformers_extension_wrapper import (
    initialize_te_extension,
)

initialize_te_extension(my_secrets)
```

Initialization can:

1. upload the pre-built Transformers Script Language Container to BucketFS;
2. ensure the BucketFS `CONNECTION` exists;
3. create the Hugging Face token `CONNECTION` when a token is configured; and
4. deploy the extension scripts into the configured schema.

When rerunning setup after the language container is already present, use
flags appropriate to the state of the database:

```python
initialize_te_extension(
    my_secrets,
    run_deploy_container=False,
    run_deploy_scripts=True,
    run_encapsulate_hf_token=False,
    allow_override=True,
)
```

`initialize_te_extension()` currently ensures the BucketFS connection as part
of its setup flow. Do not document this workflow as if it skipped connection
creation.

To deploy only the scripts when the language container is already available:

```python
from exasol.nb_connector.transformers_extension_wrapper import (
    LANGUAGE_ALIAS,
    deploy_scripts,
)

deploy_scripts(my_secrets, language_alias=LANGUAGE_ALIAS)
```

## Activate the language

Before invoking a Function in a session, obtain and execute the activation SQL:

```python
from exasol.nb_connector.language_container_activation import get_activation_sql

activation_sql = get_activation_sql(my_secrets)
assert activation_sql
print(activation_sql)
```

The SQL must be executed in the database session before script deployment or
Function invocation, as required by the notebook-connector workflow.

## Install the default Answer and Translate models

The simple Functions use predefined models, but the model artifacts still
need to be available in BucketFS. Install them before invoking the Functions:

```python
from transformers import AutoModelForCausalLM, AutoModelForSeq2SeqLM
from exasol.nb_connector.model_installation import TransformerModel, install_model

install_model(
    my_secrets,
    TransformerModel(
        "HuggingFaceTB/SmolLM2-135M-Instruct",
        "text-generation",
        AutoModelForCausalLM,
    ),
)

install_model(
    my_secrets,
    TransformerModel(
        "google-t5/t5-base",
        "translation",
        AutoModelForSeq2SeqLM,
    ),
)
```

The task type is significant. `AI_ANSWER` uses a text-generation model and
`AI_TRANSLATE` uses a translation model. Do not install a question-answering
model for `AI_ANSWER`; the question-answering pipeline was removed from
Transformers 5 and the current Answer implementation uses text generation.

For private or gated models, configure the Hugging Face token in `Secrets`
before initialization. Do not print or embed the token.

## Current AI Function surface

Use these names in new documentation and SQL:

| Function | Task | Model behavior |
|---|---|---|
| `AI_SENTIMENT` | text classification | Uses a predefined sentiment model |
| `AI_CLASSIFY` | zero-shot classification | Uses a predefined zero-shot model |
| `AI_EXTRACT_ENTITIES` | token classification | Uses a predefined entity model |
| `AI_ANSWER` | text generation | Uses `HuggingFaceTB/SmolLM2-135M-Instruct` |
| `AI_TRANSLATE` | translation | Uses `google-t5/t5-base` |
| `AI_CUSTOM_CLASSIFY_EXTENDED` | text classification | User supplies model and runtime parameters |
| `AI_ENTAILMENT_EXTENDED` | text-pair classification | User supplies model and runtime parameters |
| `AI_FILL_MASK_EXTENDED` | fill-mask | User supplies model and runtime parameters |
| `AI_COMPLETE_EXTENDED` | text generation | User supplies model and runtime parameters |
| `AI_EXTRACT_EXTENDED` | token classification | User supplies model and runtime parameters |
| `AI_CLASSIFY_EXTENDED` | zero-shot classification | User supplies model and runtime parameters |
| `AI_ANSWER_EXTENDED` | text generation | User supplies model and runtime parameters |
| `AI_TRANSLATE_EXTENDED` | translation | User supplies model and runtime parameters |

The former `TE_*` names are legacy names. They may still appear in historical
material, but should not be used as the primary examples for current users.

All current AI Functions are listed above with their current names and task
behavior. This ticket provides detailed executable examples only for
`AI_ANSWER` and `AI_TRANSLATE`; additional Function examples are outside the
current scope and can be added in follow-up work.

## Answer example

After initialization, model installation, and language activation:

```sql
SELECT MY_SCHEMA.AI_ANSWER(
    'Which database is described in the context?',
    'Exasol is a high-performance analytical database.'
);
```

The result includes `answer` and `error_message` columns. Check the error column
before accepting the answer. Answer is generative: the result can be
influenced by the model's training and is not guaranteed to be an extractive
copy of the context. Do not use it as an authority without application-level
validation.

For model and parameter control, use the extended Function:

```sql
SELECT MY_SCHEMA.AI_ANSWER_EXTENDED(
    NULL,
    'TE_BFS_<db-user>',
    'models',
    'HuggingFaceTB/SmolLM2-135M-Instruct',
    'Which database is described in the context?',
    'Exasol is a high-performance analytical database.'
);
```

Replace `MY_SCHEMA`, the connection name, and the model directory with the
values created by the configured environment. Do not copy credentials into SQL.

## Translate example

After initialization, model installation, and language activation:

```sql
SELECT MY_SCHEMA.AI_TRANSLATE(
    'Hello world',
    'English',
    'German'
);
```

The result includes `translation_text` and `error_message` columns. The simple
Function uses `google-t5/t5-base` and a maximum output length of 256 new
tokens. Split long inputs or use the extended Function when that limit is not
sufficient.

For model and output-length control, use:

```sql
SELECT MY_SCHEMA.AI_TRANSLATE_EXTENDED(
    NULL,
    'TE_BFS_<db-user>',
    'models',
    'google-t5/t5-base',
    'Hello world',
    'English',
    'German',
    256
);
```

Replace `MY_SCHEMA` and the other placeholders with environment values. The source and target language
arguments must be supported by the selected model; multilingual models may
require them explicitly.

## Validation

Validate in layers rather than starting with a large table:

1. Confirm the required `Secrets` values exist without printing secrets.
2. Run `initialize_te_extension(...)` or the required setup subset.
3. Confirm `get_activation_sql(...)` returns non-empty SQL.
4. Confirm the model artifacts are present in the configured BucketFS model directory.
5. Run one Answer or Translate query with synthetic text.
6. Check both prediction columns and the error column.
7. Only then run a bounded sample of the real workload.

Typical failures include missing language activation, missing scripts, missing
BucketFS models, incorrect task types, unsupported model/language combinations,
and insufficient memory. A row-level error should be investigated through the
returned error column rather than silently treated as a valid prediction.

## Large-model operational guidance

Large models can exhaust shared resources. Before using one:

- pin the extension version, model revision, and relevant package versions;
- verify the model license and provider terms;
- estimate BucketFS, local-cache, memory, CPU/GPU, and execution-time needs;
- start with one small row and a bounded sample;
- use practical input and output token limits and batch sizes;
- avoid mixing many models in one query because models may be loaded separately;
- use a compatible CUDA device only when GPU execution is available and authorized;
- set workload limits or schedule expensive jobs away from critical workloads;
- protect local caches and generated outputs; and
- remove temporary credentials and sessions according to supported expiry and cleanup behavior.

Large size is not a quality guarantee. Choose a model that matches the task,
language, domain, license, privacy requirements, and available resources. Do
not submit personal or confidential data unless the processing is authorized.
