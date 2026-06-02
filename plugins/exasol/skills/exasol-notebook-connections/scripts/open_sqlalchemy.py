from pathlib import Path

from exasol.nb_connector.connections import open_sqlalchemy_connection
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    engine = open_sqlalchemy_connection(conf)
    with engine.connect() as connection:
        print(connection.execute("SELECT 1"))

    conf.close()


if __name__ == "__main__":
    main()
