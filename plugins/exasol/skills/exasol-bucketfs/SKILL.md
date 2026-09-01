---
name: exasol-bucketfs
description: "Exasol BucketFS file system management via the `exapump bucketfs` CLI. Covers listing, uploading, downloading, and deleting files and directories in BucketFS, the `bfsdefault` service and other bucket services, bucket structure, `bfs_*` profile settings, the `/buckets/<service>/<bucket>/<path>` UDF path, and staging JARs, models, and Script Language Containers for UDFs."
---

# Exasol BucketFS Skill

BucketFS is Exasol's synchronous distributed file system: whatever is written to
a bucket is replicated to every cluster node and mounted read-only inside UDFs
at `/buckets/<service>/<bucket>/<path>`. This skill covers moving files in and
out of it and referencing them from scripts.

## Routing Algorithm

Choose the narrowest matching route. If several apply, load all matching
references before answering.

1. **Run a BucketFS operation** — list, upload, download, delete, or configure the connection
   - Trigger phrases: `exapump bucketfs`, `ls`, `cp`, `rm`, `upload`, `download`, `delete`, `--bfs-host`, `--bfs-bucket`, `bfs_write_password`, `config.toml`, `exapump profile add`
   - Load: `references/exapump-bucketfs-cli.md`

2. **Stage a file for a UDF or SLC** — JARs, pickled models, containers, and the SQL that points at them
   - Trigger phrases: `upload jar`, `%jar`, `upload model`, `load model in UDF`, `upload SLC`, `SCRIPT_LANGUAGES`, `activate container`
   - Load: `references/bucketfs-udf-usage.md`

3. **Understand BucketFS itself** — services, buckets, path forms, replication, durability
   - Trigger phrases: `what is BucketFS`, `bfsdefault`, `service`, `bucket structure`, `replication`, `backup`, `atomic write`, `size limit`
   - Load: `references/bucketfs-concepts.md`

An upload for a UDF usually needs routes 1 and 2 together: the command form
comes from the CLI reference, the path spelling in the SQL from the usage
reference.

## Before Any Operation

Verify that `~/.exapump/config.toml` holds a usable profile before running a
command. If it does not, name the host, port, bucket, and credential fields the
user needs and have them enter secrets locally via `exapump profile add <name>`.
Never ask the user to paste passwords into the conversation, and never echo or
pass them on the command line.

## Safety Rules

- Before `rm`, show the exact bucket, path, and profile, then obtain explicit
  confirmation. BucketFS is not part of database backups, so a deletion is not
  recoverable from a database restore.
- Before a `cp` that would overwrite an existing BucketFS or local file, inspect
  the target and obtain confirmation.
- Never print profile passwords or pass them as command-line arguments when a
  profile can hold them securely.

## Related Skills

- **exasol-udfs**: creating UDF scripts that read BucketFS files, and building the Script Language Containers staged here.
- **exasol-database**: SQL-level operations and database connectivity.
