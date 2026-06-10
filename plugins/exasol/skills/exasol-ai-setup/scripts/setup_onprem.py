"""Create an on-prem notebook-connector configuration in a Secrets store."""

from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey, StorageBackend
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Persist database and BucketFS values for an on-prem Exasol setup."""
    # Open the secure config store that will hold the notebook-connector setup.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Mark the store as on-prem so Notebook Connector resolves DB and BucketFS directly.
    conf.save(CKey.storage_backend, StorageBackend.onprem.name)

    # Save the database connection details for the target Exasol system.
    conf.save(CKey.db_host_name, "my-db-host")
    conf.save(CKey.db_port, "8563")
    conf.save(CKey.db_user, "sys")
    conf.save(CKey.db_password, "secret")
    conf.save(CKey.db_schema, "AI_SCHEMA")
    conf.save(CKey.db_encryption, "True")
    conf.save(CKey.cert_vld, "True")

    # Save the BucketFS details used for SLCs, models, and related assets.
    conf.save(CKey.bfs_host_name, "my-bfs-host")
    conf.save(CKey.bfs_port, "2580")
    conf.save(CKey.bfs_user, "w")
    conf.save(CKey.bfs_password, "secret")
    conf.save(CKey.bfs_bucket, "default")
    conf.save(CKey.bfs_service, "bfsdefault")
    conf.save(CKey.bfs_encryption, "True")

    # Close the encrypted store so all values are flushed and the file is unlocked.
    conf.close()


if __name__ == "__main__":
    main()
