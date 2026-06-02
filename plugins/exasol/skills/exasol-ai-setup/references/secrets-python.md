# notebook-connector Setup via `Secrets`

Use the Python API when the user wants notebook cells or automation.

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/setup_onprem.py`
- `scripts/setup_saas.py`

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

## Use This Path When

- the user wants copy-pasteable notebook cells
- the agent is generating a Python script
- the workflow is part of a larger automated setup
