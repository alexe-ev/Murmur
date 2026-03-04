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

## Rules Summary

1. Every epic must have at least 2 tasks + 1 testing task
2. Every task must have: Title, Epic, Status, Description, Work, DoD, Test Checklist
3. The last task in every epic is always a `[TEST]` task
4. The `[TEST]` task's checklist must reference every other task in the epic
5. A task is only `done` when every item in its DoD checklist is checked
6. The `[TEST]` task cannot be `done` until all other tasks in the epic are `done`
7. After every completed task the agent must update: task file, epic index, and roadmap.md
