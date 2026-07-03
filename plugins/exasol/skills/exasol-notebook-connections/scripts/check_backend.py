"""Detect which backend type the stored notebook-connector config targets."""

import os
from pathlib import Path

from exasol.nb_connector.connections import get_backend
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Print the backend resolved from the current Secrets configuration."""
    # Open the secure config store so notebook-connector can inspect the configured backend type.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )
    try:
        # Print the resolved backend, for example onprem or saas.
        print(get_backend(conf).name)
    finally:
        # Close the encrypted store even if backend resolution fails.
        conf.close()


if __name__ == "__main__":
    main()
