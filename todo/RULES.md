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

## Task Numbering Convention

Tasks are numbered **per-epic**, with the epic number embedded in the task ID.

**Format**: `E<epic_number>-TASK-<task_number>`

Examples:
- Epic 1, Task 1 → `E1-TASK-01`
- Epic 1, Task 3 → `E1-TASK-03`
- Epic 2, Task 1 → `E2-TASK-01`
- Epic 2, [TEST] task → `E2-TASK-05` (last in that epic)

**Rules:**
- Epic numbers are assigned globally and sequentially as epics are created (E1, E2, E3...)
- Task numbers within an epic start at `01` and increment sequentially
- The `[TEST]` task always gets the last number in the epic (e.g. if there are 3 regular tasks, `[TEST]` is `TASK-04`)
- The `[RETEST]` task, if created, always follows immediately after `[TEST]` (e.g. `TASK-05`)
- Never reuse or reassign a task ID — if a task is removed, its ID is retired

---

## Epic Structure

```
## Epic N: <Epic Title>

<Short description of what this epic covers and what it delivers>

### Dependencies
- **Depends on**: <Other Epic> — <reason> | None
- **Intersects with**: <Other Epic or module> — <what is shared> | None

### Affected Files
- `src/path/to/file.ts` — created | modified | deleted
- `src/path/to/other.ts` — created | modified | deleted

### Tasks
- [ ] EN-TASK-01 — <Task Title>
- [ ] EN-TASK-02 — <Task Title>
- [ ] EN-TASK-03 — <Task Title>
- [ ] EN-TASK-04 — [TEST] <Epic Title> — Integration & Testing
```

---

## Task Structure

Each task is written as a second-level section under its Epic.

```
---

### EN-TASK-XX — <Task Title>

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`
**Depends on**: EN-TASK-XX | None
**Intersects with**: <Task or Epic name> — <what is shared> | None

#### Affected Files
| File | Change |
|---|---|
| `src/path/to/file.ts` | created \| modified \| deleted |

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

## Affected Files

Every epic and every task must list the files it will touch. This keeps the agent
focused — it should only open or modify files explicitly listed here.

### At the epic level

The epic's `Affected Files` is the **union** of all its tasks' affected files.
It gives a full picture of the epic's footprint across the codebase.

```
### Affected Files
- `src/audio/recorder.ts` — created
- `src/audio/types.ts` — modified
- `src/ui/RecordButton.tsx` — modified
- `src/utils/permissions.ts` — deleted
```

### At the task level

Each task lists only the files **that task** will touch — not the full epic scope.

```
#### Affected Files
| File | Change |
|---|---|
| `src/audio/recorder.ts` | created |
| `src/audio/types.ts` | modified |
```

### Change types

| Type | Meaning |
|---|---|
| `created` | File does not exist yet and will be created by this task |
| `modified` | File exists and will be changed |
| `deleted` | File will be removed entirely |

### Rules for Affected Files

- The agent **must not touch any file not listed** in the task's Affected Files
- If during implementation a new file needs to be added or removed, **update the list first**
  before making the change — this keeps the task spec accurate
- At the epic level, if a task adds a new file, the epic's Affected Files must also be updated
- Files shared between tasks within the same epic are a natural intersection point —
  flag them in the relevant tasks' `Intersects with` fields

---

## Dependencies & Intersections

When writing an epic or a task, you must explicitly map out dependencies and
intersections — places where tasks or epics touch shared code, state, or behavior.
These are the highest-risk areas for bugs and must be reflected in DoD and test checklists.

### Where to document dependencies

**At the epic level** — add a `Dependencies` section to the epic header:

```
## Epic: <Epic Title>

<Short description>

### Dependencies
- **Depends on**: <Other Epic or external system> — reason why
- **Intersects with**: <Other Epic or Task> — what is shared (e.g. audio pipeline, clipboard state)
- **None** (write explicitly if there are no dependencies)

### Tasks
- [ ] TASK-01 — ...
```

**At the task level** — add a `Dependencies` field to every task:

