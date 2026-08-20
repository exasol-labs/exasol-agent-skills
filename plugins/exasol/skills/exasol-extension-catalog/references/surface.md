# SURFACE Catalog

Use SURFACE when the user wants to expose Exasol to humans, applications, BI, APIs, low-code tools, or agents.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs and `github.com/exasol/...`.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## BI and visualization tools

Use these when the user asks about dashboards, reports, semantic exploration, self-service analytics, or BI connectivity:

- Tableau Connector: https://github.com/exasol/tableau-connector
- Tableau: https://www.tableau.com/
- Power BI: https://learn.microsoft.com/en-us/power-bi/
- Amazon QuickSight: https://aws.amazon.com/quicksight/
- Qlik Sense: https://www.qlik.com/
- Looker: https://looker.com/
- Apache Superset: https://superset.apache.org/
- Grafana Datasource for Exasol: https://github.com/exasol-labs/grafana-datasource
- MicroStrategy / Strategy One: https://www.microstrategy.com/
- IBM Cognos: https://www.ibm.com/products/cognos-analytics
- SAP BusinessObjects: https://www.sap.com/products/technology-platform/bi-platform.html
- Yellowfin: https://www.yellowfinbi.com/
- Sisense: https://www.sisense.com/
- SAS: https://www.sas.com/
- Pyramid Analytics: https://www.pyramidanalytics.com/
- Metabase: https://www.metabase.com/
- Pentaho Business Analytics: https://www.hitachivantara.com/
- WebFOCUS: https://www.ibi.com/
- Veezoo: https://www.veezoo.com/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## dash-server

- **Use for**: agent-operated Dash and Plotly hosting for live analytical apps backed by Exasol.
- **Best when**: user wants an agent to create, validate, deploy, promote, diagnose, or roll back real Python dashboard applications instead of manually building a fixed BI canvas.
- **Notable capabilities**: MCP-first control plane, GitOps-backed app/revision history, preview and live URLs, structured diagnostics, Exasol profile bootstrap, Exasol dashboard scaffolds, schema-aware scaffold generation, SQL file layout, and secret metadata kept outside Git.
- **Links**:
  - https://github.com/exasol-labs/dash-server

## Exasol REST API / ERA

- **Use for**: REST API access to Exasol.
- **Best when**: user wants HTTP/REST integration or low-code connector backing.
- **Links**:
  - https://github.com/exasol/exasol-rest-api
  - https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Power Apps Connector for Exasol

- **Use for**: Microsoft Power Apps integration.
- **Best when**: user wants low-code applications that communicate with Exasol using ERA.
- **Links**:
  - https://github.com/exasol/power-apps-connector
  - https://learn.microsoft.com/en-us/connectors/exasol/

## Low-code platforms

Use these when the user asks for low-code application builders:

- Microsoft Power Apps: https://learn.microsoft.com/en-us/power-apps/
- OutSystems: https://www.outsystems.com/
- UI Bakery: https://uibakery.io/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## MCP and agent surfaces

- Exasol MCP Server: https://github.com/exasol/mcp-server
- Governed SQL MCP Server: https://github.com/exasol-labs/exasol-labs-text2sql-mcp-server
- dash-server: https://github.com/exasol-labs/dash-server
- exasol-agent-skills: https://github.com/exasol-labs/exasol-agent-skills
- Agent Control Plane blog: https://www.exasol.com/blog/exasol-agent-control-plane/

## Application drivers and API surfaces

- JDBC: https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm
- ODBC: https://docs.exasol.com/db/latest/connect_exasol/drivers/odbc.htm
- ADO.NET: https://docs.exasol.com/db/latest/connect_exasol/drivers/ado_net.htm
- PyExasol: https://github.com/exasol/pyexasol
- SQLAlchemy Exasol: https://github.com/exasol/sqlalchemy-exasol
- Exasol TypeScript/JavaScript driver: https://github.com/exasol/exasol-driver-ts
- Go SQL Driver: https://github.com/exasol/exasol-driver-go
- WebSockets API: https://github.com/exasol/websocket-api

## Data virtualization and query engines

Use these when the user wants to expose Exasol through another query/virtualization layer:

- CData Virtuality: https://www.cdata.com/virtuality/
- Denodo: https://www.denodo.com/
- Trino: https://trino.io/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Admin and developer surfaces

- Exasol Launcher: https://github.com/exasol/exasol-personal
- Exasol Admin: https://docs.exasol.com/db/latest/administration/on-premise/admin_interface/admin_ui_overview.htm
- EXAplus: https://docs.exasol.com/db/latest/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm
- VS Code extension: https://marketplace.visualstudio.com/items?itemName=Exasol.exasol-vscode
- Notebook Connector: https://github.com/exasol/notebook-connector
