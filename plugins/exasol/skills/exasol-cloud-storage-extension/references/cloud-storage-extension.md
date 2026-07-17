# Cloud Storage Extension Workflows

## Decision Guide

Pick the narrowest supported loading path:

- Direct local CSV or Parquet movement: use **exasol-import**
- Direct native `IMPORT` SQL: use **exasol-import**
- Object storage file-reading extension path: use Cloud Storage Extension
- Read-only federation instead of copying data: use **exasol-extension-catalog** to choose the right Virtual Schema path

## Security and Boundaries

- keep credentials in the connector or connection mechanism that the workflow already expects
- do not move secrets into ad hoc local artifacts just to make the agent workflow easier
- do not suggest bypassing normal source-system permissions, connection boundaries, or Exasol privileges
- use placeholders in examples instead of real customer endpoints, keys, tokens, or datasets
- keep the distinction clear between database-side SQL, external source systems, and supporting infrastructure

## Cloud Storage Extension

Use Cloud Storage Extension when the user wants an extension-based path for object storage files rather than native `IMPORT` or `EXPORT`.

Use it when:

- the workflow is already built around the extension
- the user is loading object-storage files through an extension-based read path
- the user needs supported file-reader behavior for formats such as Parquet, Avro, ORC, or CSV in that extension family

Do not route simple native `IMPORT` cases here if Exasol `IMPORT` already fits the request more directly.

## Example Requests

Typical requests that belong in this skill:

```text
load Parquet files from object storage through Cloud Storage Extension
read ORC files from a bucket with the Cloud Storage Extension path
use the extension-based file reader instead of native IMPORT
```

## Practical Routing Rules

- If the user says `IMPORT INTO`, `CREATE CONNECTION`, `upload CSV`, or `upload Parquet`, switch back to **exasol-import**
- If the user says `virtual schema`, `adapter`, `federated query`, or `read external tables without loading`, switch to **exasol-extension-catalog** to choose the right Virtual Schema path
- If the user asks which object-storage extension path fits the workflow, stay in this skill and choose the narrowest supported extension workflow
