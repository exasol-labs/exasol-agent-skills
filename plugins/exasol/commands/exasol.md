# /exasol Command

Unified entry point for Exasol work. Route any Exasol task to the narrowest relevant skill or command flow.

## Usage

```
/exasol <Exasol task, SQL query, or question>
```

## Arguments

The argument can be either:
- A **SQL query** to execute directly: `/exasol SELECT * FROM my_table LIMIT 10`
- A **task description** to get guided help: `/exasol upload a CSV file to a new table`
- A **specialized Exasol task**: `/exasol list BucketFS files under models/`
- A **tooling or integration question**: `/exasol which connector should I use for Databricks?`
- A **setup request**: `/exasol set up Exasol Personal on AWS`

## Behavior

When invoked:

1. **Classify the task before checking connections.**
   - Database, general SQL outside direct `IMPORT`, export, schemas, tables, or general `CREATE CONNECTION` questions -> use **exasol-database** behavior.
   - Import workflows such as `IMPORT` or `IMPORT INTO`, local CSV or Parquet upload, remote file loading via connection objects, `CREATE CONNECTION` for import/object-store loading, or `exapump upload` -> use **exasol-import** behavior.
   - If `CREATE CONNECTION` appears with `EXPORT` or without import/load intent, prefer **exasol-database** behavior.
   - Notebook-connector setup, `Secrets`, `scs`, secure config store values, or backend configuration keys such as `db_host_name`, `db_schema`, `storage_backend`, or `huggingface_token` -> use **exasol-ai-setup** behavior.
   - Exasol tools, extensions, connectors, integrations, migration, governance, observability, BI/API surfaces, or architecture recommendations -> use **exasol-extension-catalog** behavior.
   - BucketFS files, buckets, `bfsdefault`, model/JAR uploads, BucketFS list/download/delete -> use **exasol-bucketfs** behavior.
   - Notebook Connector local Docker database workflows such as `bring_itde_up`, `restart_itde`, `get_itde_status`, or `take_itde_down` -> use **exasol-itde** behavior.
   - Notebook Connector Python helper calls such as `open_pyexasol_connection`, `open_sqlalchemy_connection`, `open_ibis_connection`, `open_bucketfs_bucket`, `open_bucketfs_location`, or `get_backend` -> use **exasol-notebook-connections** behavior.
   - Text AI Extension workflows such as `deploy_license`, `initialize_text_ai_extension`, `Extraction`, `NamedEntityExtractor`, `PipelineExtractor`, `BranchExtractor`, `StandardExtractor`, `TopicClassifierExtractor`, feature extraction, or zero-shot classification -> use **exasol-text-ai** behavior.
   - Transformers Extension workflows such as `initialize_te_extension`, `deploy_scripts`, `TE UDF` usage, or Transformers model workflows in Exasol -> use **exasol-transformers** behavior.
   - UDFs, `CREATE SCRIPT`, `ExaIterator`, Python/Java/Lua/R scripts, Script Language Containers, or `exaslct` -> use **exasol-udfs** behavior.
   - Exasol Personal, AWS setup, first Exasol deployment, or new database setup -> use **exasol-setup-personal** behavior.

   If a request matches the broad `extension` wording and also contains
   `Text AI Extension`, `TXAIE`, `deploy_license`, `initialize_text_ai_extension`,
   or extraction-class entrypoints, prefer **exasol-text-ai** over
   **exasol-extension-catalog**.

2. **Do not ask the user to choose a sub-skill.**
   Infer the route from the task. If the task is ambiguous, ask one concrete question about the desired outcome.

3. **For any route that will run `exapump` commands:**
   - Check connectivity with `exapump sql "SELECT 1"`.
   - If it fails, run `exapump profile list`.
   - If profiles exist, ask which profile to use and retry with `exapump sql --profile <name> "SELECT 1"`; always place `--profile` after the subcommand.
   - If no profiles exist, tell the user to run `exapump profile add default`.
   - Apply this check before database SQL work and before `exapump upload` or `exapump export`; if a non-default profile is selected, keep using `--profile <name>` after the subcommand.
   - If the task is an import or upload workflow, follow **exasol-import** behavior first.
   - Use direct `exapump sql` execution for `IMPORT` only when that guidance resolves to an executable remote-file `IMPORT` statement rather than a local-file workflow such as `exapump upload` or `IMPORT INTO "MY_SCHEMA"."MY_TABLE" FROM LOCAL CSV FILE '/path/to/data.csv'`.
   - If the argument is another SQL query (starts with SELECT, CREATE, DROP, INSERT, UPDATE, DELETE, MERGE, EXPORT, ALTER, GRANT, etc.), execute it via `exapump sql "<query>"`.
   - For exports, use `exapump export` with the appropriate format.

4. **For extension catalog routes:**
   - Classify the user objective as deploy, load, explore, enrich, surface, or scale.
   - Load only the matching catalog reference files from `exasol-extension-catalog`.
   - Prefer official Exasol docs and repositories for installation/configuration guidance.
   - Distinguish Exasol-maintained, Exasol Labs/community, and third-party ecosystem options.
   - For current versions, latest releases, security status, or support status, check the linked source before answering.

5. **For BucketFS routes:**
   - Prefer `exapump bucketfs` commands.
   - List with `exapump bucketfs ls`.
   - Upload/download with `exapump bucketfs cp`.
   - Delete with `exapump bucketfs rm`, but always confirm before deleting.
   - `/bucketfs` remains a compatibility shortcut, but `/exasol bucketfs ...` is the preferred user-facing form.

6. **For Notebook Connector setup routes:**
   - Use the Notebook Connector setup skill and validate prerequisites before generating downstream AI helper or extension calls.

7. **For Notebook Connector helper routes:**
   - Use the Notebook Connector connection helper skill and its runnable Python templates for helper-level access.
   - Resolve Notebook Connector setup prerequisites before generating helper calls.

8. **For UDF and SLC routes:**
   - Use Exasol UDF and Script Language Container guidance.
   - Route file upload or SLC activation sub-tasks through BucketFS or database behavior as needed.

9. **For Exasol Personal setup routes:**
   - Do not require an existing exapump profile before setup.
   - Guide deployment first, then create or validate the exapump profile after the database exists.

10. **On errors:** Apply Exasol-specific knowledge to diagnose and fix issues. Common causes:
   - Reserved keyword used as identifier: verify by running `exapump sql "SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = '<word>'"`, then double-quote the identifier.
   - Uppercase identifier mismatch
   - Missing NOT NULL on UNIQUE constraint columns
   - Using unsupported syntax from other databases
   - Using TIME data type

## Examples

```
/exasol SELECT COUNT(*) FROM my_schema.my_table
/exasol CREATE TABLE analytics.events (id DECIMAL(18,0), event_name VARCHAR(200), created_at TIMESTAMP)
/exasol upload sales_data.csv to analytics.sales
/exasol export the users table to parquet with zstd compression
/exasol list BucketFS files under models/
/exasol upload model.pkl to BucketFS at models/model.pkl
/exasol which Exasol connector should I use for Databricks?
/exasol compare Exasol options for governed Text-to-SQL
/exasol write a Python UDF that normalizes product names
/exasol build a Script Language Container with pandas installed
/exasol set up Exasol Personal on AWS
/exasol show me the schema of the orders table
/exasol is "profile" a reserved keyword in Exasol?
```
