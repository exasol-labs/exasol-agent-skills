# Exasol SQL Quirks & Differences

A comprehensive reference for SQL behavior that differs from standard SQL, PostgreSQL, MySQL, or Oracle. Knowing these prevents hard-to-debug errors.

## Data Types

### No TIME Type
Exasol has **no standalone TIME data type**. Workarounds:
- Use `TIMESTAMP` and ignore the date portion
- Store as `VARCHAR(8)` in `HH:MM:SS` format
- Store as `INTERVAL DAY TO SECOND`

### Native BOOLEAN
Exasol supports `BOOLEAN` as a first-class type (unlike Oracle).
```sql
CREATE TABLE t (is_active BOOLEAN DEFAULT TRUE);
INSERT INTO t VALUES (TRUE), (FALSE), (NULL);
SELECT * FROM t WHERE is_active;  -- works directly
```

### VARCHAR2 / NVARCHAR2
Exasol supports `VARCHAR2` and `NVARCHAR2` as aliases for `VARCHAR` (Oracle compatibility). Max length is 2,000,000 characters.

### DECIMAL Precision
`DECIMAL(p,s)` supports precision up to 36 digits. Default `DECIMAL` without parameters is `DECIMAL(18,0)`.

### HASHTYPE
Exasol has a native `HASHTYPE` type for storing hash values (MD5, SHA, etc.). Stored as fixed-length binary.

### GEOMETRY
Native spatial data type for geospatial data (WKT/WKB format).

---

## Identifier Handling

### Unquoted Identifiers Are UPPERCASED
```sql
CREATE TABLE customers (name VARCHAR(100));
-- Actually creates: TABLE "CUSTOMERS" ("NAME" VARCHAR(100))

SELECT name FROM customers;     -- works (both get uppercased)
SELECT "name" FROM customers;   -- ERROR: column "name" not found (table has "NAME")
SELECT "NAME" FROM "CUSTOMERS"; -- works
```

### Quoted Identifiers Are Case-Sensitive
```sql
CREATE TABLE "myTable" ("myColumn" INT);
SELECT "myColumn" FROM "myTable";  -- works
SELECT mycolumn FROM myTable;      -- ERROR: "MYTABLE" not found
```

**Rule of thumb:** Don't use quoted identifiers unless you have a specific reason. Let everything be uppercase.

---

## Constraints

### No CHECK Constraints
```sql
CREATE TABLE t (age INT CHECK (age >= 0));  -- ERROR
```
Workaround: Validate in application logic or use a view with a WHERE clause.

### UNIQUE Requires NOT NULL
All columns in a UNIQUE constraint must be `NOT NULL`:
```sql
CREATE TABLE t (a INT, UNIQUE(a));          -- ERROR: nullable column in UNIQUE
CREATE TABLE t (a INT NOT NULL, UNIQUE(a)); -- OK
```

### PRIMARY KEY Implies NOT NULL and UNIQUE
Same as standard SQL, but worth noting given the UNIQUE restriction above.

### Foreign Keys Are Not Enforced
Exasol accepts `FOREIGN KEY` syntax but **does not enforce referential integrity**. Foreign keys are hints for the optimizer only.

---

## Regular Expressions (PCRE2)

Exasol uses **PCRE2** syntax, not POSIX. This means full Perl-compatible regex support.

### Functions

```sql
-- Test if pattern matches
SELECT REGEXP_LIKE('hello123', '^\w+\d+$');  -- TRUE

-- Find position of match
SELECT REGEXP_INSTR('abc 123 def', '\d+');  -- 5

-- Replace matches
SELECT REGEXP_REPLACE('foo  bar', '\s+', ' ');  -- 'foo bar'

-- Extract matching substring
SELECT REGEXP_SUBSTR('abc 123 def', '\d+');  -- '123'

-- With capture groups
SELECT REGEXP_SUBSTR('2024-01-15', '(\d{4})-(\d{2})-(\d{2})', 1, 1, '', 2);  -- '01' (2nd group)
```

### PCRE2 Features Available
- Lookahead/lookbehind: `(?=...)`, `(?<=...)`
- Non-greedy quantifiers: `*?`, `+?`, `??`
- Named groups: `(?P<name>...)`
- Character classes: `\d`, `\w`, `\s`, `\b`
- Unicode support

---

## Set Operations

### MINUS and EXCEPT
Exasol supports both `MINUS` (Oracle-compatible) and `EXCEPT` for set difference:
```sql
SELECT * FROM a EXCEPT SELECT * FROM b;  -- works
SELECT * FROM a MINUS SELECT * FROM b;   -- also works (identical behavior)
```

`UNION`, `UNION ALL`, and `INTERSECT` also work as in standard SQL.

---

## IMPORT / EXPORT Statements

### IMPORT FROM Local CSV
```sql
IMPORT INTO my_schema.my_table
FROM LOCAL CSV FILE '/path/to/data.csv'
COLUMN SEPARATOR = ','
COLUMN DELIMITER = '"'
SKIP = 1
REJECT LIMIT 0;
```

### IMPORT FROM S3
```sql
-- First create a connection
CREATE OR REPLACE CONNECTION s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=AKIA...;S3_SECRET_KEY=secret...';

-- Import CSV
IMPORT INTO my_schema.my_table
FROM CSV AT s3_conn
FILE 'path/to/data.csv'
COLUMN SEPARATOR = ','
SKIP = 1;

-- Import Parquet
IMPORT INTO my_schema.my_table
FROM PARQUET AT s3_conn
FILE 'data/*.parquet';  -- wildcards supported
```

