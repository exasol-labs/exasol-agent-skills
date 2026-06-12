"""Check whether the managed ITDE container is ready and reachable."""

import os
from pathlib import Path

from exasol.nb_connector.itde_manager import (
    ItdeContainerStatus,
    get_itde_status,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Read the current ITDE container status from notebook-connector."""
    # Open the secure config store that identifies the managed ITDE instance.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    # Ask notebook-connector for the current container status instead of inferring it from raw Docker output.
    status = get_itde_status(conf)
    if status == ItdeContainerStatus.READY:
        print("Docker DB is up and reachable")
    else:
        print(status)

    # Close the encrypted store after the status check finishes.
    conf.close()


if __name__ == "__main__":
    main()
