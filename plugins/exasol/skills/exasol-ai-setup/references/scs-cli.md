# notebook-connector Setup via `scs`

Use the `scs` CLI when the user wants terminal-first setup of the encrypted Secure Configuration Storage (SCS).

## Help

Use these commands first when the user wants to inspect the available CLI surface before choosing a specific setup flow.

```bash
scs --help
scs configure --help
scs configure onprem --help
scs configure saas --help
scs configure docker-db --help
scs check --help
scs show --help
```

## Master Password and SCS File

All commands operate on an encrypted SCS file. The CLI creates it if it does not already exist.

Prefer environment variables for automation and to avoid putting secrets into shell history:

```bash
export SCS_FILE=ai_config.db
export SCS_MASTER_PASSWORD="my-strong-password"
```

Related secret env vars:

- `SCS_EXASOL_DB_PASSWORD`
- `SCS_BUCKETFS_PASSWORD`
- `SCS_EXASOL_SAAS_TOKEN`

## On-Prem Exasol

This template writes a complete on-prem notebook-connector configuration, including both database and BucketFS credentials.

```bash
scs configure onprem ai_config.db \
  --db-host-name <host> \
  --db-port 8563 \
  --db-username <user> \
  --db-password <password> \
  --db-schema <schema> \
  --db-use-encryption \
  --bucketfs-host <bfs-host> \
  --bucketfs-port 2580 \
  --bucketfs-user <bfs-user> \
  --bucketfs-password <bfs-password> \
  --bucket default \
  --bucketfs-name bfsdefault \
  --bucketfs-use-encryption
```

## Exasol SaaS

This template writes the SaaS-specific configuration. It uses account and database identity plus a personal access token instead of direct host and BucketFS fields.

```bash
scs configure saas ai_config.db \
  --saas-url https://cloud.exasol.com \
  --saas-account-id <account-id> \
  --saas-database-name <database-name> \
  --saas-token <personal-access-token> \
  --db-schema <schema>
```

If the user knows the database ID instead of the name, use `--saas-database-id`.

## Docker-DB / ITDE

This command stores the local Docker database configuration in the secure config store. It does not start the container by itself.

```bash
scs configure docker-db ai_config.db \
  --db-schema <schema> \
  --db-mem-size 4 \
  --db-disk-size 10 \
  --accelerator none
```

This stores the desired local-database config. Use the `exasol-itde` skill to actually start the container.

## Validate and Inspect

Use these commands to verify the stored configuration before continuing to AI-Lab, Transformers Extension, or Text AI Extension workflows.

```bash
scs check ai_config.db
scs check --connect ai_config.db
scs show ai_config.db
```

Use `scs check --connect` before extension deployment work whenever possible.

## Typical Safe Workflows

On-prem:

```bash
export SCS_MASTER_PASSWORD="my-strong-password"

scs configure onprem ai_config.db \
  --db-host-name 192.168.1.10 \
  --db-port 8563 \
  --db-username sys \
  --db-schema MY_SCHEMA \
  --bucketfs-host 192.168.1.10 \
  --bucketfs-port 2580 \
  --bucketfs-name bfsdefault \
  --bucket default

scs check --connect ai_config.db
scs show ai_config.db
```

SaaS:

```bash
export SCS_MASTER_PASSWORD="my-strong-password"
export SCS_EXASOL_SAAS_TOKEN="<your-pat>"

scs configure saas ai_config.db \
  --saas-account-id "<your-account-id>" \
  --saas-database-name "my-database" \
  --db-schema MY_SCHEMA

scs check --connect ai_config.db
scs show ai_config.db
```
