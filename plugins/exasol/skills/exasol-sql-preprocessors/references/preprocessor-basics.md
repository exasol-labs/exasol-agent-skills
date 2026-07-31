# SQL Preprocessor Basics

Authoritative source: [SQL Preprocessor](https://docs.exasol.com/db/latest/database_concepts/sql_preprocessor.htm). Check it for the version you are targeting before giving version-specific answers; the Python 3 and Java entry points in particular are recent.

## What It Is

Before Exasol hands a statement to the SQL compiler, it can hand the statement's **text** to a script you wrote. That script returns text. The compiler then compiles whatever came back.

```
Client ──▶ statement text ──▶ preprocessor script ──▶ returned text ──▶ SQL compiler ──▶ execution
```

Consequences worth stating plainly to a user:

- It is **string in, string out**. There is no AST, no bind-variable awareness, no result-set hook. `sqlparsing` gives you a tokenizer, not a parser.
- It runs **on every statement** in scope, so its cost is paid by every query in the system.
- It can make Exasol accept syntax it does not have (`SHOW TOP TABLES`, `SELECT TOP 5`, `expr::type`), and it can rewrite valid SQL into different valid SQL.
- It cannot see or change results, cannot read remote systems, and cannot run more than one statement in place of the one it was given.

## The One Slot

`SQL_PREPROCESSOR_SCRIPT` is a single-valued session/system parameter naming one script. There is no list, no chain, no priority. Whoever is in the slot owns preprocessing for that scope.

Before deploying anything, check whether the slot is already taken:

```sql
-- What is set for the current session
SELECT * FROM EXA_PARAMETERS WHERE PARAMETER_NAME = 'SQL_PREPROCESSOR_SCRIPT';
```

If the slot is occupied by a script you do not own, do not overwrite it. Either merge your transformation into the incumbent script or use a dispatcher — see `preprocessor-framework.md`.

## Activating and Deactivating

Session scope — the only correct place to start:

```sql
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = MY_SCHEMA.MY_PREPROCESSOR_V1;
```

System scope — every session, including sessions already open:

```sql
ALTER SYSTEM SET SQL_PREPROCESSOR_SCRIPT = MY_SCHEMA.MY_PREPROCESSOR_V1;
```

Deactivating:

```sql
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = NULL;   -- this session only
ALTER SYSTEM  SET SQL_PREPROCESSOR_SCRIPT = NULL;   -- system-wide
```

**The escape hatch is guaranteed.** The documentation states that you can deactivate preprocessing with `ALTER SESSION` / `ALTER SYSTEM` "since these statements are deliberately excluded from the preprocessing". A broken active script therefore cannot lock you out of turning it off. This is the single most reassuring fact to give a user hesitant to try one, and the reason a system-wide mistake is recoverable rather than fatal.

Do not extend that guarantee further than it goes. It covers the deactivation path; it is not a licence to assume nothing else your script sees needs guarding. In particular, treat statements you issue **from inside** the preprocessor (via `query()` / `pquery()`) as potentially preprocessed themselves, and guard against re-entry — see the control-statement guard in `lua-authoring-guide.md`.

Two practical notes:

- A session that is already open keeps its own session-level setting; `ALTER SYSTEM` affects sessions that have not overridden it. When rolling back a bad system-wide script, tell affected users to also clear it for their own session (or reconnect) if they had set it explicitly.
- Some tooling uses the empty string (`= ''`) instead of `NULL` to clear the slot. `NULL` is the documented form; prefer it.

## Statements That Are Never Preprocessed

For data-security reasons, statements that can carry passwords are excluded:

- `CREATE USER`, `ALTER USER`
- `CREATE CONNECTION`, `ALTER CONNECTION`
- `IMPORT` and `EXPORT` when an `IDENTIFIED BY` clause is present

Plus the `ALTER SESSION` / `ALTER SYSTEM` deactivation path, as above.

Design implication: a preprocessor can never be a complete policy enforcement point. Any statement in that list bypasses it entirely. If a user is reaching for a preprocessor to enforce security, say this explicitly and route them to roles, privileges, and views.

## Which Languages

| Language | DDL | Availability |
|---|---|---|
| Lua | `CREATE LUA SCRIPT` (a scripting program) or `CREATE LUA PREPROCESSOR SCRIPT` | All supported versions |
| Python 3 | `CREATE PYTHON3 PREPROCESSOR SCRIPT` | Exasol **2025.1.5+** |
| Java | `CREATE JAVA PREPROCESSOR SCRIPT` | Exasol **2025.1.5+** |

Lua is the default choice: it is available everywhere, has the `sqlparsing` helper library, and starts up with no container overhead on every statement. Reach for Python 3 or Java only when you genuinely need a library that Lua does not have — realistically, `sqlglot` for dialect transpilation. See `python-java-preprocessors.md`.

Privileges are *the same as for Lua scripting programs*: the calling user needs `EXECUTE` on the script (grant on the schema in practice), and the script's own body runs with the invoker's privileges — there are no definer-rights Lua scripts in Exasol. Design around that: a preprocessor cannot read a table an ordinary user cannot read. The usual bridge is a definer-rights **view** the script selects from.

## The Lua Skeleton

A Lua preprocessor is an ordinary Lua script in a schema. Inside it — and only inside the script that occupies the slot — two extra functions exist:

```sql
--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.MY_PREPROCESSOR_V1 () AS
    local sqltext = sqlparsing.getsqltext()
    -- transform sqltext here
    sqlparsing.setsqltext(sqltext)
/
```

- `--/` on its own line and `/` on its own line are the EXAplus block-marker delimiters. They are required because the Lua body contains semicolons. Every SQL client that runs script DDL needs them (or its own equivalent).
- If you never call `setsqltext`, the original statement is compiled unchanged. That is the correct behaviour for a statement your preprocessor does not handle — do not call `setsqltext` with a "reconstructed" version of text you did not change.
- `getsqltext` / `setsqltext` are available **only in the main preprocessor script**, not in scripts it imports. This is why the standard shape is a thin wrapper in the slot plus the real logic in an imported helper script:

```sql
--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.MY_PREPROCESSOR_V1 () AS
    import('MY_SCHEMA.MY_LOGIC_V1', 'logic')
    sqlparsing.setsqltext(logic.preprocess(sqlparsing.getsqltext()))
/
```

That split is also what makes the thing testable: `MY_SCHEMA.MY_LOGIC_V1.preprocess(text)` is a pure `string -> string` function you can call from an ordinary `EXECUTE SCRIPT` or a unit test, with no slot involved. **`EXECUTE SCRIPT` cannot be used to call a preprocessor script**, so the wrapper itself is not directly runnable — the helper is. Recommend this shape by default.

Functions loaded by `import()` must be **plain top-level globals** in the imported script. A `local function`, or a function inside a returned table literal, is not visible to the importer.

## The `sqlparsing` Library

Documented alongside the other Lua scripting libraries ([Libraries](https://docs.exasol.com/db/latest/database_concepts/scripting/libraries.htm)). It is a **tokenizer plus predicates plus a token-sequence search**. It is not a parser and will not tell you whether a statement is valid.

| Function | Returns |
|---|---|
| `sqlparsing.getsqltext()` | The current statement text. Main preprocessor script only. |
| `sqlparsing.setsqltext(string)` | Sets the text passed to the compiler. Main preprocessor script only. |
| `sqlparsing.tokenize(sqlstring)` | Array of token strings. **Concatenating all tokens reproduces the input exactly** — whitespace and comments are tokens too. |
| `sqlparsing.normalize(tokenstring)` | Normalized form of a token, collapsing representations that differ only in case for identifiers. |
| `sqlparsing.iswhitespace(t)` | Token is whitespace. |
| `sqlparsing.iscomment(t)` | Token is a comment. |
| `sqlparsing.iswhitespaceorcomment(t)` | Either of the above. The usual `ignoreFunction` argument to `find`. |
| `sqlparsing.isidentifier(t)` | Token is an identifier. |
| `sqlparsing.iskeyword(t)` | Token is a SQL keyword (`SELECT`, `FROM`, `TABLE`, …). |
| `sqlparsing.isstringliteral(t)` | Token is a string literal. |
| `sqlparsing.isnumericliteral(t)` | Token is a numeric literal. |
| `sqlparsing.isany(t)` | Always true. Use as a wildcard match. |

### `find`

```lua
sqlparsing.find(tokenlist, startTokenNr, searchForward, searchSameLevel,
                ignoreFunction, match1 [, match2, ... matchN])
```

Searches `tokenlist` from `startTokenNr` for a **directly successive** sequence of tokens matching `match1 … matchN`, skipping any token for which `ignoreFunction` returns true. Only the first occurrence is returned. Returns an array of the matched tokens' positions (one entry per `match`), or `nil`.

- `searchForward` — `true` to scan forward, `false` to scan backward.
- `searchSameLevel` — `true` to stay within the current parenthesis nesting level. This is what lets you find the `)` that closes *your* `(` rather than an inner one.
- Each `match` is either a literal token string (matched against the normalized token, so case-insensitive for keywords) or one of the predicate functions above.

Because tokens include whitespace and comments, `table.concat(tokens, '', from, to)` reassembles a source range **verbatim**, which is how you copy the parts you are not changing. That property is the whole reason to use the tokenizer instead of pattern matching.

A known behavioural wrinkle: backward search has historically not matched at the very end of the token list. If a backward `find` from the last token returns `nil` unexpectedly, that is the cause — search from `#tokens - 1` or check the [Exasol changelog entry](https://exasol.my.site.com/s/article/Changelog-content-8071) for your version.

### Worked example: `IF(a, b, c)` to `CASE`

Adapted from the official documentation. It is the canonical demonstration of the tokenize/find/concat idiom — note that every unchanged byte is carried across by `table.concat`, and that the loop re-tokenizes after each rewrite so nested `IF`s resolve:

```lua
function processIf(sqltext)
    while true do
        local tokens = sqlparsing.tokenize(sqltext)
        local ifStart = sqlparsing.find(tokens, 1, true, false,
                                        sqlparsing.iswhitespaceorcomment, 'IF', '(')
        if ifStart == nil then break end

        local ifEnd = sqlparsing.find(tokens, ifStart[2], true, true,
                                      sqlparsing.iswhitespaceorcomment, ')')
        if ifEnd == nil then error("if statement not ended properly") end

        local comma1 = sqlparsing.find(tokens, ifStart[2] + 1, true, true,
                                       sqlparsing.iswhitespaceorcomment, ',')
        if comma1 == nil then error("invalid if function") end

        local comma2 = sqlparsing.find(tokens, comma1[1] + 1, true, true,
                                       sqlparsing.iswhitespaceorcomment, ',')
        if comma2 == nil then error("invalid if function") end

        local p1 = table.concat(tokens, '', ifStart[2] + 1, comma1[1] - 1)
        local p2 = table.concat(tokens, '', comma1[1] + 1, comma2[1] - 1)
        local p3 = table.concat(tokens, '', comma2[1] + 1, ifEnd[1] - 1)

        local caseStmt = 'CASE WHEN (' .. p1 .. ') != 0 THEN (' .. p2 .. ') ELSE (' .. p3 .. ') END '

        sqltext = table.concat(tokens, '', 1, ifStart[1] - 1)
                  .. caseStmt
                  .. table.concat(tokens, '', ifEnd[1] + 1)
    end
    return sqltext
end
```

Two things to point out when showing this to a user: `searchSameLevel = true` on the `)` and `,` searches is what makes it survive nested function calls, and the `while true` loop terminates because each pass removes one `IF(` from the text.

## Auditing What Happened

When auditing is on, `EXA_DBA_AUDIT_SQL` records **two** entries per preprocessed statement: one for the preprocessor script's execution, carrying the original text in a comment, and one for the transformed statement that actually ran. That pair is the ground truth for "what did the user type and what did the database run", and it is the first place to look when a result is surprising.

```sql
SELECT SESSION_ID, STMT_ID, START_TIME, SQL_TEXT
FROM   EXA_DBA_AUDIT_SQL
WHERE  SESSION_ID = CURRENT_SESSION
ORDER  BY STMT_ID DESC
LIMIT  20;
```

## Cost

The transformation runs inline, before compilation, on every statement in scope. Budget for it:

- Pure string/token work on a normal statement is sub-millisecond and effectively free.
- A `query()` or `pquery()` inside the transformation adds a full round-trip **to every statement in the system**. The documentation is explicit that these "should only be used in exceptional cases if you activate preprocessing globally, since all SQL queries will be decelerated". Treat one as a design smell and look for a way to hoist it (a cached constant, a definer-rights view read once, or a marker-triggered path that only pays the cost when the marker is present).
- Calling a UDF from the transformation costs a container start plus the call. Gate it behind a cheap text test so unmarked statements never reach it — the pattern in `python-java-preprocessors.md`.

Add a cheap **fast-path guard** as the first line of any transformation: a plain `string.find(sqltext, "<the marker or operator I need>", 1, true)` that returns the input immediately when the statement obviously cannot match. Most statements in a real workload take that exit.

## Where To Go Next

- Writing the transformation in Lua, with complete deployable examples: `lua-authoring-guide.md`
- Python 3 / Java preprocessors and dialect transpilation: `python-java-preprocessors.md`
- More than one preprocessor, or per-role/user/client scoping: `preprocessor-framework.md`
- Rollout, rollback, versioning, and debugging: `operations-and-troubleshooting.md`
