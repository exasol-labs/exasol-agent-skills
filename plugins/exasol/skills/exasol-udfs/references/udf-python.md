# Python UDFs

## Context Object API

| Method/Property | SCALAR | SET | Description |
|----------------|--------|-----|-------------|
| `ctx.<column>` | yes | yes | Access input column by name |
| `ctx[index]` | yes | yes | Access input column by index |
| `return value` | yes | no | Return single value (RETURNS) |
| `ctx.emit(v1, v2, ...)` | no | yes | Emit output row (EMITS) |
| `ctx.emit(dataframe)` | no | yes | Emit entire DataFrame as rows |
| `ctx.next()` | no | yes | Advance to next row; returns `False` at end |
| `ctx.size()` | no | yes | Number of rows in current group |
| `ctx.reset()` | no | yes | Reset iterator to first row |
| `ctx.get_dataframe(num_rows, start_col)` | no | yes | Get rows as pandas DataFrame |

**Important:** There is no `emit_dataframe()` method. Use `ctx.emit(dataframe)` to emit a DataFrame.

## Type Mapping

| Exasol Type | Python Type | Notes |
|-------------|------------|-------|
| `DECIMAL(p,0)` where p <= 18 | `int` | |
| `DECIMAL(p,s)` where s > 0 or p > 18 | `decimal.Decimal` | |
| `DOUBLE` | `float` | |
| `BOOLEAN` | `bool` | |
| `VARCHAR(n)` / `CHAR(n)` | `str` | |
| `DATE` | `datetime.date` | |
| `TIMESTAMP` | `datetime.datetime` | |

NULL values map to `None` in Python.

## DataFrame Pattern

Use `ctx.get_dataframe()` to collect rows efficiently, then emit results as a DataFrame:

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT my_schema.batch_predict(
    id INT, feature1 DOUBLE, feature2 DOUBLE
)
EMITS (id INT, prediction DOUBLE) AS
import pickle

# Load model once (module-level, not per-call)
with open('/buckets/bfsdefault/default/models/model.pkl', 'rb') as f:
    model = pickle.load(f)

def run(ctx):
    df = ctx.get_dataframe(num_rows='all', start_col=0)
    df.columns = ['id', 'f1', 'f2']
    df['prediction'] = model.predict(df[['f1', 'f2']])
    ctx.emit(df[['id', 'prediction']])
/
```

**Key points:**
- `ctx.get_dataframe(num_rows='all')` fetches all rows in the group
- `ctx.get_dataframe(num_rows=10000)` fetches in chunks (use in a loop for memory control)
- `start_col=0` is the default; set to skip leading columns
- `ctx.emit(dataframe)` emits the entire DataFrame — column count must match EMITS

## Manual Row Collection (Alternative to get_dataframe)

```python
def run(ctx):
    data = []
    while True:
        data.append([ctx.id, ctx.feature1, ctx.feature2])
        if not ctx.next():
            break
    df = pd.DataFrame(data, columns=['id', 'f1', 'f2'])
    # ... process df ...
    for _, row in df.iterrows():
        ctx.emit(int(row['id']), row['prediction'])
```

## BucketFS File Access

Path format: `/buckets/<service>/<bucket>/<path>`

```python
# Load pickled model
import pickle
with open('/buckets/bfsdefault/default/models/model.pkl', 'rb') as f:
    model = pickle.load(f)

# Import a custom module from BucketFS
import sys
sys.path.append('/buckets/bfsdefault/default/python_modules/')
import my_custom_module

# Read a CSV reference file
import pandas as pd
ref_data = pd.read_csv('/buckets/bfsdefault/default/data/reference.csv')
```

**Performance tip:** Place BucketFS reads at module level (outside `run()`), so they execute once per UDF instance rather than once per row group.

## Error Handling and Debugging

```python
def run(ctx):
    try:
        result = risky_operation(ctx.input_value)
        return result
    except ValueError as e:
        return f"ERROR: {str(e)}"
    except Exception:
        return None  # Or re-raise to fail the entire query
```

To debug, write diagnostic info to the output:
```python
def run(ctx):
    import sys
    print(f"Processing row: {ctx.id}", file=sys.stderr)  # Goes to UDF logs
    # ... actual logic ...
```

## Dynamic Imports

Import packages installed in the SLC:

```sql
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT my_schema.sentiment(text VARCHAR(10000))
RETURNS DOUBLE AS
def run(ctx):
    from textblob import TextBlob  -- Must be installed in the SLC
    blob = TextBlob(ctx.text)
    return blob.sentiment.polarity
/
```

## Memory Management

- Each UDF instance has a memory limit (check via `exa.meta.memory_limit`)
- For large datasets, process in chunks: `ctx.get_dataframe(num_rows=10000)` in a loop
- Release large objects explicitly: `del large_object`
- Use generators where possible instead of materializing full lists

## Metadata Access

```python
def run(ctx):
    schema = exa.meta.current_schema
    script_name = exa.meta.script_name
    mem_limit = exa.meta.memory_limit  # in bytes
    input_cols = exa.meta.input_columns  # list of column info
    # input_cols[i].name, input_cols[i].type, input_cols[i].sql_type
```

## Testing with udf-mock-python

**Note:** This library is experimental and early-stage. It supports basic UDF testing but has limitations.

```bash
pip install exasol-udf-mock-python
```

```python
from exasol_udf_mock_python.mock_meta_data import MockMetaData
from exasol_udf_mock_python.mock_exa_environment import MockExaEnvironment
from exasol_udf_mock_python.mock_executor import UDFMockExecutor
from exasol_udf_mock_python.column import Column
from exasol_udf_mock_python.group import Group

def udf_wrapper():
    def run(ctx):
        return ctx.val * 2
    return run

executor = UDFMockExecutor()
meta = MockMetaData(
    script_code_wrapper_function=udf_wrapper,
    input_type="SCALAR",
    input_columns=[Column("val", int, "INTEGER")],
    output_type="RETURNS",
    output_columns=[Column("result", int, "INTEGER")]
)
exa = MockExaEnvironment(meta)
result = executor.run([Group([(5,), (10,)])], exa)
# result[0].rows == [(10,), (20,)]
```

**Limitations:**
- No BucketFS access (file paths won't resolve)
- No Import/Export specs
- No dynamic output parameters
- Single UDF instance only (no parallel execution testing)
- No container isolation (tests run in your local Python)
