# Writing Lua Preprocessors Well

Read `preprocessor-basics.md` first for the slot, the activation syntax, and the `sqlparsing` API. This file is about the transformation itself: how to structure it, the traps that account for most first-attempt bugs, and complete deployable examples.

## Decide What Kind of Transformation It Is

Three kinds turn up in practice. They have **different safety postures**, and picking the wrong posture is the most consequential design mistake in a preprocessor.

| Kind | Input is | On no match | On internal failure |
|---|---|---|---|
| **Command expansion** — add syntax Exasol does not have (`SHOW TOP TABLES`, `PING`) | not valid Exasol SQL | return input unchanged; the engine raises a loud syntax error | **fail open** is safe: the unmatched command reaches the engine and fails visibly. It cannot silently corrupt anything. |
| **Dialect translation** — accept another dialect's SQL (`SELECT TOP 5`, `expr::type`) | not valid Exasol SQL | return input unchanged | **fail closed**: return the *original* text. Never emit half-translated SQL. A partial translation can be syntactically valid and semantically wrong, which is the worst outcome available. |
| **Policy rewrite** — change what valid SQL does (inject a predicate, redirect a table, tag a statement) | valid Exasol SQL | return input unchanged | **the dangerous one.** If your rewrite is skipped, the original statement runs — that is a silent policy bypass. Decide up front whether skipping is acceptable; if it is not, let the error propagate so the statement fails instead of running unguarded. |

Name the kind out loud when advising a user. It determines the error handling, and error handling is the part people get wrong.

## Error Handling: Read This Before Writing Any Code

**Without a dispatcher, an uncaught Lua error in the preprocessor surfaces on the user's statement and the statement does not run.** A standalone preprocessor is therefore **fail-closed by default**: a bug in it breaks every statement in scope, not just the ones it meant to transform.

So for a standalone preprocessor, put a `pcall` in the **wrapper** (the script in the slot) and nowhere else:

```sql
--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.MY_PREPROCESSOR_V1 () AS
    -- The slot script is a thin, fail-open wrapper. All logic lives in the
    -- imported helper, which is a pure string -> string function and therefore
    -- unit-testable without ever occupying the slot.
    import('MY_SCHEMA.MY_LOGIC_V1', 'logic')

    local original = sqlparsing.getsqltext()

    -- Control statements pass through untouched: never risk breaking the
    -- statement that turns this preprocessor off.
    if string.match(string.upper(original), "^%s*ALTER%s+SESSION")
       or string.match(string.upper(original), "^%s*ALTER%s+SYSTEM") then
        return
    end

    local ok, result = pcall(logic.preprocess, original)
    if ok and type(result) == "string" and result ~= original then
        sqlparsing.setsqltext(result)
    end
    -- Not ok, not a string, or unchanged: leave the statement alone.
/
```

That wrapper gives you three properties worth stating explicitly to a user:

1. A bug in the logic degrades to "no transformation" instead of "the database is down for this user".
2. `setsqltext` is called **only when the text actually changed**, so unmatched statements are provably untouched.
3. The control-statement guard means the rollback line always works, no matter what.

For a **policy rewrite** where a silent skip is a bypass, invert this: drop the `pcall` (or re-raise after logging) so a failure blocks the statement. Choose deliberately and write down which you chose.

> **If you are writing a module for the preprocessor framework, the rule is the opposite: no `pcall` in your module.** The framework's dispatcher already wraps every module call, and a second `pcall` inside the module converts a visible fault into a silent wrong answer. The `pcall` belongs to whoever owns the slot — exactly once. See `preprocessor-framework.md`.

## The Traps

### 1. `string.gsub` returns two values

This is the single most common authoring bug. `gsub` returns `(result, count)`. Lua forwards both when you return or pass the call directly.

