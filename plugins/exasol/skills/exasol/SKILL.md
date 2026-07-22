---
name: exasol
description: Top-level router for Exasol work. Use for any Exasol database, exapump, SQL, BucketFS, extension, integration, UDF, Script Language Container, or Exasol Personal setup task, then route to the narrowest specialized Exasol skill.
---

# Exasol Router Skill

Use this skill whenever the user asks about Exasol. The user does not need to know internal skill names. Treat `/exasol <task>` and natural-language Exasol requests as the public interface.

## Routing Algorithm

Choose the narrowest matching route. If multiple routes apply, load them in dependency order.

When a request mentions `FROM SCRIPT CLOUD_STORAGE_EXTENSION`,
`INTO SCRIPT CLOUD_STORAGE_EXTENSION`, `CLOUD_STORAGE_EXTENSION.IMPORT_PATH`,
or `CLOUD_STORAGE_EXTENSION.EXPORT_PATH`, prefer
**exasol-cloud-storage-extension** over native import or export routes.

When a request mentions importing `Avro`, `ORC`, or `Delta` from object storage
such as S3, Azure Blob Storage, Azure Data Lake, Google Cloud Storage, HDFS, or
Alluxio, prefer **exasol-cloud-storage-extension** unless the user clearly asks
for native `IMPORT`.

When a request mentions `IMPORT`, `IMPORT INTO`, `exapump upload`, or
other import-specific phrases, prefer **exasol-import** over the broader
database route even if the wording also contains generic terms such as `SQL`
or `query`.

When a request mentions `EXPORT`, `EXPORT INTO`, or `exapump export`,
prefer **exasol-export** over the broader database route.

When a request mentions `document virtual schema`, `document virtual schemas`,
`document-file virtual schema`, `document files virtual schema`,
`S3 document files`, `Google Cloud Storage document files`,
`Azure Blob document files`,
`Azure Data Lake Gen2 document files`, or
`Azure Data Lake Storage Gen2 document files`,
prefer **exasol-document-virtual-schemas** over the JDBC virtual schema route.
When a request mentions `JDBC virtual schema`, or a
database-source virtual schema such as PostgreSQL, Oracle, MySQL, SQL Server,
or DB2, prefer **exasol-jdbc-virtual-schemas** over the broader extension
catalog route. Do not route a bare `Virtual Schema` mention here unless the
source is clearly JDBC/database-based.

When a request mentions custom virtual schema adapter implementation,
source-specific JDBC dialect code, `virtual-schema-common-jdbc`, adapter JAR
packaging, adapter-side debugging, or remote debugging for a virtual schema
adapter, prefer **exasol-virtual-schema-adapter-development** over the normal
JDBC/document virtual schema usage routes.

When a request mentions `CREATE CONNECTION` without clear import, export, or
object-store file movement intent, prefer **exasol-database**.

1. **Exasol database, query, and general exapump workflows**
   - Trigger phrases: `query`, `SQL`, `Exasol SQL`, `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`, `CREATE CONNECTION`, `connection object`, `profile`, `exapump sql`, `exapump profile`
   - Activate: **exasol-database**

2. **Import workflows**
   - Trigger phrases: `IMPORT`, `IMPORT INTO`, `upload CSV`, `upload Parquet`, `local file load`, `S3 import`, `Azure Blob import`, `GCS import`, `CREATE CONNECTION` with import or object-store loading intent, `Parquet import`, `exapump upload`
   - Activate: **exasol-import**

3. **Cloud Storage Extension workflows**
   - Trigger phrases: `Cloud Storage Extension`, `FROM SCRIPT CLOUD_STORAGE_EXTENSION`, `INTO SCRIPT CLOUD_STORAGE_EXTENSION`, `CLOUD_STORAGE_EXTENSION.IMPORT_PATH`, `CLOUD_STORAGE_EXTENSION.EXPORT_PATH`, `Avro from object storage`, `ORC from object storage`, `Delta from object storage`, `ORC from S3`, `Avro from S3`, `Delta from S3`, `extension-based object-storage loading`, `extension-based Parquet reader`, `Avro through Cloud Storage Extension`, `ORC through Cloud Storage Extension`, `Delta through Cloud Storage Extension`, `extension-based Parquet export`, `extension-based file reader`
   - Activate: **exasol-cloud-storage-extension**

4. **Export workflows**
   - Trigger phrases: `EXPORT`, `EXPORT INTO`, `export table`, `export local file`, `export CSV`, `export Parquet`, `export to S3`, `export to Azure Blob`, `export to GCS`, `export to FTP`, `export to SFTP`, `export to HTTP`, `export to HTTPS`, `CREATE CONNECTION` with export target setup intent, `exapump export`
   - Activate: **exasol-export**

5. **JDBC virtual schema workflows**
   - Trigger phrases: `JDBC virtual schema`, `database-source virtual schema`, `query external database through a virtual schema`, `supported JDBC dialect`, `PostgreSQL virtual schema`, `Oracle virtual schema`, `SQL Server virtual schema`, `MySQL virtual schema`, `DB2 virtual schema`, `EXPLAIN VIRTUAL` with JDBC/database-source context, `ALTER VIRTUAL SCHEMA` with JDBC/database-source context
   - Activate: **exasol-jdbc-virtual-schemas**

6. **Document-file virtual schema workflows**
   - Trigger phrases: `document files virtual schema`, `document-file virtual schema`, `S3 document files`, `Google Cloud Storage document files`, `Azure Blob document files`, `Azure Data Lake Gen2 document files`, `Azure Data Lake Storage Gen2 document files`, `document-file virtual schema adapter`, `query object storage via virtual schema`
   - Activate: **exasol-document-virtual-schemas**

