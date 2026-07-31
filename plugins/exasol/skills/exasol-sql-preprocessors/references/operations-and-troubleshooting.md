# Preprocessor Operations and Troubleshooting

## The Rollout Ladder

Never skip a rung. Each one bounds the blast radius of the next.

1. **Test the logic with no slot involved.** The transformation lives in an importable helper script, so `EXECUTE SCRIPT` can call it directly. Run the case list from `lua-authoring-guide.md` — including string-literal and comment cases — before the slot is touched at all.
2. **Activate in the author's own session.** `ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = MY_SCHEMA.MY_PREPROCESSOR_V1;`. Nobody else is affected. Run the target statements, then run a normal workload's worth of ordinary statements and confirm they still work.
3. **Activate in a second session as a non-privileged user.** This is the rung people skip, and it is where the grant bugs surface: the script runs with the *invoker's* privileges, so a preprocessor that works for a DBA can fail for everyone else. The documentation says this explicitly — test "with a user without special rights".
4. **Activate system-wide, off-hours, with a DBA session already open and the rollback line already typed.**
5. **Watch.** Check `EXA_DBA_AUDIT_SQL` for original-versus-transformed pairs, and check whether statement durations moved.

Give the rollback line in the same message as the activation line, every time:

```sql
ALTER SYSTEM SET SQL_PREPROCESSOR_SCRIPT = NULL;
```

## Emergency: Everything Is Broken

The off switch is deliberately excluded from preprocessing, so it works even when the active script is broken.

```sql
-- Fix your own session first, so you can work at all:
ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT = NULL;

-- Then fix the system:
ALTER SYSTEM SET SQL_PREPROCESSOR_SCRIPT = NULL;
```

Then, in order:

1. Confirm the slot is clear: `SELECT * FROM EXA_PARAMETERS WHERE PARAMETER_NAME = 'SQL_PREPROCESSOR_SCRIPT';`
2. Tell users who set it explicitly for their own session to clear it too, or reconnect. A system-level change does not override a session-level one.
3. Diagnose against the *helper* script with `EXECUTE SCRIPT`, not by re-activating the slot.
4. Fix forward as `_V2`. Do not `CREATE OR REPLACE` the script that just broke production — someone may still be pinned to it.

## Versioning

Treat the script in the slot as a live object with sessions pointing at it.

- Name it with a version suffix from day one: `MY_PREPROCESSOR_V1`.
- To change behaviour, deploy `MY_PREPROCESSOR_V2` **beside** V1, repoint the slot, then drop V1 once nothing references it.
- The first deploy is the only safe time for `CREATE OR REPLACE`, because nothing is bound yet.
- Never drop a script while the slot — or, under the framework, an enabled rule — still names it. Under the framework this specific mistake produces a distinctive failure where every admin command breaks; see `preprocessor-framework.md`.

## Symptom Table

| Symptom | Likely cause | Check |
|---|---|---|
| Every statement fails right after activation | Uncaught error in the script; without a `pcall` in the wrapper, the statement does not run | Clear the slot, then call the helper via `EXECUTE SCRIPT` with a plain `SELECT 1` as input |
| Works for the DBA, fails for everyone else | Missing `EXECUTE` grant on the script/schema, or the script reads an object the invoker cannot see (Lua scripts run with invoker rights) | `SELECT * FROM EXA_ALL_SCHEMA_PRIVILEGES WHERE SCHEMA_NAME = '<schema>';` and re-test as an ordinary user |
| Custom command still a syntax error | Preprocessor not active for that session; matcher failed on client-added leading comments or a trailing `-- comment`; text arrived lower-cased or with unexpected whitespace | Print the exact input in a test call; add the leading-comment strip from `lua-authoring-guide.md` |
| Transform fires on statements it should ignore | Match pattern is too loose, or it is matching inside a string literal or comment | Add literal-and-comment test cases; move to the region-aware scanner |
| A statement's results changed and nobody knows why | The rewrite is doing more than intended | `EXA_DBA_AUDIT_SQL` holds the original text and the transformed statement as two entries — compare them |
| "Function expects one parameter", or a stray number appearing in output | `string.gsub` two-value return forwarded directly | Capture the `gsub` result into a local first |
| Syntax error mentioning a second statement | The transform returned more than one statement | Return exactly one; use `EXECUTE SCRIPT` for multi-statement work |
| Deployed script body is corrupted; `object <NAME> not found` or `SyntaxError: expected ':'` | GUI SQL client substituted named parameters on the `:` characters in the Lua/Python body | Disable parameterized SQL in the client (DbVisualizer: *SQL Commander → Parameterized SQL → off*; DBeaver: *Preferences → Editors → SQL Editor → uncheck "Use named parameters"*) and redeploy. EXAplus is unaffected |
| `CREATE ... SCRIPT` DDL itself fails | Missing `--/` and `/` block delimiters around a body containing semicolons | Wrap the statement in `--/` … `/`, each on its own line |
| Everything got slower after activation | `query()`/`pquery()` or a UDF call on the hot path, or an O(n²) string build | Add a fast-path guard; hoist or gate the round-trip; use `table.concat` |
| A password-bearing statement is not transformed | Working as designed — `CREATE`/`ALTER USER`, `CREATE`/`ALTER CONNECTION`, and `IMPORT`/`EXPORT ... IDENTIFIED BY` are excluded | Nothing to fix; a preprocessor can never be a complete policy enforcement point |
| `EXECUTE SCRIPT` on the preprocessor script fails | `EXECUTE SCRIPT` cannot call a preprocessor script | Call the imported helper instead — the reason to split wrapper from logic |

