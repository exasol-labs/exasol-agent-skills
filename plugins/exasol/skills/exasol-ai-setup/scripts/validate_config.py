"""Run a minimal database and BucketFS smoke test from notebook-connector config."""

from pathlib import Path

from exasol.nb_connector.connections import (
    get_backend,
    open_bucketfs_bucket,
    open_pyexasol_connection,
)
from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Validate that the stored configuration opens both DB and BucketFS access."""
    # Open the existing secure config store that should already contain DB and BucketFS values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Print the configured backend so the caller can confirm on-prem vs. SaaS resolution.
    print(get_backend(conf))

    # open_pyexasol_connection() does not apply db_schema automatically, so pass it explicitly.
    with open_pyexasol_connection(conf, schema=conf.get(CKey.db_schema)) as connection:
        print(connection.execute("SELECT 1").fetchone())

    # Verify that the same config also resolves a BucketFS bucket object successfully.
    bucket = open_bucketfs_bucket(conf)
    print(bucket)

    # Close the encrypted store when validation is finished.
    conf.close()


if __name__ == "__main__":
    main()
