# Notebook Connector Validation

Use these checks before handing off to extension-deployment skills.

## CLI Validation

Use this pair when the user wants a terminal-first smoke test of the stored configuration.

```bash
scs check ai_config.db
scs check --connect ai_config.db
```

## Python Validation

Use the executable template:

- `scripts/validate_config.py`

It demonstrates:

- opening a pyexasol connection from notebook-connector config
- explicitly passing `schema=` to `open_pyexasol_connection(...)`
- opening a BucketFS object from the same config
- reading which backend is active
- doing a minimal smoke test before continuing

This is the preferred path when the user wants a notebook cell or Python script instead of a CLI check.

Typical pattern:

```python
from exasol.nb_connector.connections import (
    get_backend,
    open_bucketfs_bucket,
    open_pyexasol_connection,
)

print(get_backend(conf))
with open_pyexasol_connection(conf, schema="MY_SCHEMA") as connection:
    print(connection.execute("SELECT 1").fetchone())

bucket = open_bucketfs_bucket(conf)
print(bucket)
```

## Guidance

- Prefer `scs check --connect` for terminal-first workflows.
- Prefer the Python smoke test for notebook or automation workflows.
- Remember that `open_pyexasol_connection()` does not apply `db_schema` automatically; pass `schema="MY_SCHEMA"` explicitly.
- If validation fails, fix config first instead of continuing to TE or TXAIE deployment.
