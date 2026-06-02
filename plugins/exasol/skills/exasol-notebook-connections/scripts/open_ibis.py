from pathlib import Path

from exasol.nb_connector.connections import open_ibis_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    ibis_conn = open_ibis_connection(conf)
    print(ibis_conn.list_tables())

    conf.close()


if __name__ == "__main__":
    main()
