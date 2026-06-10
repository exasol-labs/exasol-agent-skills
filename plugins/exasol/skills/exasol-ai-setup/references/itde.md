# Notebook Connector ITDE

Use the ITDE helpers when the user wants a local Docker Exasol database managed through Notebook Connector.

## Required Extra

```bash
pip install "notebook-connector[docker-db]"
```

## Core Lifecycle

`bring_itde_up(my_secrets)` starts the Docker DB, pulls the image if needed, waits until the database is ready to accept connections, and writes the generated DB and BucketFS connection values back into the same `Secrets` store.

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.itde_manager import bring_itde_up

my_secrets.save(CKey.mem_size, "4")
my_secrets.save(CKey.disk_size, "10")
bring_itde_up(my_secrets)
```

After `bring_itde_up`, the store is populated with the DB and BucketFS keys needed by the other Notebook Connector APIs, including:

- `db_host_name`, `db_port`, `db_user`, `db_password`
- `bfs_host_name`, `bfs_port`, `bfs_user`, `bfs_password`
- `bfs_service`, `bfs_bucket`
- `db_encryption`, `bfs_encryption`, `cert_vld`

## Status and Lifecycle

```python
from exasol.nb_connector.itde_manager import (
    ItdeContainerStatus,
    get_itde_status,
    restart_itde,
    take_itde_down,
)

status = get_itde_status(my_secrets)
print(status == ItdeContainerStatus.READY)

restart_itde(my_secrets)
take_itde_down(my_secrets)
take_itde_down(my_secrets, stop_db=False)
```

## Guidance

- Prefer ITDE when the user wants a disposable local environment without SaaS or on-prem infrastructure.
- `scs configure docker-db` stores sizing preferences only; it does not start Docker by itself.
- `restart_itde` is preferable to a full re-creation when the container already exists.
- Use this setup skill for the config and lifecycle, then hand off to DB, BucketFS, or UDF skills for actual usage.
