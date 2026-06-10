"""Create an Exasol SaaS notebook-connector configuration in a Secrets store."""

from pathlib import Path

from exasol.nb_connector.ai_lab_config import AILabConfig as CKey, StorageBackend
from exasol.nb_connector.secret_store import Secrets


def main() -> None:
    """Persist SaaS account, database, and PAT values for notebook-connector."""
    # Open the secure config store that will hold the SaaS setup values.
    conf = Secrets(
        db_file=Path("ai_config.db"),
        master_password="my-master-password",
    )

    # Mark the store as SaaS so Notebook Connector resolves connections through the SaaS API.
    conf.save(CKey.storage_backend, StorageBackend.saas.name)

    # Save the SaaS account, database, and PAT values required by notebook-connector.
    conf.save(CKey.saas_url, "https://cloud.exasol.com")
    conf.save(CKey.saas_account_id, "<account-id>")
    conf.save(CKey.saas_database_name, "<database-name>")
    conf.save(CKey.saas_token, "<personal-access-token>")
    conf.save(CKey.db_schema, "AI_SCHEMA")
    conf.save(CKey.cert_vld, "True")

    # Close the encrypted store so all values are flushed and the file is unlocked.
    conf.close()


if __name__ == "__main__":
    main()
