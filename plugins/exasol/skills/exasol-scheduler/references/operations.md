# Running and Securing the Scheduler

The scheduler is a single stateless binary, `exasol_scheduler`, that polls the
task table and executes due `SQL_TEXT` against Exasol. No broker, no controller
plane, no state outside the database.

For anything that installs or provisions — building from source, prebuilt
binaries, systemd units, Docker packaging, the full environment-variable
list — fetch the upstream document named in `upstream-docs.md` rather than
reproducing steps from memory.

## Starting it

```bash
# Positional DSN:
exasol_scheduler "exasol://myuser:PASSWORD@exasol-host:8563?tls=1"

# Or environment variables (full list in upstream docs/configuration.md):
export EXA_HOST=exasol-host
export EXA_USER=myuser
export EXA_PASSWORD=...
export EXA_TLS=true
exasol_scheduler
```

On first startup it creates the `SCHED` schema plus `SCHED_TASKS` and
`SCHED_HISTORY` automatically — no DDL required. `EXA_SCHEMA` changes the
schema name.

Never place the password on a command line where `ps` would show it when an
environment or credentials-file option is available, and never print or log a
credential value.

Users of the Exasol Personal Local Starter Kit should install the scheduler
from `exakit marketplace` instead of running the binary by hand — the kit
provisions a least-privilege database user, supervises the process, and wires
it into `exakit status`/`start`/`stop`/`logs`. The kit's own bundled skill
covers that path.

## Least privilege — the grant list is the blast radius

`SCHED_TASKS` is a code-execution surface: whoever can write a row runs
arbitrary SQL as the scheduler's database user. Run the scheduler as a
**dedicated database user**, not as `SYS`, and grant that user only what its
jobs touch:

```sql
CREATE USER scheduler_svc IDENTIFIED BY "...";
GRANT CREATE SESSION TO scheduler_svc;
-- bootstrap only, revoke once SCHED exists:
GRANT CREATE SCHEMA, CREATE TABLE TO scheduler_svc;
-- per job, explicitly:
GRANT SELECT, INSERT ON SCHEMA MY_SCHEMA TO scheduler_svc;
```

After the first startup has created the schema, revoke the bootstrap grants
and prove the posture rather than asserting it:

```sql
REVOKE CREATE SCHEMA, CREATE TABLE FROM scheduler_svc;
SELECT PRIVILEGE FROM EXA_DBA_SYS_PRIVS WHERE GRANTEE = 'SCHEDULER_SVC';
-- expect exactly: CREATE SESSION
```

The upstream `docs/security.md` carries the full trust model and hardening
checklist — fetch it before advising on production credential handling.

## Supervision realities

- **A root task failure exits the process** by design (child and finalizer
  failures do not). Run the scheduler under a supervisor — systemd
  `Restart=on-failure`, Docker restart policy, or the starter kit's launcher —
  and alert on repeated restarts, because a persistently failing root will
  crash-loop it.
- **Missed runs are never replayed.** A machine asleep or a process down at
  02:00 does not run the 02:00 job later; the next occurrence is computed from
  the current clock, and no history row marks the gap. If a run must happen
  after wake, use a shorter schedule or trigger the SQL once by hand.
- **One process per task table.** Two pollers on the same table run every job
  twice. Separate failure domains get separate processes with distinct task
  tables (`EXA_SCHEMA`), never a shared one.

## Diagnosing

| You see | It means | Do |
|---|---|---|
| a `FAILED` row with `insufficient privileges` | the task touches a schema the scheduler's user has no grant for | `GRANT` what the job needs; it retries on the next occurrence |
| nothing in `SCHED_HISTORY` for a due task | process not running, task `ENABLED = FALSE`, or an orphan/cycle `AFTER` reference | check the process, the row's `"ENABLED"`, and that `"AFTER"` names an existing `TASK_ID` |
| a task ran twice per occurrence | two scheduler processes poll the same task table | stop one; give independent deployments distinct task tables |
| an `INVALID` row with `GRAPH_PHASE = 'VALIDATION'` | the task row itself was rejected while loading | fix the row (schedule syntax, references) and it reloads on the next poll |
| every pipeline stopped at once | a root task failed and the process exited | read the process logs, fix the root's SQL, let the supervisor restart it |
| the current connection cannot write `SCHED_TASKS` | a read-only trust boundary, working as designed | report it; the user runs the write over an admin connection |
