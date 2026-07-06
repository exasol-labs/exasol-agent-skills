"""Restart the managed ITDE-backed Exasol instance."""

import os
from pathlib import Path

from exasol.nb_connector.itde_manager import restart_itde
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Restart the local Exasol container referenced by the stored config."""
    # Open the secure config store that identifies the managed ITDE instance.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )
    try:
        # Restart the managed local Exasol container using the stored notebook-connector configuration.
        restart_itde(conf)
    finally:
        # Close the encrypted store even if the restart request fails.
        conf.close()


if __name__ == "__main__":
    main()
