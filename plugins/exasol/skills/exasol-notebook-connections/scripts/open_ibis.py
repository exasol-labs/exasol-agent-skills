"""Open an Ibis connection from notebook-connector config and inspect it."""

import os
from pathlib import Path

from exasol.nb_connector.connections import open_ibis_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Create an Ibis connection and run a lightweight metadata call."""
    # Open the secure config store that contains the database connection values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )
    try:
        # Open an Ibis connection using notebook-connector's configured backend details.
        ibis_conn = open_ibis_connection(conf)

        # Run a lightweight metadata call to prove the connection works.
        print(ibis_conn.list_tables())
    finally:
        # Close the encrypted store even if the Ibis check fails.
        conf.close()


if __name__ == "__main__":
    main()
