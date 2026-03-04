# Roadmap

This file is the **agent's entry point** for all task work.
Open this first, find the next task, then read the full context before touching any code.

---

## How to read this file

- Epics are listed in priority order (top = highest priority)
- Each epic links to its detail file
- Statuses are kept in sync with the individual task files
- **Next task to pick up** = the first `pending` task in the first non-`done` epic

---

## Quick Links

| Document | Purpose |
|---|---|
| `todo/roadmap.md` | This file — task navigation and status overview |
| `todo/bugs.md` | Global bug log — all found bugs, fixes, and pre-release re-verification |
| `todo/RULES.md` | Full conventions for epics, tasks, bugs, and agent workflow |

---

## Current Focus

> _(No active tasks yet — epics and tasks will be added here as planning progresses)_

---

## Epics

| # | Epic | File | Status | Progress |
|---|---|---|---|---|
| — | _(no epics yet)_ | — | — | — |

---

## Epic Detail

_(Sections below will be added as epics are created, one subsection per epic)_

---

## Roadmap Rules (for the agent)

These rules are **mandatory** every time the agent picks up work:

### Before starting any task

1. Read `CLAUDE.md` — project context, constraints, and development notes
2. Read `ARCHITECTURE.md` — current system design
3. Read `PRD.md` — product requirements and feature intent
4. Read this file (`todo/roadmap.md`) — find the next pending task
5. Open the epic file the task belongs to, read the full epic and all its tasks

Only after completing steps 1–5 should the agent begin implementation.

### Picking the next task

- Find the **first epic** that is not `done`
- Inside that epic, find the **first task** that is `pending`
- That is the task to work on
- Never skip tasks or work out of order within an epic
- Never start the `[TEST]` task until all other tasks in the epic are `done`

### After completing a task

Update **all three places** before considering the work finished:

1. **Task file** — mark the task status as `done`, check off all DoD items
2. **Epic index** in the task file — check off the task in the epic's task list
3. **This file** — update the task status in the epic's table below

Additionally, if the work introduced changes worth documenting:
- Update `ARCHITECTURE.md` if the system design changed
- Update `CLAUDE.md` if there are new development notes relevant to future agents
- Update `PRD.md` only if product scope or requirements changed (rare)

### Status values

| Status | Meaning |
|---|---|
| `pending` | Not started |
| `in progress` | Agent is actively working on this |
| `done` | All DoD conditions met and verified |

---

## Task Status Template (copy when adding a new epic)

```
### Epic N — <Epic Title>

**File**: `todo/<filename>.md`
**Status**: `pending`

| Task | Title | Status |
|---|---|---|
| TASK-01 | <Task Title> | `pending` |
| TASK-02 | <Task Title> | `pending` |
| TASK-03 | [TEST] <Epic Title> — Integration & Testing | `pending` |
```
