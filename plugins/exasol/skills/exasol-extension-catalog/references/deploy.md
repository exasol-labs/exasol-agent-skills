# DEPLOY Catalog

Use DEPLOY when the user wants to provision, install, package, configure, schedule, or operate Exasol.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs, `github.com/exasol/...`, and Exasol download artifacts.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## Exasol SaaS

- **Use for**: fully managed cloud Exasol deployments.
- **Best when**: user wants the fastest managed production route and does not want to manage infrastructure.
- **Links**:
  - https://docs.exasol.com/db/latest/home.htm

## Exasol Personal

- **Use for**: free personal-use Exasol deployments on own infrastructure.
- **Best when**: user wants to deploy a full Exasol database in AWS, Azure, Exoscale, STACKIT, or local macOS Apple Silicon.
- **Notable capabilities**: Exasol Launcher, local & cloud presets, custom preset extensibility, built-in SQL client, agent-friendly CLI.
- **Links**:
  - https://github.com/exasol/exasol-personal
  - https://downloads.exasol.com/exasol-personal

## Exasol Docker DB

- **Use for**: local development and testing.
- **Best when**: user needs a fast disposable database for tests, demos, CI, or local experimentation.
- **Links**:
  - https://github.com/exasol/docker-db
  - https://hub.docker.com/r/exasol/docker-db

## Exasol database releases, downloads, Docker images, and public keys

- **Use for**: choosing or verifying Exasol database artifacts for AWS own-account, on-prem, Docker, and download-portal deployments.
- **Best when**: user asks for current/LTS release packages, Docker image tags, release notes, artifact verification, public keys, or supply-chain checks.
- **Versions**: read the current LTS and latest database releases, and the current JDBC, ODBC, EXAplus, and ADO.NET driver builds, from the release-notes index and the download portal below. Do not answer from memory. A Linux ARM64 ODBC build exists.
- **Links**:
  - https://docs.exasol.com/db/latest/release_notes.htm
  - https://downloads.exasol.com/
  - https://hub.docker.com/r/exasol/docker-db
  - https://docs.exasol.com/db/latest/connect_exasol/public_keys.htm

## Extension Manager

- **Use for**: installing and managing Exasol extensions, especially Virtual Schemas.
- **Best when**: user asks how to deploy/manage extension lifecycle.
- **Links**:
  - https://github.com/exasol/extension-manager

## Exasol Terraform Provider

- **Use for**: warehouse-as-code.
- **Best when**: user wants reproducible management of schemas, connections, users, roles, and privileges.
- **Notable capabilities**: RBAC consistency, drift detection, reviewable changes, dev/prod alignment.
- **Links**:
  - https://registry.terraform.io/providers/exasol-labs/exasol/latest/docs
  - https://github.com/exasol-labs/terraform-provider-exasol

## exasol-scheduler

- **Use for**: lightweight table-driven SQL job scheduling.
- **Best when**: user wants scheduled SQL jobs, dependencies, finalizers, and SQL-auditable execution history.
- **Notable capabilities**: SCHED_TASKS, SCHED_HISTORY, CRON syntax, dependency graphs through AFTER, finalizers through IS_FINAL.
- **Links**:
  - https://github.com/exasol-labs/exasol-scheduler

## Script Language Containers / Exasol Script Languages

- **Use for**: UDF runtime packaging.
- **Best when**: user needs custom Python/R/Java/Lua libraries, runtime dependencies, or AI/ML libraries inside Exasol UDFs.
- **Capabilities to look for in the current release**: ARM support for Conda template flavors, package-manager metadata preservation so SBOM tools can read the generated images, APT dependency pinning, and Docker image tag layout. Read the releases index below for which release carries which.
- **Links**:
  - https://github.com/exasol/script-languages
  - https://github.com/exasol/script-languages-release
  - https://github.com/exasol/script-languages-release/releases
  - https://docs.exasol.com/db/latest/database_concepts/udf_scripts.htm

## Exasol public GPG keys

- **Use for**: verifying Exasol artifact signatures and supply-chain trust.
- **Best when**: user asks how to verify downloads, signed artifacts, public keys, expired keys, or key rotation.
- **Links**:
  - https://docs.exasol.com/db/latest/connect_exasol/public_keys.htm

## Exasol Ansible Collection

- **Use for**: automating Exasol SQL execution and user management from Ansible playbooks.
- **Best when**: user wants idempotent automation, check-mode support, structured SQL results, password/LDAP user management, password rotation, or safe user removal.
- **Notable modules**: `exasol_query`, `exasol_user`.
- **Links**:
  - https://github.com/exasol/ansible-collection
  - https://github.com/exasol/ansible-collection/releases

## Ansible Runner Wrapper

- **Use for**: Ansible-based automation originally separated from AI Lab.
- **Best when**: user asks about automating deployment/provisioning workflows around AI Lab or similar setups.
- **Links**:
  - https://github.com/exasol/ansible-runner-wrapper

## Workflow orchestration integrations

- **Use for**: external scheduling/orchestration.
- **Tools**: Apache Airflow, Automic, dbt.
- **Links**:
  - https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm
  - https://airflow.apache.org/
  - https://www.getdbt.com/
