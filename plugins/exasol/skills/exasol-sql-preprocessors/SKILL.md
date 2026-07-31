---
name: exasol-sql-preprocessors
description: "Write, deploy, test, and debug Exasol SQL preprocessor scripts that rewrite statement text before compilation. Covers the SQL_PREPROCESSOR_SCRIPT slot, the Lua sqlparsing library, Python3 and Java PREPROCESSOR SCRIPT entry points, custom SQL commands and dialect translation, fail-open and fail-closed safety, testing without a live slot, and the optional Exasol Labs preprocessor framework for running many preprocessors from the one slot."
---

# Exasol SQL Preprocessor Skill

Trigger when the user mentions **SQL preprocessor**, **preprocessor script**, **SQL_PREPROCESSOR_SCRIPT**, **sqlparsing**, **rewrite SQL before execution**, **custom SQL command**, **add syntax to Exasol**, **SQL dialect translation inside Exasol**, **transpile SQL in the database**, **statement rewriting**, **query guardrails in SQL text**, **CREATE PREPROCESSOR SCRIPT**, **preprocessor framework**, **preprocessor module**, or **PREPROC ADD RULE**.

A preprocessor is a text-in / text-out transformation the database applies to every SQL statement before the compiler sees it. It is the only supported way to make Exasol accept syntax it does not have.

## First: Two Facts That Shape Every Answer

1. **There is exactly one slot per system.** `SQL_PREPROCESSOR_SCRIPT` holds one script name. Whoever occupies it owns preprocessing for the whole database, so "add a second preprocessor" is never a plain deploy — it is either a merge into the existing script or a dispatcher (see route 4).
2. **The off switch cannot be broken by a broken script.** The `ALTER SESSION` / `ALTER SYSTEM` statements that set `SQL_PREPROCESSOR_SCRIPT` are deliberately excluded from preprocessing, so `= NULL` always works. Say this early whenever a user is nervous about activating one.

Never activate a preprocessor at `ALTER SYSTEM` scope as a first step. Always prove it at `ALTER SESSION` scope in the author's own session first.

## Routing Algorithm

Choose the narrowest matching route. Load `references/preprocessor-basics.md` for any route other than route 4 alone.

1. **Understand the mechanism, activate or deactivate it, or read the API surface**
   - Trigger phrases: `what is a SQL preprocessor`, `SQL_PREPROCESSOR_SCRIPT`, `activate preprocessor`, `turn off preprocessor`, `ALTER SESSION SET SQL_PREPROCESSOR_SCRIPT`, `sqlparsing`, `tokenize`, `getsqltext`, `setsqltext`, `which statements are not preprocessed`, `preprocessor privileges`, `audit preprocessed SQL`
   - Load: `references/preprocessor-basics.md`

2. **Write a Lua preprocessor**
   - Trigger phrases: `write a preprocessor`, `custom SQL command`, `add syntax to Exasol`, `rewrite my SQL`, `Lua preprocessor`, `CREATE LUA SCRIPT` with preprocessor intent, `token scanning`, `string.gsub in a preprocessor`, `inject a filter into every query`, `block a statement pattern`
   - Load: `references/preprocessor-basics.md`, then `references/lua-authoring-guide.md`

3. **Write a Python 3 or Java preprocessor**
   - Trigger phrases: `Python preprocessor`, `PYTHON3 PREPROCESSOR SCRIPT`, `JAVA PREPROCESSOR SCRIPT`, `adapter_call`, `adapterCall`, `sqlglot in a preprocessor`, `transpile T-SQL in Exasol`, `use a Python library to rewrite SQL`
   - Load: `references/preprocessor-basics.md`, then `references/python-java-preprocessors.md`
   - Requires Exasol **2025.1.5 or later**. Check the target version before recommending this path.

4. **Run more than one preprocessor, or scope preprocessing per role, user, or client**
   - Trigger phrases: `multiple preprocessors`, `two preprocessors`, `preprocessor framework`, `preprocessor module`, `PREPROC ADD RULE`, `PREPROC INSTALL MODULE`, `PREPROC_RT.MASTER`, `MY_PIPELINE`, `preprocessor per role`, `only for these users`, `only for DbVisualizer`, `install a ready-made preprocessor`, `publish my preprocessor`
   - Load: `references/preprocessor-framework.md`
   - Also load `references/lua-authoring-guide.md` when the user is writing the transformation itself, not only wiring it up.

5. **Deploy, roll out, roll back, or debug a preprocessor**
   - Trigger phrases: `preprocessor broke my queries`, `every statement fails`, `preprocessor not firing`, `preprocessor performance`, `slow since we enabled the preprocessor`, `roll out preprocessor`, `roll back preprocessor`, `test a preprocessor`, `version a preprocessor`, `preprocessor error message`
   - Load: `references/operations-and-troubleshooting.md`
   - For a suspected authoring bug, also load `references/lua-authoring-guide.md`.

## Framework or No Framework

The framework is [`exasol-labs/preprocessor-framework`](https://github.com/exasol-labs/preprocessor-framework); its module catalog is [`exasol-labs/preprocessor-library`](https://github.com/exasol-labs/preprocessor-library).

Both paths are legitimate. Decide with this, and state the choice explicitly rather than defaulting:

| Situation | Recommend |
|---|---|
| One transformation, one cluster, the slot is free | **No framework.** One `CREATE LUA SCRIPT` plus one `ALTER SESSION`/`ALTER SYSTEM`. |
| The slot is already occupied by something you do not own | **Framework**, or merge into the incumbent script — do not silently take the slot. |
| Two or more independent transformations | **Framework.** Hand-merging independent transforms into one script is where preprocessor projects rot. |
| The transform must apply to some roles/users/clients and not others | **Framework.** Scoping is its main feature; hand-rolling it means a per-statement identity lookup you have to write and secure yourself. |
| You want to install a ready-made transform, or publish yours | **Framework** plus `exasol-labs/preprocessor-library`. |
| Air-gapped cluster, minimal moving parts, one transform | **No framework.** |

Do not present the framework as a prerequisite for writing a preprocessor. It is not. The transformation function is identical either way; the framework only changes how it is dispatched, scoped, and distributed.

## Non-Negotiable Rules to Carry Into Any Answer

- Prove it at session scope before system scope, and give the user the `= NULL` rollback line in the same message as the activation line.
- Recommend a version suffix (`_V1`, `_V2`) on the script name and never `CREATE OR REPLACE` over a script that is live in someone's session.
- A preprocessor must return exactly **one** SQL statement. Nothing splits the returned text on semicolons.
- Keep `query()` / `pquery()` out of the transformation path unless there is no alternative — every statement in the system pays for it.
- Statements the preprocessor does not recognize must pass through **byte-for-byte unchanged**. A preprocessor that reformats statements it does not handle is a defect.
- Never write a preprocessor whose purpose is to hide, silently redirect, or misreport what a statement does to the user who submitted it. Text rewriting that changes results without the caller's knowledge is a support and audit hazard; if the user wants access control, route them to Exasol roles, privileges, and views instead.

## Notes

- Use **exasol-udfs** for the general `CREATE SCRIPT` / UDF / `ExaIterator` surface, Script Language Containers, and Lua execute scripts that are not in the preprocessor slot.
- Use **exasol-database** for the SQL the preprocessor emits, and for reserved-keyword or identifier-quoting questions about the generated text.
- Use **exasol-virtual-schema-adapter-development** when the goal is federating an external source rather than rewriting local statement text. A preprocessor cannot read a remote system; a virtual schema can.
- Use **exasol-bucketfs** when a companion UDF needs files, or when a framework module is staged in a bucket for an air-gapped install.
