from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    conf.save(CKey.db_host_name, "my-db-host")
    conf.save(CKey.db_port, "8563")
    conf.save(CKey.db_user, "sys")
    conf.save(CKey.db_password, "secret")
    conf.save(CKey.db_schema, "AI_SCHEMA")

    conf.save(CKey.bfs_host_name, "my-bfs-host")
    conf.save(CKey.bfs_port, "2580")
    conf.save(CKey.bfs_user, "w")
    conf.save(CKey.bfs_password, "secret")
    conf.save(CKey.bfs_bucket, "default")
    conf.save(CKey.bfs_service, "bfsdefault")

    conf.close()


if __name__ == "__main__":
    main()
