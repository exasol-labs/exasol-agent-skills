from pathlib import Path

from exasol.nb_connector.connections import (
    open_bucketfs_bucket,
    open_bucketfs_connection,
    open_bucketfs_location,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    # Open the secure config store that contains the BucketFS connection values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Resolve the low-level BucketFS connection object from notebook-connector config.
    print(open_bucketfs_connection(conf))

    # Resolve the configured bucket object itself.
    print(open_bucketfs_bucket(conf))

    # Resolve a concrete path inside the bucket, such as a model directory.
    print(open_bucketfs_location(conf, "models/my_model"))

    # Close the encrypted store after the BucketFS lookups finish.
    conf.close()


if __name__ == "__main__":
    main()
