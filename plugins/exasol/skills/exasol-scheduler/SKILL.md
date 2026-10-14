---
name: exasol-scheduler
description: "Schedule SQL jobs on an Exasol database with Exasol Scheduler, the table-driven scheduler whose task definitions and execution history are plain SQL tables. Covers the SCHED_TASKS and SCHED_HISTORY tables, the exasol_scheduler binary, six-field CRON schedules with a TZ= timezone, the SQL_TEXT, AFTER, IS_FINAL, ENABLED, and PARALLEL_CHILDREN columns, GRAPH_RUN_ID pipeline runs, pausing and hot-reloading tasks without a restart, and diagnosing tasks that did not run."
---

# Exasol Scheduler Skill

Exasol Scheduler runs SQL jobs on a schedule: tasks are rows in the
`SCHED_TASKS` table, every execution lands in `SCHED_HISTORY`, and the whole
surface — defining, chaining, pausing, auditing — is plain SQL. This skill
covers managing those tasks and operating the scheduler process. It is a SQL
scheduler, not a workflow runner: `SQL_TEXT` goes straight to the database, and
work that needs a shell, Python, or dbt belongs elsewhere.

Trigger when the user mentions **scheduled SQL jobs**, **SCHED_TASKS**,
**cron for Exasol**, **task chains**, or **a scheduled job that did not run**.

## Routing Algorithm

1. **Define, change, pause, or audit tasks**
   - Trigger phrases: `schedule a query`, `run this SQL every night`, `SCHED_TASKS`, `SCHED_HISTORY`, `pause a task`, `task chain`, `finalizer`, `CRON`
   - Load: `references/task-management.md`

2. **Install, run, supervise, or secure the scheduler process**
   - Trigger phrases: `install exasol-scheduler`, `run the scheduler`, `exasol_scheduler`, `EXA_HOST`, `DSN`, `systemd`, `Docker`, `least privilege`, `scheduler user`
   - Load: `references/operations.md` **and** `references/upstream-docs.md`

3. **Diagnose a task that failed, was skipped, or never ran**
   - Trigger phrases: `job did not run`, `FAILED`, `SKIPPED`, `INVALID`, `missed run`, `insufficient privileges`, `ran twice`
   - Load: `references/task-management.md` **and** `references/operations.md`

4. **Complex pipeline design, exact failure semantics, or anything this
   skill's references do not settle** — fetch the upstream normative agent
   reference before answering
   - Load: `references/upstream-docs.md`

## Non-Negotiable Rules

- **`SCHED_TASKS` is a code-execution surface.** Whoever can `INSERT` or
  `UPDATE` a row runs arbitrary SQL as the scheduler's database user. Show the
  user a task's `SQL_TEXT` before inserting or changing it — that text will run
  unattended, repeatedly.
- **Never route a task-write around a rejected write path.** If the current
  connection cannot write `SCHED_TASKS`, that is a trust boundary working, not
  an obstacle: report it and let the user run the write over an admin
  connection they control.
- **Validate with `SCHED_HISTORY`, not with silence.** A task that never
  appears in history did not run; never report success without a `SUCCEEDED`
  row.
- **Missed runs are never replayed.** A trigger missed while the scheduler
  process is down leaves no history row at all. Say so plainly when scheduling
  on machines that sleep or restart.
- **Never point two scheduler processes at the same task table** — every task
  would run twice.

## Notes

- Use **exasol-database** for general SQL, schema inspection, and table design;
  the SQL inside a task's `SQL_TEXT` is ordinary Exasol SQL that skill covers.
- Use **exasol-extension-catalog** when the user is still comparing scheduling
  and orchestration options rather than operating this scheduler.
- Use **exasol-setup-personal** to set up the Exasol database itself; this
  skill assumes a reachable database and schedules work on it.