```lua
-- WRONG: returns two values; callers see the match count as a second argument
return sqltext:gsub("^%s+", "")

-- WRONG: setsqltext receives an extra argument
sqlparsing.setsqltext(sqltext:gsub("^%s+", ""))

-- RIGHT: capture the string first
local s = sqltext:gsub("^%s+", "")
return s

-- ALSO RIGHT: discard the count explicitly
local s, _ = sqltext:gsub("^%s+", "")
```

### 2. Never rewrite inside a string literal, quoted identifier, or comment

A naive `gsub` over the whole statement will happily rewrite the inside of `'don''t'` or `-- todo: fix ::`. If your pattern is a punctuation sequence (`::`, `,`, `#`) rather than a distinctive keyword, a whole-text `gsub` **is a correctness bug**, not a shortcut. Use the region-aware scanner below.

### 3. Return exactly one statement

Nothing splits your returned text on semicolons. Two statements concatenated produce a syntax error. If a command genuinely needs several statements, the preprocessor must expand to a single `EXECUTE SCRIPT` call on a Lua script that does the multi-statement work.

### 4. Statements you decline must come back byte-for-byte

Do not normalize whitespace, strip comments, or re-emit "cleaned up" text for statements you are not transforming. Those bytes end up in the audit log and in error messages, and a preprocessor that reformats everything makes every other problem in the system harder to debug. Structure the code so the untransformed path literally `return sqltext`.

### 5. Clients send comments with the statement

SQL clients routinely submit a leading comment block together with the statement. Your matcher sees that raw text. If you are matching a custom command, strip leading whitespace and full-line comments first — and be aware a *trailing* `-- comment` on the same line will also be part of the text, which is why a strict `^COMMAND$` match fails in real clients:

```lua
-- Trim, drop leading full-line comments, drop one trailing semicolon.
local function normalise(text)
    local s = text
    while true do
        s = s:gsub("^%s+", "")
        local without = s:gsub("^%-%-[^\n]*\n?", "", 1)
        if without == s then break end
        s = without
    end
    local trimmed = s:gsub("^%s*(.-)%s*$", "%1")
    local stripped = trimmed:gsub(";%s*$", "")
    return stripped
end
```

### 6. Build strings with `table.concat`, not `..` in a loop

Lua strings are immutable, so appending one character at a time is O(n²). On a long statement that is a visible per-statement cost. Accumulate chunks in a table and `table.concat` once.

### 7. Identifiers are upper-cased, function names are not

Exasol folds unquoted identifiers to upper case, so match keywords case-insensitively (`string.upper` first, or a normalized token compare). But the Lua function name you export is a case-sensitive Lua symbol — write it exactly as declared everywhere it is referenced.

## Tokenizer or Hand-Written Scanner?

| Use | When |
|---|---|
| `sqlparsing.tokenize` + `find` + `table.concat` | You need structure: matching parentheses, argument lists, "the token after `FROM`". `searchSameLevel = true` handles nesting for you, and concatenating token ranges preserves the original bytes exactly. |
| A hand-written single-pass character scanner | You are matching punctuation that also appears inside strings and comments (`::`, trailing `,`), or you need a strictly linear pass over large text. |
| A plain `string.match` / `gsub` on the whole text | Only for a distinctive anchored pattern that cannot occur inside a literal — typically a whole-statement custom command matched with `^`. |

## The Region-Aware Scanner Skeleton

Reuse this shape whenever you must find something in *code* and ignore it inside literals and comments. It is the structure the published `cast_shorthand` and `trailing_comma` modules use, and it handles the `''` and `""` escape forms correctly.

The `<...>` placeholders below are **not valid Lua** — they mark the three spots that are specific to your transform (the fast-path marker, the match test, and the replacement). Fill all three in before deploying.

