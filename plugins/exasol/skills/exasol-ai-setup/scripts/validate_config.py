"""Run a minimal database and BucketFS smoke test from notebook-connector config."""

from pathlib import Path

from exasol.nb_connector.connections import (
    open_bucketfs_bucket,
    open_pyexasol_connection,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Validate that the stored configuration opens both DB and BucketFS access."""
    # Open the existing secure config store that should already contain DB and BucketFS values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Verify that the stored DB credentials are sufficient to open a working pyexasol connection.
    with open_pyexasol_connection(conf) as connection:
        print(connection.execute("SELECT 1").fetchone())

    # Verify that the same config also resolves a BucketFS bucket object successfully.
    bucket = open_bucketfs_bucket(conf)
    print(bucket)

    # Close the encrypted store when validation is finished.
    conf.close()


if __name__ == "__main__":
    main()
