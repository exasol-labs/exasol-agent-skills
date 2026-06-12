"""Validate that the Secrets store contains the core notebook-connector setup values."""

import os
from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey, StorageBackend
from exasol.nb_connector.connections import get_backend
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Validate that the stored configuration contains the required setup keys."""
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    try:
        backend = get_backend(conf)
        print(backend.name)

        common_keys = [
            CKey.storage_backend,
            CKey.db_schema,
        ]
        onprem_keys = [
            CKey.db_host_name,
            CKey.db_port,
            CKey.db_user,
            CKey.db_password,
            CKey.bfs_host_name,
            CKey.bfs_port,
            CKey.bfs_user,
            CKey.bfs_password,
            CKey.bfs_bucket,
            CKey.bfs_service,
        ]
        saas_keys = [
            CKey.saas_url,
            CKey.saas_account_id,
            CKey.saas_token,
        ]

        required_keys = list(common_keys)
        if backend == StorageBackend.onprem:
            required_keys.extend(onprem_keys)
        elif backend == StorageBackend.saas:
            required_keys.extend(saas_keys)
        else:
            raise ValueError(f"Unsupported backend: {backend}")

        missing_keys = [key.name for key in required_keys if not conf.get(key)]
        if missing_keys:
            raise ValueError(f"Missing required config keys: {', '.join(missing_keys)}")

        placeholder_values = {
            "my-db-host",
            "my-bfs-host",
            "<account-id>",
            "<database-name>",
            "<personal-access-token>",
            "<your-account-id>",
            "<your-pat>",
        }
        present_placeholders = []
        for key in required_keys:
            value = conf.get(key)
            if value in placeholder_values:
                present_placeholders.append(f"{key.name}={value}")
        if present_placeholders:
            raise ValueError(
                "Replace placeholder config values before continuing: "
                + ", ".join(present_placeholders)
            )

        print("Setup values are present for the configured backend")
    finally:
        conf.close()


if __name__ == "__main__":
    main()
