"""Detect which backend type the stored notebook-connector config targets."""

from pathlib import Path

from exasol.nb_connector.connections import get_backend
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Print the backend resolved from the current Secrets configuration."""
    # Open the secure config store so notebook-connector can inspect the configured backend type.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Print the resolved backend, for example on-prem or SaaS.
    print(get_backend(conf))

    # Close the encrypted store after the lookup.
    conf.close()


if __name__ == "__main__":
    main()
