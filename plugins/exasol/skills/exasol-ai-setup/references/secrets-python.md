# Notebook Connector Setup via `Secrets`

Use the Python API when the user wants notebook cells, scripts, or automation.

`Secrets` is the shared configuration object used by every Notebook Connector API.

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/setup_onprem.py` writes all required on-prem database and BucketFS keys into a `Secrets` store.
- `scripts/setup_saas.py` writes the SaaS account, database, and PAT values into a `Secrets` store.

They show:

- how to open or create a `Secrets` store
- how to save notebook-connector configuration values via `conf.save(...)`
- how to select the backend with `StorageBackend`
- how to close the store cleanly

## Open or Create a Store

```python
from pathlib import Path
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey, StorageBackend
from exasol.nb_connector.secret_store import Secrets

conf = Secrets(
    db_file=Path("ai_config.db"),
    master_password="my-strong-password",
)
```

If the file already exists, the same master password must be used again.

## Common Save/Read Pattern

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey

conf.save(CKey.db_host_name, "192.168.1.10")
conf.save(CKey.db_port, "8563")
conf.save(CKey.db_user, "sys")
conf.save(CKey.db_password, "exasol")
conf.save(CKey.db_schema, "MY_SCHEMA")

host = conf.get(CKey.db_host_name)
schema = conf.get(CKey.db_schema, "MY_SCHEMA")
```

All values are stored as strings, so ports and booleans should also be saved as strings.

## Common Operations

Typical `Secrets` operations the agent may still mention inline:

- `conf.get(...)`
- `conf.save(...)`
- `conf.keys()`
- `conf.items()`
- `conf.remove(...)`
- `conf.close()`

Use these operations when the user wants to inspect, update, or remove individual values after the initial setup script has been created.

## Backend Selection

Use `storage_backend` to tell Notebook Connector whether to resolve connections as on-prem or SaaS:

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey, StorageBackend

conf.save(CKey.storage_backend, StorageBackend.onprem.name)
conf.save(CKey.storage_backend, StorageBackend.saas.name)
```

Typical SaaS keys:

```python
conf.save(CKey.saas_url, "https://cloud.exasol.com")
conf.save(CKey.saas_account_id, "<your-account-id>")
conf.save(CKey.saas_token, "<your-pat>")
conf.save(CKey.saas_database_name, "my-database")
```

To confirm which backend is active, call `get_backend(conf)`:

```python
from exasol.nb_connector.connections import get_backend

print(get_backend(conf).name)
```

## Important Keys the Skill Should Know

- DB: `db_host_name`, `db_port`, `db_user`, `db_password`, `db_schema`
- TLS: `db_encryption`, `bfs_encryption`, `cert_vld`, `trusted_ca`, `client_cert`, `client_key`
- BucketFS: `bfs_host_name`, `bfs_port`, `bfs_service`, `bfs_bucket`, `bfs_user`, `bfs_password`
- SaaS: `saas_url`, `saas_account_id`, `saas_database_id`, `saas_database_name`, `saas_token`, `storage_backend`
- Some downstream notebook-connector skills may use additional ITDE or extension-specific keys after setup is complete.

## Use This Path When

- the user wants copy-pasteable notebook cells
- the agent is generating a Python script
- the workflow is part of a larger automated setup
- downstream notebook-connector skills still need a populated `Secrets` store first
