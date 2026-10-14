---
name: exasol-transformers
description: "Deploy and use the Exasol Transformers Extension AI Functions for NLP inference inside Exasol with notebook-connector. Covers initialize_te_extension, model installation, activation SQL, validation, and safe use of large models."
---

# Exasol Transformers Extension Skill

Trigger when the user mentions **Transformers Extension**, **TE extension**, **initialize_te_extension**, **deploy_scripts**, **Hugging Face models in Exasol**, **TE UDF**, **PYTHON3_TE**, or NLP inference inside Exasol.

## Purpose

Use this skill to deploy the Transformers Extension Script Language Container
(SLC) and UDFs, install models, generate activation SQL, and run or validate the
current `AI_*` SQL Functions. Load the reference for detailed instructions and
examples.

## Routing Algorithm

1. **Extension setup and model handling**
   - Trigger phrases: `initialize_te_extension`, `deploy_scripts`, `install_model`, `huggingface_token`
   - Load: `references/transformers-extension.md`

2. **AI Function usage and validation**
   - Trigger phrases: `AI_SENTIMENT`, `AI_CLASSIFY`, `AI_EXTRACT_ENTITIES`, `AI_ANSWER`, `AI_TRANSLATE`, `AI_CUSTOM_CLASSIFY_EXTENDED`, `AI_ENTAILMENT_EXTENDED`, `AI_FILL_MASK_EXTENDED`, `AI_COMPLETE_EXTENDED`, `AI_EXTRACT_EXTENDED`, `AI_CLASSIFY_EXTENDED`, `AI_ANSWER_EXTENDED`, `AI_TRANSLATE_EXTENDED`, `get_activation_sql`, `transformers sql function`
   - Load: `references/transformers-extension.md`

Multiple routes can apply. Load the reference before responding.

## Prerequisites

1. Check whether the secure config store (SCS) contains the required database
   and BucketFS values. If values are missing, activate
   **exasol-notebook-connector-config** first.
2. Confirm that the SCS contains:

   - DB values: `db_host_name`, `db_port`, `db_user`, `db_password`, `db_schema`
   - BucketFS values: `bfs_host_name`, `bfs_port`, `bfs_service`, `bfs_bucket`, `bfs_user`, `bfs_password`
   - optional: `huggingface_token` for gated or private models

3. Confirm that the database user can activate the `PYTHON3_TE` language alias
   for the TE SLC, create and execute the TE UDFs (defined with `CREATE SCRIPT`),
   and use the required BucketFS connection.

## Security and Model Governance

Do not use a shared database account. Keep credentials and tokens in the
supported secure configuration store; never put them in examples, source
files, or shell history.

Before using a model, confirm its license, provider terms, revision, required
resources, and whether the input data is allowed to be sent to that provider.
Use synthetic data for validation until those checks are complete.

## Validation

Validate setup with the reference flow after loading
`references/transformers-extension.md`.

Success signals:

- the returned activation SQL is present and non-empty
- the TE setup or validation step from the reference completes without language-activation errors
- at least one current `AI_*` Function call returns a valid result set instead
  of errors like "missing-language" or "missing-script"

For the user-facing AI Functions, also verify that the installed model matches
the function's task and that the result contains the expected output and
`error_message` columns. Start with one small row before running a table-wide
query.

Expected failure mode:

- if DB, BucketFS, or Hugging Face settings are incomplete, initialization or UDF execution should fail until **exasol-notebook-connector-config** has been completed with real values

## Guidance

- Use **exasol-notebook-connector-config** when secure config store, DB, or BucketFS values are still missing.
- Use **exasol-bucketfs** when the user needs to inspect or manipulate the uploaded SLC or model files directly.
- Use **exasol-udfs** when the task is about language activation or custom UDF work beyond the packaged TE surface.

## Current AI Functions

Use these public names in new SQL examples. The former `TE_*` names are legacy
names and should not be the primary user guidance.

| Function | Purpose |
|---|---|
| `AI_SENTIMENT` | Sentiment classification with the default model |
| `AI_CLASSIFY` | Zero-shot classification with user-provided labels |
| `AI_EXTRACT_ENTITIES` | Entity extraction with the default model |
| `AI_ANSWER` | Answer a question using a context and the default generative model |
| `AI_TRANSLATE` | Translate text with the default translation model |
| `AI_CUSTOM_CLASSIFY_EXTENDED` | Configurable text classification |
| `AI_ENTAILMENT_EXTENDED` | Configurable text-pair classification |
| `AI_FILL_MASK_EXTENDED` | Configurable fill-mask prediction |
| `AI_COMPLETE_EXTENDED` | Configurable text completion |
| `AI_EXTRACT_EXTENDED` | Configurable token/entity extraction |
| `AI_CLASSIFY_EXTENDED` | Configurable zero-shot classification |
| `AI_ANSWER_EXTENDED` | Configurable text-generation answer function |
| `AI_TRANSLATE_EXTENDED` | Configurable translation function |

Each extended function takes the device, BucketFS connection name, model
directory, and model name as SQL input parameters. The model and task type must
be compatible with the selected function.

## Large-Model Operations

Large models affect BucketFS storage, local caches, memory, startup time,
query latency, and shared-cluster availability. Before a large run:

- pin the extension version, model revision, and relevant package versions;
- test with one small input and inspect `error_message`;
- estimate model, cache, and runtime resource requirements;
- avoid mixing many models in one query because each model may be loaded
  separately;
- set practical input/output token limits and batch sizes;
- set workload limits and timeouts where supported, and define how failures are handled;
- use GPU only when the database runtime provides a compatible CUDA device;
- keep generated outputs and local caches protected and free of unnecessary
  secrets or personal data.

Large models do not automatically produce better results. Select a model that
matches the task, language, domain, license, and available resources.
