from pathlib import Path

from exasol.nb_connector.itde_manager import restart_itde
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    # Open the secure config store that identifies the managed ITDE instance.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Restart the managed local Exasol container using the stored notebook-connector configuration.
    restart_itde(conf)

    # Close the encrypted store after the restart request is issued.
    conf.close()


if __name__ == "__main__":
    main()