```
### EN-TASK-XX — <Task Title>

**Epic**: <Epic Title>
**Status**: `pending`
**Depends on**: EN-TASK-XX | None
**Intersects with**: <Other task or epic> | None
```

### What counts as a dependency or intersection

- **Depends on**: this task cannot start or will likely break if another task is not done first
- **Intersects with**: this task touches the same file, module, API, state, or user-facing behavior
  as another task or epic — they don't block each other but changes in one can affect the other

### How dependencies affect DoD and Test Checklists

- If a task **depends on** another → its DoD must include: `[ ] EN-TASK-XX is done and stable`
- If a task **intersects with** another → its Test Checklist must include a cross-check:
  `[ ] Verify <intersecting feature> still works correctly after changes in this task`
- The epic `[TEST]` task must include an intersection check for every flagged pair:
  `[ ] No regressions at the intersection of EN-TASK-XX and EN-TASK-YY`

### When writing a new epic

Before writing any tasks, scan existing epics and note:
1. Which existing epics does this one depend on?
2. Which modules or features does this epic touch that other epics also touch?
3. Are there tasks within this epic that must run in a specific order?

Document all findings in the epic's `Dependencies` section and carry them forward
into the affected tasks' DoD and test checklists.

---

## Testing Task (Last Task in Every Epic)

The final task in each Epic is always a dedicated testing task.
Its job is to verify the entire Epic end-to-end, not just individual pieces.

```
---

### EN-TASK-XX — [TEST] <Epic Title> — Integration & Testing

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`
**Depends on**: EN-TASK-01, EN-TASK-02, EN-TASK-03 (all other tasks in this epic)
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/<epic-file>.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

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
- [ ] EN-TASK-01: <brief description of what to verify>
- [ ] EN-TASK-02: <brief description of what to verify>
- [ ] EN-TASK-03: <brief description of what to verify>
- [ ] Full flow works end-to-end as described in the epic
- [ ] No regressions at intersections flagged across the epic
```

---

## Retest Task (Created When a Bug is Found in [TEST])

A `[RETEST]` task is created only when a bug is found during an epic's `[TEST]` task.
Its structure is identical to the `[TEST]` task — it re-runs the full epic validation
after the bug has been fixed.

```
---

### EN-TASK-XX — [RETEST] <Epic Title> — Re-run After Bug Fix

**Epic**: <Epic Title>
**Status**: `pending` | `in progress` | `done`
**Depends on**: EN-TASK-XX ([TEST] task, where the bug was found and fixed)
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/<epic-file>.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

#### Description
Re-test task for the <Epic Title> epic. Created because a bug was found and fixed
during the [TEST] task. Validates that the fix is correct and that the full epic
still works end-to-end with no regressions.

#### Work
- Confirm the bug fix is in place (see Bug Log entry BUG-XX)
- Re-run the full test checklist from the [TEST] task
- Manually verify the user-facing behavior described in the epic

#### Definition of Done (DoD)
- [ ] BUG-XX is marked `done` in `todo/bugs.md`
- [ ] All test cases below pass
- [ ] No new regressions introduced

#### Test Checklist
(Same checklist as the [TEST] task — copy it in full)
- [ ] EN-TASK-01: <brief description of what to verify>
- [ ] EN-TASK-02: <brief description of what to verify>
- [ ] EN-TASK-03: <brief description of what to verify>
- [ ] Full flow works end-to-end as described in the epic
- [ ] No regressions at intersections flagged across the epic
- [ ] BUG-XX: <brief description of the fixed bug — confirm it no longer reproduces>
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

**Found in**: <Epic Name> / <EN-TASK-ID>
**Found during**: `regular task` | `[TEST] task`
**Status**: `pending` | `in progress` | `done`

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
11. Every epic must have a `Dependencies` section — write `None` explicitly if there are none
12. Every task must have `Depends on` and `Intersects with` fields
13. Dependencies and intersections must be reflected in DoD and Test Checklists of affected tasks
14. The epic `[TEST]` task must include a regression check for every intersection flagged in the epic
15. Every epic and task must have an `Affected Files` list — the agent must not touch unlisted files
16. If a new file is needed during implementation, update `Affected Files` in the task (and epic) first
