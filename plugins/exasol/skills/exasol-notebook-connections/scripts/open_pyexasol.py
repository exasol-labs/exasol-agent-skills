"""Open a pyexasol connection from notebook-connector config and run a smoke test."""

import os
from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.connections import open_pyexasol_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Create a pyexasol connection and execute a minimal validation query."""
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )
    try:
        # open_pyexasol_connection() does not apply db_schema automatically.
        with open_pyexasol_connection(
            conf, schema=conf.get(CKey.db_schema)
        ) as connection:
            print(connection.execute("SELECT 1").fetchone())
    finally:
        # Close the encrypted store even if the connection or query fails.
        conf.close()


if __name__ == "__main__":
    main()
