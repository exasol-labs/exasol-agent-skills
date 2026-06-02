from pathlib import Path

from exasol.nb_connector.connections import (
    open_bucketfs_bucket,
    open_bucketfs_connection,
    open_bucketfs_location,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    print(open_bucketfs_connection(conf))
    print(open_bucketfs_bucket(conf))
    print(open_bucketfs_location(conf, "models/my_model"))

    conf.close()


if __name__ == "__main__":
    main()
