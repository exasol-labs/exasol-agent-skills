# The Exasol Labs Preprocessor Framework

An **optional** Exasol Labs project that occupies the single `SQL_PREPROCESSOR_SCRIPT` slot and multiplexes it, so many independent preprocessors can coexist and be scoped per role, user, or client application.

It is not a prerequisite for writing a preprocessor. The transformation function is the same either way — `fn(text) -> nil | string`. The framework changes only how that function is *dispatched, scoped, and distributed*.

**Repositories:** the framework is [`exasol-labs/preprocessor-framework`](https://github.com/exasol-labs/preprocessor-framework); the module catalog is [`exasol-labs/preprocessor-library`](https://github.com/exasol-labs/preprocessor-library).

Check the framework repository itself for anything version-specific before answering:

- [`README.md`](https://github.com/exasol-labs/preprocessor-framework#readme) — quick start, "bring your own preprocessor", and the current release
- [`docs/how-it-works.md`](https://github.com/exasol-labs/preprocessor-framework/blob/main/docs/how-it-works.md) — pipeline architecture, phase and dispatch semantics, the fail-open contract, session self-optimization
- [`docs/operations.md`](https://github.com/exasol-labs/preprocessor-framework/blob/main/docs/operations.md) — install, activate, rules, refresh, status, modes, module management, troubleshooting
- [`docs/module-authoring.md`](https://github.com/exasol-labs/preprocessor-framework/blob/main/docs/module-authoring.md) — the authoritative module contract: the `fn(text) -> nil|string` signature per phase, the `module.toml` schema, the `_V<N>` versioning discipline
- [`docs/air-gap-runbook.md`](https://github.com/exasol-labs/preprocessor-framework/blob/main/docs/air-gap-runbook.md) — the whole no-egress deploy-and-install procedure as one ordered page
- [`demo/`](https://github.com/exasol-labs/preprocessor-framework/tree/main/demo) — a guided, runnable demo suite; point users here to see it work before reading about it
- [`examples/`](https://github.com/exasol-labs/preprocessor-framework/tree/main/examples) — single-file example preprocessors to copy from, one per phase

Confirm the current release before quoting version numbers; the details below were accurate for the 0.x line verified against Exasol 2026.1. If the repository is unreachable for the user, say so rather than guessing at its contents.

## When To Recommend It

| Situation | Recommend |
|---|---|
| One transform, one cluster, slot is free | **No framework.** One script, one `ALTER`. |
| Slot already occupied by something you do not own | **Framework**, or merge into the incumbent — never silently take the slot. |
| Two or more independent transforms | **Framework.** Hand-merging independent transforms into one monolith is where preprocessor projects rot. |
| Must apply to some roles/users/clients only | **Framework.** Otherwise you are writing and securing a per-statement identity lookup yourself. |
| Want to install a ready-made transform, or publish yours | **Framework** + the library. |
| Air-gapped cluster, one transform, minimal moving parts | **No framework.** |

Adding the framework for a single transform on a cluster where the slot is free is over-engineering. Say so.

## What It Does

```
Statement ─▶ PREPROC_RT.MASTER ─▶ TRANSLATE ─▶ EXPAND ─▶ REWRITE ─▶ Engine
                   │
                   └─ resolves this user's rules from a config table
```

`PREPROC_RT.MASTER` sits in the slot. For each statement it looks up the calling user's resolved rule chain and runs their transformation functions in a fixed three-phase order. You add and remove transformations by editing rows in a config table and refreshing — never by rewriting the global script.

Two schemas, because Exasol Lua scripts run with **invoker** rights (there are no definer-rights Lua scripts):

- `PREPROC` — admin schema, owned by the `PREPROC_ADMIN` role, not readable by PUBLIC. Config, resolution, settings, module provenance, admin scripts.
- `PREPROC_RT` — runtime schema, EXECUTE and SELECT granted to PUBLIC. `MASTER`, the deployed module scripts, and the definer-rights views that are the only bridge across the boundary.

## The Three Phases

These are framework concepts, not Exasol concepts. They correspond to the three kinds of transformation in `lua-authoring-guide.md`, and they differ in **dispatch semantics**, which changes what your function must return.

| Phase | Input is | Dispatch | `nil` means | Safety posture |
|---|---|---|---|---|
| `TRANSLATE` | foreign-dialect SQL | **run-all**, threading text forward through every matching rule | not applicable — **always return a string** | Module must **fail closed**: return the original text on any failure, so wrong-dialect or partial text never reaches the engine looking like a successful translation. |
| `EXPAND` | a custom command, not valid Exasol SQL | **first-match-terminal** — the first non-`nil` return ends the phase | "not my command, keep scanning" | Inherently safe: an unclaimed command reaches the engine and produces a loud syntax error. |
| `REWRITE` | valid Exasol SQL | **run-all** | not applicable — **always return a string** | The dangerous one. A skipped `REWRITE` silently runs the original statement, which for a policy rule is a bypass. Design with that in mind. |

Within a phase, rules run in ascending rule id. `REWRITE` always runs on whatever `EXPAND` produced.

## The Module Contract

The whole contract is one Lua function in a versioned Lua script:

```lua
function my_guard(sqltext)
    if string.find(string.upper(sqltext), "^%s*DROP%s+TABLE") then
        return "SELECT 'blocked by my_guard' AS refused"
    end
    return nil          -- not my statement: keep scanning
end
```

Deploy it and register it — two statements, no toolchain, no manifest:

```sql
--/
CREATE OR REPLACE LUA SCRIPT PREPROC_RT.MY_GUARD_V1 AS
function my_guard(sqltext)
    ...
end
/

PREPROC ADD RULE FOR ROLE DBA PHASE EXPAND
    SCRIPT PREPROC_RT.MY_GUARD_V1 FUNCTION my_guard;
```

That is the complete loop: **write a function, deploy it, add a rule.** Everything else in the ecosystem — manifests, checksums, the registry — exists to *distribute* preprocessors, not to run them.

### The Rules Modules Must Follow

- **Plain top-level global function.** `import()` reads globals; a `local function`, or a function inside a returned table, is invisible to the dispatcher and the rule silently does nothing.
- **`fn(sqltext)` takes the text as its argument.** Do **not** call `sqlparsing.getsqltext()` inside a module — those functions exist only in the script that occupies the slot, which is `MASTER`, not you.
- **No defensive `pcall`.** The dispatcher wraps every module call. A second `pcall` inside your module converts a visible fault into a silent wrong answer. This is the exact opposite of the rule for a standalone preprocessor, where *you* own the slot and therefore own the error boundary.
- **`string.gsub` returns two values.** Never `return` or forward a `gsub` call directly.
- **Exactly one statement out.** Nothing splits on semicolons.
- **Never `CREATE OR REPLACE` a live module.** Ship `_V<N+1>` beside `_V<N>`, repoint the rule, refresh, retire the old version once no rule and no live session references it. The `_V<N>` suffix in the name is what makes that discipline mechanical.

## Rules, Scoping, and Refresh

A rule binds a phase, a script, and a function to a **scope**: a `ROLE` or a `USER`, optionally narrowed by a `CLIENT` pattern.

```sql
PREPROC ADD RULE FOR ROLE ANALYSTS PHASE EXPAND
    SCRIPT PREPROC_RT.MY_MODULE_V1 FUNCTION expand;

PREPROC ADD RULE FOR USER BOB PHASE TRANSLATE
    SCRIPT PREPROC_RT.MY_XLATE_V1 FUNCTION translate;

PREPROC ADD RULE FOR ROLE ANALYSTS PHASE EXPAND
    SCRIPT PREPROC_RT.MY_MODULE_V1 FUNCTION expand
    CLIENT 'DbVisualizer';         -- scoping, NOT security

PREPROC LIST RULES;
PREPROC DISABLE RULE 3;            -- keep the row, stop applying it
PREPROC ENABLE RULE 3;
PREPROC DROP RULE 3;
```

Facts that account for most "it isn't working" reports:

- A `ROLE`-scoped rule reaches a user only if that user **holds** the role. Role grants resolve transitively through nested roles; `PUBLIC` applies to everyone.
- **Refresh is required** after changing rules *and* after role grants change, because resolution is built from config plus the live grant graph. The `PREPROC …` sugar auto-refreshes on each change; schedule `EXECUTE SCRIPT PREPROC.REFRESH` to track ongoing role changes.
- `CLIENT` matches the connecting application name as a **literal substring**, not a pattern. It is scoping, not a security control — a client can report any name.
- The `FUNCTION <name>` value is a case-sensitive Lua symbol, unlike the identifiers around it. Write it exactly as declared.
- No trailing `-- comment` on a `PREPROC …` line: most clients send the comment as part of the statement, and the command module strips only *leading* comment lines, so `PREPROC STATUS; -- check` fails with a puzzling syntax error. Ordinary SQL is unaffected.

### The One Query Worth Remembering

Any user, no admin rights needed:

```sql
SELECT * FROM PREPROC_RT.MY_PIPELINE;
```

Each row is one transformation that will run on this user's statements, in order. **No rows means nothing applies to you** — the expected answer for most users, and the first thing to check when a module "isn't working". The usual cause is not holding the role the rule is scoped to.

## Installing, Activating, Verifying

```sql
-- 1. Deploy the control plane (DBA, clean install; creates roles, schemas,
--    tables, MASTER, and the admin surface, but activates nothing).
--    Run release.sql from the framework's latest GitHub Release:
--    https://github.com/exasol-labs/preprocessor-framework/releases/latest/download/release.sql

-- 2. Activate. Session scope first, always.
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = PREPROC_RT.MASTER;
-- then, once proven:
ALTER SYSTEM  SET SQL_PREPROCESSOR_SCRIPT = PREPROC_RT.MASTER;

-- 3. Verify (DBA or PREPROC_ADMIN)
EXECUTE SCRIPT PREPROC.STATUS;       -- current / stale / never-refreshed
EXECUTE SCRIPT PREPROC.RULE_LIST;

-- Rollback
ALTER SYSTEM SET SQL_PREPROCESSOR_SCRIPT = NULL;
```

Deployment notes to pass on:

- `release.sql` is **clean-install only** — it re-creates its tables. Do not run it to "update" an existing installation.
- **Turn off named-parameter substitution in GUI SQL clients before running it.** DbVisualizer, DBeaver, and other JDBC tools treat `:name` as a bind placeholder, and the file is full of Lua and Python bodies containing literal colons (`'bucketfs:'`, `if …:`, `def …:`). With substitution on, the deployed scripts are silently corrupted and you get later errors like `object <NAME> not found` or `SyntaxError: expected ':'`. EXAplus needs no change.
- `SYS` cannot be granted `PREPROC_ADMIN`, so the installer also seeds the command surface for `DBA`, which `SYS` holds.
- Once the preprocessor is active, the shorter `PREPROC STATUS;` / `PREPROC LIST RULES;` sugar works in place of `EXECUTE SCRIPT`. Before activation, use the `EXECUTE SCRIPT` forms — the sugar is itself implemented as a preprocessor module.

## Installing Ready-Made Modules

The catalog is [`exasol-labs/preprocessor-library`](https://github.com/exasol-labs/preprocessor-library) — currently `cast_shorthand` (`expr::type` → `CAST(expr AS type)`) and `trailing_comma` (`SELECT a, b, FROM t` just works). Both are worth reading as reference implementations of a region-aware scanner even if you never install them.

```sql
PREPROC CATALOG MODULES;                                   -- browse
PREPROC INSTALL MODULE cast_shorthand FOR ROLE ANALYSTS;   -- deploy + register
```

With no `FROM`, the source defaults to the library's index at its mutable `latest` tag over HTTPS. Pin for reproducibility, or stage in BucketFS for a cluster with no egress:

```sql
PREPROC INSTALL MODULE cast_shorthand
  FROM 'https://raw.githubusercontent.com/exasol-labs/preprocessor-library/v0.3.1/registry/index.json'
  FOR ROLE ANALYSTS;

PREPROC INSTALL MODULE cast_shorthand
  FROM 'bucketfs:bfsdefault/<bucket>/preproc-lib-<ver>.tar.gz'
  FOR ROLE ANALYSTS;
```

Review before installing, audit after:

```sql
PREPROC CATALOG MODULES;                    -- name, version, phase, object inventory, installed?
SELECT NAME, VERSION, LIBRARY_VERSION, SOURCE_URL, SHA256, OBJECTS
FROM   PREPROC_RT.INSTALLED_MODULES WHERE STATUS = 'deployed';
```

An install is DDL executed under `PREPROC_ADMIN`, and a module may create more than one object in any schema the installing admin can write — so the object inventory is declared up front and the install is refused if the artifact disagrees with it in either direction, the same discipline applied to the `sha256`.

Caveat worth stating: **`min_framework` is advisory and nothing enforces it.** A module declaring a framework version newer than yours installs cleanly and reports `installed`; it fails later, at use. Check it yourself.

Turning a module off is a rule operation, not a script operation:

```sql
PREPROC LIST RULES;
PREPROC DISABLE RULE <id>;    -- reversible
PREPROC DROP RULE <id>;       -- removes the activation
```

Both leave the script deployed on purpose, so an in-flight session is never stranded. Physically reclaiming the script is a separate later step.

## Packaging Your Own Module

You never have to package anything. Escalate only when you need the next capability:

| You want | You add |
|---|---|
| A transform running on your own cluster | nothing — the two statements above |
| The same transform installable by name on many clusters | a `module.toml` manifest, served from a registry index |
| More than one object (a UDF, a table, a schema) as one unit | an `[[objects]]` inventory in the manifest |
| Others to install it from the public catalog | a PR to `preprocessor-library` |

A `module.toml` declares `name` (snake_case, identifier-safe — no hyphens, so it works unquoted in `PREPROC INSTALL MODULE <name>`), `description`, `phase`, `script_name` (fully qualified, ending `_V<N>`), `function`, `version` (equal to `<N>`), `min_framework`, `suggested_scope`, `deploy_mode`, and either `sha256` (for `library-deployed`) or a `[source]` repo/ref (for `self-deployed`).

The artifact is one `.sql` file carrying one or more statements. Statements are separated with the EXAplus block-marker convention: a statement whose body contains semicolons goes between a line that is exactly `--/` and a line that is exactly `/`; anything else ends with `;`. Every object the artifact creates carries the `_V<N>` suffix, companions included — that is what lets a v1 and a v2 generation coexist without collision.

**A registry is just a `registry/index.json` plus the artifacts it points at.** Hosting your own internal catalog — private modules, your own versioning and review — is a first-class path, not a workaround:

```sql
PREPROC CATALOG MODULES FROM 'https://git.internal/preproc-modules/raw/v2/registry/index.json';
PREPROC INSTALL MODULE my_guard
  FROM 'https://git.internal/preproc-modules/raw/v2/registry/index.json' FOR ROLE DBA;
```

The public library is simply the default when you omit `FROM`. Publishing there is for *reach*; the mechanism does not require it. The contribution workflow — copy `modules/_template/`, write the artifact and manifest, regenerate the index, validate, add a README and tests, open a PR — is in the library's [CONTRIBUTING.md](https://github.com/exasol-labs/preprocessor-library/blob/main/CONTRIBUTING.md).

## Performance Posture

```sql
PREPROC SET MODE convenience;    -- default
PREPROC SET MODE strict;
```

The per-statement rule lookup costs a few milliseconds. In **convenience** mode a session pays it only on its first statement, then self-optimizes: a session with no resolved rules clears its own preprocessor, and a session with rules repoints itself to a generated profile script with its chain baked in and no lookup. In **strict** mode nothing self-optimizes and every statement pays the full lookup — the deliberate trade for a posture that never lets a session repoint itself.

This matters when advising: in convenience mode, the overwhelming majority of users — those with no rules — end up paying nothing at all after their first statement.

## Framework-Specific Failure Modes

Beyond the generic ones in `operations-and-troubleshooting.md`:

| Symptom | Cause |
|---|---|
| `MY_PIPELINE` is empty for a user | No rule resolves to them. Usually they do not hold the scope role, or a refresh has not run since the rule or grant changed. |
| A module is deployed but never fires | Rule points at the wrong script or function name (`FUNCTION` is case-sensitive), the rule is disabled, or a `CLIENT` pattern does not match the connecting tool. |
| A module throws but the statement still runs | Expected fail-open. The dispatcher caught it, skipped the rule, and continued. Investigate the module directly; do not add a `pcall` to it. |
| Custom command gives a plain syntax error | `EXPAND` is fail-open: nothing claimed the statement, so it reached the engine verbatim. Not a framework bug — the module is missing, misnamed, or out of scope. |
| **Every admin command fails with `attempt to call a nil value (field 'rebuild')`** | An enabled rule points at a script that **no longer exists**. A module that *throws* fails open; a module that is *missing* breaks the `import` the admin scripts themselves rely on. Recover by clearing the preprocessor for your own session first, dropping the dangling rule, then re-activating. **Always drop the rule before dropping the script** and you will never see this. |
| Resolution looks stale after a role grant | Run `PREPROC STATUS`, then `PREPROC REFRESH`. Consider scheduling the refresh. |
