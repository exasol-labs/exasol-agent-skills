# Python 3 and Java Preprocessors

**Availability: Exasol 2025.1.5 and later.** From that release, a preprocessor may be written in the languages that support virtual schema adapter scripts — currently Python 3 and Java — in addition to Lua scripting programs. Verify the target version before recommending this path; on anything older, the only option is Lua (see `lua-authoring-guide.md`).

Reference: [SQL Preprocessor](https://docs.exasol.com/db/latest/database_concepts/sql_preprocessor.htm).

## When To Use This Instead of Lua

Use Python 3 or Java **only** when you need a library Lua does not have. In practice that means one thing: real SQL dialect transpilation with [`sqlglot`](https://github.com/tobymao/sqlglot). Hand-writing a cross-dialect translator in Lua is not a project worth starting.

Stay in Lua when:

- the transform is string or token work (`sqlparsing` exists, and there is no container involved)
- the cluster is older than 2025.1.5
- the preprocessor must be as cheap as possible on every statement

The cost difference is the point. A Python 3 or Java preprocessor runs in the script-language container. That is per-statement overhead paid by **every statement in scope**, whether or not the statement is one you wanted to transform. It is a very different budget from a few hundred microseconds of Lua string work.

## Python 3

The entry point the database calls is `adapter_call(sql_statement)`. It receives the statement text and returns the text to compile.

```sql
--/
CREATE PYTHON3 PREPROCESSOR SCRIPT MY_SCHEMA.PYTHON_PREPROCESSOR_V1 AS
import sqlglot

def adapter_call(sql_statement):
    translated = sqlglot.transpile(sql_statement, read="tsql", write="exasol")
    return translated[0]
/
```

That is the documentation's example, and it is deliberately minimal. **Do not ship it as written.** It has three defects that matter in production, and every one of them is a defect a user will hit on their first day:

1. **It transpiles unconditionally.** Every statement, including valid Exasol SQL, goes through a full parse/regenerate cycle. That is both slow and risky: round-tripping already-valid SQL through a foreign dialect can change quoting and escaping.
2. **It raises on unparseable input.** An uncaught exception makes the user's statement fail, so any statement `sqlglot` cannot parse — including perfectly good Exasol SQL with syntax `sqlglot`'s T-SQL reader rejects — becomes an error.
3. **`transpile` returns a list.** An empty list means no statement was produced, and `translated[0]` raises `IndexError`.

The production shape fixes all three — a marker gate, an explicit fail-closed return, and an empty-result guard:

```sql
--/
CREATE PYTHON3 PREPROCESSOR SCRIPT MY_SCHEMA.DIALECT_PREPROCESSOR_V1 AS
import re
import sqlglot

# Statements opt in with a leading marker comment:
#     --!dialect:tsql
#     SELECT TOP 5 col FROM t
# Anything without the marker is returned byte-for-byte and never parsed.
MARKER = re.compile(r"^\s*--!dialect:(\S+)[^\n]*\n?")


def adapter_call(sql_statement):
    match = MARKER.match(sql_statement)
    if match is None:
        return sql_statement                      # untouched, and cheap

    dialect = match.group(1)
    body = sql_statement[match.end():]

    try:
        translated = sqlglot.transpile(body, read=dialect, write="exasol")
    except Exception:
        return sql_statement                      # fail closed: original runs
    if not translated:
        return sql_statement

    return translated[0]
/
```

Why the marker rather than always-transpiling: an unmarked statement costs one regex match, and already-valid Exasol SQL is never put at risk of cross-dialect quote mangling. The trade-off — users must annotate — is worth it, and it is the choice the Exasol Labs demo modules landed on after measuring always-transpile at roughly 133 ms per statement.

Why fail closed rather than propagating: a failed translation that returns the original text produces a normal, comprehensible Exasol syntax error. A propagated exception produces a preprocessor error on *every* statement the transpiler chokes on, including ones the user never meant to translate.

Usage:

```sql
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = MY_SCHEMA.DIALECT_PREPROCESSOR_V1;

--!dialect:tsql
SELECT TOP 5 * FROM example_users ORDER BY name;      -- becomes ... LIMIT 5

SELECT 1;                                             -- untouched

ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = NULL;
```

`SELECT TOP n` is the demo worth showing: it is a hard Exasol syntax error and transpiles cleanly to `LIMIT n`.

### Non-Standard Python Dependencies

`sqlglot` ships in Exasol's default Python 3 UDF container, so the example above needs no extra work. Anything not in the default container requires a custom Script Language Container built with `exaslct` and activated on the cluster — route to **exasol-udfs** for that, and weigh it carefully: an SLC in the preprocessor slot means every statement in the system depends on that container.

## Java

The callback is `String adapterCall(final ExaMetadata metadata, final String sqlStatement)`.

```sql
--/
CREATE JAVA PREPROCESSOR SCRIPT MY_SCHEMA.JAVA_PREPROCESSOR_V1 AS
class JAVA_PREPROCESSOR {
    public static String adapterCall(final ExaMetadata metadata, final String sqlStatement)
            throws Exception {
        // Return sqlStatement unchanged for anything this preprocessor does not own.
        return sqlStatement;
    }
}
/
```

Java gets `ExaMetadata`, which Python 3 and Lua do not — useful when the transform needs the current user or session context without a `query()` round-trip. Otherwise the same rules apply: catch your own exceptions and return the original text, return exactly one statement, and gate expensive work behind a cheap test on the incoming string.

For a Java preprocessor that needs external JARs, the deployment story is BucketFS plus `%jar` directives, exactly as for a Java UDF — route to **exasol-udfs**, and to **exasol-bucketfs** for the upload.

## The Alternative Worth Offering: Lua Wrapper Plus Companion UDF

Before committing the slot to a container language, consider keeping Lua in the slot and calling a Python UDF only for the statements that need it. This gets `sqlglot` without making every statement pay for a container:

```sql
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT MY_SCHEMA.TRANSPILE_V1
    (dialect VARCHAR(64), txt VARCHAR(2000)) RETURNS VARCHAR(2000) AS
import sqlglot
def run(ctx):
    # Never raises: a sentinel is the contract with the calling Lua module.
    try:
        result = sqlglot.transpile(ctx.txt, read=ctx.dialect, write='exasol')
        return result[0] if result else ctx.txt
    except Exception as e:
        return 'ERR:' + str(e)
/

--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.DIALECT_LOGIC_V1 () AS

function preprocess(sqltext)
    local dialect = string.match(sqltext, "^%s*%-%-!dialect:(%S+)")
    if dialect == nil then
        return sqltext                       -- no marker: the UDF is never called
    end

    local stripped = string.gsub(sqltext, "^%s*%-%-!dialect:%S+[^\n]*\n?", "")

    local ok, result = pquery("SELECT MY_SCHEMA.TRANSPILE_V1(:d, :t)",
                              { d = dialect, t = stripped })
    if not ok or result == nil or result[1] == nil or result[1][1] == null then
        return sqltext                       -- fail closed
    end

    local transpiled = tostring(result[1][1])
    if string.sub(transpiled, 1, 4) == "ERR:" then
        return sqltext                       -- fail closed
    end
    return transpiled
end
/
```

Two contract details to point out when showing this:

- The UDF **never raises**; it returns an `ERR:` sentinel. That sentinel is the load-bearing part of the contract — the Lua side checks the exact prefix and falls back to the original text. Without it, a transpile failure inside the UDF fails the user's statement.
- `pquery`'s `ok` flag is ordinary control flow here, not error suppression. Reading it does not violate the "no defensive `pcall`" rule.

Deploy the Lua side behind the wrapper from `lua-authoring-guide.md`. The `pquery` cost is paid only by marked statements, which is the entire advantage over putting Python in the slot.

## Choosing

| Need | Choose |
|---|---|
| String or token transform, any Exasol version | Lua in the slot |
| `sqlglot` transpilation, marked statements only, minimum overhead for everyone else | Lua in the slot + Python 3 companion UDF |
| `sqlglot` transpilation and you accept container cost on every statement, 2025.1.5+ | `CREATE PYTHON3 PREPROCESSOR SCRIPT` |
| You need `ExaMetadata` in the transform, or an existing Java rewriting library, 2025.1.5+ | `CREATE JAVA PREPROCESSOR SCRIPT` |
| Several of these at once, or per-role scoping | The framework — see `preprocessor-framework.md` |
