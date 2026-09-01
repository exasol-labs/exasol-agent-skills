# BucketFS Concepts

**BucketFS** is a synchronous distributed file system available on all nodes of an Exasol cluster. Files stored in BucketFS are automatically replicated to every cluster node.

## The Service / Bucket / Path Model

- **Service**: A named BucketFS instance. The default service is `bfsdefault`.
- **Bucket**: A storage container within a service. The default bucket is `default`.
- **Path inside BucketFS**: Files are referenced by the path within the bucket (e.g., `models/my_model.pkl`).
- **Local path inside UDFs**: Files are accessible at `/buckets/<service>/<bucket>/<path>` (e.g., `/buckets/bfsdefault/default/models/my_model.pkl`).

The two path forms matter constantly: `exapump bucketfs` commands take the
bucket-relative path (`models/my_model.pkl`), while UDF code opens the absolute
mounted path (`/buckets/bfsdefault/default/models/my_model.pkl`). The same file
is named differently on each side.

## Characteristics and Limits

- Writes are atomic — a file is either fully written or not at all.
- No transactions and no file locks; the latest write wins.
- All nodes see identical content after synchronisation.
- BucketFS is not included in database backups — manage backups separately.
- Not suited for very large datasets due to replication overhead.

Because there are no locks, a file that a running UDF is reading can be
replaced underneath it. Version model and library files by name
(`model-2026-03-01.pkl`) rather than overwriting a fixed path when UDFs may be
running.