```lua
-- Walks sqltext once. Single-quoted strings, double-quoted identifiers, line
-- comments and block comments are skipped over so their contents are never
-- inspected. Output is assembled from verbatim slices of the original, so every
-- byte you do not deliberately change survives untouched.
function transform(sqltext)
    -- Fast path: if the thing we rewrite cannot be present, do no work at all.
    -- Most statements in a real workload leave here.
    if not string.find(sqltext, "::", 1, true) then
        return sqltext
    end

    local s, n = sqltext, #sqltext
    local parts, seg_start, i = {}, 1, 1
    local changed = false

    while i <= n do
        local c = s:sub(i, i)

        if c == "'" or c == '"' then
            -- Quoted region; the doubled quote ('' or "") is an escape.
            local q, j = c, i + 1
            while j <= n do
                if s:sub(j, j) == q then
                    if s:sub(j + 1, j + 1) == q then j = j + 2 else j = j + 1; break end
                else
                    j = j + 1
                end
            end
            i = j

        elseif c == '-' and s:sub(i + 1, i + 1) == '-' then
            local j = i + 2
            while j <= n and s:sub(j, j) ~= '\n' do j = j + 1 end
            i = j + 1

        elseif c == '/' and s:sub(i + 1, i + 1) == '*' then
            local j = i + 2
            while j <= n do
                if s:sub(j, j) == '*' and s:sub(j + 1, j + 1) == '/' then j = j + 2; break end
                j = j + 1
            end
            i = j

        else
            -- Code region: this is the only place a rewrite may happen.
            local hit = <your match test at position i>
            if hit then
                parts[#parts + 1] = s:sub(seg_start, i - 1)   -- verbatim prefix
                parts[#parts + 1] = <your replacement text>
                i = <position after the matched text>
                seg_start = i
                changed = true
            else
                i = i + 1
            end
        end
    end

    if not changed then
        return sqltext          -- byte-for-byte, guaranteed
    end
    parts[#parts + 1] = s:sub(seg_start, n)
    return table.concat(parts)
end
```

If the match test cannot determine a safe rewrite — an operand shape you do not support, an unterminated construct — `return sqltext` immediately. Emitting partially-rewritten SQL is never the better option.

## Complete Example 1 — A Custom Command (Command Expansion)

Adds `SHOW TOP TABLES [n]`, which Exasol does not have. Standalone: no framework, two objects, deployable as-is.

```sql
-- =============================================================================
-- SHOW TOP TABLES [n]  ->  the object-size query.
-- Deploy in EXAplus, or any client that understands the --/ ... / block
-- delimiters. In DbVisualizer / DBeaver, TURN OFF named-parameter substitution
-- first, or the client rewrites the ':' characters in the body and silently
-- corrupts the deployed script.
-- =============================================================================

OPEN SCHEMA MY_SCHEMA;

--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.TOP_TABLES_LOGIC_V1 () AS
-- Pure string -> string. Testable without the preprocessor slot.
-- Returns the original text when the statement is not our command.

local function normalise(text)
    local s = text
    while true do
        s = s:gsub("^%s+", "")
        local without = s:gsub("^%-%-[^\n]*\n?", "", 1)
        if without == s then break end
        s = without
    end
    local trimmed = s:gsub("^%s*(.-)%s*$", "%1")
    local stripped = trimmed:gsub(";%s*$", "")
    return stripped
end

-- Must be a plain top-level global: import() only sees globals.
function preprocess(sqltext)
    local n = string.upper(normalise(sqltext)):match("^SHOW%s+TOP%s+TABLES%s*(%d*)$")
    if n == nil then
        return sqltext                      -- not our command; untouched
    end
    if n == "" then n = "10" end
    return "SELECT ROOT_NAME AS SCHEMA_NAME, OBJECT_NAME AS TABLE_NAME,"
        .. " RAW_OBJECT_SIZE AS RAW_BYTES, MEM_OBJECT_SIZE AS MEM_BYTES"
        .. " FROM EXA_ALL_OBJECT_SIZES WHERE OBJECT_TYPE = 'TABLE'"
        .. " ORDER BY RAW_OBJECT_SIZE DESC LIMIT " .. n
end
/

--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.TOP_TABLES_PREPROCESSOR_V1 () AS
    import('MY_SCHEMA.TOP_TABLES_LOGIC_V1', 'logic')
    local original = sqlparsing.getsqltext()
    local upper = string.upper(original)
    if string.match(upper, "^%s*ALTER%s+SESSION") or string.match(upper, "^%s*ALTER%s+SYSTEM") then
        return
    end
    local ok, result = pcall(logic.preprocess, original)
    if ok and type(result) == "string" and result ~= original then
        sqlparsing.setsqltext(result)
    end
/

-- Users who will type the command need EXECUTE on both scripts:
GRANT EXECUTE ON SCHEMA MY_SCHEMA TO <role>;

-- Try it in YOUR session only:
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = MY_SCHEMA.TOP_TABLES_PREPROCESSOR_V1;
SHOW TOP TABLES;
SHOW TOP TABLES 3;
SELECT 1;                                  -- unaffected, and provably untouched

-- Rollback, always in the same breath as the activation:
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = NULL;
```

