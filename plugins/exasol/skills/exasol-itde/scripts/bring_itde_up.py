"""Start a local ITDE-backed Exasol instance from notebook-connector config."""

import os
from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.itde_manager import bring_itde_up
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Save resource sizing and bring the managed ITDE container up."""
    # Open the secure config store that will hold the local Docker DB settings.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    # Save the requested resource sizing before starting the ITDE container.
    conf.save(CKey.mem_size, "4")
    conf.save(CKey.disk_size, "10")

    # Start the managed local Exasol container and let notebook-connector populate the derived connection values.
    bring_itde_up(conf)

    # Close the encrypted store when setup is complete.
    conf.close()


if __name__ == "__main__":
    main()
