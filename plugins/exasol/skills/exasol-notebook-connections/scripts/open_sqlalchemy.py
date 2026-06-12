"""Open a SQLAlchemy engine from notebook-connector config and validate it."""

import os
from pathlib import Path

from exasol.nb_connector.connections import open_sqlalchemy_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Create a SQLAlchemy engine and run a minimal connectivity check."""
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    engine = open_sqlalchemy_connection(conf)
    with engine.connect() as connection:
        print(connection.exec_driver_sql("SELECT 1").fetchone())

    conf.close()


if __name__ == "__main__":
    main()
