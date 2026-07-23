---
name: exasol-bucketfs
description: "Exasol BucketFS file system management via exapump CLI. Covers listing, uploading, downloading, and deleting files and directories in BucketFS, BucketFS configuration, bucket structure, and use with UDFs."
---

# Exasol BucketFS Skill

Trigger when the user mentions **BucketFS**, **exapump**, **bucket**, **bfsdefault**, **upload to BucketFS**, **download from BucketFS**, **delete from BucketFS**, **BucketFS path**, **BucketFS file**, or any BucketFS file management task.

## BucketFS Concepts

**BucketFS** is a synchronous distributed file system available on all nodes of an Exasol cluster. Files stored in BucketFS are automatically replicated to every cluster node.

Key concepts:
- **Service**: A named BucketFS instance. The default service is `bfsdefault`.
- **Bucket**: A storage container within a service. The default bucket is `default`.
- **Path inside BucketFS**: Files are referenced by the path within the bucket (e.g., `models/my_model.pkl`).
- **Local path inside UDFs**: Files are accessible at `/buckets/<service>/<bucket>/<path>` (e.g., `/buckets/bfsdefault/default/models/my_model.pkl`).

Important characteristics:
- Writes are atomic — a file is either fully written or not at all.
- No transactions and no file locks; the latest write wins.
- All nodes see identical content after synchronisation.
- BucketFS is not included in database backups — manage backups separately.
- Not suited for very large datasets due to replication overhead.

## exapump CLI

The `exapump` command is the CLI tool for managing BucketFS. All BucketFS operations use the `exapump bucketfs` subcommand.

### Connection Configuration

Connection settings are stored in `~/.exapump/config.toml` as named profiles. Example:

```toml
[production]
host = "exasol-prod.example.com"
user = "admin"
password = "s3cret"
default = true
bfs_write_password = "bucketpw"
bfs_read_password = "bucketpw"
```

Key profile fields:

| Field | Default | Purpose |
|-------|---------|---------|
| `bfs_host` | Falls back to `host` | BucketFS hostname |
| `bfs_port` | `2581` | BucketFS port |
| `bfs_bucket` | `default` | Bucket name |
| `bfs_write_password` | Required | Write authentication |
| `bfs_read_password` | Falls back to write password | Read authentication |
| `bfs_tls` | Falls back to `tls` | Enable TLS |
| `bfs_validate_certificate` | Falls back to `validate_certificate` | Certificate validation |

Connection parameters can also be overridden per command via CLI flags (highest priority):

| Flag | Purpose |
|------|---------|
| `--profile` | Select a named profile |
| `--bfs-host` | Override hostname |
| `--bfs-port` | Override port |
| `--bfs-bucket` | Override bucket name |
| `--bfs-write-password` | Override write password |
| `--bfs-read-password` | Override read password |
| `--bfs-tls` | Override TLS setting |
| `--bfs-validate-certificate` | Override certificate validation |

**Parameter resolution order:** CLI flags → profile values → smart defaults.

### Configuration Protocol

**Before any BucketFS operation**, verify the connection is configured:

1. Check if `~/.exapump/config.toml` exists and contains a default profile.
2. If configured, proceed with the operation.
3. If not configured, **ask the user** for the required connection details (host, port, bucket, passwords). Do not guess or assume any defaults. Help the user create the profile in `~/.exapump/config.toml`.

---

## Commands

### `ls` — List Contents

```bash
exapump bucketfs ls [PATH] [OPTIONS]
exapump bucketfs ls -r [PATH]            # Recursive listing
exapump bucketfs ls --recursive [PATH]
```

**Examples:**
```bash
exapump bucketfs ls                      # List bucket root
exapump bucketfs ls models/             # List a directory
exapump bucketfs ls -r models/          # Recursively list all files under models/
```

---

### `cp` — Copy / Upload / Download

Direction is automatically determined by the source type (local file vs. BucketFS path).

Upload a local file to BucketFS:
```bash
exapump bucketfs cp <local-file> <bucket-path>
exapump bucketfs cp <local-file> <bucket-dir>/    # Preserve filename
```

Download a file from BucketFS to local:
```bash
exapump bucketfs cp <bucket-path> <local-path>
```

**Examples:**
```bash
exapump bucketfs cp my_model.pkl models/my_model.pkl     # Upload with explicit name
exapump bucketfs cp my_model.pkl models/                 # Upload, preserve filename
exapump bucketfs cp library.jar jars/library.jar         # Upload JAR for UDF
exapump bucketfs cp models/my_model.pkl .                # Download to current dir
exapump bucketfs cp models/my_model.pkl ./local-copy.pkl # Download with rename
```

---

### `rm` — Remove a File

```bash
exapump bucketfs rm <path-in-bucket>
```

**Examples:**
```bash
exapump bucketfs rm models/old_model.pkl     # Delete a single file
```

---

## Typical Use Cases

### Upload a JAR for a Java UDF

```bash
exapump bucketfs cp my_library.jar jars/my_library.jar
```

Reference in UDF SQL:
```sql
CREATE OR REPLACE JAVA SCALAR SCRIPT my_schema.my_func(input VARCHAR(2000))
RETURNS VARCHAR(2000) AS
  %scriptclass com.example.MyClass;
  %jar /buckets/bfsdefault/default/jars/my_library.jar;
/
```

### Upload an ML Model for a Python UDF

```bash
exapump bucketfs cp model.pkl models/model.pkl
```

Load in Python UDF:
```python
import pickle
with open('/buckets/bfsdefault/default/models/model.pkl', 'rb') as f:
    model = pickle.load(f)
```

### Upload a Custom Script Language Container (SLC)

```bash
exapump bucketfs cp my_slc.tar.gz slc/my_slc.tar.gz
```

Then activate via SQL:
```sql
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///bfsdefault/default/slc/my_slc?lang=python#buckets/bfsdefault/default/slc/my_slc/exaudf/exaudfclient_py3';
```

### Browse and Clean Up BucketFS

```bash
exapump bucketfs ls -r                        # See all files
exapump bucketfs rm old_model.pkl             # Remove an outdated file
```

---

## Related Skills

- **exasol-udfs**: For creating UDF scripts that reference files stored in BucketFS.
- **exasol-database**: For SQL-level operations and connecting to Exasol.