Note that `EXA_ALL_OBJECT_SIZES` is read with the *invoker's* privileges, so a non-DBA sees only their own objects. That is correct behaviour, not a bug — but say so, because the surprising-empty-result question always follows.

## Complete Example 2 — A Guardrail (Policy Rewrite)

Refuses unqualified `DELETE`/`UPDATE` — statements with no `WHERE` clause — by replacing them with a statement that explains itself. This is a *policy rewrite*, so note the deliberate choices: it matches only fully-formed statements, it explains rather than silently no-ops, and it does not pretend to be a security control.

```sql
--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.REQUIRE_WHERE_LOGIC_V1 () AS

function preprocess(sqltext)
    local tokens = sqlparsing.tokenize(sqltext)

    -- Is this a DELETE FROM ... or UPDATE ... at the start of the statement?
    local kind = nil
    local start = sqlparsing.find(tokens, 1, true, false,
                                  sqlparsing.iswhitespaceorcomment, 'DELETE')
    if start ~= nil and start[1] <= 3 then kind = 'DELETE' end
    if kind == nil then
        start = sqlparsing.find(tokens, 1, true, false,
                                sqlparsing.iswhitespaceorcomment, 'UPDATE')
        if start ~= nil and start[1] <= 3 then kind = 'UPDATE' end
    end
    if kind == nil then
        return sqltext                       -- not our concern
    end

    -- searchSameLevel = false: a WHERE inside a subquery still counts as one
    -- the author wrote deliberately, so we accept it rather than guess.
    local whereTok = sqlparsing.find(tokens, start[1] + 1, true, false,
                                     sqlparsing.iswhitespaceorcomment, 'WHERE')
    if whereTok ~= nil then
        return sqltext                       -- qualified; leave it alone
    end

    -- Refuse, visibly. A single statement, and it names itself so the user can
    -- find out who blocked them.
    return "SELECT 'Blocked by REQUIRE_WHERE_V1: " .. kind
        .. " without a WHERE clause. Add a WHERE clause, or ask a DBA to run it "
        .. "with the preprocessor disabled.' AS REFUSED"
end
/
```

Deploy behind the same wrapper as Example 1, **but drop the `pcall`** — for a guardrail, a skipped rewrite is a bypass, so a failure should block the statement rather than let it through. Point out the honest limits in the same message: it is an ergonomics guardrail, not a security boundary. Anyone can clear the slot for their own session, `TRUNCATE` is untouched, and the excluded-statement list bypasses it entirely. Real protection is roles, privileges, and views.

## Complete Example 3 — Dialect Shorthand (Dialect Translation)

