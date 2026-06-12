"""Stop and remove the managed ITDE-backed Exasol instance."""

import os
from pathlib import Path

from exasol.nb_connector.itde_manager import take_itde_down
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Tear down the local Exasol container referenced by the stored config."""
    # Open the secure config store that identifies the managed ITDE instance.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password=os.environ["SCS_MASTER_PASSWORD"],
    )

    # Stop and remove the managed local Exasol container.
    take_itde_down(conf)

    # Close the encrypted store after teardown completes.
    conf.close()


if __name__ == "__main__":
    main()
