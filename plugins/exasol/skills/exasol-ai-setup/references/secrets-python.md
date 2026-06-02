# notebook-connector Setup via `Secrets`

Use the Python API when the user wants notebook cells or automation.

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/setup_onprem.py` writes all required on-prem database and BucketFS keys into a `Secrets` store.
- `scripts/setup_saas.py` writes the SaaS account, database, and PAT values into a `Secrets` store.

They show:

- how to open a `Secrets` store
- how to save notebook-connector configuration values
- how to close the store cleanly

## Common Operations

Typical `Secrets` operations the agent may still mention inline:

- `conf.get(...)`
- `conf.keys()`
- `conf.items()`
- `conf.remove(...)`
- `conf.close()`

Use these operations when the user wants to inspect, update, or remove individual values after the initial setup script has been created.

## Use This Path When

- the user wants copy-pasteable notebook cells
- the agent is generating a Python script
- the workflow is part of a larger automated setup
