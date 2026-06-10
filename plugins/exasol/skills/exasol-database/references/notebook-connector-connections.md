# notebook-connector Database Connections

Use this reference when the user wants to connect to Exasol through Notebook Connector instead of `exapump`.

All helpers read credentials from a `Secrets` store.

## Important Behavior

- `open_pyexasol_connection()` is best for raw SQL and UDF work.
- `open_sqlalchemy_connection()` is best for pandas, SQLAlchemy, or Alembic-style tooling.
- `open_ibis_connection()` is best for ibis dataframe-style queries.
- `open_pyexasol_connection()` does not apply `db_schema` automatically. Pass `schema="MY_SCHEMA"` explicitly.
- `open_sqlalchemy_connection()` and `open_ibis_connection()` do apply `db_schema` automatically.

## pyexasol

```python
from exasol.nb_connector.connections import open_pyexasol_connection

with open_pyexasol_connection(my_secrets, schema="MY_SCHEMA") as conn:
    rows = conn.execute("SELECT * FROM MY_TABLE LIMIT 10").fetchall()
    print(rows)
```

## SQLAlchemy

```python
import pandas as pd
from exasol.nb_connector.connections import open_sqlalchemy_connection

engine = open_sqlalchemy_connection(my_secrets)
df = pd.read_sql("SELECT * FROM MY_TABLE LIMIT 10", engine)
print(df)
```

## ibis

```python
from exasol.nb_connector.connections import open_ibis_connection

conn = open_ibis_connection(my_secrets)
print(conn.list_tables())
print(conn.table("MY_TABLE").limit(10).execute())
```

## Guidance

- Use this reference only after SCS configuration is complete.
- If connection setup is still missing, switch to the `exasol-ai-setup` skill first.
