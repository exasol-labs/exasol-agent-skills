from pathlib import Path

from exasol.nb_connector.itde_manager import restart_itde
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )
    restart_itde(conf)
    conf.close()


if __name__ == "__main__":
    main()
