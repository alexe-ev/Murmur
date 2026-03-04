# Todo — Rules & Conventions

This document defines how epics and tasks are structured in this project.
All todo files must follow these rules exactly.

---

## File Structure

- Each todo file covers one area of work (e.g. `todo/audio.md`, `todo/ui.md`)
- A file contains one or more **Epics**
- Each Epic contains multiple **Tasks**
- The **last task** of every Epic must always be a **Testing Task** that validates all work done in that Epic

---

## Epic Structure

```
## Epic: <Epic Title>

<Short description of what this epic covers and what it delivers>

### Tasks
- [ ] TASK-01 — <Task Title>
- [ ] TASK-02 — <Task Title>
- [ ] TASK-03 — <Task Title>
- [ ] TASK-04 — [TEST] <Epic Title> — Integration & Testing
```

---

## Task Structure

Each task is written as a second-level section under its Epic.

```
---

### TASK-XX — <Task Title>

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`

#### Description
A short paragraph explaining the context and purpose of this task.

#### Work
A clear list of everything that needs to be implemented or done:
- Item 1
- Item 2
- Item 3

#### Definition of Done (DoD)
A checklist of conditions that must all be true before this task is considered complete:
- [ ] Condition 1
- [ ] Condition 2
- [ ] Condition 3

#### Test Checklist
Manual or automated checks to verify this task works correctly:
- [ ] Test case 1
- [ ] Test case 2
- [ ] Test case 3
```

---

## Testing Task (Last Task in Every Epic)

The final task in each Epic is always a dedicated testing task.
Its job is to verify the entire Epic end-to-end, not just individual pieces.

```
---

### TASK-XX — [TEST] <Epic Title> — Integration & Testing

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`

#### Description
End-to-end testing task for the <Epic Title> epic. Validates that all tasks
in this epic work correctly together as a whole.

#### Work
- Review all tasks in the epic are marked done
- Run integration tests covering the full epic scope
- Manually verify the user-facing behavior described in the epic

#### Definition of Done (DoD)
- [ ] All prior tasks in this epic are marked `done`
- [ ] All test cases below pass
- [ ] No regressions introduced in related areas

#### Test Checklist
A comprehensive checklist covering every task in the epic:
- [ ] TASK-01: <brief description of what to verify>
- [ ] TASK-02: <brief description of what to verify>
- [ ] TASK-03: <brief description of what to verify>
- [ ] Full flow works end-to-end as described in the epic
```

---

## Status Values

| Status | Meaning |
|---|---|
| `pending` | Not started |
| `in progress` | Actively being worked on |
| `done` | All DoD conditions met |

---

## Agent Workflow

These rules govern how an agent must behave when picking up and completing work.

### Before starting any task — mandatory reading

1. Read `CLAUDE.md` — project context, constraints, development notes
2. Read `ARCHITECTURE.md` — current system design
3. Read `PRD.md` — product requirements and feature intent
4. Read `todo/roadmap.md` — find the next pending task, understand the full picture
5. Open the epic file the task belongs to — read the full epic and all its tasks

Only after completing all five steps should the agent begin implementation.

### Picking the next task

- Open `todo/roadmap.md` and locate the **first epic** that is not `done`
- Inside that epic, find the **first task** with status `pending`
- That is the task to work on — do not skip tasks or work out of order
- Never start a `[TEST]` task until every other task in that epic is `done`

### After completing a task — mandatory updates

Update **all three places** before the task is considered finished:

1. **Task file** — set status to `done`, check off all DoD items
2. **Epic index** in the same task file — check off the task in the epic's task list
3. **`todo/roadmap.md`** — update the task's status in the epic table

If the work introduced changes worth documenting:
- Update `ARCHITECTURE.md` if system design changed
- Update `CLAUDE.md` if there are new notes relevant to future agents
- Update `PRD.md` only if product scope or requirements changed (rare)

---

## Bug Handling

### Bug found during a regular task

If a bug is discovered while implementing or verifying a regular task — fix it
immediately as part of that same task. Log it in the Bug Log (see below).

### Bug found during an epic [TEST] task

If a bug is discovered during the epic's `[TEST]` task:

1. **Fix it** within that same `[TEST]` task — do not create a separate fix task
2. **Log it** in the Bug Log (see below)
3. **Create an extra re-test task** for the epic: `[RETEST] <Epic Title> — Re-run After Bug Fix`
   - Add it to the epic's task list in the task file and in `roadmap.md`
   - The `[RETEST]` task's checklist must cover the full epic again
   - Only after the `[RETEST]` task passes is the epic considered `done`

### Bug Log — `todo/bugs.md`

All bugs found at any point must be recorded in `todo/bugs.md`.
This file is **not tied to any epic** — it is a global log.

Its purpose: before a release, the team uses this file to re-verify every known
issue was truly fixed. Every entry must include the epic and task where the bug
was found, a short description, and the fix applied.

```
## BUG-XX — <Short Bug Title>

**Found in**: <Epic Name> / <TASK-ID>
**Found during**: regular task | [TEST] task
**Status**: `fixed`

### Description
What the bug was and how it manifested.

### Fix
What was done to fix it.

### Verification
- [ ] Fix confirmed in the task where it was found
- [ ] Re-tested in the epic [RETEST] task (if applicable)
```

The Bug Log is also linked from `todo/roadmap.md` for quick access.

---

## Rules Summary

1. Every epic must have at least 2 tasks + 1 testing task
2. Every task must have: Title, Epic, Status, Description, Work, DoD, Test Checklist
3. The last task in every epic is always a `[TEST]` task
4. The `[TEST]` task's checklist must reference every other task in the epic
5. A task is only `done` when every item in its DoD checklist is checked
6. The `[TEST]` task cannot be `done` until all other tasks in the epic are `done`
7. After every completed task the agent must update: task file, epic index, and roadmap.md
8. Every bug found (anywhere) must be logged in `todo/bugs.md`
9. A bug found in a `[TEST]` task triggers a `[RETEST]` task for the full epic
10. `todo/bugs.md` is the pre-release verification checklist — never delete entries from it