`expr::type` to `CAST(expr AS type)`, the Postgres/Redshift porting aid. The full published implementation is `cast_shorthand` in [`exasol-labs/preprocessor-library`](https://github.com/exasol-labs/preprocessor-library) — read it rather than rewriting it. What matters for authoring is the shape:

1. **Fast path first** — `if not string.find(s, "::", 1, true) then return sqltext end`. Statements with no `::` pay nothing.
2. **Region-aware scan** — the skeleton above. `::` inside `'...'`, `"..."`, `--`, or `/* */` is not a cast.
3. **Backward operand scan** — from the `::`, walk left to identify what is being cast: identifier, dotted identifier, `(...)` group, `f(...)` call, literal, or a previous `CAST(...)`.
4. **Fail closed** — if the operand shape is not one you support, `return sqltext`. A partially rewritten statement is worse than an untranslated one.
5. **Chaining falls out for free** — rewriting left to right means `a::int::text` naturally becomes `CAST(CAST(a AS int) AS text)`, because the first rewrite's output is the second's operand.

For anything more than shorthand — real cross-dialect SQL — do not hand-write a translator. Use `sqlglot` in a Python 3 preprocessor or a companion UDF; see `python-java-preprocessors.md`.

## Testing Without Occupying the Slot

This is why the logic lives in a separate, imported script. `EXECUTE SCRIPT` cannot call a preprocessor script, but it can call the helper:

```sql
--/
CREATE OR REPLACE LUA SCRIPT MY_SCHEMA.TEST_TOP_TABLES () AS
    import('MY_SCHEMA.TOP_TABLES_LOGIC_V1', 'logic')

    local cases = {
        { input = 'SHOW TOP TABLES',      expect_changed = true  },
        { input = 'show top tables 5',    expect_changed = true  },
        { input = '-- a comment\nSHOW TOP TABLES', expect_changed = true },
        { input = 'SELECT 1',             expect_changed = false },
        { input = "SELECT 'SHOW TOP TABLES'", expect_changed = false },  -- literal!
    }

    local failures = {}
    for _, c in ipairs(cases) do
        local out = logic.preprocess(c.input)
        local changed = (out ~= c.input)
        if changed ~= c.expect_changed then
            failures[#failures + 1] = c.input
        end
    end

    if #failures > 0 then
        error('FAILED: ' .. table.concat(failures, ' | '))
    end
    return 'all ' .. #cases .. ' cases passed'
/

EXECUTE SCRIPT MY_SCHEMA.TEST_TOP_TABLES;
```

Cases every preprocessor's test set should contain, whatever it does:

- the statement it targets, in lower case and with odd whitespace
- the target string appearing **inside a string literal** — must be untouched
- the target appearing **inside a comment** — must be untouched
- a leading comment block before a real match — clients send these
- an ordinary `SELECT 1` — must come back byte-identical
- an already-transformed statement — running the transform twice must be a no-op, or you will corrupt text the moment two rules chain
- for a translator: a malformed input in the source dialect — must return the original, not a partial rewrite

## Anti-Patterns

- A whole-text `gsub` for a punctuation pattern. Rewrites the inside of string literals. Use the region-aware scanner.
- `query()` or `pquery()` on the hot path. Every statement in the system pays the round-trip. Hoist it, cache it, or gate it behind a marker.
- `CREATE OR REPLACE` over the script currently in the slot. Deploy `_V2` beside `_V1`, repoint the slot, retire `_V1` once nothing points at it.
- Logic inline in the slot script. Untestable, because `EXECUTE SCRIPT` cannot call a preprocessor script. Split wrapper from logic.
- `local function` as the entry point. `import()` reads globals only; a `local` entry point is invisible and the call fails at dispatch.
- A defensive `pcall` inside a framework module. The dispatcher already has one; a second turns a visible fault into a silent wrong answer.
- Emitting multiple statements. Nothing splits on `;`.
- Rewriting statements the preprocessor does not own — normalizing whitespace, stripping comments, re-quoting identifiers. Untouched means untouched.
- Treating a preprocessor as an access control. The excluded-statement list and per-session `= NULL` both bypass it.