### IMPORT FROM Azure Blob Storage
```sql
CREATE OR REPLACE CONNECTION azure_conn
TO 'https://myaccount.blob.core.windows.net/mycontainer'
USER '' IDENTIFIED BY 'AZURE_SAS_TOKEN=sv=2021-06-08&ss=b&srt=co...';

IMPORT INTO my_schema.my_table
FROM CSV AT azure_conn
FILE 'data/file.csv';
```

### IMPORT FROM Google Cloud Storage
```sql
CREATE OR REPLACE CONNECTION gcs_conn
TO 'https://storage.googleapis.com/my-bucket'
USER '' IDENTIFIED BY 'GCS_ACCESS_KEY=GOOG...;GCS_SECRET_KEY=secret...';

IMPORT INTO my_schema.my_table
FROM CSV AT gcs_conn
FILE 'data/file.csv';
```

### EXPORT TO File
```sql
EXPORT my_schema.my_table
INTO LOCAL CSV FILE '/path/to/output.csv'
COLUMN SEPARATOR = ','
COLUMN DELIMITER = '"'
WITH COLUMN NAMES;
```

### EXPORT Query Result
```sql
EXPORT (SELECT * FROM t WHERE status = 'active')
INTO LOCAL CSV FILE '/path/to/active.csv'
WITH COLUMN NAMES;
```

---

## Connection Objects

```sql
-- Create
CREATE OR REPLACE CONNECTION my_conn
TO 'connection-url'
USER 'username' IDENTIFIED BY 'password';

-- View
SELECT * FROM EXA_DBA_CONNECTIONS;

-- Drop
DROP CONNECTION my_conn;
```

---

## Reserved Keywords

Exasol reserves many keywords beyond the SQL standard. Using these as unquoted identifiers causes syntax errors. **Always double-quote identifiers that match reserved words.**

**Do not rely on a hardcoded list — query the live database instead:**

```bash
# Get ALL reserved keywords (authoritative, always up-to-date)
exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"

# Check if a specific word is reserved
exapump sql "SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = 'PROFILE'"

# Search for keywords matching a pattern
exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED AND KEYWORD LIKE '%CONNECT%'"

# Count total reserved keywords
exapump sql "SELECT COUNT(*) FROM EXA_SQL_KEYWORDS WHERE RESERVED"
```

The `EXA_SQL_KEYWORDS` system table has two columns: `KEYWORD` (VARCHAR) and `RESERVED` (BOOLEAN). This is the single source of truth for keyword reservation status and reflects the exact version of Exasol running.

### Escaping Reserved Words
```sql
-- These fail because PROFILE and RANDOM are reserved:
CREATE TABLE stats (profile VARCHAR(100), random INT);  -- ERROR

-- Double-quote to escape:
CREATE TABLE stats ("PROFILE" VARCHAR(100), "RANDOM" INT);  -- OK

-- When querying, you must also quote:
SELECT "PROFILE", "RANDOM" FROM stats;
```

### Common Traps
Some frequently-used words that are reserved in Exasol but not in other databases:
- `PROFILE`, `SCRIPT`, `RANDOM`, `SESSION`, `STATEMENT` — Exasol-specific
- `QUALIFY`, `PREFERRING`, `LISTAGG`, `GROUP_CONCAT` — analytics
- `NVL`, `DECODE`, `ROWNUM`, `MINUS`, `VARCHAR2`, `NVARCHAR2` — Oracle-compatible
- `CONNECT_BY_ROOT`, `PRIOR`, `NOCYCLE` — hierarchical queries
- `EMITS`, `DISTRIBUTE`, `HASHTYPE`, `GEOMETRY` — Exasol extensions

When in doubt, run the query above rather than guessing.

---

## Useful System Tables

| Table | Contents |
|-------|----------|
| `EXA_ALL_TABLES` | All accessible tables |
| `EXA_ALL_COLUMNS` | All accessible columns with types |
| `EXA_ALL_SCHEMAS` | All accessible schemas |
| `EXA_ALL_VIEWS` | All accessible views |
| `EXA_ALL_SCRIPTS` | All accessible UDF scripts |
| `EXA_DBA_CONNECTIONS` | All connection objects (DBA only) |
| `EXA_SQL_KEYWORDS` | All SQL keywords and their reservation status |
| `EXA_METADATA` | Database metadata (version, etc.) |
| `EXA_STATISTICS` | Query statistics |

```sql
-- Check if a word is reserved
SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = 'PROFILE';

-- Get all reserved keywords
SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED;
```

---

## Other Noteworthy Behaviors

### LIKE Is Case-Sensitive
```sql
SELECT * FROM t WHERE name LIKE '%John%';  -- won't match 'john'
SELECT * FROM t WHERE UPPER(name) LIKE '%JOHN%';  -- case-insensitive workaround
```

### String Concatenation
Both `||` and `CONCAT()` work:
```sql
SELECT 'hello' || ' ' || 'world';
SELECT CONCAT('hello', ' ', 'world');
```

### LIMIT and OFFSET
Exasol supports `LIMIT` and `OFFSET` (unlike older Oracle):
```sql
SELECT * FROM t ORDER BY id LIMIT 10 OFFSET 20;
```

### CREATE TABLE AS SELECT (CTAS)
```sql
CREATE TABLE new_table AS SELECT * FROM old_table WHERE condition;
```

### MERGE (Upsert)
```sql
MERGE INTO target t
USING source s ON (t.id = s.id)
WHEN MATCHED THEN UPDATE SET t.value = s.value
WHEN NOT MATCHED THEN INSERT VALUES (s.id, s.value);
```

### Date/Time Functions
```sql
SELECT CURRENT_TIMESTAMP;                          -- now
SELECT ADD_DAYS(CURRENT_DATE, 7);                 -- 7 days from now
SELECT DAYS_BETWEEN('2024-01-01', '2024-12-31');  -- day difference
SELECT TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD');  -- format
```
