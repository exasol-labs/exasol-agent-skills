# Connections and SQL

## Install and Compatibility

Install `pyexasol` and only the extras the program needs: `pandas`, `polars`,
`pyarrow`, `orjson`, `rapidjson`, or `ujson`. Set
`EXASOL_TELEMETRY_DISABLE` when policy requires telemetry to be disabled.

Check the target release before stating compatibility. At the 2026-10-27
review, `master` requires Python 3.11 through 3.14, while its README says Exasol
7.1 or newer and Getting Started says Exasol 8 or newer. Do not resolve that
upstream conflict by guessing.

## Connect

Use context managers and an application secret source:

```python
import os
import pyexasol

with pyexasol.connect(
    dsn=os.environ["EXASOL_DSN"],
    user=os.environ["EXASOL_USER"],
    password=os.environ["EXASOL_PASSWORD"],
) as connection:
    with connection.execute("SELECT 1") as statement:
        result = statement.fetchval()
```

Important defaults are `autocommit=True`, `compression=False`,
`encryption=True`, and certificate verification enabled. Consider compression
for bandwidth-constrained links and measure it; it can reduce throughput on
fast networks. SaaS accepts `access_token` or `refresh_token` and requires TLS.
Use a CA file or DSN fingerprint for private certificates; never use
`nocertcheck` in production.

`connect_local_config(section)` reads `~/.pyexasol.ini` by default. The file can hold
plain-text credentials. Never display it; pass overrides as keyword arguments.

## Execute SQL

`execute()` returns `ExaStatement`. Use its context manager or iteration for
large results. Common methods are `fetchone()`, `fetchmany()`, `fetchall()`,
`fetchcol()`, `fetchval()`, `columns()`, `column_names()`, and `rowcount()`.
`fetchall()`, `fetchcol()`, and DataFrame exports can exhaust memory.

Use named PyExasol placeholders:

- `{x}` or `{x!s}`: quoted value
- `!d` or `!f`: checked unquoted number
- `!i`: checked unquoted identifier
- `!q`: quoted identifier; tuples represent qualified names
- `!r`: unchecked SQL text; accept only trusted fixed values

`None` becomes `NULL`, and lists become comma-separated values. These are
client-side formatter substitutions, not server bind variables.

The direct API defaults to `fetch_mapper=None`. For Python-native values use
`pyexasol.data_types.convert_websocket_to_python`. A mapper receives the value
and its WebSocket `dataType` metadata. Do not use the deprecated
`pyexasol.exasol_mapper` alias or `pyexasol.mapper` module in new code.

Use `create_prepared_statement()` with `?` placeholders for reusable prepared
statements. Use `execute_sql_script()` for multiple statements; it does not
accept query parameters, stops after the first failure, and does not roll back
earlier work automatically.

Keep autocommit enabled unless the task needs a transaction. With
`autocommit=False`, call `commit()` or `rollback()` explicitly.
Use `set_query_timeout()` to bound long-running work, especially UDF calls.
