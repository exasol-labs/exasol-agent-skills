# Notebook Connector Transformers Extension

Use this reference for the Python setup flow and SQL UDF surface of the
Transformers Extension.

It covers:

- `initialize_te_extension(...)`
- `deploy_scripts(...)`
- `get_activation_sql(...)`
- current limits of `upload_model(...)`
- the current SQL UDF examples documented in notebook-connector

Keep setup prerequisites in `Secrets` first, then use this reference for the
extension-specific workflow and validation.

Current notebook-connector main behavior to preserve in this skill:

- `initialize_te_extension(...)` always ensures the BucketFS `CONNECTION`
  object exists, even if `run_encapsulate_bfs_credentials=False`
- `upload_model(...)` is not a working end-to-end model-upload path because it
  reaches `upload_model_from_cache(...)`, which still raises
  `NotImplementedError`
- model-handling guidance should therefore point to the bundled Transformers
  notebooks instead of presenting `upload_model(...)` as a supported workflow
