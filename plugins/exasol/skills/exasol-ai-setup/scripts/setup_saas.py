from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    conf.save(CKey.saas_account_id, "<account-id>")
    conf.save(CKey.saas_database_id, "<database-id>")
    conf.save(CKey.saas_pat, "<personal-access-token>")
    conf.save(CKey.db_schema, "AI_SCHEMA")

    conf.close()


if __name__ == "__main__":
    main()
