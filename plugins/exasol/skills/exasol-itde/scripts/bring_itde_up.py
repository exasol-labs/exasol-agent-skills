from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.itde_manager import bring_itde_up
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    conf.save(CKey.mem_size, "4")
    conf.save(CKey.disk_size, "10")
    bring_itde_up(conf)
    conf.close()


if __name__ == "__main__":
    main()