## Performance Triage

If statements got slower, work through this in order:

1. **Is there a fast-path guard?** The first line of the transform should be a cheap `string.find` that returns the input immediately for statements that cannot match. Most statements in a real workload should exit there.
2. **Is there a `query()` or `pquery()` on the hot path?** Every statement in the system pays that round-trip. The documentation is explicit that these should be used only in exceptional cases when preprocessing is active globally. Hoist it to a constant, read it once from a definer-rights view, or gate it behind a marker so only opted-in statements pay.
3. **Is a UDF or container language involved?** A `CREATE PYTHON3|JAVA PREPROCESSOR SCRIPT` in the slot pays container overhead on every statement. Consider Lua in the slot with a companion UDF called only for marked statements — see `python-java-preprocessors.md`.
4. **Is a string being built with `..` in a loop?** Lua strings are immutable, so that is O(n²). Accumulate in a table, `table.concat` once.
5. **Is the transform re-tokenizing in a loop?** The `IF()`-to-`CASE` idiom re-tokenizes once per rewrite. Correct, but linear in the number of matches — fine for a handful, not for hundreds.
6. **Under the framework:** confirm the mode. `convenience` lets a session stop paying the lookup after its first statement; `strict` makes every statement pay it.

Measure rather than assume — compare the same statement with the slot set and with the slot cleared in the same session.

## Reviewing Someone Else's Preprocessor

A short checklist for auditing an existing script:

- What happens to a statement it does not recognize? It must come back **byte-for-byte**.
- Is there exactly one error boundary? A `pcall` in the wrapper for a standalone script; none inside a framework module.
- Is the failure mode the right one for the kind of transform? Fail-open is fine for command expansion, wrong for a policy rewrite, and fail-closed is mandatory for dialect translation.
- Does it look inside string literals and comments? If it uses a whole-text `gsub` on punctuation, it has a correctness bug.
- Is the transform idempotent? Running it twice on its own output must not corrupt the text.
- Is there a `query()`/`pquery()` or UDF call that unmarked statements pay for?
- Does the script name carry a version suffix, and is anything currently `CREATE OR REPLACE`-ing a live script?
- Is it being used as an access control? If so, say plainly that it is not one, and route to roles, privileges, and views.

## What A Preprocessor Cannot Do

State these when a user's plan depends on one:

- It cannot see or change **results** — only statement text.
- It cannot run **more than one statement** in place of the one it received.
- It cannot read a **remote system**. That is a virtual schema; route to **exasol-virtual-schema-adapter-development**.
- It cannot read data the **calling user** cannot read; Lua scripts run with invoker rights. The bridge is a definer-rights view.
- It cannot touch the **excluded statements** — anything carrying a password, or the `ALTER SESSION`/`ALTER SYSTEM` deactivation path.
- It is not an **access control**, because any user can clear the slot for their own session.
- It has no **transaction hook**. Writing an audit row per statement from inside a preprocessor is a transaction-conflict hazard; use `EXA_DBA_AUDIT_SQL` instead, which already records the original and transformed text.
