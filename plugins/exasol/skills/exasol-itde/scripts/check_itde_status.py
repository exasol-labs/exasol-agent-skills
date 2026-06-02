from pathlib import Path

from exasol.nb_connector.itde_manager import (
    ItdeContainerStatus,
    get_itde_status,
)
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    status = get_itde_status(conf)
    if status == ItdeContainerStatus.READY:
        print("Docker DB is up and reachable")
    else:
        print(status)

    conf.close()


if __name__ == "__main__":
    main()