7. **Virtual schema adapter development workflows**
   - Trigger phrases: `custom adapter`, `build virtual schema adapter`, `source-specific JDBC dialect`, `virtual-schema-common-jdbc`, `new SQL dialect adapter`, `remote debugging for virtual schemas`, `adapter JAR packaging`, `adapter-side debugging`
   - Activate: **exasol-virtual-schema-adapter-development**

8. **Notebook-connector AI setup**
   - Trigger phrases: `Secrets`, `scs`, `secure config store`, `notebook-connector setup`, `db_host_name`, `db_schema`, `storage_backend`, `huggingface_token`
   - Activate: **exasol-ai-setup**

9. **Transformers Extension workflows**
   - Trigger phrases: `Transformers Extension`, `TE extension`, `initialize_te_extension`, `deploy_scripts`, `TE UDF`, `PYTHON3_TE`, `Hugging Face models in Exasol`
   - Activate: **exasol-transformers**

10. **Exasol tools, extensions, connectors, integrations, and architecture patterns**
   - Trigger phrases: `extension`, `connector`, `integration`, `catalog`, `tool`, `which Exasol tool`, `Virtual Schema adapter selection`, `maintained virtual schema adapter`, `MCP`, `Text-to-SQL`, `Lakehouse Turbo`, `Terraform`, `Ansible`, `Databricks`, `SAP`, `Power BI`, `Tableau`, `migration`, `governance`, `observability`, `semantic layer`, `Agent Control Plane`
   - Activate: **exasol-extension-catalog**

11. **BucketFS file management**
   - Trigger phrases: `BucketFS`, `bfsdefault`, `bucket`, `upload jar`, `upload model`, `list files`, `download from bucket`, `delete bucket file`
   - Activate: **exasol-bucketfs**

12. **Notebook-connector connection helpers**
   - Trigger phrases: `open_pyexasol_connection`, `open_sqlalchemy_connection`, `open_ibis_connection`, `open_bucketfs_bucket`, `open_bucketfs_location`, `get_backend`, `connection helper`, `notebook-connector`
   - Activate: **exasol-notebook-connections**

13. **Notebook Connector local Docker database workflows**
   - Trigger phrases: `bring_itde_up`, `restart_itde`, `get_itde_status`, `take_itde_down`, `ITDE`
   - Activate: **exasol-itde**

14. **Text AI Extension workflows**
   - Trigger phrases: `Text AI Extension`, `TXAIE`, `deploy_license`, `initialize_text_ai_extension`, `Extraction`, `NamedEntityExtractor`, `PipelineExtractor`, `BranchExtractor`, `StandardExtractor`, `TopicClassifierExtractor`, `zero-shot classification`, `feature extraction`, `PYTHON3_TXAIE`
   - Activate: **exasol-text-ai**

When a user mentions `Text AI Extension`, `TXAIE`, `deploy_license`,
`initialize_text_ai_extension`, or extraction classes such as
`NamedEntityExtractor`, prefer **exasol-text-ai** over the broader
**exasol-extension-catalog** route.

15. **UDFs and Script Language Containers**
   - Trigger phrases: `UDF`, `CREATE SCRIPT`, `SCALAR`, `SET script`, `ExaIterator`, `Python UDF`, `Java UDF`, `Lua UDF`, `R UDF`, `SLC`, `Script Language Container`, `exaslct`
   - Activate: **exasol-udfs**

16. **Exasol Personal setup**
   - Trigger phrases: `set up Exasol`, `Exasol Personal`, `deploy Exasol`, `install Exasol on AWS`, `new Exasol database`
   - Activate: **exasol-setup-personal**

17. **Distributed ML, machine learning, data mining, iterative HPC**
   - Trigger phrases: `distributed ML`, `machine learning`, `train model`, `batch inference`,
     `prediction`, `feature engineering`, `hyperparameter`, `PyTorch`, `TensorFlow`,
     `scikit-learn`, `RAPIDS`, `GPU model`, `model deployment`, `distributed training`,
     `ensemble`, `anomaly detection`, `forecasting`, `clustering at scale`, `k-means`,
     `gradient descent`, `iterative algorithm`, `frequent itemset`, `association rules`,
     `market basket`, `Apriori`, `FP-Growth`, `data mining`, `SON algorithm`
   - Activate: **exasol-distributed-ml**

## Dependency Order

When setup and usage both apply, resolve prerequisites first:

1. Exasol Personal or external database availability
2. Tool, extension, connector, or architecture selection
3. Virtual schema adapter selection when external federation is required
4. Custom virtual schema adapter implementation or packaging when a maintained adapter is not enough
5. Notebook-connector AI setup when required
6. Local Docker database lifecycle or helper-level connectivity validation
7. Extension-specific TXAIE or Transformers workflow
8. SQL, data movement, BucketFS, UDF, SLC, or integration task
9. Distributed ML, data mining, or iterative HPC task (depends on UDF/SLC and BucketFS)

## User Interaction Rules

- Do not ask the user to choose a sub-skill.
- Infer the route from the task.
- If the task is ambiguous, ask one concrete question about the desired outcome, not about internal skill names.
- Prefer `/exasol <task>` in examples.
- Do not expose implementation labels such as `exasol-database` unless the user is contributing to this repo.

## Adding Routes

When adding a new specialized Exasol skill, update this router and mirror the same intent route in `plugins/exasol/commands/exasol.md`. Keep the new skill focused on its domain and put detailed docs in `references/`.
