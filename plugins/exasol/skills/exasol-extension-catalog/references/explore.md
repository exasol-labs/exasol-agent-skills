# EXPLORE Catalog

Use EXPLORE when the user wants to inspect schemas, query data interactively, use notebooks, BI tools, catalogs, or agentic query interfaces.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs and `github.com/exasol/...`.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## Exasol MCP Server

- **Use for**: AI assistant access to Exasol schemas, tables, SQL, diagnostics, and profiling.
- **Best when**: user wants agentic exploration or tool-based natural-language workflows.
- **Links**:
  - https://github.com/exasol/mcp-server
  - https://docs.exasol.com/db/latest/ai/ai_ask_db/index.htm

## Governed SQL MCP Server / Text-to-SQL MCP Server

- **Use for**: experimental governed Text-to-SQL, especially local/read-only setups.
- **Best when**: user wants natural-language SQL generation with local metadata/query handling.
- **Links**:
  - https://github.com/exasol-labs/exasol-labs-text2sql-mcp-server
  - https://docs.exasol.com/db/latest/ai/ai_ask_db/index.htm

## VS Code extension

- **Use for**: SQL editing, execution, object browsing, notebooks, result viewing, formatting.
- **Best when**: user wants a developer-friendly Exasol IDE experience.
- **Links**:
  - https://github.com/exasol-labs/exasol-vscode
  - https://marketplace.visualstudio.com/items?itemName=Exasol.exasol-vscode

## AI Lab and Notebook Connector

- **AI Lab use for**: preconfigured Docker/Jupyter environment for AI/ML experiments on Exasol, with Docker images, AMIs, and VM images available from release pages.
- **Notebook Connector use for**: connection configuration management, notebook tooling, CLI/Python APIs, and SLC deployment support.
- **Direction of travel**: AI Lab now builds on Notebook Connector, which hosts the notebooks and the tests migrated from AI Lab; the SageMaker notebooks have been removed, and Notebook Connector supports SLC deployment to Exasol SaaS instances. Read each releases index below for the current release.
- **Links**:
  - https://github.com/exasol/ai-lab
  - https://github.com/exasol/ai-lab/releases
  - https://github.com/exasol/notebook-connector
  - https://github.com/exasol/notebook-connector/releases
  - https://exasol.github.io/notebook-connector/main/
  - https://docs.exasol.com/db/latest/ai/ai_get_started/set-up-ai-lab.htm
  - https://docs.exasol.com/db/latest/ai/ai_github-resources.htm

## SQL/database clients

Use these when the user wants human SQL exploration:

- EXAplus: https://docs.exasol.com/db/latest/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm
- DBeaver: https://github.com/dbeaver/dbeaver
- DataGrip: https://www.jetbrains.com/datagrip/
- DBVisualizer: https://www.dbvis.com/
- Advanced Query Tool: https://www.querytool.com/
- PushMetrics: https://pushmetrics.io/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Data catalog integrations

Use these when the user wants metadata discovery, governance, documentation, or catalog search:

- Alation: https://www.alation.com/
- Azure Data Catalog / Microsoft Purview: https://learn.microsoft.com/en-us/purview/
- Collibra: https://www.collibra.com/
- D-QUANTUM: verify through the Exasol ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm
- OpenMetadata: https://docs.open-metadata.org/connectors/database/exasol
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Semantic layer / semantic views

- **Use for**: business entities, metrics, governed definitions, agentic grounding.
- **Best when**: user wants agents or BI tools to query with business meaning rather than raw tables.
- **Links**:
  - https://github.com/exasol-labs/exasol-semantic-views
