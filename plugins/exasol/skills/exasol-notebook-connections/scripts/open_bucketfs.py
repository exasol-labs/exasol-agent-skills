"""Open BucketFS bucket helpers and locations from notebook-connector config."""

import os
from pathlib import Path

from exasol.nb_connector.connections import (
    get_udf_bucket_path,
    open_bucketfs_bucket,
    open_bucketfs_location,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Resolve the BucketFS bucket object, one sample location, and the UDF path."""
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    print(open_bucketfs_bucket(conf))
    print(open_bucketfs_location(conf) / "models" / "my_model")
    print(get_udf_bucket_path(conf))

    conf.close()


if __name__ == "__main__":
    main()
