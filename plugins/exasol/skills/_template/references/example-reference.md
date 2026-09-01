# Example Reference

Rename this file to something that names its content — `import.md`,
`slc-reference.md`, `adapter-development.md` — and update every `Load:` line in
`SKILL.md` that points at it. A reference file that no `Load:` line names is an
orphan, and CI rejects it.

This file is where the actual content of a skill lives. It is read only when a
route in `SKILL.md` matches, so it can be long: several reference files in this
repo run past 400 lines. Use as many as the domain needs, one per task cluster,
and keep each one answerable on its own — the agent may load it without the
others.

## Scope

Open with the boundary of this file, not of the skill. State what a request has
to look like for this file to be the right answer, so an agent that loaded it on
a weak match can bail out early.

## Workflow

Give the steps in the order the user performs them, numbered, with the command or
statement that performs each one under the step it belongs to:

1. Check the precondition that most often fails — here, that the target exists
   and the current user can read it:

   ```sql
   SELECT COUNT(*) FROM "<schema>"."<table>";
   ```

2. Run the operation, with the one option that is easy to get wrong called out
   in the step rather than left to the reader.
3. Verify the result, and say what the expected output looks like so the agent
   can tell success from a silent no-op.

Use angle-bracket placeholders — `<schema>`, `<host>`, `<password>` — for
anything user-specific. Never put a real host name, user name, token, or
password in an example: `test/check-security.sh` scans tracked files for
credential-like material, and an example that looks copy-pasteable will be
copy-pasted.

## Behaviour Worth Knowing

Document what the official docs do not make obvious: the default that surprises
people, the option that silently does nothing, the error message and its real
cause. This is where a skill earns its place over a web search.

## Limits and Failure Modes

| Situation | What happens | What to do |
| --- | --- | --- |
| `<the common failure>` | `<the error the user sees>` | `<the fix>` |

## Safety

Call out destructive operations explicitly and say what to confirm before
running them. Link out for material that changes with every release — version
numbers go stale in a file an agent may read months from now, so name the
capability and link the release notes instead of quoting a version.
