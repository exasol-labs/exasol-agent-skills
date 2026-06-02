"""Open a SQLAlchemy engine from notebook-connector config and validate it."""

from pathlib import Path

from exasol.nb_connector.connections import open_sqlalchemy_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Create a SQLAlchemy engine and run a minimal connectivity check."""
    # Open the secure config store that contains the database connection values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Build a SQLAlchemy engine from notebook-connector's stored configuration.
    engine = open_sqlalchemy_connection(conf)
    with engine.connect() as connection:
        # Run a minimal statement to prove the engine can connect successfully.
        print(connection.execute("SELECT 1"))

    # Close the encrypted store after the connectivity check finishes.
    conf.close()


if __name__ == "__main__":
    main()
