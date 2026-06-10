# ITDE Lifecycle

Install the Docker extra:

```bash
pip install "notebook-connector[docker-db]"
```

## What ITDE Handles

The Integration Test Docker Environment starts a local Exasol database in
Docker and writes the generated DB and BucketFS connection values back into the
same secure config store.

After `bring_itde_up(...)`, the store contains the DB and BucketFS keys needed
by the other notebook-connector APIs, including:

- `db_host_name`, `db_port`, `db_user`, `db_password`
- `bfs_host_name`, `bfs_port`, `bfs_user`, `bfs_password`
- `bfs_service`, `bfs_bucket`
- `db_encryption`, `bfs_encryption`, `cert_vld`

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/bring_itde_up.py`
- `scripts/check_itde_status.py`
- `scripts/restart_itde.py`
- `scripts/take_itde_down.py`

## Core Lifecycle

Set optional sizing keys before startup:

```python
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.itde_manager import bring_itde_up

my_secrets.save(CKey.mem_size, "4")
my_secrets.save(CKey.disk_size, "10")
bring_itde_up(my_secrets)
```

Status and lifecycle helpers:

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

## Status Meanings

- `ABSENT`: the container does not exist
- `STOPPED`: the container exists but is not running
- `RUNNING`: the container process is alive
- `VISIBLE`: the database port is reachable
- `READY`: both running and reachable

## Notes

- `bring_itde_up` is the fastest way to get a local notebook-connector-ready Exasol instance.
- `restart_itde` is preferable to a full re-creation when the container already exists.
- `take_itde_down(stop_db=False)` removes the stored ITDE config while keeping the Docker DB intact.
