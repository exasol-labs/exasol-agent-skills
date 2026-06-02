from pathlib import Path

from exasol.nb_connector.connections import open_pyexasol_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    # Open the secure config store that contains the database connection values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Open a pyexasol connection and run the smallest useful smoke test query.
    with open_pyexasol_connection(conf) as connection:
        print(connection.execute("SELECT 1").fetchone())

    # Close the encrypted store after the connectivity check finishes.
    conf.close()


if __name__ == "__main__":
    main()
