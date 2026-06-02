from pathlib import Path

from exasol.nb_connector.connections import (
    open_bucketfs_bucket,
    open_pyexasol_connection,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    with open_pyexasol_connection(conf) as connection:
        print(connection.execute("SELECT 1").fetchone())

    bucket = open_bucketfs_bucket(conf)
    print(bucket)

    conf.close()


if __name__ == "__main__":
    main()
