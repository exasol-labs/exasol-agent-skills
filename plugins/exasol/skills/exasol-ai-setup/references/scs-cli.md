# notebook-connector Setup via `scs`

Use the `scs` CLI when the user wants terminal-first setup.

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

## On-Prem Exasol

This template writes a complete on-prem notebook-connector configuration, including both database and BucketFS credentials.

```bash
scs configure onprem ai_config.db \
  --db-host-name <host> \
  --db-port 8563 \
  --db-user <user> \
  --db-password <password> \
  --db-schema <schema> \
  --bfs-host-name <bfs-host> \
  --bfs-port 2580 \
  --bfs-user <bfs-user> \
  --bfs-password <bfs-password> \
  --bfs-bucket default \
  --bfs-service bfsdefault
```

## Exasol SaaS

This template writes the SaaS-specific configuration. It uses account and database identity plus a personal access token instead of direct host and BucketFS fields.

```bash
scs configure saas ai_config.db \
  --saas-account-id <account-id> \
  --saas-database-id <database-id> \
  --saas-pat <personal-access-token> \
  --db-schema <schema>
```

If the user knows the database name instead of the database ID, use `--saas-database-name`.

## Docker-DB / ITDE

This command stores the local Docker database configuration in the secure config store. It does not start the container by itself.

```bash
scs configure docker-db ai_config.db \
  --db-schema <schema>
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
